/// 中国大陆坐标系互转：WGS-84 ⇄ GCJ-02。
///
/// 纯 Dart 实现，**不依赖 Flutter**，因此可以直接跑语言级断言。
///
/// ## 为什么需要它
///
/// 国内同时流通着三套经纬度：
///
/// | 坐标系 | 谁在用 | 与 WGS-84 的关系 |
/// | --- | --- | --- |
/// | WGS-84 | GPS 原始输出、天地图（CGCS2000，实际等同）、OpenStreetMap | 基准 |
/// | GCJ-02 | 高德 / 腾讯 | 中国境内被**系统性偏移**，量级见下 |
/// | BD-09 | 百度 | 在 GCJ-02 上又加了一层偏移 |
///
/// 偏移量到底多大：网上流传的"约 500 米"只是个笼统说法，实际随位置变化很大。
/// 对中国范围（18°~53.5°N，74°~134.5°E）做网格实测，结果是 **40 ~ 690 米**——
/// 西部偏小、东部偏大，并且在**东经 105° 附近明显收窄**
/// （偏移公式正是以东经 105° 为参考基准，实测最小 41 米出现在青海）。
///
/// 几个城市的具体数值（同一次实测，`.dart_tool/coord_check.dart`）：
///
/// | 城市 | 偏移 |
/// | --- | --- |
/// | 乌鲁木齐 | 265 米 |
/// | 成都 | 361 米 |
/// | 上海 | 481 米 |
/// | 哈尔滨 | 517 米 |
/// | 北京 | 555 米 |
/// | 广州 | 625 米 |
///
/// 方向上也别想当然：经度位移**恒为正**（一律向东），
/// 但纬度位移**可正可负**（上海、广州是往南偏的），
/// 所以"整体往东北挪"是一种不准确的说法。
///
/// 本 App 的库里的坐标是当年用**高德 geocode** 产出的，也就是 **GCJ-02**；
/// 而现在底图换成了**天地图**，它按 **WGS-84** 出图。
/// 如果直接把 GCJ-02 的点丢给天地图，标记会整体偏出去几百米。
///
/// ## 使用约定
///
/// **数据库里存的仍然是 GCJ-02，一个字节都不动。**
/// 只有两处会调用这里的函数：
///
/// * `lib/screens/lost/map.dart` —— 渲染前 `gcj02ToWgs84`，把库里的点喂给天地图；
/// * `lib/screens/lost/report.dart` —— 天地图 geocoder 返回 WGS-84，
///   入库前 `wgs84ToGcj02` 正算回去，保证同一列里不混两种坐标系。
library;

import 'dart:math' as math;

/// 一个经纬度点。**坐标系由调用方决定**（见库文档），类型本身不带坐标系信息。
typedef GeoPoint = ({double latitude, double longitude});

/// 克拉索夫斯基椭球长半轴，单位米。
///
/// 这是 GCJ-02 偏移公式的约定常数，**不是** WGS-84 的椭球参数——
/// 公式本身就长这样，换数值会算错。
const double _ellipsoidA = 6378245.0;

/// 该椭球的偏心率平方。
const double _ellipsoidEE = 0.00669342162296594323;

/// 粗略判断是否在中国境外。
///
/// 偏移量公式只在中国境内成立，境外强行加偏会算出错误结果，
/// 所以直接原样返回。这里的经纬度是一个宽松外框，只用来做"要不要加偏"的开关。
bool _outOfChina(double latitude, double longitude) =>
    longitude < 72.004 ||
    longitude > 137.8347 ||
    latitude < 0.8293 ||
    latitude > 55.8271;

/// 纬度方向的偏移量（单位：度）。
double _deltaLatitude(double x, double y) {
  double ret = -100.0 +
      2.0 * x +
      3.0 * y +
      0.2 * y * y +
      0.1 * x * y +
      0.2 * math.sqrt(x.abs());
  ret += (20.0 * math.sin(6.0 * x * math.pi) +
          20.0 * math.sin(2.0 * x * math.pi)) *
      2.0 /
      3.0;
  ret += (20.0 * math.sin(y * math.pi) + 40.0 * math.sin(y / 3.0 * math.pi)) *
      2.0 /
      3.0;
  ret += (160.0 * math.sin(y / 12.0 * math.pi) +
          320.0 * math.sin(y * math.pi / 30.0)) *
      2.0 /
      3.0;
  return ret;
}

