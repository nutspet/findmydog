import 'package:find_dog/models/dog_selection.dart';

/// 「附近走失」的查询中心坐标。
///
/// 语义上它不是"筛选条件"，而是这次查询的**输入参数**（以哪里为中心）。
/// 之所以纳入 [DogSelection] 体系，是为了直接复用列表页那套
/// `DogFetchBloc` 的加载 / 重置 / 失败处理，不必给附近单独写一套 bloc。
class DogLostNearBySelection extends DogSelection<DogLostNearBySelection> {
  const DogLostNearBySelection({this.longitude, this.latitude});

  final double? longitude;
  final double? latitude;

  DogLostNearBySelection copyWith({double? longitude, double? latitude}) {
    return DogLostNearBySelection(
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
    );
  }

  @override
  List<Object?> get props => [longitude, latitude];

  @override
  String toString() =>
      'DogLostNearBySelection { longitude: $longitude, latitude: $latitude }';
}
