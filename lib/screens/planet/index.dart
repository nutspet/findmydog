import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluwx/fluwx.dart' as fluwx;

import 'about.dart';
import 'quick_start.dart';
import 'thanks.dart';

// 汪星球
class PlanetIndex extends StatelessWidget {
  const PlanetIndex({super.key});

  // fluwx 6.x 起改为实例式 API（旧版是静态方法 fluwx.launchMiniProgram）。
  // 用 static final 保证全局只创建一个实例，避免重复订阅微信回调事件流。
  static final fluwx.Fluwx _fluwx = fluwx.Fluwx();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar.brightness 已在 Flutter 3.x 移除，改用 systemOverlayStyle
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: const Color(0xfff8f8f8),
        elevation: 0.0,
      ),
      body: SafeArea(
          child: Column(
        children: <Widget>[
          Container(
            child: const Text(
              "欢迎来到汪星球",
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
              "寻狗App：用最好的技术善待生命！",
              style: TextStyle(color: Colors.grey, fontSize: 14.0),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
          ),
          const SizedBox(
            height: 30.0,
          ),
          Table(
            children: [
              TableRow(children: [
                InkWell(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(
                          height: 20.0,
                        ),
                        const Image(
                          image:
                              AssetImage("data_repo/img/grid/icecream-04.png"),
                          width: 45.0,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          "快速入门H5",
                          style: TextStyle(fontSize: 13.0),
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top:
                            BorderSide(width: 1.0, color: Colors.grey.shade200),
                        right:
                            BorderSide(width: 1.0, color: Colors.grey.shade200),
                        bottom:
                            BorderSide(width: 1.0, color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuickStart(),
                      ),
                    );
                  },
                ),
                InkWell(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(
                          height: 20.0,
                        ),
                        const Image(
                          image:
                              AssetImage("data_repo/img/grid/icecream-12.png"),
                          width: 45.0,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          "关于我们",
                          style: TextStyle(fontSize: 13.0),
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top:
                            BorderSide(width: 1.0, color: Colors.grey.shade200),
                        right:
                            BorderSide(width: 1.0, color: Colors.grey.shade200),
                        bottom:
                            BorderSide(width: 1.0, color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const About(),
                      ),
                    );
                  },
                ),
                InkWell(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(
                          height: 20.0,
                        ),
                        const Image(
                          image:
                              AssetImage("data_repo/img/grid/icecream-16.png"),
                          width: 45.0,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          "特别鸣谢",
                          style: TextStyle(fontSize: 13.0),
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top:
                            BorderSide(width: 1.0, color: Colors.grey.shade200),
                        bottom:
                            BorderSide(width: 1.0, color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Thanks(),
                      ),
                    );
                  },
                ),
              ]),
              TableRow(children: [
                InkWell(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(
                          height: 20.0,
                        ),
                        const Image(
                          image: AssetImage(
                              "data_repo/img/grid/icecream-14.png"),
                          width: 45.0,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          "打开小程序版",
                          style: TextStyle(fontSize: 13.0),
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right:
                            BorderSide(width: 1.0, color: Colors.grey.shade200),
                        bottom:
                            BorderSide(width: 1.0, color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  onTap: () {
                    showDialog<String>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) => SimpleDialog(
                          title: const Text('特别说明'),
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child:
                                  Text("该功能将直接调用手机上的微信打开我们寻狗小程序版本！"),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 25.0),
                              child: Image(
                                image: AssetImage("data_repo/img/logo/wx.png"),
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            FractionallySizedBox(
                              child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    // 直接跳小程序（fluwx 6.x 实例式 API）
                                    _fluwx
                                        .open(
                                      target: fluwx.MiniProgram(
                                        username: "gh_0c80acc3f473",
                                      ),
                                    )
                                        .then((data) {
                                      print(data);
                                    });
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text("带我去看看吧！")),
                              widthFactor: 0.9,
                            )
                          ]),
                    );
                  },
                ),
                Container(),
                Container(),
              ])
            ],
          ),
          const SizedBox(
            height: 20.0,
          ),
          Container(
            child: const Text(
              "我们是微信上最大的寻狗启事小程序“寻狗”的原生APP版本，（百度小程序：鸣让寻狗启事助手）（支付宝小程序：公益寻狗）。希望通过我们的努力帮助到狗狗和养狗狗的人，我们的网站是www.91xungou.com。",
              style: TextStyle(color: Colors.grey, fontSize: 12.0),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 45.0),
          ),
        ],
      )),
    );
  }
}
