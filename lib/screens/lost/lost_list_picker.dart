import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:find_dog/models/dog_lost_filter.dart';
import 'package:find_dog/models/dog_lost_selection.dart';
import 'package:find_dog/models/location.dart';

/// 列表页顶部的筛选工具栏：地区 / 体型·品种 / 颜色 / 性别。
///
/// 这是一个**无状态的纯展示组件**，自己不持有任何筛选状态：
/// - 当前选中项由外部传进来的 [selection] 反推（单一数据源就是 bloc 的 state）
/// - 用户确认后，把换算好的新 [DogLostSelection] 通过 [onChanged] 抛出去
///
/// 为什么不让它自己 `setState` 存下标（改造前就是那样）：
/// `TabBarView` 内部是 `PageView`，离开视口的子树会被销毁 ——
/// 状态存在组件内部的话，切走 tab 再切回来就会被悄悄打回"全部"，
/// 而筛选其实还在生效，两边就对不上了。
///
/// 所有的"下标 ↔ 接口参数"换算都在纯 Dart 的 [DogLostFilter] 里，
/// 本文件只管弹选择器和显示文案。
class LostListPicker extends StatelessWidget {
  const LostListPicker({
    super.key,
    required this.selection,
    required this.onChanged,
  });

  /// 按钮文字的样式（与改造前一致：12 号、black54）
  static const TextStyle _labelStyle =
      TextStyle(fontSize: 12.0, color: Colors.black54);

  /// 当前生效的筛选（由 bloc 的 state 传进来）
  final DogLostSelection selection;

  /// 用户确认了新的筛选
  final ValueChanged<DogLostSelection> onChanged;

  // ==================== 四个选择器 ====================

  void _showLocationPicker(BuildContext context) {
    Picker(
      adapter:
          PickerDataAdapter<String>(pickerData: convertPickerData(locations)),
      changeToFirst: true,
      textAlign: TextAlign.left,
      confirmText: "确认",
      cancelText: "取消",
      columnPadding: const EdgeInsets.all(8.0),
      onConfirm: (Picker picker, List<int> value) => onChanged(
        DogLostFilter.applyRegion(selection, picker.getSelectedValues()),
      ),
    ).showModal(context);
  }

  void _showSizeBreedPicker(BuildContext context) {
    Picker(
      adapter:
          PickerDataAdapter<String>(pickerData: DogLostFilter.sizeBreedOptions),
      // changeToFirst / selecteds 改造前就是关掉的，保持一致
      confirmText: "确认",
      cancelText: "取消",
      textAlign: TextAlign.left,
      columnPadding: const EdgeInsets.all(8.0),
      onConfirm: (Picker picker, List<int> value) {
        final int sizeIndex = value.isNotEmpty ? value[0] : 0;
        final int breedIndex = value.length > 1 ? value[1] : 0;
        onChanged(
          DogLostFilter.applySizeBreed(selection, sizeIndex, breedIndex),
        );
      },
    ).showModal(context);
  }

  void _showColorPicker(BuildContext context) {
    Picker(
      adapter: PickerDataAdapter<String>(
          pickerData: [DogLostFilter.colorOptions], isArray: true),
      // 颜色、性别这两个单列选择器，改造前就打开了"回显上次选择"
      selecteds: <int>[DogLostFilter.colorIndexOf(selection.color)],
      confirmText: "确认",
      cancelText: "取消",
      onConfirm: (Picker picker, List<int> value) => onChanged(
        DogLostFilter.applyColor(
            selection, value.isNotEmpty ? value[0] : 0),
      ),
    ).showModal(context);
  }

  void _showGenderPicker(BuildContext context) {
    Picker(
      adapter: PickerDataAdapter<String>(
          pickerData: [DogLostFilter.genderOptions], isArray: true),
      selecteds: <int>[DogLostFilter.genderIndexOf(selection.gender)],
      confirmText: "确认",
      cancelText: "取消",
      onConfirm: (Picker picker, List<int> value) => onChanged(
        DogLostFilter.applyGender(
            selection, value.isNotEmpty ? value[0] : 0),
      ),
    ).showModal(context);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextButton(
            onPressed: () => _showLocationPicker(context),
            child: Text(DogLostFilter.regionText(selection),
                style: _labelStyle),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => _showSizeBreedPicker(context),
            child: Text(DogLostFilter.sizeBreedText(selection),
                style: _labelStyle),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => _showColorPicker(context),
            child: Text(DogLostFilter.colorText(selection), style: _labelStyle),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => _showGenderPicker(context),
            child: Text(DogLostFilter.genderText(selection),
                style: _labelStyle),
          ),
        ),
      ],
    );
  }
}
