// 用户 Profile
class Profile {
  static const Map<bool, String> UserGender = {
    false: '女士',
    true: '先生',
  };
  String avatar;
  String birthDay;
  String gender;
  bool genderRaw;
  bool mobileVerify = false;
  String name = "访客";
  String uuid;
  // 空的构造
  Profile();
  // 用json的构造
  Profile.fromJson(Map<String, dynamic> json)
      : avatar = json['avatar'],
        birthDay = json['birthDay'],
        gender = UserGender[json['gender']],
        genderRaw = json['gender'],
        mobileVerify = json['mobileVerify'],
        name = json['name'],
        uuid = json['uuid'];
}