/// 经度方向的偏移量（单位：度）。
double _deltaLongitude(double x, double y) {
  double ret = 300.0 +
      x +
      2.0 * y +
      0.1 * x * x +
      0.1 * x * y +
      0.1 * math.sqrt(x.abs());
  ret += (20.0 * math.sin(6.0 * x * math.pi) +
          20.0 * math.sin(2.0 * x * math.pi)) *
      2.0 /
      3.0;
  ret += (20.0 * math.sin(x * math.pi) + 40.0 * math.sin(x / 3.0 * math.pi)) *
      2.0 /
      3.0;
  ret += (150.0 * math.sin(x / 12.0 * math.pi) +
          300.0 * math.sin(x / 30.0 * math.pi)) *
      2.0 /
      3.0;
  return ret;
}

/// 不做出入境判断的加偏，内部使用。
///
/// 反算（[gcj02ToWgs84]）迭代过程中坐标会在中国境内小幅游走，
/// 如果每一轮都去做外框判断，边界附近的点可能被判成"境外"从而停止加偏、
/// 导致迭代不收敛。所以把判断提到外面，循环里只用这个无判断版本。
GeoPoint _offset(double lat, double lng) {
  final double dLatRaw = _deltaLatitude(lng - 105.0, lat - 35.0);
  final double dLngRaw = _deltaLongitude(lng - 105.0, lat - 35.0);

  final double radLat = lat / 180.0 * math.pi;
  final double magic = 1.0 - _ellipsoidEE * math.sin(radLat) * math.sin(radLat);
  final double sqrtMagic = math.sqrt(magic);

  final double dLat =
      (dLatRaw * 180.0) / ((_ellipsoidA * (1.0 - _ellipsoidEE)) / (magic * sqrtMagic) * math.pi);
  final double dLng =
      (dLngRaw * 180.0) / (_ellipsoidA / sqrtMagic * math.cos(radLat) * math.pi);

  return (latitude: lat + dLat, longitude: lng + dLng);
}

/// WGS-84 → GCJ-02（正算）。
///
/// 境外坐标原样返回。
///
/// 用途：天地图 geocoder 返回的点要存进本来就全是 GCJ-02 的库时，
/// 先走一遍这个函数。
GeoPoint wgs84ToGcj02(GeoPoint point) => _outOfChina(point.latitude, point.longitude)
    ? point
    : _offset(point.latitude, point.longitude);

/// GCJ-02 → WGS-84（反算）。
///
/// 境外坐标原样返回。
///
/// GCJ-02 的加偏公式没有解析形式的反函数，这里用**定点迭代**逼近：
/// 以待求的 GCJ 点自身作为初值，每轮算出"加偏后的点"与目标的差，
/// 再把差补回去。
///
/// 收敛很快：迭代的压缩比就是偏移量对流坐标的灵敏度（量级 1e-4），
/// 所以初值那 ~0.005 度的误差经过四五轮就掉到双精度极限了。
/// 实测 `.dart_tool/coord_check.dart` 里对全中国 55769 个点做往返扫描，
/// 最大残差在 **1e-15 度量级（远小于 1 微米）**。
///
/// 用途：把库里的 GCJ-02 坐标喂给按 WGS-84 出图的天地图之前，先反算一次。
GeoPoint gcj02ToWgs84(GeoPoint point) {
  if (_outOfChina(point.latitude, point.longitude)) return point;

  double lat = point.latitude;
  double lng = point.longitude;

  // 上限给 30 轮纯属保险，实际四五轮就收敛到 double 的精度极限了。
  const int maxRounds = 30;
  // 这里不能取 1e-9：那会让残差正好卡在 0.1 毫米量级。
  // 1e-12 度 ≈ 0.1 微米，足够把结果推到浮点噪声里。
  const double epsilon = 1e-12;

  for (int i = 0; i < maxRounds; i++) {
    final GeoPoint guess = _offset(lat, lng);
    final double dLat = guess.latitude - point.latitude;
    final double dLng = guess.longitude - point.longitude;
    if (dLat.abs() < epsilon && dLng.abs() < epsilon) break;
    lat -= dLat;
    lng -= dLng;
  }

  return (latitude: lat, longitude: lng);
}
