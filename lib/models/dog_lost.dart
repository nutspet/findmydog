import 'dog.dart';

// 失踪狗的view model
class DogLost extends Dog {
  static const Map<bool, String> UserGender = {
    false: '女士',
    true: '先生',
  };

// 失踪相关
  static const List<String> LostTime = [
    '上午',
    '下午',
    '晚上',
  ];

// 狗狗相关
  static const Map<bool, String> DogGender = {
    false: '母',
    true: '公',
  };
  int id;
  String uuid;
  int age;
  String date;
  String contactsGender;
  String contactsMobile;
  String contactsName;
  bool found = false;
  String gender;
  String locationAddress;
  String locationName;
  String locationLatitude;
  String locationLongitude;
  bool negotiate = false;
  String regionArea;
  String regionCity;
  String regionProvince;
  String remark = '';
  int reward = 0;
  String time;
  int weight;
  String wxaQrCode;

  DogLost();

  // 用命名构造函数
  DogLost.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        uuid = json["uuid"],
        age = json["age"],
        date = json["date"],
        contactsGender = UserGender[json["contactsGender"]],
        contactsMobile = json["contactsMobile"],
        contactsName = json["contactsName"],
        found = json["found"],
        gender = DogGender[json["gender"]],
        locationAddress = json["locationAddress"],
        locationName = json["locationName"],
        locationLatitude = json["locationLatitude"],
        locationLongitude = json["locationLongitude"],
        negotiate = json["negotiate"],
        regionArea = json["regionArea"],
        regionCity = json["regionCity"],
        regionProvince = json["regionProvince"],
        remark = json["remark"],
        reward = json["reward"],
        time = LostTime[json["time"]],
        weight = json["weight"],
        wxaQrCode = json["wxaQrCode"],
        super.fromJson(json);
}
