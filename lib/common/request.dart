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

  // 初始化，dart在静态变量读取的时候实例化，实际只有一个实例。
  static final Request _singleton = Request._internal();
  // 工厂构造函数
  factory Request() => _singleton;
  // 原始点，留一个getInstance方法。
  static Request getInstance() => _singleton;

  // 命名构造函数，初始化。
  Request._internal() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = CONNECT_TIMEOUT;
    _dio.options.receiveTimeout = RECEIVE_TIMEOUT;
  }

  // 都封装好了 不会用到的 这是用来调试用的
  Dio getDio() => _dio;

  // 保存jwt
  void _saveJwt(String token) {
    // 如果是经过jwt的成功请求 存起来
    Login().jwt = token;
  }

  /// 真正发请求，并把 dio 的异常统一翻译成 [RequestError]。
  ///
  /// dio 默认的 validateStatus 只放行 2xx，所以 4xx/5xx 都会在这里被转成 [RequestError]。
  /// （旧代码在 await 之后判断 `statusCode == 403` / `!= 200`，那两处其实永远不可达，
  /// 已顺手删掉；错误提示仍优先取服务端返回的 message。）
  Future<Response<dynamic>> _send(
    String uri, {
    required Options options,
    Object? data,
    CancelToken? cancelToken,
  }) async {
    // FormData（表单/文件上传）必须放进请求体，普通 Map 作为 query 参数。
    final bool isFormData = data is FormData;
    try {
      return await _dio.request(uri,
          data: isFormData ? data : null,
          queryParameters: isFormData ? null : data as Map<String, dynamic>?,
          options: options,
          cancelToken: cancelToken);
    } on DioException catch (e) {
      throw RequestError(
        message: _bodyMessage(e.response?.data) ?? e.message ?? '请求失败',
        requestOptions: e.requestOptions,
      );
    }
  }

  /// 发请求 → 校验响应 → 返回 `data` 段。
  ///
  /// 失败一律抛 [RequestError]，由调用方（[req] 或 [fetch]）决定怎么处理。
  ///
  /// ⚠️ 旧实现把 fail 回调存在单例字段上（`errorHandler = fail`），
  /// 并发请求时会互相覆盖——后发请求的失败会调到先发请求的 fail 上。
  /// 改成把 fail 当作局部变量传递后，这个隐患就没了。
  Future<Map<String, dynamic>> _request(
    String uri, {
    required String method,
    required bool auth,
    Object? data,
    CancelToken? cancelToken,
  }) async {
    // 请求初始化
    final Options options = Options(method: method);
    if (auth) {
      // 等待登录成功
      await Login().status;
      // 如果是身份验证的 加上头部
      options.headers = {JWT_REQUEST_HEADER: Login().jwt};
    }

    final Response<dynamic> response =
        await _send(uri, options: options, data: data, cancelToken: cancelToken);

    // 走到这里说明 HTTP 层面是 2xx，再看业务层的 status
    final dynamic body = response.data;
    if (body is! Map || body["status"] != "SUCCESS") {
      throw RequestError(
        message: 'status非success！{${_bodyMessage(body) ?? ''}',
        requestOptions: response.requestOptions,
      );
    }

    // 如果有remember的header
    final List<String>? remember = response.headers[JWT_RESPONSE_HEADER];
    if (remember != null && remember.isNotEmpty) {
      _saveJwt(remember[0]);
    }

    // 直接把 response 内容中的 data 段交出去
    final dynamic payload = body["data"];
    return payload is Map<String, dynamic> ? payload : <String, dynamic>{};
  }

  // 从响应体里挖出服务端的错误提示（可能是 Map，也可能是一段纯文本）
  static String? _bodyMessage(Object? body) {
    if (body is Map) {
      final dynamic message = body['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    }
    if (body is String && body.isNotEmpty) return body;
    return null;
  }

  /// 回调式请求，默认 GET，所有结果在回调中处理。
  ///
  /// [data] 允许传 Map（走 query，对应 GET）或 FormData（走 body，对应 POST 上传）。
  /// 未提供 [fail] 时按旧行为把异常抛出去（由 FlutterError.onError 兜底打印）。
  Future<void> req(
    String uri, {
    SuccessHandler? success,
    FailHandler? fail,
    CompleteHandler? complete,
    String method = "GET",
    bool auth = false,
    Object? data,
    CancelToken? cancelToken,
  }) async {
    try {
      final Map<String, dynamic> payload = await _request(
        uri,
        method: method,
        auth: auth,
        data: data,
        cancelToken: cancelToken,
      );
      success?.call(payload);
    } catch (e) {
      final String message =
          e is RequestError ? (e.message ?? '请求失败') : e.toString();
      if (fail != null) {
        fail(message);
      } else {
        rethrow;
      }
    } finally {
      // 旧实现接了 complete 参数却从未调用，这里补上
      complete?.call();
    }
  }

  /// Future 式请求：成功直接返回 `data` 段，失败抛 [RequestError]。
  ///
  /// 列表页的 bloc 用 `await` + `try/catch` 消费，不再需要回调。
  Future<Map<String, dynamic>> fetch(
    String uri, {
    String method = "GET",
    bool auth = false,
    Object? data,
    CancelToken? cancelToken,
  }) {
    return _request(
      uri,
      method: method,
      auth: auth,
      data: data,
      cancelToken: cancelToken,
    );
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
