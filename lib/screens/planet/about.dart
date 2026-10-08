import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 技术团队
class About extends StatelessWidget {
  const About({super.key});

  static const TextStyle mainTitle =
      TextStyle(fontSize: 13.0, color: Colors.black87);
  static const TextStyle subTitle =
      TextStyle(fontSize: 13.0, color: Colors.black54);
  static const EdgeInsets cellPadding = EdgeInsets.all(3.0);

  static const Map<String, String> teamList = {
    "服务端主程": "我们来晚了",
    "小程序开发": "A-vod",
    "React工程师": "Inzer",
    "架构师": "b919p4",
    "技术顾问": "舟哥",
    "产品设计": "领袖门徒倒数第一",
    "交互设计": "Sidewinder",
    "平面设计": "悲鸣星",
    "实习测试": "国服东皇",
    "服务器运维": "共和新高架守护神",
    "运营专员": "Al Fayeed",
    "商务合作": "悲利机长",
    "Flutter主程": "和谐人类",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "技术团队",
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
        // AppBar.brightness 已在 Flutter 3.x 移除，改用 systemOverlayStyle
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: const Color(0xfff8f8f8),
      ),
      body: Column(children: <Widget>[
        const SizedBox(
          height: 20.0,
        ),
        Container(
          child: const Text(
            "整合一实验室",
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
            "无善无恶心之体，有善有恶意之动。知善知恶是良知，为善去恶是格物。",
            style: TextStyle(color: Colors.grey, fontSize: 14.0),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
        ),
        const SizedBox(
          height: 30.0,
        ),
        Container(
          child: Table(
              children: teamList.keys.toList().map((String k) {
            return TableRow(
              children: [
                TableCell(
                  child: Padding(
                    padding: cellPadding,
                    child: Text(
                      "$k：",
                      textAlign: TextAlign.right,
                      style: mainTitle,
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: cellPadding,
                    child: Text(
                      // Map 的 [] 在空安全下返回 String?，
                      // 这里显式兜底，保证渲染结果与旧版一致（不会出现 null 断言）
                      teamList[k] ?? '',
                      style: subTitle,
                    ),
                  ),
                ),
              ],
            );
          }).toList()),
        )
      ]),
    );
  }
}
