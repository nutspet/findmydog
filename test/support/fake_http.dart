// 测试用的 HTTP 拦截层。
//
// 生产代码里 `Request` 是单例，并且把内部 Dio 暴露成 `getDio()`：
//   final Dio _dio = Dio();
//   Dio getDio() => _dio;
// 所以测试可以直接把它的 `httpClientAdapter` 换成假的 ——
// **不需要为了可测性去改任何生产代码**。
//
// 用法：
//   final FakeHttpAdapter http = installFakeHttp((options) => successEnvelope(...));
//   ... 跑页面 ...
//   expect(http.requests, hasLength(2));
//
// 想造非 200 的响应（测 4xx/5xx 分支）时，把工厂的返回值换成 [FakeResponse]：
//   installFakeHttp((_) => FakeResponse(failureEnvelope('炸了'), statusCode: 500));

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:find_dog/common/request.dart';

/// 带状态码的假响应体。
///
/// 不复用它时，工厂直接返回 `String` 即视为 **200 + application/json**。
class FakeResponse {
  const FakeResponse(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;
}

/// 由请求参数决定返回哪段 JSON 文本（或带状态码的 [FakeResponse]）。
typedef ResponseFactory = FutureOr<Object> Function(RequestOptions options);

/// 把 HTTP 完全拦下来的适配器：不发真实网络，只按 [factory] 回一段文本。
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.factory);

  final ResponseFactory factory;

  /// 按到达顺序记录所有请求，用来断言"究竟打了几次、带了什么参数"。
  final List<RequestOptions> requests = <RequestOptions>[];

  /// 取某个 query 参数（`page` / `pageSize` / `gender` ...）。
  List<Object?> queryValuesOf(String name) => requests
      .map((RequestOptions r) => r.queryParameters[name])
      .toList(growable: false);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object result = await factory(options);
    final (String body, int statusCode) = switch (result) {
      FakeResponse r => (r.body, r.statusCode),
      String b => (b, 200),
      _ => throw ArgumentError(
          '假 HTTP 工厂只能返回 String 或 FakeResponse，收到 ${result.runtimeType}'),
    };
    // content-type 必须是 json：否则 dio 的默认 transformer 会把 body
    // 当成纯字符串交出去，`Request._request` 里的 `body is! Map` 判断就会失败。
    return ResponseBody.fromString(body, statusCode, headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// 装上假适配器并返回它，方便后续断言。
///
/// `main()` 里会设置 `Request.baseUrl`，测试不走 main，
/// 所以这里必须自己补一个合法绝对地址 —— 否则 dio 拿到相对路径会直接抛错。
FakeHttpAdapter installFakeHttp(ResponseFactory factory) {
  Request.baseUrl = 'https://fake.test';
  final Dio dio = Request.getInstance().getDio();
  dio.options.baseUrl = Request.baseUrl;
  final FakeHttpAdapter adapter = FakeHttpAdapter(factory);
  dio.httpClientAdapter = adapter;
  return adapter;
}

/// 一条失踪狗的后端记录。
///
/// 下标型字段（color / size / breed / time）与真实接口一致，传的是**整数下标**，
/// 需要被测代码翻译成中文文案 —— 这正是最值得盯的映射。
Map<String, dynamic> lostDogJson(int index) => <String, dynamic>{
      'id': index,
      'uuid': 'uuid-$index',
      'age': 2,
      'date': '2024-05-01',
      'contactsGender': true,
      'contactsMobile': '13800000000',
      'contactsName': '张三',
      'found': false,
      'gender': false, // false -> 母
      'locationAddress': '某某路 $index 号',
      'locationName': '示例小区$index',
      'locationLatitude': '31.2000',
      'locationLongitude': '121.4000',
      'negotiate': false, // false -> 显示 "¥ 金额"
      'regionArea': '浦东新区',
      'regionCity': '上海市',
      'regionProvince': '上海市',
      'remark': '备注$index',
      'reward': 100 * index,
      'time': 1, // 1 -> 下午
      'weight': 5,
      'wxaQrCode': 'qr-$index',
      'color': 5, // 5 -> 黑色
      'size': 0, // 0 -> 小型
      'breed': 0, // DogSizeBreed[0][0] -> 中华田园犬
      // 刻意留空：非空时 LostListItem 会走 CachedNetworkImage，
      // 而它依赖 path_provider / sqflite 这类原生插件，在 widget test 里没有实现。
      // 图片分支单独留作后续用 mock 覆盖，先不让它污染整条用例。
      'pic': <dynamic>[],
    };

/// 正常的 SUCCESS 信封：`{status: SUCCESS, data: {list, pagination}}`
String successEnvelope({
  required List<Map<String, dynamic>> list,
  int page = 1,
  int pageSize = 25,
  bool nextPage = false,
}) =>
    jsonEncode(<String, dynamic>{
      'status': 'SUCCESS',
      'data': <String, dynamic>{
        'list': list,
        'pagination': <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
          'total': list.length,
          'nextPage': nextPage,
        },
      },
    });

/// 业务失败信封（HTTP 200，但 status 不是 SUCCESS）。
String failureEnvelope(String message) =>
    jsonEncode(<String, dynamic>{'status': 'FAIL', 'message': message});

/// 一次性造 n 条记录。
List<Map<String, dynamic>> lostDogs(int n, {int base = 1}) =>
    List<Map<String, dynamic>>.generate(n, (int i) => lostDogJson(base + i));
