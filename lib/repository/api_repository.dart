import 'package:find_dog/models/pagination.dart';

/// 分页列表的统一返回容器。
///
/// service 层把各接口返回收敛成这个形状，bloc 只需关心
/// `list`（数据）与 `pagination`（下一页信息）两件事，
/// 不必了解每个接口的差异。
///
/// 注：原设计里还有一个 `selection` 字段，但没有任何调用点读取它
/// （bloc 的筛选状态自己维护），移植时删掉以免留下死字段。
class ApiRepository<T> {
  const ApiRepository({required this.list, required this.pagination});

  final List<T> list;
  final Pagination pagination;
}
