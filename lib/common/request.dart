import 'dart:io';

import 'package:dio/dio.dart';

import 'basis.dart';
import 'login.dart';

// 远程请求对象，单例模式。
// 封装好dio的拦截器，可以用到jwt。
class Request {
  // 连接超时（dio 5 起超时统一用 Duration）
  static const Duration CONNECT_TIMEOUT = Duration(milliseconds: 10000);
  // 接受超时
  static const Duration RECEIVE_TIMEOUT = Duration(milliseconds: 10000);
  // JWT的TOKEN
  static const String JWT_REQUEST_HEADER = "kobe";
  // JWT的REMEMBER
  static const String JWT_RESPONSE_HEADER = "rememberme";
  // base URl 例如：https://api.91xungou.com
  static String baseUrl = "";
  // dio 实例
  final Dio _dio = Dio();

  // 错误handler（没有设置时走默认抛异常）
  FailHandler? errorHandler;

  // 初始化，dart在静态变量读取的时候实例化，实际只有一个实例。
  static final Request _singleton = Request._internal();
  // 工厂构造函数
  factory Request() => _singleton;
  // 原始点，留一个getInstance方法。
  static Request getInstance() => _singleton;

  // 命名构造函数，初始化。
  Request._internal() {
    // 190409在这里修改baseurl
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = CONNECT_TIMEOUT;
    _dio.options.receiveTimeout = RECEIVE_TIMEOUT;
    // 拦截器 给jwt用的 过期了 要看手册用新写法
  }

  // 保存jwt
  void _saveJwt(String token) {
    // 如果是经过jwt的成功请求 存起来
    Login().jwt = token;
  }

  // 读取jwt
  // 应该扔一个error用来处理没身份的情况
  String _loadJwt() {
    return Login().jwt;
  }

  void _handleError(String message) {
    final FailHandler? handler = errorHandler;
    if (handler != null) {
      // 全局的有就接住
      handler(message);
    } else {
      // 默认直接扔出去
      throw RequestError(message: message);
    }
  }

  // 都封装好了 不会用到的 这是用来调试用的
  Dio getDio() => _dio;

  // 发送请求，默认GET，所有返回在回调中处理。
  // [data] 允许传 Map（走 query，对应 GET）或 FormData（走 body，对应 POST 上传）。
  Future<void> req<T>(String uri,
      {SuccessHandler? success,
      FailHandler? fail,
      CompleteHandler? complete,
      String method = "GET",
      bool auth = false,
      Object? data,
      CancelToken? cancelToken}) async {
    // 初始化，默认get，以及baseurl。
    Options options = Options(
      method: method,
    );
    if (auth) {
      // 等待登录成功
      await Login().status;
      // 如果是身份验证的 加上头部
      String token = _loadJwt();
      options.headers = {JWT_REQUEST_HEADER: token};
    }

    // 绑定fail作为errorHandler
    errorHandler = fail;

    // FormData（表单/文件上传）必须放进请求体，普通 Map 作为 query 参数。
    final bool isFormData = data is FormData;

    // 执行请求
    try {
      Response response = await _dio.request(uri,
          data: isFormData ? data : null,
          queryParameters: isFormData ? null : data as Map<String, dynamic>?,
          options: options,
          cancelToken: cancelToken);

      // 如果api返回http code 403就是未授权
      if (response.statusCode == HttpStatus.forbidden) {
        // 重新登录
        Login().doLogin();
        _handleError("登录超时，已重登录，请重新尝试。");
      }
      // 不是200的（500，403已排除）
      if (response.statusCode != HttpStatus.ok) {
        _handleError("非200请求。");
      }

      // 如果有api返回有errMsg
      if (response.data["status"] != "SUCCESS") {
        _handleError("status非success！{${response.data["message"]}");
      }
      // 如果有remember的header
      final List<String>? remember = response.headers[JWT_RESPONSE_HEADER];
      if (remember != null && remember.isNotEmpty) {
        _saveJwt(remember[0]);
      }
      // 成功的回调 直接给response内容 中的 data下标 其他情况在钩子里已全部处理了
      if (success != null) {
        success(response.data["data"]);
      }
    } on DioException catch (e) {
      // 500在这里会被处理掉 DioException把500的拿走了
      if (e.response != null) {
        _handleError("${e.response?.data?['message'] ?? e.message ?? '请求失败'}");
      } else {
        _handleError(e.message ?? '请求失败');
      }
    }
  }
}

// 封装的错误
class RequestError extends DioException {
  RequestError({required String message, RequestOptions? requestOptions})
      : super(
          requestOptions: requestOptions ?? RequestOptions(),
          message: message,
        );
}
