// 校验类 全部静态方法
class Validate {
  static String phone(String value) {
    final RegExp phoneExp = RegExp(
        r'^(1(3[4-9]|5[012789]|8[78])\d{8}|1(?:3[0-2]|5[56]|8[56])\d{8}|18[0-9]\d{8}|1[35]3\d{8}|14[57]\d{8}|17[0123678]\d{8})$');
    if (!phoneExp.hasMatch(value)) return '请输入正确手机号！';
    return null;
  }
}