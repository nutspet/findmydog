import 'package:equatable/equatable.dart';

/// 分页模型。
///
/// 线上实测：`/lost/latest2` 与 `/lost/top_reward2` 的 `data` 里都带
/// `pagination = {page, pageSize, total, nextPage}`，这里做一对一映射。
///
/// 注意：`/lost/nearby2` **不返回 pagination**（`data` 里只有 `list`），
/// 那种场景由 service 层手工构造 `nextPage: false` 的实例。
class Pagination extends Equatable {
  const Pagination({
    this.page = 1,
    this.pageSize = 25,
    this.total,
    this.nextPage = true,
  });

  /// 从接口返回的 `data.pagination` 构造。
  ///
  /// 全程宽松解析：字段缺失或类型不符时退回安全默认值。
  /// 尤其是 [nextPage] 缺失时默认 **false**——宁可少请求一次，
  /// 也不要因为拿不到标志位而陷入"无限请求下一页"。
  factory Pagination.fromJson(Object? json) {
    if (json is! Map) {
      // 没有分页信息（例如 nearby2）→ 视为"只有一页"
      return const Pagination(nextPage: false);
    }
    return Pagination(
      page: _asInt(json['page']) ?? 1,
      pageSize: _asInt(json['pageSize']) ?? 25,
      total: _asInt(json['total']),
      nextPage: _asBool(json['nextPage']) ?? false,
    );
  }

  /// 当前页
  final int page;

  /// 单页条数
  final int pageSize;

  /// 总条数
  final int? total;

  /// 是否还有下一页
  final bool nextPage;

  /// 下一页的分页参数（仍沿用当前的 pageSize）。
  ///
  /// 已经是最后一页时抛 [StateError]；调用方（bloc）应当先判断 [nextPage]。
  Pagination goNextPage() {
    if (!nextPage) {
      throw StateError('已经是最后一页了');
    }
    return Pagination(
      page: page + 1,
      pageSize: pageSize,
      total: total,
      nextPage: nextPage,
    );
  }

  Pagination copyWith({int? page, int? pageSize, int? total, bool? nextPage}) {
    return Pagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      nextPage: nextPage ?? this.nextPage,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final String v = value.toLowerCase();
      if (v == 'true') return true;
      if (v == 'false') return false;
    }
    return null;
  }

  // total 不参与相等判断：它只是展示用的统计值，变化时不需要重建列表。
  @override
  List<Object?> get props => [page, pageSize, nextPage];

  @override
  String toString() =>
      'Pagination { page: $page, pageSize: $pageSize, total: $total, nextPage: $nextPage }';
}
