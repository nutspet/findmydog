import 'dog_lost_selection.dart';
import 'pagination.dart';

/// 「分页 + 筛选」→ 接口 query 参数 的构造。
///
/// 刻意做成**纯 Dart**（不 import flutter）。
///
/// 为什么单独拆出来：
/// 1. 这里每一个参数名 / 取值都是踩过坑的地方（`reionProvince` 少一个 g、
///    `gender` 必须发数字 0/1 而不是布尔…），最值得被断言覆盖；
/// 2. 但 `Request` 这条链路上缠着 Flutter 插件
///    （request.dart → login.dart → flutter_udid → package:flutter → dart:ui），
///    纯 Dart VM 进不去，所以必须把这段逻辑从 service 里挪出来才能测。
///
/// 服务端的实测结论都写在对应分支上。
class DogLostQuery {
  const DogLostQuery._();

  /// `/lost/latest2`、`/lost/top_reward2` 共用的 query 构造。
  ///
  /// 下标一律按 0 基原样下发；字段为 null 表示"不限"，不拼进 query。
  static Map<String, dynamic> build(
    Pagination pagination, [
    DogLostSelection? selection,
  ]) {
    final Map<String, dynamic> query = <String, dynamic>{
      "page": pagination.page,
      "pageSize": pagination.pageSize,
    };
    if (selection == null) return query;

    if (selection.color != null) {
      query["color"] = selection.color;
    }

    if (selection.gender != null) {
      // ⚠️ 必须发数字 1/0，不能发 true/false。
      //
      // 线上实测：
      //   gender=0     → total 10017，返回的记录 gender 全是 false（母）✅
      //   gender=1     → total 13800，返回的记录 gender 全是 true （公）✅
      //   gender=false → total 13800，返回的记录 gender 竟然全是 true （公）❌
      //                  —— 与 gender=1 的结果一模一样
      // 服务端对布尔字面量的处理是不可靠的，所以这里坚持发 0/1。
      query["gender"] = selection.gender! ? 1 : 0;
    }

    if (selection.size != null) {
      // 0=小型 1=中型 2=大型（线上实测 size 是 0 基；越界如 size=3 返回 0 条）
      query["size"] = selection.size;
    }

    if (selection.breed != null) {
      // ⚠️ breed 是**该体型内部的 0 基相对索引**，不是全局索引，且必须配合 size 使用。
      // 实测：size=1&breed=0 有数据；
      //      size=0&breed=17、size=2&breed=33、单独发 breed=17 全部 0 条 ⇒ 越界即空。
      // （`DogLostFilter.applySizeBreed` 已经保证不会构造出"只有 breed 没有 size"的组合）
      query["breed"] = selection.breed;
    }

    // ⚠️ 这里曾经写成 "reionProvince"（少了一个 g）。
    // 线上实测：regionProvince=上海市 → total 1328（全是上海）；
    //          reionProvince=上海市  → total 23817（等同完全不筛选）。
    // 也就是说旧版本里"省份"这个筛选条件从来没有生效过。
    if (selection.regionProvince != null) {
      query["regionProvince"] = selection.regionProvince;
    }
    if (selection.regionCity != null) {
      query["regionCity"] = selection.regionCity;
    }
    if (selection.regionArea != null) {
      query["regionArea"] = selection.regionArea;
    }

    return query;
  }

  /// `/lost/nearby2` 的 query 构造（该接口不分页）。
  static Map<String, dynamic> buildNearBy({
    double? longitude,
    double? latitude,
  }) =>
      <String, dynamic>{
        // `?x` 是 Dart 3.9 起的 null-aware element：值为 null 时该条目不参与构造
        "longitude": ?longitude,
        "latitude": ?latitude,
      };
}
