// 失踪狗相关的具体事件。
//
// 这里刻意**做成独立 library**（而不是 `part of 'dog_bloc.dart'`），
// 这样 `dog_bloc.dart` 这个泛型基类库就不必反向 import 具体的筛选条件模型，
// 保持"基类不依赖具体业务"的分层。

import 'package:find_dog/bloc/dog_bloc.dart';
import 'package:find_dog/models/dog_lost_near_by_selection.dart';
import 'package:find_dog/models/dog_lost_selection.dart';

// ============================ 最新发布 ============================

/// 最新发布：滚动加载下一页
class DogLostLatestFetchEvent extends DogFetchedEvent<DogLostSelection> {
  const DogLostLatestFetchEvent({super.selection});
}

/// 最新发布：重置（下拉刷新 / 切换筛选 / 调整单次条数）
class DogLostLatestFetchWithResetEvent
    extends DogFetchedWithResetEvent<DogLostSelection> {
  const DogLostLatestFetchWithResetEvent({super.selection, super.pageSize});
}

// ============================ 悬赏最高 ============================

/// 悬赏最高：滚动加载下一页
class DogLostTopFetchEvent extends DogFetchedEvent<DogLostSelection> {
  const DogLostTopFetchEvent({super.selection});
}

/// 悬赏最高：重置（下拉刷新 / 切换筛选 / 调整单次条数）
class DogLostTopFetchWithResetEvent
    extends DogFetchedWithResetEvent<DogLostSelection> {
  const DogLostTopFetchWithResetEvent({super.selection, super.pageSize});
}

// ============================ 附近走失 ============================

/// 附近走失：以给定坐标为中心拉一次。
///
/// 该接口没有分页（线上实测 `data` 里只有 `list`），所以只有"重置"语义，
/// 没有对应的"加载下一页"事件。
class DogLostNearByFetchWithResetEvent
    extends DogFetchedWithResetEvent<DogLostNearBySelection> {
  const DogLostNearByFetchWithResetEvent({super.selection, super.pageSize});
}
