import 'package:equatable/equatable.dart';

/// 列表页"筛选条件"的公共基类。
///
/// 采用自限定泛型（F-bounded）：子类把自己作为类型实参传进来，
/// 例如 `class DogLostSelection extends DogSelection<DogLostSelection>`。
/// 这样基类就能约定"`copyWith` 返回具体子类型"，调用方不必强转，
/// 同时给 [DogFetchBloc] 的泛型参数一个统一的约束。
///
/// 基类本身刻意不定义任何方法 —— 各类筛选条件的字段差异太大
/// （有的是 int 下标、有的是 bool、有的是字符串），强行抽象成一个签名
/// 反而会限制表达力。具体字段由各子类自行声明。
abstract class DogSelection<T> extends Equatable {
  const DogSelection();
}
