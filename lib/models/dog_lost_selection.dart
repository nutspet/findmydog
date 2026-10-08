import 'package:find_dog/models/dog_selection.dart';

/// `copyWith` 的哨兵值。
///
/// 目的是区分两种情况：
/// - **参数没传** → 保持原值
/// - **显式传了 null** → 清空该筛选
///
/// 若直接用 `int? color` 当参数就无法表达"把颜色改回不限"，
/// 而列表页的「全部颜色 / 全部性别 / 全部区域」恰恰需要清空。
const Object _unset = Object();

/// 失踪狗列表的筛选条件。
///
/// 每个字段为 null 表示"不限"，service 层不会把该字段拼进 query。
/// 所有下标一律走 **0 基**，与接口参数、`Dog.DogSize` / `Dog.DogColor` 的下标一致
/// （这一点由线上接口实测确认：`size=0&breed=1` 返回的记录 `breed` 全为 1）。
class DogLostSelection extends DogSelection<DogLostSelection> {
  const DogLostSelection({
    this.size,
    this.breed,
    this.color,
    this.gender,
    this.regionProvince,
    this.regionCity,
    this.regionArea,
  });

  /// 体型下标（0 基）
  final int? size;

  /// 品种下标（0 基，相对于该体型下的品种列表）
  final int? breed;

  /// 颜色下标（0 基）
  final int? color;

  /// 性别：false = 母，true = 公
  final bool? gender;

  final String? regionProvince;
  final String? regionCity;
  final String? regionArea;

  /// 只修改想改的字段；要"清空"某个筛选就显式传 null。
  ///
  /// ```dart
  /// selection.copyWith(color: 3);     // 只看巧克力色
  /// selection.copyWith(color: null);  // 颜色改回"不限"，其它筛选保留
  /// selection.copyWith();             // 原样复制
  /// ```
  DogLostSelection copyWith({
    Object? size = _unset,
    Object? breed = _unset,
    Object? color = _unset,
    Object? gender = _unset,
    Object? regionProvince = _unset,
    Object? regionCity = _unset,
    Object? regionArea = _unset,
  }) {
    return DogLostSelection(
      size: identical(size, _unset) ? this.size : size as int?,
      breed: identical(breed, _unset) ? this.breed : breed as int?,
      color: identical(color, _unset) ? this.color : color as int?,
      gender: identical(gender, _unset) ? this.gender : gender as bool?,
      regionProvince: identical(regionProvince, _unset)
          ? this.regionProvince
          : regionProvince as String?,
      regionCity: identical(regionCity, _unset)
          ? this.regionCity
          : regionCity as String?,
      regionArea: identical(regionArea, _unset)
          ? this.regionArea
          : regionArea as String?,
    );
  }

  /// 是否没有任何筛选条件
  bool get isAll =>
      size == null &&
      breed == null &&
      color == null &&
      gender == null &&
      regionProvince == null &&
      regionCity == null &&
      regionArea == null;

  @override
  List<Object?> get props =>
      [size, breed, color, gender, regionProvince, regionCity, regionArea];

  @override
  String toString() =>
      'DogLostSelection { regionProvince: $regionProvince, regionCity: $regionCity, '
      'regionArea: $regionArea, size: $size, breed: $breed, color: $color, gender: $gender }';
}
