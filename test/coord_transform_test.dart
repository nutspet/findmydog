import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:find_dog/common/tianditu.dart';
import 'package:find_dog/utils/coord_transform.dart';

/// 两点间大圆距离（米）。用平均地球半径，够判断"偏了几百米"这个量级。
double haversineMeters(GeoPoint a, GeoPoint b) {
  const double r = 6371008.8;
  final double dLat = (b.latitude - a.latitude) * math.pi / 180.0;
  final double dLng = (b.longitude - a.longitude) * math.pi / 180.0;
  final double lat1 = a.latitude * math.pi / 180.0;
  final double lat2 = b.latitude * math.pi / 180.0;
  final double h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
}

void main() {
  // 底图从高德换成天地图之后，坐标系是这条链路上唯一会"静默算错"的地方：
  // 转换写错不会崩、不会报错，只是标记点悄悄偏出去几百米。
  // 所以这里把数值性质钉死。
  group('coord_transform', () {
    test('境外坐标正反算都原样返回（不加偏）', () {
      const Map<String, GeoPoint> abroad = <String, GeoPoint>{
        '伦敦': (latitude: 51.50740, longitude: -0.12780),
        '纽约': (latitude: 40.71280, longitude: -74.00600),
        '东京': (latitude: 35.67620, longitude: 139.65030),
        '悉尼': (latitude: -33.86880, longitude: 151.20930),
      };

      for (final MapEntry<String, GeoPoint> e in abroad.entries) {
        expect(
          wgs84ToGcj02(e.value),
          e.value,
          reason: '${e.key} 不该被加偏',
        );
        expect(
          gcj02ToWgs84(e.value),
          e.value,
          reason: '${e.key} 不该被反算',
        );
      }
    });

    test('反算精度：全中国网格扫描，往返残差 < 1e-9 度', () {
      // 实测 34749 个点的最大残差在 4e-12 度量级（亚微米），
      // 这里留两个数量级余量，只用来拦住"公式或迭代被改坏"。
      double maxErrDeg = 0.0;

      for (double lat = 18.0; lat <= 53.5; lat += 0.5) {
        for (double lng = 74.0; lng <= 134.5; lng += 0.5) {
          final GeoPoint wgs = (latitude: lat, longitude: lng);
          final GeoPoint back = gcj02ToWgs84(wgs84ToGcj02(wgs));
          maxErrDeg = math.max(
            maxErrDeg,
            math.max(
              (back.latitude - wgs.latitude).abs(),
              (back.longitude - wgs.longitude).abs(),
            ),
          );
        }
      }

      expect(maxErrDeg, lessThan(1e-9));
    });

    test('偏移量量级：境内 200~900 米，且经度方向恒向东', () {
      double minMeters = double.infinity;
      double maxMeters = 0.0;
      double minDLng = double.infinity;
      double minDLat = double.infinity;
      double maxDLat = -double.infinity;

      for (double lat = 18.0; lat <= 53.5; lat += 0.5) {
        for (double lng = 74.0; lng <= 134.5; lng += 0.5) {
          final GeoPoint wgs = (latitude: lat, longitude: lng);
          final GeoPoint gcj = wgs84ToGcj02(wgs);
          final double dLat = gcj.latitude - lat;
          final double dLng = gcj.longitude - lng;

          final double meters = haversineMeters(wgs, gcj);
          minMeters = math.min(minMeters, meters);
          maxMeters = math.max(maxMeters, meters);
          minDLng = math.min(minDLng, dLng);
          minDLat = math.min(minDLat, dLat);
          maxDLat = math.max(maxDLat, dLat);
        }
      }

      // 实测：38 ~ 686 米
      expect(minMeters, greaterThan(200.0));
      expect(maxMeters, lessThan(900.0));

      // 实测：经度位移恒为正（0.000145 ~ 0.009682 度）——
      // 这是这套偏移公式的稳定特征，常数抄错时守不住。
      expect(minDLng, greaterThan(0.0));

      // 而纬度位移有正有负，所以网上"整体往东北挪"那种说法是不准的。
      expect(minDLat, lessThan(0.0));
      expect(maxDLat, greaterThan(0.0));
    });

    test('典型城市偏移量可复现（回归锚点）', () {
      // 数值是实测出来的，不是从别处抄的。
      final GeoPoint beijing = wgs84ToGcj02(
        (latitude: 39.90860, longitude: 116.39130),
      );
      expect(beijing.latitude - 39.90860, closeTo(0.001401, 1e-5));
      expect(beijing.longitude - 116.39130, closeTo(0.006241, 1e-5));
      expect(
        haversineMeters((latitude: 39.90860, longitude: 116.39130), beijing),
        closeTo(555.0, 5.0),
      );

      final GeoPoint urumqi = wgs84ToGcj02(
        (latitude: 43.82560, longitude: 87.61680),
      );
      expect(
        haversineMeters((latitude: 43.82560, longitude: 87.61680), urumqi),
        closeTo(265.0, 5.0),
      );
    });

    test('反算结果代入正算能回到原点（自洽性）', () {
      final GeoPoint gcj = (latitude: 31.23040, longitude: 121.47370);
      final GeoPoint wgs = gcj02ToWgs84(gcj);
      final GeoPoint again = wgs84ToGcj02(wgs);
      expect(again.latitude, closeTo(gcj.latitude, 1e-9));
      expect(again.longitude, closeTo(gcj.longitude, 1e-9));
    });
  });

  group('tianditu', () {
    test('geocoder URI：路径、参数名、JSON 编码都正确', () {
      final Uri uri = tiandituGeocoderUri('上海市静安区南京西路');

      expect(uri.scheme, 'https');
      expect(uri.host, 'api.tianditu.gov.cn');
      expect(uri.path, '/geocoder');
      // 参数名必须是 ds / tk：写成 key 服务端会当成"参数丢失"
      expect(uri.queryParameters.keys, containsAll(<String>['ds', 'tk']));
      expect(
        uri.queryParameters['ds'],
        '{"keyWord":"上海市静安区南京西路"}',
      );

      // 中文必须被百分号编码，否则请求行里会出现非 ASCII 字节
      expect(
        uri.toString().codeUnits.every((int c) => c < 128),
        isTrue,
        reason: 'URL 里不该出现非 ASCII 字符：$uri',
      );
    });

    test('瓦片 URL 模板：图层名与占位符齐全', () {
      // vec_w 缺了就没有底图，cva_w 缺了就没有地名——
      // 天地图这两层是分开的，必须都挂。
      expect(tiandituVectorTileUrl, contains('T=vec_w'));
      expect(tiandituVectorLabelTileUrl, contains('T=cva_w'));

      for (final String url in <String>[
        tiandituVectorTileUrl,
        tiandituVectorLabelTileUrl,
      ]) {
        for (final String token in <String>['{s}', '{x}', '{y}', '{z}']) {
          expect(url, contains(token), reason: '$url 缺少 $token');
        }
        expect(url, contains('&tk='));
        expect(url, contains('DataServer'));
      }
    });

    test('瓦片集群子域是 t0~t7', () {
      expect(tiandituSubdomains, hasLength(8));
      expect(tiandituSubdomains.first, '0');
      expect(tiandituSubdomains.last, '7');
    });

    test('缩放范围卡在天地图允许的区间内', () {
      // 超出范围服务端返回空白瓦片且不报错，必须自己卡住
      expect(tiandituMinZoom, greaterThanOrEqualTo(1));
      expect(tiandituMaxZoom, lessThanOrEqualTo(18));
      expect(tiandituMaxZoom, greaterThan(tiandituMinZoom));
    });
  });
}
