import 'pic.dart';

// 抽象类 基础的狗讯息 为了填充数据方便 不要在view那层工作
abstract class Dog {
  static const List<String> DogSize = ['小型', '中型', '大型'];
  static const List<List<String>> DogBreed = [
    [
      '中华田园犬',
      '贵宾犬',
      '博美犬',
      '雪纳瑞',
      '柯基犬',
      '茶杯犬',
      '比熊犬',
      '法国斗牛犬',
      '比格犬',
      '巴哥犬',
      '吉娃娃',
      '迷你杜宾',
      '腊肠犬',
      '约克夏',
      '京巴犬',
      '马尔济斯',
      '其他',
    ],
    [
      '哈士奇',
      '萨摩耶',
      '拉布拉多',
      '金毛犬',
      '边境牧羊犬',
      '柴犬',
      '松狮犬',
      '马犬',
      '英国斗牛犬',
      '可卡犬',
      '牛头梗',
      '沙皮犬',
      '巴吉度',
      '德国牧羊犬',
      '美国恶霸犬',
      '其他',
    ],
    [
      '阿拉斯加犬',
      '秋田犬',
      '巨型贵宾犬',
      '罗威纳',
      '藏獒',
      '大白熊',
      '古牧',
      '杜宾',
      '高加索',
      '卡斯特罗',
      '杜高犬',
      '其他',
    ]
  ];
  static const List<Map<String, List>> DogSizeBreed = [
    {
      '小型': [
        '中华田园犬',
        '贵宾犬',
        '博美犬',
        '雪纳瑞',
        '柯基犬',
        '茶杯犬',
        '比熊犬',
        '法国斗牛犬',
        '比格犬',
        '巴哥犬',
        '吉娃娃',
        '迷你杜宾',
        '腊肠犬',
        '约克夏',
        '京巴犬',
        '马尔济斯',
        '其他',
      ],
    },
    {
      '中型': [
        '哈士奇',
        '萨摩耶',
        '拉布拉多',
        '金毛犬',
        '边境牧羊犬',
        '柴犬',
        '松狮犬',
        '马犬',
        '英国斗牛犬',
        '可卡犬',
        '牛头梗',
        '沙皮犬',
        '巴吉度',
        '德国牧羊犬',
        '美国恶霸犬',
        '其他',
      ]
    },
    {
      '大型': [
        '阿拉斯加犬',
        '秋田犬',
        '巨型贵宾犬',
        '罗威纳',
        '藏獒',
        '大白熊',
        '古牧',
        '杜宾',
        '高加索',
        '卡斯特罗',
        '杜高犬',
        '其他',
      ]
    }
  ];
  static const List<String> DogColor = [
    '巧克力色',
    '红色',
    '金黄色',
    '奶油色',
    '浅黄褐色',
    '黑色',
    '蓝色',
    '灰色',
    '白色',
  ];

  // 空安全：字段必须有初始值，空构造（new Dog()）才是合法的
  String breed = ''; // 品种
  String size = ''; // 尺寸
  String color = ''; // 颜色
  List<Pic> pic = []; // 图片

  Dog();

  Dog.fromJson(Map<String, dynamic> json)
      : color = _at(DogColor, json['color']),
        size = _at(DogSize, json['size']),
        breed = _breedOf(json['size'], json['breed']) {
    // 初始化 补一个pic 这样有静态类型。
    //
    // 顺带做容错：pic 缺失 / 类型不对时退化成"没有图片"，
    // 而不是让一条脏数据把整页列表打崩。
    final Object? picJson = json["pic"];
    if (picJson is List) {
      for (final Object? e in picJson) {
        // 做个兼容 dart 空的 map 会被转成 list
        if (e is Map<String, dynamic>) {
          pic.add(Pic.fromJson(e));
        }
      }
    }
  }

  /// 下标安全取值：越界 / 类型不符时退化为空串。
  ///
  /// 改造前这里是裸的 `DogSize[json['size']]` 这种写法，
  /// 只要服务端出现一条越界记录，整个列表就会被打崩。
  static String _at(List<String> table, Object? index) {
    if (index is int && index >= 0 && index < table.length) {
      return table[index];
    }
    return '';
  }

  /// 品种名（二维表，需要先定位体型再定位品种）。
  ///
  /// ⚠️ 这里必须做越界保护，不是杞人忧天 —— 线上实测：
  /// 服务端 `size=1`（中型）实际存在 `breed = 0..16` 共 **17** 种，
  /// 而本地 [DogBreed]`[1]` 只列了 **16** 种。
  /// 直接写 `DogBreed[size][breed]` 一旦翻到"中型 + 第 17 种"的那几条记录
  /// 就会抛 RangeError，`DogService.parseList` 整体失败，
  /// 列表页直接变成"没有数据"（这几条记录是真实存在的，`size=1&breed=16` 实测 total=4）。
  ///
  /// 本地表缺的那个品种名无从考证，所以这里选择"退化成一个空品种名"，
  /// 而不是让整页数据消失。
  static String _breedOf(Object? size, Object? breed) {
    if (size is! int || size < 0 || size >= DogBreed.length) return '';
    return _at(DogBreed[size], breed);
  }
}
