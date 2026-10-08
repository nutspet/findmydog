import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 特别鸣谢
class Thanks extends StatelessWidget {
  const Thanks({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "特别鸣谢",
          style: TextStyle(fontSize: 16.0, color: Colors.black),
        ),
        elevation: 0.0,
        leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        // AppBar.brightness 已在 Flutter 3.x 移除，
        // 等价写法是直接指定状态栏图标的明暗风格（原 Brightness.light = 深色图标）
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: const Color(0xfff8f8f8),
      ),
      body: Column(children: <Widget>[
        const SizedBox(
          height: 20.0,
        ),
        Container(
          child: const Text(
            "感谢",
            style: TextStyle(fontSize: 18.0),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
        ),
        const SizedBox(
          height: 10.0,
        ),
        Container(
          child: const Text(
            "感谢在建设过程给予帮助的好心人，排名不分先后。",
            style: TextStyle(color: Colors.grey),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
        ),
        const SizedBox(
          height: 30.0,
        ),
        Container(
          child: const Text(
            "maggie_ke，mteng，junfei",
            style: TextStyle(fontSize: 14.0, color: Colors.black54),
          ),
        )
      ]),
    );
  }
}
