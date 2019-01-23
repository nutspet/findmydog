import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:find_dog/common/login.dart';
import 'lost.dart';
import 'profile.dart';
import 'package:find_dog/common/request.dart';
import 'package:find_dog/models/profile.dart';

class MyIndex extends StatefulWidget {
  @override
  MyIndexState createState() => new MyIndexState();
}

// 个人中心
class MyIndexState extends State<MyIndex> {
  Profile profile = new Profile();

  MyIndexState() {
    _loadProfile();
  }

  @override
  void initState() {
    super.initState();
  }

  void _loadProfile() {
    Request api = Request();
    api.req("/my/profile2", auth: true, success: (res) {
      //print(res['result']);
      setState(() {
        profile = Profile.fromJson(res['result']);
      });
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff8f8f8),
      appBar: AppBar(
        title: Text(
          "个人中心",
          style: TextStyle(fontSize: 16.0, color: Colors.black),
        ),
        elevation: 0.0,
        centerTitle: true,
        brightness: Brightness.light,
        backgroundColor: Color(0xfff8f8f8),
      ),
      body: Column(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Divider(
                  height: 1.0,
                ),
                ListTile(
                  dense: true,
                  title: Text(profile.name),
                  subtitle: Text(profile.mobileVerify ? "手机已认证" : "手机尚未验证"),
                  leading: CircleAvatar(
                    child: Icon(
                      Icons.person,
                      size: 40.0,
                    ),
                    maxRadius: 23.0,
                  ),
                  trailing: Icon(Icons.keyboard_arrow_right),
                  onTap: () async {
                    bool fresh = await Navigator.push(
                      context,
                      new MaterialPageRoute<bool>(
                        builder: (_) => new MyProfile(
                              profile: profile,
                            ),
                      ),
                    );
                    // 如果更新了
                    if (fresh == true) {
                      _loadProfile();
                    }
                  },
                ),
                Divider(
                  height: 1.0,
                ),
                Container(
                  height: 40.0,
                  color: Color(0xfff8f8f8),
                ),
                Divider(
                  height: 1.0,
                ),
                ListTile(
                  dense: true,
                  isThreeLine: false,
                  title: Text(
                    "我的失踪汪报告",
                    style: TextStyle(fontSize: 14.0),
                  ),
                  leading: Image(
                    image: AssetImage("data_repo/img/my/clock.png"),
                    width: 24.0,
                  ),
                  trailing: Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      new MaterialPageRoute(
                        builder: (_) => new MyLost(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1.0,
                ),
                Container(
                  height: 40.0,
                  color: Color(0xfff8f8f8),
                ),
                Divider(
                  height: 1.0,
                ),
                ListTile(
                  dense: true,
                  title: Text(
                    "重新获取登录态",
                    style: TextStyle(fontSize: 14.0),
                  ),
                  leading: Image(
                    image: AssetImage("data_repo/img/my/pen&ruler.png"),
                    width: 24.0,
                  ),
                  trailing: Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) {
                        return Dialog(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 30.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CupertinoActivityIndicator(),
                                Text("请求中。。。"),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                    // 重登录
                    Login().doLogin(success: () {
                      Navigator.of(context).pop();
                      showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              content: Text("重新登录成功！"),
                              actions: <Widget>[
                                RaisedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    "确认",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              ],
                            );
                          });
                    }, fail: (message) {
                      Navigator.of(context).pop();
                      showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              content: Text("重新登录失败！$message"),
                              actions: <Widget>[
                                RaisedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    "确认",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              ],
                            );
                          });
                    });
                  },
                ),
                Divider(
                  height: 1.0,
                ),
                ListTile(
                  dense: true,
                  title: Text(
                    "寻狗",
                    style: TextStyle(fontSize: 14.0),
                  ),
                  leading: Image(
                    image: AssetImage("data_repo/img/my/plant.png"),
                    width: 24.0,
                  ),
                  trailing: Text(
                    "版本 1.9.9.14",
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            content: Text(
                              "原生APP版本！我们一直在努力！加油！",
                              style: TextStyle(fontSize: 12.0),
                            ),
                          );
                        });
                  },
                ),
                Divider(
                  height: 1.0,
                )
              ],
            ),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
