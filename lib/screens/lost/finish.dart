import 'package:flutter/material.dart';

// 返回给上一页处理逻辑 基于路由的设置 这个业务不在本页面实现
enum BackAction { normal, detail }

// 提交完成页面
class LostFinish extends StatefulWidget {
  // 唯一id
  final String uuid;

  LostFinish(this.uuid);

  @override
  createState() => new LostFinishState();
}

class LostFinishState extends State<LostFinish> {
  // 回上一页
  void _goBack(BackAction action) {
    Navigator.pop(context, action);
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        child: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 120.0,
              ),
              Container(
                child: Icon(
                  Icons.beenhere,
                  size: 130.0,
                  color: Colors.blue,
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 30.0),
                child: Text(
                  "报告失踪汪成功",
                  style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w400),
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 5.0),
                child: Text(
                  widget.uuid,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                child: Text(
                    "请立即进入详情页面开始转发扩散失踪汪讯息。我们已经将您的寻狗启事同步到了91xungou.com，并且通过“寻狗小程序”官方账号推送至微博。"),
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: RaisedButton(
                  onPressed: () {
                    _goBack(BackAction.detail);
                  },
                  color: Colors.blue,
                  child: Text(
                    "查看详情",
                    style: TextStyle(color: Colors.white, fontSize: 20.0),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: RaisedButton(
                  onPressed: () {
                    _goBack(BackAction.normal);
                  },
                  child: Text(
                    "返回列表",
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
              ),
            ],
          ),
        ),
        onWillPop: () {
          _goBack(BackAction.normal);
        });
  }
}
