import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:find_dog/bloc/simple_bloc_observer.dart';
import 'package:find_dog/common/login.dart';
import 'package:find_dog/common/request.dart';
import 'package:find_dog/screens/lost/list.dart';
import 'package:find_dog/screens/lost/report.dart';
import 'package:find_dog/screens/my/index.dart';
import 'package:find_dog/screens/planet/index.dart';
import 'package:fluwx/fluwx.dart';
import 'package:geolocator/geolocator.dart';

// fluwx 6.x 用一个实例来调用（registerApi / open 等）
final Fluwx _fluwx = Fluwx();

void main() {
  // 插件（微信 SDK）要在 runApp 之前注册，必须先初始化绑定
  WidgetsFlutterBinding.ensureInitialized();

  // 列表页用的 bloc 全局观察者：只在 debug 构建打印事件/状态流转，便于排查。
  // bloc 9 已移除 BlocOverrides.runZoned，直接赋值即可。
  Bloc.observer = SimpleBlocObserver();

  FlutterError.onError = (errorDetails) {
    print("全局错误");
    print(errorDetails);
  };
  // 默认的api设置
  Request.baseUrl = "https://api.91xungou.com";

  // 初始化fluwx 需要你自己的key
  _fluwx.registerApi(appId: "xxxxxxxxxxxxx");

  // _debug();

  // 登录
  Login();
  // Login.debug();

  runApp(MaterialApp(
    // 关掉debug展示
    debugShowCheckedModeBanner: true,
    title: "寻狗Flutter测试",
    // 主题颜色
    theme: ThemeData(
      brightness: Brightness.light,
      // 保留升级前（Flutter 1.x 只有 Material 2）的视觉风格，
      // 避免 M3 默认主题导致按钮/AppBar 等外观变化。
      // 想切到 Material 3 只需把它改成 true（或删掉这一行）。
      useMaterial3: false,
      // 旧的 RaisedButton 默认是灰底黑字，ElevatedButton 在 M2 模式下默认是蓝底。
      // 这里把全局默认调回灰底黑字，保证未显式设色的按钮外观不变
      // （显式设置 backgroundColor 的按钮仍以自身样式为准）。
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE0E0E0),
          foregroundColor: Colors.black87,
        ),
      ),
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
    home: MyHome(),
    // 静态路由
    routes: <String, WidgetBuilder>{
      '/lost/report': (_) => LostReport(),
      '/lost/list': (_) => LostList(),
    },
  ));
}

// 用来的debug的
// 故意保留的手动调试入口：在 main() 里取消注释 `// _debug();` 即可调用。
// ignore: unused_element
Future<void> _debug() async {
  print("lala");
  final LocationPermission permission = await Geolocator.checkPermission();
  print(permission);
  final Position position = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high));
  print(position.longitude);
  print(position.latitude);
  print("dddd");
}

// 有状态的
class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  MyHomeState createState() => MyHomeState();
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
  // List<Widget> _mainPage = [LostList(key: _scaffoldKey,), PlanetIndex(), MyIndex()];

  Widget _page(int index) {
    switch (index) {
      case 0:
        return LostList();
      case 1:
        return PlanetIndex();
      case 2:
        return MyIndex();
    }

    throw "Invalid index $index";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text("寻狗小程序"),),
      body: Stack(
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
      // Set the bottom navigation bar
      bottomNavigationBar: Material(
        // set the color of the bottom navigation bar
        color: Colors.white,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          fixedColor: Colors.blue,
          currentIndex: _currentIndex,
          // title: 属性已被移除（改为 label: String），文字样式改由这两个属性承载，
          // 保持与升级前一致的粗体 10 号字。
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.0),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.0),
          onTap: (int index) {
            // print(index);
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Image(image: AssetImage("data_repo/img/bar/lost.png")),
              label: "流浪汪",
            ),
            BottomNavigationBarItem(
              icon: Image(image: AssetImage("data_repo/img/bar/planet.png")),
              label: "汪星球",
            ),
            BottomNavigationBarItem(
              icon: Image(image: AssetImage("data_repo/img/bar/my.png")),
              label: "个人中心",
            )
          ],
        ),
      ),
    );
  }
}
