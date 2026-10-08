import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:find_dog/models/dog.dart';
import 'package:find_dog/models/dog_selection.dart';
import 'package:find_dog/models/pagination.dart';
import 'package:find_dog/repository/api_repository.dart';
import 'package:stream_transform/stream_transform.dart';

part 'dog_event.dart';
part 'dog_state.dart';

/// 滚动触发的连击保护窗口
const Duration throttleDuration = Duration(milliseconds: 100);

/// throttle + droppable 双重保护：
/// - `throttle` 限制频率 —— 快速滑动时不会每滚一点就发一次请求
/// - `droppable` 保证同一时刻只有一个事件在处理，处理期间到来的事件直接丢弃
///
/// 这正是"用 bloc 而不是 cubit"的价值所在：cubit 没有事件流，做不了这个。
EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) =>
      droppable<E>().call(events.throttle(duration), mapper);
}

/// 取数回调：给一页分页参数（可带筛选），返回一页数据。
///
/// 由子类把 `DogService` 上对应的方法直接作为参数传进来（方法 tear-off）。
typedef FetchEventHandler<Model, Selection> = Future<ApiRepository<Model>>
    Function(Pagination pagination, {Selection? selection});

/// 列表页 bloc 的泛型基类。
///
/// 泛型参数：
/// - [Event]     事件类型。子类传 `DogFetchEventAbstract<XxxSelection>`，
///               这样一次可以注册多个具体事件
/// - [Model]     数据模型（DogLost 等）
/// - [Selection] 筛选条件类型
///
/// 「翻页」与「重置」两套流程抽在这里，子类只需声明事件、把 service 方法挂上去。
///
/// 注意：本文件刻意**不 import Flutter**（只依赖 bloc / equatable / dio /
/// stream_transform 这些纯 Dart 包）。这样状态机逻辑可以用 `dart run` 直接跑测试 ——
/// 本机的 `flutter test` 因 Windows 管道限制不可用（见 README 迁移说明）。
abstract class DogFetchBloc<
        Event extends DogFetchEventAbstract<Selection>,
        Model extends Dog,
        Selection extends DogSelection<Selection>>
    extends Bloc<Event, DogState<Model, Selection>> {
  DogFetchBloc(super.initialState);

  /// 加载下一页（滚动到底部时触发），新数据**追加**在列表尾部。
  Future<void> onDogFetched(
    DogFetchEventAbstract<Selection> event,
    Emitter<DogState<Model, Selection>> emit,
    DogState<Model, Selection> state,
    FetchEventHandler<Model, Selection> handler,
  ) async {
    // 已经是最后一页：直接吞掉事件。
    // 旧实现无条件调用 goNextPage()，而它在最后一页会抛异常 →
    // 被 catch 后把整个列表打成"加载失败"，已经拉到的数据全没了。
    if (!state.pagination.nextPage) return;

    emit(state.copyWith(status: DogStatus.loading));

    try {
      final Pagination pagination = state.pagination.goNextPage();
      // 事件带了筛选就整体替换（这样才能表达"把某个筛选清回不限"）；
      // 没带就沿用当前筛选（滚动加载就是这种情况）。
      final Selection? selection = event.selection ?? state.selection;
      final ApiRepository<Model> page =
          await handler(pagination, selection: selection);
      if (isClosed) return;
      emit(state.copyWith(
        status: DogStatus.success,
        dogs: <Model>[...state.dogs, ...page.list],
        selection: selection,
        pagination: page.pagination,
        reset: false,
      ));
    } catch (e) {
      if (isClosed) return;
      // 保留已有的 dogs —— 一次翻页失败不该把已经加载出来的列表清空。
      emit(state.copyWith(
        status: DogStatus.failure,
        errorMessage: describeError(e),
      ));
    }
  }

  /// 重新加载（下拉刷新 / 切换筛选 / 调整单次条数）：
  /// 从第一页开始，并让列表滚回顶部（UI 通过 [DogState.reset] 得知该滚回顶部）。
  Future<void> onDogFetchedWithReset(
    DogFetchedWithResetEvent<Selection> event,
    Emitter<DogState<Model, Selection>> emit,
    DogState<Model, Selection> state,
    FetchEventHandler<Model, Selection> handler,
  ) async {
    emit(state.copyWith(status: DogStatus.loading));

    try {
      // 从第一页重新开始。页大小优先用事件里带的（抽屉里调过），
      // 否则沿用当前状态里记录的（初始为 Pagination 的默认值）。
      final Pagination pagination =
          Pagination(pageSize: event.pageSize ?? state.pagination.pageSize);
      final Selection? selection = event.selection ?? state.selection;
      final ApiRepository<Model> page =
          await handler(pagination, selection: selection);
      if (isClosed) return;
      emit(state.copyWith(
        status: DogStatus.success,
        dogs: page.list,
        selection: selection,
        pagination: page.pagination,
        reset: true,
      ));
    } catch (e) {
      if (isClosed) return;
      // 刷新失败同样保留旧数据（与原实现一致：失败只提示，不清空）。
      emit(state.copyWith(
        status: DogStatus.failure,
        errorMessage: describeError(e),
      ));
    }
  }
}

/// 把异常翻译成可直接展示给用户的文案。
///
/// `RequestError`（继承自 DioException）在 common/request.dart 里已经把
/// 服务端的 message 放好了，这里取出来即可；其它异常退化为 toString()。
String describeError(Object error) {
  if (error is DioException) {
    final String? message = error.message;
    if (message != null && message.isNotEmpty) return message;
  }
  return error.toString();
}
