import 'package:find_dog/models/dog_lost.dart';
import 'package:find_dog/models/dog_lost_query.dart';
import 'package:find_dog/models/dog_lost_selection.dart';
import 'package:find_dog/models/pagination.dart';
import 'package:find_dog/repository/api_repository.dart';
import 'package:find_dog/service/basic_service.dart';

/// 失踪狗（"人找狗"）相关接口。
///
/// 单例：列表页三个 tab 各自 new 一次拿到的都是同一个对象。
class DogService extends BasicService {
  DogService._internal();

  static final DogService _singleton = DogService._internal();

  factory DogService() => _singleton;

  /// 最新发布。
  ///
  /// 线上实测返回：`data = {list, pagination:{page,pageSize,total,nextPage}}`
  Future<ApiRepository<DogLost>> getLostLatest(
    Pagination pagination, {
    DogLostSelection? selection,
  }) {
    return _getLostList("/lost/latest2", pagination, selection);
  }

  /// 悬赏最高。返回结构与 latest2 完全一致。
  Future<ApiRepository<DogLost>> getLostTopReward(
    Pagination pagination, {
    DogLostSelection? selection,
  }) {
    return _getLostList("/lost/top_reward2", pagination, selection);
  }

  /// 附近走失。
  ///
  /// ⚠️ 该接口 **不返回 pagination**（线上实测 `data` 里只有 `list`），
  /// 所以这里手工构造一个 `nextPage: false` 的分页，表示"一次拿完、没有下一页"。
  /// 否则交给 [Pagination.fromJson] 会拿到空分页，bloc 会误以为还要继续请求下一页。
  Future<ApiRepository<DogLost>> getLostNearBy({
    double? longitude,
    double? latitude,
  }) async {
    final Map<String, dynamic> res = await api.fetch(
      "/lost/nearby2",
      data: DogLostQuery.buildNearBy(longitude: longitude, latitude: latitude),
    );
    final List<DogLost> list = parseList(res);
    return ApiRepository(
      list: list,
      pagination: Pagination(
        page: 1,
        pageSize: list.length,
        total: list.length,
        nextPage: false,
      ),
    );
  }

  /// latest2 / top_reward2 共用的取数逻辑
  Future<ApiRepository<DogLost>> _getLostList(
    String uri,
    Pagination pagination,
    DogLostSelection? selection,
  ) async {
    // 参数名 / 取值（0 基下标、gender 发数字、regionProvince 拼写…）
    // 全部集中在纯 Dart 的 DogLostQuery 里，那边可以脱离 Flutter 直接断言
    final Map<String, dynamic> query = DogLostQuery.build(pagination, selection);

    final Map<String, dynamic> res = await api.fetch(uri, data: query);
    return ApiRepository(
      list: parseList(res),
      pagination: Pagination.fromJson(res['pagination']),
    );
  }

  /// 把接口返回的 `list` 段翻译成模型。
  /// 缺字段 / 类型不符时退化为空列表，避免一条脏数据把整个列表打崩。
  static List<DogLost> parseList(Map<String, dynamic> res) {
    final dynamic raw = res["list"];
    if (raw is! List) return const <DogLost>[];
    return raw
        .whereType<Map>()
        .map((e) => DogLost.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
