part of 'dog_bloc.dart';

/// 列表页事件的公共基类
abstract class DogEvent extends Equatable {
  const DogEvent();
}

/// "取数"类事件的公共形状：可以带一份筛选条件。
///
/// `selection` 为 null 表示"不改动筛选"，沿用当前状态里的筛选
/// （滚动加载就是这种情况）。
abstract class DogFetchEventAbstract<Selection extends DogSelection<Selection>>
    extends DogEvent {
  const DogFetchEventAbstract({this.selection});

  final Selection? selection;

  @override
  List<Object?> get props => [selection];
}

/// 滚动加载下一页：**不重置**，新数据追加到列表尾部
abstract class DogFetchedEvent<Selection extends DogSelection<Selection>>
    extends DogFetchEventAbstract<Selection> {
  const DogFetchedEvent({super.selection});
}

/// 下拉刷新 / 切换筛选：**重置**到第一页，并让列表滚回顶部
///
/// [pageSize] 是"单次请求条数"（列表页抽屉里可调）。
/// 只有重置类事件带它：滚动加载时必须沿用当前的页大小，
/// 否则会把已经翻过的页码全部错位。
/// 传 null 表示沿用当前状态里记录的页大小。
abstract class DogFetchedWithResetEvent<Selection extends DogSelection<Selection>>
    extends DogFetchEventAbstract<Selection> {
  const DogFetchedWithResetEvent({super.selection, this.pageSize});

  final int? pageSize;

  @override
  List<Object?> get props => [selection, pageSize];
}
