// 列表页 BLoC 状态机的测试。
//
// 覆盖 lib/bloc/dog_bloc.dart 与 lib/bloc/dog_lost_bloc.dart 里**从来没被执行过**
// 的几条分支：
//   1. 重置（下拉刷新 / 切筛选 / 调页大小）→ 第一页数据 + reset 标志
//   2. 已经到最后一页时，滚动事件应当被**直接吞掉**
//      （旧实现无条件调 goNextPage()，它在末页抛 StateError，
//       被 catch 之后整个列表被打成"加载失败"，已经拉到的数据全没了）
//   3. 滚动加载 → 新一页**追加**在尾部，不是替换
//   4. 翻页失败 → 保留已加载的数据，并把服务端 message 透出来
//   5. throttle + droppable → 连击滚动只放一个请求出去
//
// 本文件自身不 import Flutter —— 但注意整条链路仍然牵进了 Flutter：
// DogService → BasicService → Request → Login → flutter_udid → dart:ui。
// 所以它只能在 `flutter test`（真引擎）里跑，不能丢给纯 Dart VM。
// 状态机逻辑本身（dog_bloc.dart）是纯 Dart 的，这也是当初把它拆成泛型基类的原因之一。

import 'package:flutter_test/flutter_test.dart';

import 'package:find_dog/bloc/dog_bloc.dart';
import 'package:find_dog/bloc/dog_lost_bloc.dart';
import 'package:find_dog/bloc/dog_lost_event.dart';
import 'package:find_dog/models/dog_lost.dart';
import 'package:find_dog/models/dog_lost_selection.dart';

import 'support/fake_http.dart';

/// 订阅"终态"（success / failure），用来 await 一次请求走完。
///
/// ⚠️ 必须在 `bloc.add(...)` **之前**调用：`bloc.stream` 是广播流、不重放历史状态，
/// 先 add 再订阅会永远等不到（这正是 list.dart 里 `_awaitFetch` 的写法）。
Future<DogState<DogLost, DogLostSelection>> latestDone(
  DogLostLatestFetchBloc bloc,
) =>
    bloc.stream
        .firstWhere((DogState<DogLost, DogLostSelection> s) =>
            s.status == DogStatus.success || s.status == DogStatus.failure)
        .timeout(const Duration(seconds: 10));

