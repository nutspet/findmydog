import 'package:flutter/material.dart';

// 技术团队
class Thanks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text(
          "特别鸣谢",
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
            "感谢",
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
            "感谢在建设过程给予帮助的好心人，排名不分先后。",
            style: TextStyle(color: Colors.grey),
          ),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 40.0),
        ),
        SizedBox(
          height: 30.0,
        ),
        Container(
          child: Text(
            "maggie_ke，mteng，junfei",
            style: TextStyle(fontSize: 14.0, color: Colors.black54),
          ),
        )
      ]),
    );
  }
}
