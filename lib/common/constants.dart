class Constants {
  // 服务端相关
  static const String schema = "https";
  static const String apiHost = "$schema://api.91xungou.com";
  static const String imgHost = "$schema://img.91xungou.com";

  // ===== 天地图（国家地理信息公共服务平台）=====
  //
  // 底图瓦片和地理编码都用这一个 tk。
  //
  // ⚠️ 必须自己去申请，留空的话地图区域会显示"未配置"提示（不会崩，但也没图）。
  //
  // 申请地址：https://console.tianditu.gov.cn  （文档 https://lbs.tianditu.gov.cn）
  //
  // 申请时的两个坑：
  //   1. 「应用类型」选 **服务端**（或"Android 平台"）。
  //      **不要选「浏览器端」** —— 它按 HTTP Referer 做白名单校验，
  //      而原生 App 根本不发 Referer，会直接被 403。
  //   2. 「服务类型」里要勾上"地图 API"（矢量底图 / 地名注记）
  //      以及 WEB 服务 API 的"地理编码"。
  //
  // 换 tk 只改这一行，瓦片 URL 与 geocoder 都会跟着走（见 lib/common/tianditu.dart）。
  static const String tiandituTk = "";
}
