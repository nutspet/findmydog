import 'package:flutter/material.dart';

// 返回给上一页处理逻辑 基于路由的设置 这个业务不在本页面实现
enum BackAction { normal, detail }

// 提交完成页面
class LostFinish extends StatefulWidget {
  // 唯一id
  final String uuid;

  const LostFinish(this.uuid, {super.key});

  @override
  LostFinishState createState() => LostFinishState();
}

class LostFinishState extends State<LostFinish> {
  // 回上一页
  void _goBack(BackAction action) {
    Navigator.pop(context, action);
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope 已废弃，改用 PopScope（等价语义：拦截返回，手动带参数 pop）
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          _goBack(BackAction.normal);
        },
        child: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 120.0,
              ),
              Container(
                child: const Icon(
                  Icons.beenhere,
                  size: 130.0,
                  color: Colors.blue,
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 30.0),
                child: const Text(
                  "报告失踪汪成功",
                  style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w400),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text(
                  widget.uuid,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                child: const Text(
                    "请立即进入详情页面开始转发扩散失踪汪讯息。我们已经将您的寻狗启事同步到了91xungou.com，并且通过“寻狗小程序”官方账号推送至微博。"),
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    _goBack(BackAction.detail);
                  },
                  child: const Text(
                    "查看详情",
                    style: TextStyle(color: Colors.white, fontSize: 20.0),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: ElevatedButton(
                  onPressed: () {
                    _goBack(BackAction.normal);
                  },
                  child: const Text(
                    "返回列表",
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
