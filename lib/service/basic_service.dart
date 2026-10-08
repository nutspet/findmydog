import 'package:find_dog/common/request.dart';

/// service 层的公共基类。
///
/// 只做一件事：统一持有 [Request]（它内部本身就是单例，
/// 这里拿到的是同一个实例，不产生额外连接池）。
abstract class BasicService {
  /// 单页请求条数，与旧实现默认值保持一致
  static const int apiLimitSize = 25;

  final Request api = Request();
}
