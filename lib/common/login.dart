import 'package:find_dog/common/request.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'dart:io' show Platform;
import 'basis.dart';

// 登录状态的单例
class Login {
  // 登录的uuid
  String uuid;
  // 是否手机验证 相当于注册会员
  bool mobileVerify;
  // 存jwt
  String jwt;
  // 登录状态
  Future<void> status;

  // 实例化
  static final Login _login = new Login._internal();

  factory Login() {
    return _login;
  }
  // 初始化 进行登录
  // 理论上只有在request需要auth的时候才会触发真的登录
  Login._internal() {
    status = doLogin();
  }

  // 核心静态登录方法
  Future<void> doLogin(
      {FailHandler fail,
      SuccessVoidHandler success,
      CompleteHandler complete}) async {
    String deviceId = await initDeviceId();
    String platform = initPlatform();
    Request api = Request();
    // 把状态传递出来
    return api.req("/auth/login_app",
        auth: false, data: {"app_device_id": deviceId, "app_os": platform},
        success: (Map<String, dynamic> res) {
      uuid = res["uuid"];
      mobileVerify = res["mobileVerify"];
      if (success != null) {
        success();
      }
    }, fail: (message) {
      if (fail != null) {
        fail(message);
      }
    }).whenComplete(() {
      if (complete != null) {
        complete();
      }
    });
  }

  // debug 看看jwt值
  debug() {
    print("has login debug");
    print("jwt_$this.jwt");
  }

  // 获得设备ID
  static Future<String> initDeviceId() async => await FlutterUdid.udid;

  // 获得操作系统
  static String initPlatform() {
    String os = Platform.operatingSystem;
    return os;
  }
}
