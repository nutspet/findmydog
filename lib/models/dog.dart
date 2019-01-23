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

  String breed; // 品种
  String size; // 尺寸
  String color; // 颜色
  List<Pic> pic = []; // 图片

  Dog();

  Dog.fromJson(Map<String, dynamic> json)
      : color = DogColor[json['color']],
        size = DogSize[json['size']],
        breed = DogBreed[json['size']][json['breed']] {
    // 初始化 补一个pic 这样有静态类型
    List picJson = json["pic"];
    //print(picJson);
    picJson.forEach((e) {
      // 做个兼容 dart 空的 map 会被转成 list
      if (e is Map<String, dynamic>) {
        pic.add(Pic.fromJson(e));
      }
    });
  }
}
