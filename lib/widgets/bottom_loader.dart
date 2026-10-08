import 'package:flutter/material.dart';

/// 列表末尾的"正在取下一页"转圈。
///
/// 只在还有下一页（`pagination.nextPage == true`）时才挂在列表最后一项，
/// 配合"滑到底部自动加载"代替了改造前的「加载更多数据」按钮。
class BottomLoader extends StatelessWidget {
  const BottomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: SizedBox(
          height: 24.0,
          width: 24.0,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
    );
  }
}
