/// 天地图（国家地理信息公共服务平台）的接入参数。
///
/// 这里集中放**所有和天地图接口有关的东西**：瓦片 URL 模板、集群子域、
/// 允许的缩放范围、地理编码 URI 的构造。
/// 业务代码（`map.dart` / `report.dart`）只引用这里，
/// 换 tk 或换图层都只需要改一个地方。
///
/// 相关：tk 本身的定义在 `lib/common/constants.dart` 的 [Constants.tiandituTk]。
library;

import 'dart:convert';

import 'package:find_dog/common/constants.dart';

/// tk 是否已经填过。
///
/// 留空时不去请求瓦片（请求也只会拿到 418），直接给用户一个明确的提示，
/// 比甩一张空白灰图更好排查。
bool get tiandituTkConfigured => Constants.tiandituTk.trim().isNotEmpty;

/// 天地图瓦片集群节点，`t0` ~ `t7`。
///
/// 八个节点轮流用，绕过浏览器/系统对同域并发连接数的限制，顺带分担负载。
const List<String> tiandituSubdomains = <String>[
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
];

/// 天地图允许的缩放级别上下限。
///
/// 超出这个范围服务端**不报错**，而是返回空白瓦片——所以必须自己卡住，
/// 否则用户往上一捏就得到一张白图，看起来像 App 坏了。
const double tiandituMinZoom = 3;
const double tiandituMaxZoom = 18;

/// 矢量底图（行政区划、道路、水系、绿地……但**没有文字**）。
///
/// 关于占位符，有三点容易踩：
///   * `l` **就是**标准 XYZ 的 `z`（0 基），不是天地图 WMTS 文档里那种 1 基层级。
///   * `{x}` / `{y}` 用平台惯用的小写；官方文档写的是 `X`/`Y`，服务端两种都认。
///   * `tk` 直接拼在 query 上，不要写成 `key` —— 参数名不对时服务端会回
///     一个"参数丢失"的错误码，很容易被误判成 tk 无效。
///
/// 天地图的底图和注记是**两个独立图层**，只挂这一个会得到一张没有任何地名的图，
/// 所以必须配合 [tiandituVectorLabelTileUrl] 一起用。
String get tiandituVectorTileUrl =>
    'https://t{s}.tianditu.gov.cn/DataServer?T=vec_w&x={x}&y={y}&l={z}'
    '&tk=${Constants.tiandituTk}';

/// 矢量注记层（地名、路名、POI 文字）。与 [tiandituVectorTileUrl] 叠着用。
String get tiandituVectorLabelTileUrl =>
    'https://t{s}.tianditu.gov.cn/DataServer?T=cva_w&x={x}&y={y}&l={z}'
    '&tk=${Constants.tiandituTk}';

/// 天地图地理编码：结构化地址 → 经纬度。
///
/// 接口**只收一个 `keyWord`**，没有独立的省/市参数（这点和高德不一样，
/// 高德有 `city`）。所以省市区要由调用方自己拼进 [keyWord]。
///
/// 返回结构（`location.lon` / `location.lat` **是字符串**，要自己转数字）：
///
/// ```json
/// {"msg":"ok","location":{"score":100,"level":"门址",
///  "lon":"116.290158","lat":"39.894696","keyWord":"..."},"status":"0"}
/// ```
///
/// `status`：`"0"` 正常、`"101"` 结果为空、`"404"` 出错。
///
/// 坐标参考系是 **CGCS2000**，与 WGS-84 的差异在 ±10 厘米内，
/// 工程上视为等同。但本 App 库里存的是 GCJ-02，**入库前要正算回去**
/// （见 `lib/utils/coord_transform.dart`）。
Uri tiandituGeocoderUri(String keyWord) => Uri.https(
  'api.tianditu.gov.cn',
  '/geocoder',
  <String, String>{
    // ds 的值是一段 JSON，交给 Uri 负责百分号编码（中文会被编成 UTF-8 转义）
    'ds': jsonEncode(<String, String>{'keyWord': keyWord}),
    'tk': Constants.tiandituTk,
  },
);
