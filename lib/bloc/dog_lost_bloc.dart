// 失踪狗列表页的三个 bloc。
//
// 三个 tab 各自独立一个 bloc 实例（互不干扰），但都复用同一个泛型基类
// [DogFetchBloc]，差别只在于"挂哪个 service 方法"和"注册哪些事件"。

import 'package:find_dog/bloc/dog_bloc.dart';
import 'package:find_dog/bloc/dog_lost_event.dart';
import 'package:find_dog/models/dog_lost.dart';
import 'package:find_dog/models/dog_lost_near_by_selection.dart';
import 'package:find_dog/models/dog_lost_selection.dart';
import 'package:find_dog/models/pagination.dart';
import 'package:find_dog/repository/api_repository.dart';
import 'package:find_dog/service/dog_service.dart';

/// 「最新发布」列表
class DogLostLatestFetchBloc extends DogFetchBloc<
    DogFetchEventAbstract<DogLostSelection>, DogLost, DogLostSelection> {
  DogLostLatestFetchBloc()
      : super(const DogState<DogLost, DogLostSelection>()) {
    // 滚动加载：带 throttle + droppable，快速滑动不会打出一串重复请求
    on<DogLostLatestFetchEvent>(
      (event, emit) =>
          onDogFetched(event, emit, state, _service.getLostLatest),
      transformer: throttleDroppable(throttleDuration),
    );
    // 重置/切筛选：不走 transformer，保证每次点击都被处理
    on<DogLostLatestFetchWithResetEvent>(
      (event, emit) =>
          onDogFetchedWithReset(event, emit, state, _service.getLostLatest),
    );
  }

  final DogService _service = DogService();
}

/// 「悬赏最高」列表
class DogLostTopFetchBloc extends DogFetchBloc<DogFetchEventAbstract<
    DogLostSelection>, DogLost, DogLostSelection> {
  DogLostTopFetchBloc() : super(const DogState<DogLost, DogLostSelection>()) {
    on<DogLostTopFetchEvent>(
      (event, emit) =>
          onDogFetched(event, emit, state, _service.getLostTopReward),
      transformer: throttleDroppable(throttleDuration),
    );
    on<DogLostTopFetchWithResetEvent>(
      (event, emit) =>
          onDogFetchedWithReset(event, emit, state, _service.getLostTopReward),
    );
  }

  final DogService _service = DogService();
}

/// 「附近走失」列表
class DogLostNearByFetchBloc extends DogFetchBloc<
    DogFetchEventAbstract<DogLostNearBySelection>,
    DogLost,
    DogLostNearBySelection> {
  DogLostNearByFetchBloc()
      : super(const DogState<DogLost, DogLostNearBySelection>()) {
    // 附近没有分页（接口不返回 pagination），因此只注册"重置"事件
    on<DogLostNearByFetchWithResetEvent>(
      (event, emit) => onDogFetchedWithReset(event, emit, state, _fetchNearBy),
    );
  }

  /// 附近接口的取数回调：坐标从 selection 里带进来
  static Future<ApiRepository<DogLost>> _fetchNearBy(
    Pagination pagination, {
    DogLostNearBySelection? selection,
  }) {
    return DogService().getLostNearBy(
      longitude: selection?.longitude,
      latitude: selection?.latitude,
    );
  }
}
