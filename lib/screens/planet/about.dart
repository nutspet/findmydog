import 'package:flutter/material.dart';

// 技术团队
class About extends StatelessWidget {
  static const TextStyle mainTitle =
      TextStyle(fontSize: 13.0, color: Colors.black87);
  static const TextStyle subTitle =
      TextStyle(fontSize: 13.0, color: Colors.black54);
  static const EdgeInsets cellPadding = EdgeInsets.all(3.0);

  Map<String, String> teamList = {
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
    return new Scaffold(
      appBar: AppBar(
        title: Text(
          "技术团队",
          style: TextStyle(fontSize: 16.0, color: Colors.black),
        ),
        elevation: 0.0,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        brightness: Brightness.light,
        backgroundColor: Color(0xfff8f8f8),
      ),
      body: Column(children: <Widget>[
        SizedBox(
          height: 20.0,
        ),
        Container(
          child: Text(
            "整合一实验室",
            style: TextStyle(fontSize: 18.0),
          ),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 40.0),
        ),
        SizedBox(
          height: 10.0,
        ),
        Container(
          child: Text(
            "无善无恶心之体，有善有恶意之动。知善知恶是良知，为善去恶是格物。",
            style: TextStyle(color: Colors.grey, fontSize: 14.0),
          ),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 40.0),
        ),
        SizedBox(
          height: 30.0,
        ),
        Container(
          child: Table(
              children: teamList.keys.toList().map((k) {
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
                      teamList[k],
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
