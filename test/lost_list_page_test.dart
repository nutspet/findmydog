// 「失踪汪救助中心」列表页（lib/screens/lost/list.dart）的 widget 测试。
//
// 背景：这一页连同 lost_list_picker / lost_list_item / bottom_loader，
// 在 BLoC 改造之后**从未真正运行过** —— 此前只有静态分析与纯 Dart 断言背书。
// 本文件第一次让它们在真实 Flutter 引擎里跑起来：真渲染、真布局、真跑状态机，
// 并用一个假的 HTTP 适配器切断外网依赖。
//
// 不覆盖的部分（有意为之）：
//   - 网络图片分支：LostListItem 的 CachedNetworkImage 依赖 path_provider /
//     sqflite 这类原生插件，widget test 里没有实现。所以假数据里 pic 一律为空，
//     走 FlutterLogo 占位分支。图片分支留作后续用 mock 覆盖。
//   - 真实 GPS：测试环境没有 geolocator 插件，'附近' tab 只能走失败分支。
//   - 详情页 / 发布页：需要单独起页面，不属本次范围。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_dog/models/dog_lost_selection.dart';
import 'package:find_dog/screens/lost/list.dart';
import 'package:find_dog/screens/lost/lost_list_item.dart';
import 'package:find_dog/screens/lost/lost_list_picker.dart';
import 'package:find_dog/widgets/bottom_loader.dart';

import 'support/fake_http.dart';

