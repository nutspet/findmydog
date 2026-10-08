import 'dog.dart';
import 'dog_lost.dart';
import 'dog_lost_selection.dart';

/// 列表页的「筛选项 ↔ 接口参数」换算中心。
///
/// 刻意做成**纯 Dart**（不 import flutter）：这里放的是整条链路上最容易出错、
/// 也最值得写断言的部分 —— 选择器下标与接口参数之间的映射。
/// 拆出来之后：
/// - UI（`screens/lost/lost_list_picker.dart`）只负责弹选择器、显示文案
/// - 这些换算可以脱离 Flutter 被 `dart run` 直接跑，也可以由 `flutter test` 覆盖
class DogLostFilter {
  const DogLostFilter._();

  /// 地区三级联动里代表"不限"的哨兵值（与改造前同名同值）
  static const String areaAll = "全部区域";

  /// 体型 / 品种联动里代表"不限"的项
  static const String sizeAll = "全部";
  static const String breedAll = "全部品种";

  /// 性别选项。首个是"不限"，所以「下标 - 1」正好是 [DogLost.DogGender] 的 0 基索引。
  /// `DogLost.DogGender` 是 `{false: '母', true: '公'}`，所以选项是
  /// `['全部性别', '母', '公']`。
  static final List<String> genderOptions = <String>[
    "全部性别",
    ...DogLost.DogGender.values,
  ];

  /// 颜色选项。首个是"不限"，所以「下标 - 1」正好是 [Dog.DogColor] 的 0 基索引。
  static final List<String> colorOptions = <String>[
    "全部颜色",
    ...Dog.DogColor,
  ];

  /// 体型 → 品种 的联动选项表。
  ///
  /// ⚠️ 与改造前相比，这里**给每个体型的品种列表都补了一项"全部品种"**。
  ///
  /// 原因（线上实测，不是推测）：
  /// 1. 接口的 `breed` 是**该体型内部的 0 基相对索引**，不是全局索引 ——
  ///    `size=1&breed=0` 能取到数据；
  ///    而 `size=0&breed=17`、`size=2&breed=33`、单独发 `breed=17` 全部返回 0 条
  ///    ⇒ 越界即空，只能按"体型内索引"解释。
  /// 2. 改造前的选项表只在「全部」那一组放了"全部品种"，
  ///    选具体体型时品种列里**没有**这一项，但换算仍然写成「列下标 - 1」
  ///    ⇒ 整列错位一格：
  ///      - 选第 1 项("中华田园犬") → 实际不发送 breed（= 不限，返回全部品种）
  ///      - 选第 2 项("贵宾犬")     → 实际返回的却是中华田园犬
  ///    也就是说"体型 + 品种"这个筛选从来没按预期工作过。
  /// 3. 每列补上"全部品种"之后，「列下标 - 1」才真正等于接口要的 0 基索引。
  static final List<Map<String, List>> sizeBreedOptions = <Map<String, List>>[
    <String, List>{sizeAll: <String>[breedAll]},
    for (final Map<String, List> group in Dog.DogSizeBreed)
      for (final MapEntry<String, List> entry in group.entries)
        <String, List>{entry.key: <String>[breedAll, ...entry.value]},
  ];

  // ======================= 选项下标 → 接口参数 =======================

  /// 体型：0 = 不限；1/2/3 = 小型/中型/大型 ⇒ 接口 `size` = 0/1/2
  static int? sizeValueOf(int index) => index <= 0 ? null : index - 1;

  /// 品种：0 = 不限；其余对应接口 `breed`（见 [sizeBreedOptions] 的说明）
  static int? breedValueOf(int index) => index <= 0 ? null : index - 1;

  /// 颜色：0 = 不限；其余对应接口 `color`（0 基，对应 [Dog.DogColor]）
  static int? colorValueOf(int index) => index <= 0 ? null : index - 1;

  /// 性别：0 = 不限；1 = 母(false)；2 = 公(true)。
  ///
  /// 注意：最终发给接口的是**数字 0/1**（[DogLostSelection.gender] 是 bool，
  /// 由 `DogService` 转成 `gender = true ? 1 : 0`）。
  /// 线上实测 `gender=false` 会返回"公"（与 `gender=1` 结果一模一样），
  /// 服务端对布尔字面量的处理是不可靠的 —— 所以绝不能直接发 true/false。
  static bool? genderValueOf(int index) {
    if (index <= 0) return null;
    final List<bool> values = DogLost.DogGender.keys.toList();
    if (index > values.length) return null;
    return values[index - 1];
  }

