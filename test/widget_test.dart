// 寻狗 App 的基础测试。
//
// 说明：原文件是 `flutter create` 生成的 Counter 冒烟测试，
// 但本项目从来没有过 Counter 页面（模板残留），因此它必然是失败的。
// 这里替换为两组「确定性、不依赖网络与原生插件」的测试：
//   1) 模型层：DogLost.fromJson 的字段映射 + 空安全兜底
//   2) Widget 层：两个纯展示页面（关于我们 / 特别鸣谢）能正常渲染
// 涉及插件（微信 / 定位 / 相机 / WebView）或发起网络请求的页面
// 不在 widget test 中冒烟，避免污染测试为「不稳定」。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_dog/models/dog_lost.dart';
import 'package:find_dog/screens/planet/about.dart';
import 'package:find_dog/screens/planet/thanks.dart';
import 'package:find_dog/utils/validate.dart';

/// 一份字段完整的后端返回结构。
/// 注意 color/size/breed/time 传的是「下标」，需要被测代码翻译成中文。
Map<String, dynamic> _fullJson() => <String, dynamic>{
      'id': 1,
      'uuid': 'uuid-0001',
      'age': 2,
      'date': '2024-05-01',
      'contactsGender': true, // true -> 先生
      'contactsMobile': '13800000000',
      'contactsName': '张三',
      'found': false,
      'gender': false, // false -> 母
      'locationAddress': '某某路 1 号',
      'locationName': '某小区',
      'locationLatitude': '31.2000',
      'locationLongitude': '121.4000',
      'negotiate': true,
      'regionArea': '浦东新区',
      'regionCity': '上海市',
      'regionProvince': '上海市',
      'remark': '怕生，请勿追赶',
      'reward': 1000,
      'time': 1, // 1 -> 下午
      'weight': 5,
      'wxaQrCode': 'qr-code',
      'color': 5, // 5 -> 黑色
      'size': 0, // 0 -> 小型
      'breed': 0, // DogSizeBreed[0][0] -> 中华田园犬
      'pic': <dynamic>[],
    };

void main() {
  group('DogLost 空安全改造', () {
    test('无参构造后所有字段都有默认值（不会出现 null 断言）', () {
      final DogLost dog = DogLost();

      expect(dog.id, 0);
      expect(dog.uuid, '');
      expect(dog.age, 0);
      expect(dog.date, '');
      expect(dog.found, false);
      expect(dog.negotiate, false);
      expect(dog.reward, 0);
      expect(dog.weight, 0);
      expect(dog.breed, '');
      expect(dog.size, '');
      expect(dog.color, '');
      expect(dog.pic, isEmpty);
    });
  });

  group('DogLost.fromJson', () {
    test('字段映射与旧版一致（性别 / 时间段 / 颜色 / 品种下标翻译）', () {
      final DogLost dog = DogLost.fromJson(_fullJson());

      expect(dog.id, 1);
      expect(dog.uuid, 'uuid-0001');
      expect(dog.age, 2);
      expect(dog.date, '2024-05-01');
      expect(dog.contactsMobile, '13800000000');
      expect(dog.contactsName, '张三');
      expect(dog.locationName, '某小区');
      expect(dog.regionCity, '上海市');
      expect(dog.remark, '怕生，请勿追赶');
      expect(dog.reward, 1000);
      expect(dog.wxaQrCode, 'qr-code');

      // bool -> 文案
      expect(dog.contactsGender, '先生');
      expect(dog.gender, '母');
      // 下标 -> 文案
      expect(dog.time, '下午');
      expect(dog.color, '黑色');
      expect(dog.size, '小型');
      expect(dog.breed, '中华田园犬');
    });

    test('contactsGender 缺失时兜底为空串而不是崩溃（本次空安全改造点）', () {
      final Map<String, dynamic> json = _fullJson()..remove('contactsGender');

      final DogLost dog = DogLost.fromJson(json);

      expect(dog.contactsGender, '');
    });

    test('gender 为未映射的取值时兜底为空串', () {
      final Map<String, dynamic> json = _fullJson()..['gender'] = null;

      final DogLost dog = DogLost.fromJson(json);

      expect(dog.gender, '');
    });
  });

  group('Validate.phone', () {
    test('合法手机号返回 null', () {
      expect(Validate.phone('13812345678'), isNull);
      expect(Validate.phone('18612345678'), isNull);
    });

    test('非法手机号返回错误提示', () {
      const String error = '请输入正确手机号！';

      expect(Validate.phone(''), error);
      expect(Validate.phone('12345678901'), error);
      expect(Validate.phone('1381234567'), error); // 只有 10 位
      expect(Validate.phone('abcdefghijk'), error);
    });
  });

  group('汪星球 - 特别鸣谢', () {
    testWidgets('可以正常渲染标题与致谢名单', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Thanks()));

      expect(find.text('特别鸣谢'), findsOneWidget);
      expect(find.text('感谢'), findsOneWidget);
      expect(find.text('maggie_ke，mteng，junfei'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('汪星球 - 关于我们', () {
    testWidgets('可以正常渲染全部 13 位成员（13 行 x 2 列 = 26 个单元格）',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: About()));

      expect(find.text('技术团队'), findsOneWidget);
      expect(find.text('服务端主程：'), findsOneWidget);
      expect(find.text('Flutter主程：'), findsOneWidget);
      expect(find.byType(TableCell), findsNWidgets(26));
      expect(tester.takeException(), isNull);
    });
  });
}
