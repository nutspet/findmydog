import 'package:flutter/material.dart';
import 'package:find_dog/screens/lost/list.dart';
import 'package:find_dog/screens/my/index.dart';
import 'package:find_dog/screens/planet/index.dart';
import 'package:find_dog/common/request.dart';
import 'package:find_dog/common/login.dart';
import 'package:find_dog/screens/lost/detail.dart';
import 'package:find_dog/screens/lost/report.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:find_dog/models/location.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io' show Platform;
import 'package:fluwx/fluwx.dart' as fluwx;

void main() {
  FlutterError.onError = (errorDetails) {
    print("全局错误");
    print(errorDetails);
  };
  // 默认的api设置
  Request.baseUrl = "https://api.91xungou.com";

  // 初始化fluwx 需要你自己的key
  fluwx.register(appId: "xxxxxxxxxxxxx");

  // _debug();

  // 登录
  Login();
  // Login.debug();

  runApp(new MaterialApp(
    // 关掉debug展示
    debugShowCheckedModeBanner: true,
    title: "寻狗Flutter测试",
    // 主题颜色
    theme: new ThemeData(
      brightness: Brightness.light,
//        primaryColor: const Color(0xFF09bb07),
//        accentColor: Colors.white,
//        bottomAppBarColor: const Color(0xFFf8f8f8),
      // accentColor: Colors.red,
    ),
    localizationsDelegates: [
      // 添加区域
      // 准备在这里添加我们自己创建的代理
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: [
      const Locale('en', 'US'), // English
      const Locale('zh', 'CH'), // 中文
    ],
    home: new MyHome(),
    // 静态路由
    routes: <String, WidgetBuilder>{
      '/lost/report': (_) => new LostReport(),
      '/lost/list': (_) => new LostList(),
    },
  ));
}

// 用来的debug的
_debug() async {
  print("lala");
  GeolocationStatus geolocationStatus =
      await Geolocator().checkGeolocationPermissionStatus();
  print(geolocationStatus);
  Position position = await Geolocator()
      .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  print(position.longitude);
  print(position.latitude);
  print("dddd");
}

// 有状态的
class MyHome extends StatefulWidget {
  @override
  MyHomeState createState() => new MyHomeState();
}

// SingleTickerProviderStateMixin 用来做动画
class MyHomeState extends State<MyHome> {
  // 底部按钮索引
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 别用静态变量
  // List<Widget> _mainPage = [new LostList(key: _scaffoldKey,), new PlanetIndex(), new MyIndex()];

  Widget _page(int index) {
    switch (index) {
      case 0:
        return new LostList();
      case 1:
        return new PlanetIndex();
      case 2:
        return new MyIndex();
    }

    throw "Invalid index $index";
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      // appBar: new AppBar(title: new Text("寻狗小程序"),),
      body: new Stack(
        children: List.generate(
          3,
          (int index) {
            return IgnorePointer(
              ignoring: index != _currentIndex,
              child: Opacity(
                opacity: _currentIndex == index ? 1.0 : 0.0,
                child: _page(index),
              ),
            );
          },
        ),
      ),
      //body: Center(child: new DropdownButton(items: [new DropdownMenuItem(child: new Text("ddd"))], onChanged: null),),
      // Set the bottom navigation bar
      bottomNavigationBar: Material(
        // set the color of the bottom navigation bar
        color: Colors.white,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          fixedColor: Colors.blue,
          currentIndex: _currentIndex,
          onTap: (int index) {
            // print(index);
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: const Image(
                  image: const AssetImage("data_repo/img/bar/lost.png")),
              title: const Text(
                "流浪汪",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10.0,
                ),
              ),
            ),
            const BottomNavigationBarItem(
              icon: const Image(
                  image: const AssetImage("data_repo/img/bar/planet.png")),
              title: const Text(
                "汪星球",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10.0,
                ),
              ),
            ),
            const BottomNavigationBarItem(
              icon: const Image(
                  image: const AssetImage("data_repo/img/bar/my.png")),
              title: const Text(
                "个人中心",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10.0,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