  // ======================= 接口参数 → 选项下标 =======================

  /// 体型选项下标：0 = 全部体型，k = 第 k 个体型
  static int sizeIndexOf(int? size) {
    if (size == null || size < 0 || size >= Dog.DogSize.length) return 0;
    return size + 1;
  }

  /// 品种在"当前体型那一列"里的下标：0 = 全部品种
  static int breedIndexOf(int? breed) {
    if (breed == null || breed < 0) return 0;
    return breed + 1;
  }

  static int colorIndexOf(int? color) {
    if (color == null || color < 0 || color >= Dog.DogColor.length) return 0;
    return color + 1;
  }

  static int genderIndexOf(bool? gender) {
    if (gender == null) return 0;
    return gender ? 2 : 1;
  }

  // ======================= 由筛选条件推出按钮文案 =======================

  /// 当前体型在选项表里的名字（'全部' / '小型' / '中型' / '大型'）
  static String sizeNameOf(int? size) {
    final int index = sizeIndexOf(size);
    return index == 0 ? sizeAll : Dog.DogSize[index - 1];
  }

  /// 体型·品种按钮的文字（取值表达式与改造前一致）
  static String sizeBreedText(DogLostSelection selection) {
    final Map<String, List> group =
        sizeBreedOptions[sizeIndexOf(selection.size)];
    final List? breeds = group[sizeNameOf(selection.size)];
    if (breeds == null) return '';
    final int index = breedIndexOf(selection.breed);
    if (index >= breeds.length) return '';
    return breeds[index].toString();
  }

  /// 地区按钮文字：区 → 市 → 省 → 全部区域（与改造前的逐级回退等价）
  static String regionText(DogLostSelection selection) {
    final String? area = selection.regionArea;
    if (area != null) return area;
    final String? city = selection.regionCity;
    if (city != null) return city;
    final String? province = selection.regionProvince;
    if (province != null) return province;
    return areaAll;
  }

  static String colorText(DogLostSelection selection) =>
      colorOptions[colorIndexOf(selection.color)];

  static String genderText(DogLostSelection selection) =>
      genderOptions[genderIndexOf(selection.gender)];

  // ======================= 选择器结果 → 新的筛选条件 =======================

  /// 地区：三级联动的选中值（省 / 市 / 区），"全部区域"一律翻译成 null（= 不下发）
  static DogLostSelection applyRegion(
    DogLostSelection selection,
    List names,
  ) {
    final String province = names.isNotEmpty ? "${names[0]}" : areaAll;
    final String city = names.length > 1 ? "${names[1]}" : areaAll;
    final String area = names.length > 2 ? "${names[2]}" : areaAll;
    return selection.copyWith(
      regionProvince: province == areaAll ? null : province,
      regionCity: city == areaAll ? null : city,
      regionArea: area == areaAll ? null : area,
    );
  }

  /// 体型·品种：两列联动的选中下标
  ///
  /// 注意 [breed] 只在选中了**具体体型**时才有意义：
  /// - 线上实测单发 `breed`（不带 `size`）返回 0 条，
  ///   因为 breed 是"该体型内部"的下标，脱离体型服务端解释不了；
  /// - 选项表里"全部体型"那一列的品种列本来也只有"全部品种"一项。
  ///
  /// 所以这里显式收口：体型选了"不限"时，品种一律跟着清空。
  /// 否则会构造出 `{size: null, breed: 3}` 这种既筛不出东西、
  /// 按钮文案又会变空串的畸形状态。
  static DogLostSelection applySizeBreed(
    DogLostSelection selection,
    int sizeIndex,
    int breedIndex,
  ) {
    final int? size = sizeValueOf(sizeIndex);
    final int? breed = size == null ? null : breedValueOf(breedIndex);
    return selection.copyWith(size: size, breed: breed);
  }

  /// 颜色
  static DogLostSelection applyColor(DogLostSelection selection, int index) =>
      selection.copyWith(color: colorValueOf(index));

  /// 性别
  static DogLostSelection applyGender(DogLostSelection selection, int index) =>
      selection.copyWith(gender: genderValueOf(index));
}