void main() {
  test('重置事件：第一页数据落地，reset 标志置位', () async {
    final FakeHttpAdapter http = installFakeHttp(
      (_) => successEnvelope(list: lostDogs(3), nextPage: true),
    );
    final DogLostLatestFetchBloc bloc = DogLostLatestFetchBloc();
    addTearDown(bloc.close);

    final Future<DogState<DogLost, DogLostSelection>> done = latestDone(bloc);
    bloc.add(const DogLostLatestFetchWithResetEvent(pageSize: 25));
    final DogState<DogLost, DogLostSelection> state = await done;

    expect(state.status, DogStatus.success);
    expect(state.dogs, hasLength(3));
    expect(state.dogs.first.locationName, '示例小区1');
    expect(state.reset, isTrue,
        reason: '重置类事件必须置 reset=true —— UI 靠它把列表 jumpTo(0)');
    expect(state.hasMore, isTrue);

    expect(http.requests, hasLength(1));
    expect(http.requests.single.queryParameters['page'], 1);
    expect(http.requests.single.queryParameters['pageSize'], 25);
  });

  test('已是最后一页：滚动事件被吞掉，既不发请求也不污染状态', () async {
    final FakeHttpAdapter http = installFakeHttp(
      (_) => successEnvelope(list: lostDogs(3), nextPage: false),
    );
    final DogLostLatestFetchBloc bloc = DogLostLatestFetchBloc();
    addTearDown(bloc.close);

    final Future<DogState<DogLost, DogLostSelection>> done = latestDone(bloc);
    bloc.add(const DogLostLatestFetchWithResetEvent(pageSize: 25));
    expect((await done).hasMore, isFalse);

    final int before = http.requests.length;
    bloc.add(const DogLostLatestFetchEvent());
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(http.requests.length, before,
        reason: 'onDogFetched 必须先看 pagination.nextPage；'
            '否则 goNextPage() 抛 StateError，catch 之后整个列表被打成失败态');
    expect(bloc.state.status, DogStatus.success);
    expect(bloc.state.dogs, hasLength(3));
  });

  test('滚动加载：新一页追加在尾部，不是替换', () async {
    final FakeHttpAdapter http = installFakeHttp((o) {
      final int page = int.tryParse('${o.queryParameters['page']}') ?? 1;
      return successEnvelope(
        list: lostDogs(25, base: page * 1000),
        page: page,
        nextPage: page < 2,
      );
    });
    final DogLostLatestFetchBloc bloc = DogLostLatestFetchBloc();
    addTearDown(bloc.close);

    final Future<DogState<DogLost, DogLostSelection>> first = latestDone(bloc);
    bloc.add(const DogLostLatestFetchWithResetEvent(pageSize: 25));
    expect((await first).dogs, hasLength(25));

    final Future<DogState<DogLost, DogLostSelection>> second = latestDone(bloc);
    bloc.add(const DogLostLatestFetchEvent());
    final DogState<DogLost, DogLostSelection> state = await second;

    expect(http.queryValuesOf('page'), <int>[1, 2]);
    expect(state.dogs, hasLength(50), reason: '第二页必须追加而不是替换');
    expect(state.dogs.first.id, 1001, reason: '第一页的记录应还在最前面');
    expect(state.dogs.last.id, 2025, reason: '第二页的记录应接在最后面');
    expect(state.hasMore, isFalse, reason: 'page=2 时服务端给了 nextPage=false');
  });

  test('翻页失败：保留已加载的数据，并把服务端 message 透出来', () async {
    int calls = 0;
    installFakeHttp((_) {
      calls++;
      return calls == 1
          ? successEnvelope(list: lostDogs(3), nextPage: true)
          : failureEnvelope('服务器开小差');
    });
    final DogLostLatestFetchBloc bloc = DogLostLatestFetchBloc();
    addTearDown(bloc.close);

    final Future<DogState<DogLost, DogLostSelection>> first = latestDone(bloc);
    bloc.add(const DogLostLatestFetchWithResetEvent(pageSize: 25));
    expect((await first).status, DogStatus.success);

    final Future<DogState<DogLost, DogLostSelection>> second = latestDone(bloc);
    bloc.add(const DogLostLatestFetchEvent());
    final DogState<DogLost, DogLostSelection> bad = await second;

    expect(bad.status, DogStatus.failure);
    expect(bad.dogs, hasLength(3), reason: '一次翻页失败不能把已经拉到的数据清空');
    expect(bad.errorMessage, contains('服务器开小差'),
        reason: 'RequestError 已经把服务端的 message 放好了');
  });

  test('连击滚动事件：throttle + droppable 只放一个请求出去', () async {
    final FakeHttpAdapter http = installFakeHttp((o) {
      final int page = int.tryParse('${o.queryParameters['page']}') ?? 1;
      return successEnvelope(
        list: lostDogs(5, base: page * 100),
        page: page,
        nextPage: true,
      );
    });
    final DogLostLatestFetchBloc bloc = DogLostLatestFetchBloc();
    addTearDown(bloc.close);

    final Future<DogState<DogLost, DogLostSelection>> done = latestDone(bloc);
    // 模拟快速滑动：同一帧里连扔三个事件
    bloc.add(const DogLostLatestFetchEvent());
    bloc.add(const DogLostLatestFetchEvent());
    bloc.add(const DogLostLatestFetchEvent());
    await done;
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(http.requests, hasLength(1),
        reason: '100ms 窗口内的重复滚动事件应被 throttle 丢弃；'
            'droppable 再兜一层，保证事件不会被并发处理');
  });
}
