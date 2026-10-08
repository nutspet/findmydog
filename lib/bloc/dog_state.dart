part of 'dog_bloc.dart';

/// 列表加载状态
enum DogStatus {
  /// 还没开始 / 首次加载中（此时 [DogState.dogs] 为空）
  initial,

  /// 请求进行中
  loading,

  /// 请求成功
  success,

  /// 请求失败（[DogState.dogs] 里可能仍有上一次成功的数据）
  failure,
}

/// 列表页状态。
///
/// 一份状态里同时承载：数据、分页游标、当前筛选、是否需要滚回顶部。
/// 旧实现把这些拆成三套 `_xxxPage / _xxxEnd / _xxxList` 字段手工维护，
/// 这里收敛成一个不可变对象，bloc 每次产出新实例，UI 只负责渲染。
class DogState<Model extends Dog, Selection extends DogSelection<Selection>>
    extends Equatable {
  const DogState({
    this.status = DogStatus.initial,
    this.dogs = const [],
    this.pagination = const Pagination(),
    this.selection,
    this.reset = false,
    this.errorMessage,
  });

  final DogStatus status;

  /// 已加载到的数据
  final List<Model> dogs;

  /// 分页游标（来自接口返回的 pagination）
  final Pagination pagination;

  /// 当前生效的筛选条件
  final Selection? selection;

  /// 本次结果是否需要把列表滚回顶部。
  /// 只有"重置"类事件会置 true；消费方（UI）据此执行 `jumpTo(0)`。
  final bool reset;

  /// 最近一次失败的原因，仅用于提示，**不参与相等判断**
  /// （每次请求都会先发一个 loading 状态，所以 failure 状态总能被监听方收到，
  ///   不需要靠它的变化来触发通知）。
  final String? errorMessage;

  /// 是否还有下一页
  bool get hasMore => pagination.nextPage;

  DogState<Model, Selection> copyWith({
    DogStatus? status,
    List<Model>? dogs,
    Pagination? pagination,
    Selection? selection,
    bool? reset,
    String? errorMessage,
  }) {
    return DogState<Model, Selection>(
      status: status ?? this.status,
      dogs: dogs ?? this.dogs,
      pagination: pagination ?? this.pagination,
      selection: selection ?? this.selection,
      reset: reset ?? this.reset,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // 说明：不再把 `Model.runtimeType` 放进 props —— equatable 3 的
  // `operator ==` 本身已经比较 runtimeType（泛型实参也参与），放进去是冗余的。
  @override
  List<Object?> get props => [dogs, status, pagination, selection, reset];

  @override
  String toString() => 'DogState { status: $status, dogs: ${dogs.length}, '
      'pagination: $pagination, selection: $selection, reset: $reset }';
}