/// 推进若干帧。
///
/// 刻意**不用** `pumpAndSettle()`：只要列表还有下一页，末尾就挂着 BottomLoader，
/// 里面的 CircularProgressIndicator 会永远调度下一帧 —— pumpAndSettle 必然超时。
Future<void> ride(WidgetTester tester, {int frames = 12}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Widget app() => const MaterialApp(home: LostList());

/// 最新 tab 的列表（list.dart 里 `PageStorageKey<String>("LostLatestList")`）。
Finder latestList() =>
    find.byKey(const PageStorageKey<String>('LostLatestList'));

/// 按 id 反查某一行的标题。
///
/// LostListItem 的标题格式（见其 build）：
///   `"${regionCity} ${locationName}附近 ${age}岁${color} ${breed}(${gender})"`
/// 假数据的 locationName 是 `示例小区<id>`，所以整串包含 `示例小区<id>附近`。
/// 用完整后缀能避免前缀误命中：`示例小区1附近` **不是**
/// `示例小区1001附近` 的子串。
Finder rowOf(int id) => find.textContaining('示例小区$id附近');

void main() {
  group('LostList 首屏', () {
    testWidgets('两个 tab 各发一次请求；最新 tab 渲染出筛选栏与列表项',
        (WidgetTester tester) async {
      final FakeHttpAdapter http =
          installFakeHttp((_) => successEnvelope(list: lostDogs(3)));

      await tester.pumpWidget(app());
      await ride(tester);

      // initState 里 _resetLatest() + _resetTop() 各发一次
      expect(http.requests, hasLength(2),
          reason: '首屏应恰好发两个请求（最新 + 悬赏最高）');

      // 筛选栏：四项都取「不限」时的文案（来自 DogLostFilter）
      expect(find.byType(LostListPicker), findsOneWidget);
      expect(find.text('全部区域'), findsOneWidget);
      expect(find.text('全部品种'), findsOneWidget);
      expect(find.text('全部颜色'), findsOneWidget);
      expect(find.text('全部性别'), findsOneWidget);

      // 列表项真的渲染出来了（标题 / 副标题 / 金额都对）
      expect(find.byType(LostListItem), findsWidgets);
      expect(rowOf(1), findsOneWidget);
      expect(find.text('失踪时间 2024-05-01 下午'), findsWidgets);
      expect(find.text('¥ 100'), findsWidgets); // negotiate=false → 显示金额

      expect(find.byType(BottomLoader), findsNothing,
          reason: 'successEnvelope 的 nextPage 默认 false');
      expect(tester.takeException(), isNull);
    });

    testWidgets('还有下一页时，列表末尾挂 BottomLoader', (WidgetTester tester) async {
      installFakeHttp(
          (_) => successEnvelope(list: lostDogs(3), nextPage: true));

      await tester.pumpWidget(app());
      await ride(tester);

      expect(find.byType(LostListItem), findsWidgets);
      expect(find.byType(BottomLoader), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('LostList 交互', () {
    testWidgets('滑到底部（≥90%）自动加载下一页，且是追加不是替换',
        (WidgetTester tester) async {
      final FakeHttpAdapter http = installFakeHttp((o) {
        final int page = int.tryParse('${o.queryParameters['page']}') ?? 1;
        return successEnvelope(
          list: lostDogs(25, base: page * 1000),
          page: page,
          nextPage: page < 2,
        );
      });

      await tester.pumpWidget(app());
      await ride(tester);

      expect(latestList(), findsOneWidget, reason: '首屏应已渲染出最新 tab 的列表');

      // 反复往上拖，直到确实打出 page=2（不依赖列表项的确切行高）
      for (int i = 0; i < 8; i++) {
        if (http.queryValuesOf('page').contains(2)) break;
        await tester.drag(latestList(), const Offset(0, -1200));
        await ride(tester, frames: 8);
      }

      expect(http.queryValuesOf('page').contains(2), isTrue,
          reason: '滑到底应自动请求下一页，实际 page 序列：${http.queryValuesOf('page')}');

      // 继续拖到底：ListView 是懒加载的，此时视口里应当是第二页的条目
      // （base=2000 → 示例小区2001..2025）
      for (int i = 0; i < 5; i++) {
        await tester.drag(latestList(), const Offset(0, -1200));
        await ride(tester, frames: 6);
      }
      expect(find.textContaining('示例小区20'), findsWidgets,
          reason: '第二页的数据应出现在视口里');

      // 滚回顶部，第一页的条目还在 ⇒ 第二页是"追加"而不是"替换"
      await tester.drag(latestList(), const Offset(0, 4000));
      await ride(tester, frames: 10);
      expect(find.textContaining('示例小区10'), findsWidgets,
          reason: '第一页（base=1000）的数据不应被第二页替换掉');

      expect(tester.takeException(), isNull);
    });

    testWidgets('短列表也能下拉刷新（依赖列表页显式声明 AlwaysScrollableScrollPhysics）',
        (WidgetTester tester) async {
      // 刻意只给 3 条：内容不足一屏 ⇒ 列表本身"不可滚动"。
      // 这正是最容易漏掉的场景：RefreshIndicator 官方文档的 Troubleshooting
      // 说明它只在可 overscroll 时响应，默认物理会直接拒收手势，
      // 必须由列表页显式声明 AlwaysScrollableScrollPhysics。
      final FakeHttpAdapter http =
          installFakeHttp((_) => successEnvelope(list: lostDogs(3)));

      await tester.pumpWidget(app());
      await ride(tester);

      int pageOneCount() =>
          http.queryValuesOf('page').where((Object? v) => '$v' == '1').length;

      final int before = pageOneCount();
      expect(before, 2, reason: '首屏两个 tab 各拉了一次 page=1');

      // 用 fling 而不是 drag：与 Flutter 官方 refresh_indicator_test.dart 的手法一致
      await tester.fling(latestList(), const Offset(0, 400), 1000);
      await ride(tester, frames: 45);

      expect(pageOneCount(), greaterThan(before),
          reason: '下拉刷新应再发一次 page=1');
      expect(tester.takeException(), isNull);
    });

    testWidgets('抽屉里的「重置列表」会重新拉取并弹提示', (WidgetTester tester) async {
      final FakeHttpAdapter http =
          installFakeHttp((_) => successEnvelope(list: lostDogs(3)));

      await tester.pumpWidget(app());
      await ride(tester);

      final int before = http.requests.length;

      await tester.tap(find.byIcon(Icons.menu));
      await ride(tester, frames: 15);

      expect(find.text('重置列表'), findsOneWidget, reason: '抽屉应已打开');

      await tester.tap(find.text('重置列表'));
      await ride(tester, frames: 25);

      expect(http.requests.length, greaterThan(before),
          reason: '重置应重新请求最新 + 悬赏最高');
      expect(find.text('全部重置完毕！'), findsWidgets,
          reason: '重置后应当弹提示');
      expect(tester.takeException(), isNull);
    });

    testWidgets('切到「附近」tab 不应崩溃（测试环境无定位插件 → 走失败分支）',
        (WidgetTester tester) async {
      installFakeHttp((_) => successEnvelope(list: lostDogs(3)));

      await tester.pumpWidget(app());
      await ride(tester);

      expect(find.text('附近'), findsOneWidget);
      await tester.tap(find.text('附近'));
      await ride(tester, frames: 25);

      expect(tester.takeException(), isNull,
          reason: '拿不到定位时应被 try/catch 吞掉，只弹一句提示');
    });
  });

  group('LostList 空态与失败态', () {
    testWidgets('请求成功但一条都没有 → 显示「没有数据，重新加载！」',
        (WidgetTester tester) async {
      installFakeHttp((_) => successEnvelope(list: <Map<String, dynamic>>[]));

      await tester.pumpWidget(app());
      await ride(tester);

      expect(find.text('没有数据，重新加载！'), findsWidgets);
      expect(find.byType(LostListItem), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('业务失败（status != SUCCESS）→ 弹提示并带上服务端 message',
        (WidgetTester tester) async {
      installFakeHttp((_) => failureEnvelope('服务器开小差'));

      await tester.pumpWidget(app());
      await ride(tester);

      // _onListStateChanged 用 SnackBar 把 message 透出来
      expect(find.textContaining('服务器开小差'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HTTP 5xx 走 dio 的 validateStatus，服务端 message 仍被透出',
        (WidgetTester tester) async {
      installFakeHttp(
          (_) => FakeResponse(failureEnvelope('服务端炸了'), statusCode: 500));

      await tester.pumpWidget(app());
      await ride(tester);

      expect(find.textContaining('服务端炸了'), findsWidgets,
          reason: 'dio 默认 validateStatus 只放行 2xx；'
              '500 应被翻译成 RequestError 并带上响应体里的 message');
      expect(tester.takeException(), isNull);
    });
  });

  group('LostListPicker 文案', () {
    Future<void> pumpPicker(
      WidgetTester tester,
      DogLostSelection selection,
    ) =>
        tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: LostListPicker(selection: selection, onChanged: (_) {}),
          ),
        ));

    testWidgets('全部不限 → 四个按钮都是「全部 xxx」', (WidgetTester tester) async {
      await pumpPicker(tester, const DogLostSelection());

      expect(find.text('全部区域'), findsOneWidget);
      expect(find.text('全部品种'), findsOneWidget);
      expect(find.text('全部颜色'), findsOneWidget);
      expect(find.text('全部性别'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('带筛选 → 按「下标 +1」反查回文案', (WidgetTester tester) async {
      await pumpPicker(
        tester,
        const DogLostSelection(
          regionArea: '浦东新区',
          size: 0, // 小型
          breed: 2, // 小型那一列的第 3 个品种
          color: 5, // 黑色
          gender: true, // 公
        ),
      );

      expect(find.text('浦东新区'), findsOneWidget);
      expect(find.text('博美犬'), findsOneWidget,
          reason: 'breed 是"体型内"的 0 基索引：'
              'sizeBreedOptions[1]["小型"] = [全部品种, 中华田园犬, 贵宾犬, 博美犬] '
              '→ breed=2 落在第 4 项');
      expect(find.text('黑色'), findsOneWidget);
      expect(find.text('公'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
