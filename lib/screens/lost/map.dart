import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:find_dog/common/tianditu.dart';
import 'package:find_dog/utils/coord_transform.dart';

/// 地图视口高度。
///
/// 原先是高德的 600×600 静态图（塞在 40 的左右内边距里，实际显示约 280 方块），
/// 换成可拖动缩放的交互地图后给一个固定的、够看的高度。
const double _mapHeight = 260.0;

/// 标记点图标尺寸，也让 marker 的落点([Alignment.topCenter])计算得出来。
const double _markerSize = 44.0;

/// 失踪地点 + 地图。
///
/// 底图走天地图（WGS-84），而库里存的坐标是当年高德 geocode 产出的 GCJ-02，
/// 境内两者系统性偏移 **40~690 米**（东经 105° 附近最窄，向东、向西逐渐变大，
/// 实测数据见 `lib/utils/coord_transform.dart` 的文档）。所以这里会在渲染前把
/// 坐标反算成 WGS-84，**数据库那边不动**。
class LostMap extends StatelessWidget {
  final String locationAddress;
  final String locationName;
  final String locationLatitude;
  final String locationLongitude;
  final String regionArea;
  final String regionCity;
  final String regionProvince;
  final String date;
  final String time;

  const LostMap({
    super.key,
    required this.locationName,
    required this.locationAddress,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.regionProvince,
    required this.regionArea,
    required this.regionCity,
    required this.time,
    required this.date,
  });

  /// 把库里存的 GCJ-02 坐标反算成天地图认得的 WGS-84。
  ///
  /// 返回 `null` 表示这个点不可用，调用方应该显示提示而不是画图。
  GeoPoint? get _wgs84Point {
    final double? lat = double.tryParse(locationLatitude.trim());
    final double? lng = double.tryParse(locationLongitude.trim());
    if (lat == null || lng == null) return null;
    // 服务端在拿不到坐标时会落 "0.0"（见 report.dart 里地理编码的失败分支）。
    // 这个点落在几内亚湾，画出来只会让人以为地图坏了，所以直接判为不可用。
    if (lat == 0.0 || lng == 0.0) return null;
    if (lat.abs() > 90.0 || lng.abs() > 180.0) return null;
    return gcj02ToWgs84((latitude: lat, longitude: lng));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        title: const Text("失踪地点"),
      ),
      body: SafeArea(
        child: Column(children: <Widget>[
          const SizedBox(
            height: 60.0,
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: const Text(
              "详细失踪地点及地图",
              style: TextStyle(fontSize: 22.0),
            ),
          ),
          const SizedBox(
            height: 10.0,
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "失踪时间：$date $time",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(
            height: 1.0,
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "失踪地点：$regionProvince $regionCity $regionArea $locationAddress 附近",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(
            height: 20.0,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: SizedBox(
                height: _mapHeight,
                width: double.infinity,
                child: _buildMap(),
              ),
            ),
          )
        ]),
      ),
    );
  }

  Widget _buildMap() {
    if (!tiandituTkConfigured) {
      return const _MapNotice(
        message: '地图未配置：\n请在 lib/common/constants.dart 里填入天地图 tk',
      );
    }

    final GeoPoint? point = _wgs84Point;
    if (point == null) {
      return const _MapNotice(message: '该记录没有可用的坐标\n所以没法在地图上标出位置');
    }

    final LatLng center = LatLng(point.latitude, point.longitude);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.0,
        minZoom: tiandituMinZoom,
        maxZoom: tiandituMaxZoom,
        // 只展示一个定点，用不着一根手指转地图；
        // 关掉旋转能少一类误操作（双指一拧地图就歪了，还很难转回来）。
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: <Widget>[
        // 底图：行政区划、道路、水系……但没有文字
        TileLayer(
          urlTemplate: tiandituVectorTileUrl,
          subdomains: tiandituSubdomains,
          maxNativeZoom: tiandituMaxZoom.toInt(),
          userAgentPackageName: 'cn.nutspet.finddog',
        ),
        // 注记层：地名 / 路名 / POI 文字。天地的底图和注记是两个图层，
        // 少了这一层整张图会干净得看不出是哪儿。
        TileLayer(
          urlTemplate: tiandituVectorLabelTileUrl,
          subdomains: tiandituSubdomains,
          maxNativeZoom: tiandituMaxZoom.toInt(),
          userAgentPackageName: 'cn.nutspet.finddog',
        ),
        MarkerLayer(
          markers: <Marker>[
            Marker(
              point: center,
              width: _markerSize,
              height: _markerSize,
              // 让整个 marker 坐落在坐标点**上方**，钉尖正好落在点上。
              // 用默认的居中对齐的话，钉子会整体上移半个身位，指着偏北的地方。
              alignment: Alignment.topCenter,
              child: const Icon(
                Icons.location_on,
                size: _markerSize,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const Align(
          alignment: Alignment.bottomRight,
          child: _MapAttribution(),
        ),
      ],
    );
  }
}

/// 底图版权标注。
///
/// 天地图的使用条款要求标注来源。这里没用 flutter_map 自带的
/// `SimpleAttributionWidget`，因为它会固定渲染成 "flutter_map | © xxx"，
/// 把包名显示给终端用户并不合适。
class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
          child: Text(
            '© 天地图',
            style: TextStyle(fontSize: 10.0, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

/// 地图画不出来时的占位块。
///
/// 有它才能区分"图没加载出来"，而不是让用户对着一块空白猜。
class _MapNotice extends StatelessWidget {
  const _MapNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xffe9e9e9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.map_outlined, size: 36.0, color: Colors.grey.shade500),
              const SizedBox(height: 8.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.0, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
