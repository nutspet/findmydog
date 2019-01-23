import 'package:find_dog/common/constants.dart';

const imgHost = Constants.imgHost;

// 图片的类 返回的格式是腾讯云的
class Pic {
  String key;
  String url; // 没用 接口的冗余
  String link; // 组合后的可用地址
  Pic.fromJson(Map<String, dynamic> json)
      : key = json["key"],
        url = json["url"],
        link = "$imgHost/${json["key"]}";
}
