import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:fluwx/fluwx.dart';
import 'package:intl/intl.dart';
import 'package:find_dog/common/request.dart';
import 'package:find_dog/common/tianditu.dart';
import 'package:find_dog/models/dog.dart';
import 'package:find_dog/models/dog_lost.dart';
import 'package:find_dog/models/location.dart';
import 'package:find_dog/screens/lost/finish.dart';
import 'package:find_dog/utils/coord_transform.dart';
import 'package:find_dog/utils/validate.dart';
import 'package:find_dog/widgets/form_image_picker.dart';

import 'detail.dart';

// fluwx 6.x 用一个实例来调用（open 等）
final Fluwx _fluwx = Fluwx();

// 提交报告成功与否 返回到list决定是否刷新
enum ReportAction { success, stop }

// 带颜色框的
const List<Map<int, Map<String, Color>>> color = [
  {
    0: {"巧克力色": Colors.brown},
  },
  {
    1: {"红色": Colors.red},
  },
  {
    2: {"金黄色": Colors.amber},
  },
  {
    3: {"奶油色": Color(0xFFDED5B6)},
  },
  {
    4: {"浅黄褐色": Colors.brown},
  },
  {
    5: {"黑色": Colors.black},
  },
  {
    6: {"蓝色": Colors.blue},
  },
  {
    7: {"灰色": Colors.grey},
  },
  {
    8: {"白色": Colors.white},
  },
];

// 失踪报告
class LostReport extends StatefulWidget {
  const LostReport({super.key});

  @override
  LostReportState createState() => LostReportState();
}

class LostReportState extends State<LostReport> {
  // 用来出snackbar的
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // formkey
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 自动校验 默认关闭 只有在校验过一次之后才自动打开
  bool _autoValidate = false;

  // 是否表单修改过
  bool _formChanged = false;

  DateTime _date = DateTime.now();
  bool _negotiate = false;
  int _reward = 200;
  int _time = 0;
  String _regionProvince = "上海市";
  String _regionCity = "上海市";
  String _regionArea = "静安区";
  String _locationName = "";
  String _locationAddress = "";
  String _remark = "";
  int _color = 0;
  bool _gender = false;
  double _age = 5;
  double _weight = 10;
  String _contactsName = '';
  bool _contactsGender = false;
  String _contactsMobile = '';
  int _size = 0;
  String _sizeName = "小型";
  int _breed = 0;

  // 非state展示用
  String locationLongitude = "0.0";
  String locationLatitude = "0.0";

  // 图片 控件的内部state 也是需要初始化和保存在页面内的
  Map<File, ImageUploadStatus> _imageFile = <File, ImageUploadStatus>{};

  // 腾讯云上传 最终上传的应该是 _uploadImage.values.toList();
  Map<File, Map<String, String>> _uploadImage = {};

