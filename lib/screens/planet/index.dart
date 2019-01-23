import 'package:flutter/material.dart';
import 'quick_start.dart';
import 'about.dart';
import 'thanks.dart';
import 'package:fluwx/fluwx.dart' as fluwx;

// 汪星球
class PlanetIndex extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        brightness: Brightness.light,
        backgroundColor: Color(0xfff8f8f8),
        elevation: 0.0,
      ),
      body: SafeArea(
          child: Column(
        children: <Widget>[
          Container(
            child: Text(
              "欢迎来到汪星球",
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
              "寻狗App：用最好的技术善待生命！",
              style: TextStyle(color: Colors.grey, fontSize: 14.0),
            ),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 40.0),
          ),
          SizedBox(
            height: 30.0,
          ),
          Table(
            children: [
              TableRow(children: [
                InkWell(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 20.0,
                        ),
                        Image(
                          image:
                              AssetImage("data_repo/img/grid/icecream-04.png"),
                          width: 45.0,
                        ),
                        SizedBox(
                          height: 8.0,
                        ),
                        Text(
                          "快速入门H5",
                          style: TextStyle(fontSize: 13.0),
                        ),
                        SizedBox(
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
                      new MaterialPageRoute(
                        builder: (context) => new QuickStart(),
                      ),
                    );
                  },
                ),
                InkWell(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 20.0,
                        ),
                        Image(
                          image:
                              AssetImage("data_repo/img/grid/icecream-12.png"),
                          width: 45.0,
                        ),
                        SizedBox(
                          height: 8.0,
                        ),
                        Text(
                          "关于我们",
                          style: TextStyle(fontSize: 13.0),
                        ),
                        SizedBox(
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
                      new MaterialPageRoute(
                        builder: (context) => new About(),
                      ),
                    );
                  },
                ),
                InkWell(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 20.0,
                        ),
                        Image(
                          image:
                              AssetImage("data_repo/img/grid/icecream-16.png"),
                          width: 45.0,
                        ),
                        SizedBox(
                          height: 8.0,
                        ),
                        Text(
                          "特别鸣谢",
                          style: TextStyle(fontSize: 13.0),
                        ),
                        SizedBox(
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
                      new MaterialPageRoute(
                        builder: (context) => new Thanks(),
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
                        SizedBox(
                          height: 20.0,
                        ),
                        Image(
                          image: AssetImage(
                              "data_repo/img/grid/icecream-14.png"),
                          width: 45.0,
                        ),
                        SizedBox(
                          height: 8.0,
                        ),
                        Text(
                          "打开小程序版",
                          style: TextStyle(fontSize: 13.0),
                        ),
                        SizedBox(
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
                      builder: (BuildContext context) =>
                          SimpleDialog(title: Text('特别说明'), children: <Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text("该功能将直接调用手机上的微信打开我们寻狗小程序版本！"),
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 25.0),
                              child: Image(
                                image: AssetImage("data_repo/img/logo/wx.png"),
                              ),
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            FractionallySizedBox(
                              child: OutlineButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    // 直接跳小程序
                                    fluwx
                                        .launchMiniProgram(
                                      username: "gh_0c80acc3f473",
                                    )
                                        .then((data) {
                                      print(data);
                                    });
                                  },
                                  icon: Icon(Icons.check),
                                  label: Text("带我去看看吧！")),
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
          SizedBox(
            height: 20.0,
          ),
          Container(
            child: Text(
              "我们是微信上最大的寻狗启事小程序“寻狗”的原生APP版本，（百度小程序：鸣让寻狗启事助手）（支付宝小程序：公益寻狗）。希望通过我们的努力帮助到狗狗和养狗狗的人，我们的网站是www.91xungou.com。",
              style: TextStyle(color: Colors.grey, fontSize: 12.0),
            ),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 45.0),
          ),
        ],
      )),
    );
  }
}