  // snackbar 提示
  void showInSnackBar(String value) {
    // ScaffoldState.showSnackBar 已在 Flutter 3.x 中移除，改用 ScaffoldMessenger
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  // 用户离开提示
  Future<bool> _warnUserAboutInvalidData() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !_formChanged) return true;

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('尚未完成！'),
              content: const Text('确认离开表单？'),
              actions: <Widget>[
                TextButton(
                  child: const Text('是'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                TextButton(
                  child: const Text('否'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// 拼出天地图地理编码要用的关键字。
  ///
  /// 天地图这个接口**只收一个 `keyWord`**，没有独立的城市参数（高德有 `city`），
  /// 所以省/市/区得自己拼进去。
  ///
  /// 直辖市的省和市是同一个词（"上海市" + "上海市"），连着的重复项去重一下，
  /// 免得拼出 "上海市上海市静安区…" 反而降低命中率。
  String _geocodeKeyWord() {
    final List<String> parts = <String>[
      _regionProvince,
      _regionCity,
      _regionArea,
      _locationName,
    ];
    final List<String> kept = <String>[];
    for (final String part in parts) {
      final String trimmed = part.trim();
      if (trimmed.isEmpty || (kept.isNotEmpty && kept.last == trimmed)) {
        continue;
      }
      kept.add(trimmed);
    }
    return kept.join();
  }

  // 表单提交
  void _handleSubmitted() async {
    final FormState? form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      _autoValidate = true; // Start validating on every change.
      showInSnackBar('请修正表单错误项！');
    } else {
      form.save();
      // 还是弄个loading吧
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(),
                  const Text("请求中。。。"),
                ],
              ),
            ),
          );
        },
      );
      // 初始化api
      Request api = Request();
      // 地理编码：把"省市区 + 详细地址"换成经纬度。
      // 原先走的是高德 v3/geocode/geo，现已换成天地图 geocoder。
      //
      // 先落成哨兵值：查不到坐标就照这个值提交，与替换前的行为保持一致
      // （服务端会存成 0.0，map.dart 会把这种点判为"不可用"并给提示）。
      locationLongitude = '0.0';
      locationLatitude = '0.0';
      try {
        final Response response = await api.getDio().getUri(
              tiandituGeocoderUri(_geocodeKeyWord()),
            );
        final dynamic data = response.data;
        final dynamic location = data is Map ? data['location'] : null;
        if (location is Map &&
            location['lon'] != null &&
            location['lat'] != null) {
          // 天地图返回的 lon / lat 是**字符串**，不是数字
          final double? wgsLat = double.tryParse('${location['lat']}');
          final double? wgsLng = double.tryParse('${location['lon']}');
          if (wgsLat != null && wgsLng != null) {
            // 天地图用的是 WGS-84（CGCS2000），而库里历史坐标全是高德产的 GCJ-02。
            // 为了不把两种坐标系混进同一列，入库前正算回 GCJ-02。
            final GeoPoint gcj = wgs84ToGcj02(
              (latitude: wgsLat, longitude: wgsLng),
            );
            locationLongitude = gcj.longitude.toString();
            locationLatitude = gcj.latitude.toString();
          }
        }
      } catch (e) {
        // 地理编码只是锦上添花：拿不到坐标不该挡住发布流程，
        // 所以这里只记日志、继续用哨兵坐标提交。
        // 注意不要打出完整请求 URL —— 那会把 tk 泄进日志。
        debugPrint('天地图地理编码失败：$e');
      }
      // showInSnackBar('${person.name}\'s phone number is ${person.phoneNumber}');
      // 提交逻辑在这里处理
      Map<String, dynamic> params = <String, dynamic>{};
      params['date'] = DateFormat("yyyy-MM-dd").format(_date);
      params['time'] = _time;
      params['regionProvince'] = _regionProvince;
      params['regionCity'] = _regionCity;
      params['regionArea'] = _regionArea;
      params['locationName'] = _locationName;
      params['locationAddress'] = _locationAddress;
      params['locationLatitude'] = locationLatitude;
      params['locationLongitude'] = locationLongitude;
      params['color'] = _color;
      params['size'] = _size;
      params['breed'] = _breed;
      params['gender'] = _gender ? 1 : 0;
      params['age'] = _age.round();
      params['weight'] = _weight.round();
      params['remark'] = _remark;
      params['pic'] = jsonEncode(_uploadImage.values.toList());
      params['contactsName'] = _contactsName;
      params['contactsGender'] = _contactsGender ? 1 : 0;
      params['contactsMobile'] = _contactsMobile;
      params['negotiate'] = _negotiate ? 1 : 0;
      params['reward'] = _reward;
      print(params);
      FormData formData = FormData.fromMap(params);
      api.req('/lost/report2', auth: true, method: 'POST', data: formData,
          success: (res) async {
        // 删除成功返回qlcoud的requestid
        print(res);
        // {result: {userId: 8f2deede-6d9a-4de6-983e-5cc15ce4929c, lostId: 103, lostUuid: abdddbd3-ebe9-42d1-b26e-29cbb65ae679}}
        String uuid = res['result']['lostUuid'];
        // 送去finish页面
        BackAction? result = await Navigator.push(
          context,
          MaterialPageRoute<BackAction>(
            builder: (context) => LostFinish(uuid),
            fullscreenDialog: true,
          ),
        );
        // finish页面的返回
        if (!mounted) return; // 跨过 await 后 State 可能已销毁，用 context 前先确认
        if (result == BackAction.detail) {
          // 直接拼模型 手工转下 补一个found 打开速度快 不请求网络
          params['negotiate'] = params['negotiate'] == 1 ? true : false;
          params['pic'] = jsonDecode(params['pic']);
          params['found'] = false;
          params['uuid'] = uuid;
          DogLost detail = DogLost.fromJson(params);
          // 测试跳详情
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LostDetail(
                dog: detail,
              ),
            ),
          );
          if (!mounted) return;
        }
        // 把mask去掉
        Navigator.of(context).pop();
        Navigator.of(context).pop(ReportAction.success);
      }).catchError((Object e) {
        showInSnackBar("提交出错！");
        // 把mask去掉
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0XFFf8f8f8),
      appBar: AppBar(
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(
              right: 0.0,
            ),
            child: IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () {
                  showDialog<String>(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) =>
                        SimpleDialog(title: const Text('帮助说明'), children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          "本表单专为生成高效率寻狗启事而设计得来，所有项都已精简到最小态，请认真填写。您也可以使用我们的微信小程序版本，可以同样的完成这项任务！",
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.0),
                        child: Image(
                          image: AssetImage("data_repo/img/logo/wx.png"),
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.9,
                        child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.accessibility),
                            label: const Text("知道了！（关闭窗口）")),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.9,
                        child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // 直接跳小程序
                              _fluwx
                                  .open(
                                target: MiniProgram(
                                  username: "gh_0c80acc3f473",
                                ),
                              )
                                  .then((data) {
                                print(data);
                              });
                            },
                            icon: const Icon(Icons.check),
                            label: const Text("带我去小程序看看吧。")),
                      )
                    ]),
                  );
                }),
          ),
        ],
        elevation: 0.0,
        title: const Text(
          "报告失踪汪",
          style: TextStyle(fontSize: 16.0),
        ),
      ),
      body: Form(
        key: _formKey,
        // onWillPop 已废弃，改用 canPop + onPopInvokedWithResult
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;
          final bool canPop = await _warnUserAboutInvalidData();
          if (canPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        onChanged: () {
          // listview只渲染看到部分 导致丢失参数 所以还是要保存一下的 挺矛盾的
          _formChanged = true;
          final FormState? form = _formKey.currentState;
          form?.save();
        },
        autovalidateMode:
            _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Theme(
                // 补丁 这样中文的日历不会有overflow
                // TextTheme 的 display1 已废弃，对应新名 headlineMedium
                data: Theme.of(context).copyWith(
                    primaryTextTheme: const TextTheme(
                        headlineMedium: TextStyle(fontSize: 24.0))),
                child: _DateTimePicker(
                  labelText: '失踪日期',
                  selectedDate: _date,
                  selectedTime: _time,
                  selectDate: (DateTime date) {
                    setState(() {
                      _date = date;
                    });
                  },
                  selectTime: (int time) {
                    setState(() {
                      _time = time;
                    });
                  },
                )),
            const SizedBox(height: 10.0),
            InkWell(
              child: InputDecorator(
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: "城市地区",
                  // contentPadding: EdgeInsets.all(5.0),
                ),
                child: Text(
                  "$_regionProvince - $_regionCity - $_regionArea",
                  style: const TextStyle(fontSize: 18.0),
                ),
              ),
              onTap: () {
                Picker(
                    adapter:
                        PickerDataAdapter<String>(pickerData: locations2),
                    changeToFirst: true,
                    textAlign: TextAlign.left,
                    confirmText: "确认",
                    cancelText: "取消",
                    columnPadding: const EdgeInsets.all(8.0),
                    // selecteds: _lostLatestPicker,
                    onConfirm: (Picker picker, List<int> value) {
                      setState(() {
                        _regionProvince = picker.getSelectedValues()[0];
                        _regionCity = picker.getSelectedValues()[1];
                        _regionArea = picker.getSelectedValues()[2];
                      });
                    }).showModal(context);
              },
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              decoration: InputDecoration(
                labelText: '详细地址',
                isDense: true,
                helperText: '填写精准地址。（例如：XX小区XX楼门口）',
                suffixIcon: const IconButton(
                    icon: Icon(Icons.location_searching), onPressed: null),
              ),
              initialValue: _locationName,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 18.0),
              validator: (String? value) {
                if (value == null || value.isEmpty) return '详细地址不能为空！';
                return null;
              },
              onSaved: (String? value) {
                _locationAddress = value ?? '';
                _locationName = value ?? '';
              },
            ),
            const SizedBox(height: 10.0),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "颜色",
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _color,
                        onChanged: (int? newValue) {
                          if (newValue == null) return;
                          setState(() {
                            _color = newValue;
                          });
                        },
                        items: color.map<DropdownMenuItem<int>>(
                            (Map<int, Map<String, Color>> item) {
                          int? i;
                          String? l;
                          Color? c;
                          item.forEach((index, combo) {
                            i = index;
                            combo.forEach((label, theme) {
                              l = label;
                              c = theme;
                            });
                          });
                          return DropdownMenuItem<int>(
                            value: i,
                            child: Row(
                              children: <Widget>[
                                Container(
                                  height: 10.0,
                                  width: 10.0,
                                  margin: const EdgeInsets.only(right: 10.0),
                                  decoration: BoxDecoration(
                                    color: c,
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                  ),
                                ),
                                Text(
                                  l ?? '',
                                  style: const TextStyle(fontSize: 14.0),
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12.0,
                ),
                Expanded(
                  flex: 2,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: "性别",
                      contentPadding: EdgeInsets.zero,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<bool>(
                        value: _gender,
                        onChanged: (bool? newValue) {
                          if (newValue == null) return;
                          setState(() {
                            _gender = newValue;
                          });
                        },
                        items: DogLost.DogGender.keys
                            .map<DropdownMenuItem<bool>>((bool key) {
                          return DropdownMenuItem<bool>(
                            value: key,
                            child: Text(
                              DogLost.DogGender[key] ?? '',
                              style: const TextStyle(fontSize: 14.0),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12.0,
                ),
                Expanded(
                  flex: 4,
                  child: InkWell(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: "品种",
                          labelStyle: TextStyle(fontSize: 16.0),
                          contentPadding: EdgeInsets.only(bottom: 12.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                Dog.DogSizeBreed[_size][_sizeName]?[_breed] ??
                                    '',
                                style: const TextStyle(fontSize: 14.0),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.grey.shade700
                                      : Colors.white70),
                            ],
                          ),
                        ),
                      ),
                      onTap: () {
                        Picker(
                            adapter: PickerDataAdapter<String>(
                                pickerData: Dog.DogSizeBreed),
                            // changeToFirst: true,
                            confirmText: "确认",
                            cancelText: "取消",
                            textAlign: TextAlign.left,
                            columnPadding: const EdgeInsets.all(8.0),
                            // selecteds: [_lostLatestSize, _lostLatestBreed],
                            onConfirm: (Picker picker, List<int> value) {
                              //print(value.toString());
                              //print(picker.getSelectedValues());
                              setState(() {
                                _size = value[0];
                                _breed = value[1];
                                _sizeName = picker.getSelectedValues()[0];
                              });
                            }).showModal(context);
                      }),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: "年龄",
                      suffixIcon: Chip(
                        label: Text("${_age.toInt()}"),
                      ),
                      contentPadding: const EdgeInsets.all(5.0),
                    ),
                    child: Slider(
                      value: _age,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      onChanged: (double value) {
                        setState(() {
                          _age = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: "重量（kg）",
                      suffixIcon: Chip(
                        label: Text("${_weight.toInt()}"),
                      ),
                      contentPadding: const EdgeInsets.all(5.0),
                    ),
                    child: Slider(
                      value: _weight,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      onChanged: (double value) {
                        setState(() {
                          _weight = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '请输入内容',
                helperText: '尽可能多的补充失踪细节和狗狗特征，能够更好的获得大家的帮助。',
                labelText: '详细说明',
                isDense: true,
              ),
              maxLines: 3,
              initialValue: _remark,
              validator: (String? value) {
                if (value == null || value.isEmpty) return '详细说明不能为空';
                return null;
              },
              onSaved: (String? value) {
                _remark = value ?? '';
              },
            ),
            const SizedBox(height: 10.0),
            FormImagePicker(
              titleLabel: "上传图片（1-9张）（单张5mb大小）",
              initialValue: _imageFile,
              onError: showInSnackBar,
              onSaved: (Map<File, ImageUploadStatus>? value) {
                _imageFile = value ?? <File, ImageUploadStatus>{};
              },
              validator: (Map<File, ImageUploadStatus>? value) {
                if (value == null || value.isEmpty) return '至少上传一张图片';
                return null;
              },
              imageUpload: (file) async {
                try {
                  // 生成File的formdata
                  FormData formData = FormData.fromMap({
                    "type": "debug",
                    "file":
                        MultipartFile.fromFileSync(file.path, filename: "debug"),
                  });
                  Request api = Request();
                  await api.req('/upload2',
                      method: 'POST',
                      auth: true,
                      data: formData, success: (res) {
                    // 返回列表 服务端是多条数据 虽然只能选择一张图
                    // 先转转类型 舒服点
                    final Map<String, List> resMap =
                        Map<String, List>.from(res);
                    (resMap['result'] ?? const <dynamic>[]).forEach((e) {
                      _uploadImage
                          .addAll({file: Map<String, String>.from(e as Map)});
                    });
                    // print(_uploadImage);
                  });
                  return ImageUploadStatus.uploadSuccess;
                } catch (e) {
                  // print("lala");
                  print(e);
                  showInSnackBar("添加图片失败！");
                  return ImageUploadStatus.uploadFail;
                }
              },
              imageDelete: (file) async {
                try {
                  FormData formData =
                      FormData.fromMap({'key': _uploadImage[file]});
                  Request api = Request();
                  print(_uploadImage[file]);
                  await api.req('/delete2',
                      auth: true,
                      method: 'POST',
                      data: formData, success: (res) {
                    // 删除成功返回qlcoud的requestid
                    print("res_$res");
                  });
                  return true;
                } catch (e) {
                  // print("lala");
                  print(e);
                  showInSnackBar('$e');
                  return false;
                }
              },
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              textCapitalization: TextCapitalization.words,
              initialValue: _contactsName,
              decoration: InputDecoration(
                isDense: true,
                suffixIcon: DropdownButtonHideUnderline(
                    child: DropdownButton<bool>(
                  value: _contactsGender,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    setState(() {
                      _contactsGender = newValue;
                    });
                  },
                  items: DogLost.UserGender.keys
                      .toList()
                      .map<DropdownMenuItem<bool>>((bool value) {
                    return DropdownMenuItem<bool>(
                      value: value,
                      child: Text(DogLost.UserGender[value] ?? ''),
                    );
                  }).toList(),
                )),
                border: const UnderlineInputBorder(),
                filled: true,
                icon: const Icon(Icons.person),
                hintText: '希望他人如何称呼您',
                labelText: '联系人姓名',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) return '姓名不能为空！';
                return null;
              },
              onSaved: (String? value) {
                _contactsName = value ?? '';
              },
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
                filled: true,
                icon: Icon(Icons.phone),
                hintText: '请准确填写联系人手机号码',
                labelText: '联系人手机',
                prefixText: '+86',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (String? value) {
                return Validate.phone(value ?? '');
              },
              onSaved: (String? value) {
                _contactsMobile = value ?? '';
              },
              initialValue: _contactsMobile,
            ),
            const SizedBox(height: 10.0),
            Stack(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    border: const UnderlineInputBorder(),
                    isDense: true,
                    suffixIcon: Switch(
                        value: _negotiate,
                        onChanged: (bool value) {
                          setState(() {
                            _negotiate = value;
                          });
                        }),
                    filled: true,
                    icon: const Icon(Icons.attach_money),
                    hintText: '若选择面议将不展示酬劳金额。',
                    labelText: '酬劳（人民币1至100000元）',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (String? value) {
                    if (value == null || value.isEmpty) return '请输入酬劳！';
                    int price = int.parse(value);
                    if (price < 1 || price > 100000) return '酬劳范围在1至100000元之间。';
                    return null;
                  },
                  onSaved: (String? value) {
                    _reward = int.tryParse(value ?? '') ?? 0;
                  },
                  initialValue: _reward.toString(),
                  // enabled: _negotiate,
                ),
                const Positioned(
                  right: 11.0,
                  top: 3.0,
                  child: Text(
                    "是否面议",
                    style: TextStyle(fontSize: 10.0),
                  ),
                ),
                Positioned(
                  right: 24.0,
                  bottom: 3.0,
                  child: Text(
                    _negotiate ? "是" : "否",
                    style: const TextStyle(
                        fontSize: 10.0, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ElevatedButton.icon(
                // ElevatedButton 没有 shape/color 直接参数，统一走 style
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                ),
                onPressed: _handleSubmitted,
                icon: const Icon(
                  Icons.save,
                  color: Colors.white,
                ),
                label: const Text(
                  "保存并发布",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputDropdown extends StatelessWidget {
  const _InputDropdown({
    required this.labelText,
    required this.valueText,
    required this.valueStyle,
    required this.onPressed,
  });

  final String labelText;
  final String valueText;
  final TextStyle? valueStyle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          labelText: labelText,
          labelStyle: const TextStyle(fontSize: 16.0),
        ),
        baseStyle: valueStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(valueText, style: valueStyle),
            Icon(Icons.arrow_drop_down,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade700
                    : Colors.white70),
          ],
        ),
      ),
    );
  }
}

// 直接从flutter example里复制来的
class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({
    required this.labelText,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectDate,
    required this.selectTime,
  });

  final String labelText;
  final DateTime selectedDate;
  final int selectedTime;
  final ValueChanged<DateTime> selectDate;
  final ValueChanged<int> selectTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        locale: const Locale('zh', 'CH'),
        initialDate: selectedDate,
        firstDate: DateTime(2017),
        lastDate: DateTime.now());
    if (picked != null && picked != selectedDate) selectDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? valueStyle = Theme.of(context).textTheme.titleLarge;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          flex: 4,
          child: _InputDropdown(
            labelText: labelText,
            valueText: DateFormat("yyyy-MM-dd").format(selectedDate),
            valueStyle: valueStyle,
            onPressed: () {
              _selectDate(context);
            },
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 3,
          child: InputDecorator(
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                value: selectedTime,
                onChanged: (int? value) {
                  if (value != null) selectTime(value);
                },
                items:
                    DogLost.LostTime.map<DropdownMenuItem<int>>((String value) {
                  return DropdownMenuItem<int>(
                    value: DogLost.LostTime.indexOf(value),
                    child: Text(value),
                  );
                }).toList(),
              ))),
        ),
      ],
    );
  }
}
