import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:find_dog/models/dog.dart';
import 'package:find_dog/models/dog_lost.dart';
import 'package:find_dog/utils/validate.dart';
import 'package:find_dog/widgets/form_image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:find_dog/common/request.dart';
import 'package:dio/dio.dart';
import 'package:find_dog/screens/lost/finish.dart';
import 'detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:find_dog/common/constants.dart';
import 'package:find_dog/models/location.dart';
import 'package:fluwx/fluwx.dart' as fluwx;

const mapKey = Constants.amapWebKey;

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
  @override
  createState() => new LostReportState();
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
  Map<File, ImageUploadStatus> _imageFile = new Map();

  // 腾讯云上传 最终上传的应该是 _uploadImage.values.toList();
  Map<File, Map<String, String>> _uploadImage = {};

  // snackbar 提示
  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(value)));
  }

  // 用户离开提示
  Future<bool> _warnUserAboutInvalidData() async {
    final FormState form = _formKey.currentState;

    if (form == null || !_formChanged) return true;

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('尚未完成！'),
              content: const Text('确认离开表单？'),
              actions: <Widget>[
                FlatButton(
                  child: const Text('是'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                FlatButton(
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

  // 表单提交
  void _handleSubmitted() async {
    final FormState form = _formKey.currentState;
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
              padding: EdgeInsets.symmetric(vertical: 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(),
                  Text("请求中。。。"),
                ],
              ),
            ),
          );
        },
      );
      // 初始化api
      Request api = Request();
      // 地理位置的说 ampa的原始请求
      print(
          "https://restapi.amap.com/v3/geocode/geo?key=$mapKey&address=$_locationName&city=$_regionCity");
      Response response = await api
          .getDio()
          .get(
            "https://restapi.amap.com/v3/geocode/geo?key=$mapKey&address=$_locationName&city=$_regionCity",
          )
          .catchError((e) {
        // print("有个错误啦");
        print(e);
      }).whenComplete(() {
        // Navigator.of(context).pop();
      });
      try {
        print(response.data['geocodes'][0]['location']);
        String location = response.data['geocodes'][0]['location'];
        List<String> loc = location.split(",");
        print(loc);
        locationLongitude = loc[0];
        locationLatitude = loc[1];
      } catch (e) {
        // 不处理了如果没正确地址
      }
      // showInSnackBar('${person.name}\'s phone number is ${person.phoneNumber}');
      // 提交逻辑在这里处理
      Map<String, dynamic> params = new Map();
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
      ;
      params['age'] = _age.round();
      params['weight'] = _weight.round();
      params['remark'] = _remark;
      params['pic'] = jsonEncode(_uploadImage.values.toList());
      params['contactsName'] = _contactsName;
      params['contactsGender'] = _contactsGender ? 1 : 0;
      ;
      params['contactsMobile'] = _contactsMobile;
      params['negotiate'] = _negotiate ? 1 : 0;
      params['reward'] = _reward;
      print(params);
      FormData formData = new FormData.from(params);
      api.req('/lost/report2', auth: true, method: 'POST', data: formData,
          success: (res) async {
        // 删除成功返回qlcoud的requestid
        print(res);
        // {result: {userId: 8f2deede-6d9a-4de6-983e-5cc15ce4929c, lostId: 103, lostUuid: abdddbd3-ebe9-42d1-b26e-29cbb65ae679}}
        String uuid = res['result']['lostUuid'];
        // 送去finish页面
        BackAction result = await Navigator.push(
          context,
          MaterialPageRoute<BackAction>(
            builder: (context) => LostFinish(uuid),
            fullscreenDialog: true,
          ),
        );
        // finish页面的返回
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
            new MaterialPageRoute(
              builder: (context) => new LostDetail(
                    dog: detail,
                  ),
            ),
          );
        }
        // 把mask去掉
        Navigator.of(context).pop();
        Navigator.of(context).pop(ReportAction.success);
      }).catchError(() {
        showInSnackBar("提交出错！");
        // 把mask去掉
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      backgroundColor: new Color(0XFFf8f8f8),
      appBar: new AppBar(
        actions: <Widget>[
          Container(
            child: IconButton(
                icon: Icon(Icons.help_outline),
                onPressed: () {
                  showDialog<String>(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) =>
                        SimpleDialog(title: Text('帮助说明'), children: <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text(
                              "本表单专为生成高效率寻狗启事而设计得来，所有项都已精简到最小态，请认真填写。您也可以使用我们的微信小程序版本，可以同样的完成这项任务！",
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 25.0),
                            child: Image(
                              image: AssetImage("data_repo/img/logo/wx.png"),
                            ),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          FractionallySizedBox(
                            child: OutlineButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: Icon(Icons.accessibility),
                                label: Text("知道了！（关闭窗口）")),
                            widthFactor: 0.9,
                          ),
                          FractionallySizedBox(
                            child: OutlineButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // 直接跳小程序
                                  fluwx
                                      .launchMiniProgram(
                                    username: "gh_0c80acc3f473",
                                  )
                                      .then((data) {
                                    print(data);
                                  });
                                },
                                icon: Icon(Icons.check),
                                label: Text("带我去小程序看看吧。")),
                            widthFactor: 0.9,
                          )
                        ]),
                  );
                }),
            margin: const EdgeInsets.only(
              right: 0.0,
            ),
          ),
        ],
        elevation: 0.0,
        title: new Text(
          "报告失踪汪",
          style: TextStyle(fontSize: 16.0),
        ),
      ),
      body: Form(
        key: _formKey,
        onChanged: () {
          // listview只渲染看到部分 导致丢失参数 所以还是要保存一下的 挺矛盾的
          _formChanged = true;
          final FormState form = _formKey.currentState;
          form.save();
        },
        autovalidate: _autoValidate,
        onWillPop: _warnUserAboutInvalidData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Theme(
                // 补丁 这样中文的日历不会有overflow
                data: Theme.of(context).copyWith(
                    primaryTextTheme:
                        TextTheme(display1: TextStyle(fontSize: 24.0))),
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
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
              onTap: () {
                new Picker(
                    adapter: PickerDataAdapter<String>(pickerdata: locations2),
                    changeToFirst: true,
                    textAlign: TextAlign.left,
                    confirmText: "确认",
                    cancelText: "取消",
                    columnPadding: const EdgeInsets.all(8.0),
                    // selecteds: _lostLatestPicker,
                    onConfirm: (Picker picker, List value) {
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
                suffixIcon: IconButton(
                    icon: Icon(Icons.location_searching), onPressed: null),
              ),
              initialValue: _locationName,
              style:
                  Theme.of(context).textTheme.display1.copyWith(fontSize: 18.0),
              validator: (String value) {
                if (value.isEmpty) return '详细地址不能为空！';
                return null;
              },
              onSaved: (String value) {
                _locationAddress = value;
                _locationName = value;
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
                        onChanged: (int newValue) {
                          setState(() {
                            _color = newValue;
                          });
                        },
                        items: color.map<DropdownMenuItem<int>>(
                            (Map<int, Map<String, Color>> item) {
                          int i;
                          String l;
                          Color c;
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
                                  margin: EdgeInsets.only(right: 10.0),
                                  decoration: BoxDecoration(
                                    color: c,
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                ),
                                Text(
                                  l,
                                  style: TextStyle(fontSize: 14.0),
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                SizedBox(
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
                        onChanged: (bool newValue) {
                          setState(() {
                            _gender = newValue;
                          });
                        },
                        items: DogLost.DogGender.keys
                            .map<DropdownMenuItem<bool>>((bool key) {
                          return DropdownMenuItem<bool>(
                            value: key,
                            child: Text(
                              DogLost.DogGender[key],
                              style: TextStyle(fontSize: 14.0),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                SizedBox(
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
                          padding: EdgeInsets.only(top: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                Dog.DogSizeBreed[_size][_sizeName][_breed],
                                style: TextStyle(fontSize: 14.0),
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
                        new Picker(
                            adapter: PickerDataAdapter<String>(
                                pickerdata: Dog.DogSizeBreed),
                            // changeToFirst: true,
                            confirmText: "确认",
                            cancelText: "取消",
                            textAlign: TextAlign.left,
                            columnPadding: const EdgeInsets.all(8.0),
                            // selecteds: [_lostLatestSize, _lostLatestBreed],
                            onConfirm: (Picker picker, List value) {
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
                      contentPadding: EdgeInsets.all(5.0),
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
                      contentPadding: EdgeInsets.all(5.0),
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
              validator: (String value) {
                if (value.isEmpty) return '详细说明不能为空';
                return null;
              },
              onSaved: (String value) {
                _remark = value;
              },
            ),
            const SizedBox(height: 10.0),
            FormImagePicker(
              titleLabel: "上传图片（1-9张）（单张5mb大小）",
              initialValue: _imageFile,
              onError: showInSnackBar,
              onSaved: (Map<File, ImageUploadStatus> value) {
                _imageFile = value;
              },
              validator: (Map<File, ImageUploadStatus> value) {
                if (value.isEmpty) return '至少上传一张图片';
                return null;
              },
              imageUpload: (file) async {
                try {
                  // 生成File的formdata
                  FormData formData = new FormData.from({
                    "type": "debug",
                    "file": [
                      new UploadFileInfo(file, "debug"),
                    ],
                  });
                  Request api = Request();
                  await api.req('/upload2',
                      method: 'POST',
                      auth: true,
                      data: formData, success: (res) {
                    // 返回列表 服务端是多条数据 虽然只能选择一张图
                    // 先转转类型 舒服点
                    Map<String, List> resMap = new Map.from(res);
                    resMap['result'].forEach((e) {
                      _uploadImage
                          .addAll({file: new Map<String, String>.from(e)});
                    });
                    // print(_uploadImage);
                    return ImageUploadStatus.UPLOAD_SUCCESS;
                  });
                  return ImageUploadStatus.UPLOAD_SUCCESS;
                } catch (e) {
                  // print("lala");
                  print(e);
                  showInSnackBar("添加图片失败！");
                  return ImageUploadStatus.UPLOAD_FAIL;
                }
              },
              imageDelete: (file) async {
                try {
                  FormData formData =
                      new FormData.from({'key': _uploadImage[file]});
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
                  showInSnackBar(e);
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
                  onChanged: (bool newValue) {
                    setState(() {
                      _contactsGender = newValue;
                    });
                  },
                  items: DogLost.UserGender.keys
                      .toList()
                      .map<DropdownMenuItem<bool>>((bool value) {
                    return DropdownMenuItem<bool>(
                      value: value,
                      child: Text(DogLost.UserGender[value]),
                    );
                  }).toList(),
                )),
                border: UnderlineInputBorder(),
                filled: true,
                icon: Icon(Icons.person),
                hintText: '希望他人如何称呼您',
                labelText: '联系人姓名',
              ),
              validator: (String value) {
                if (value.isEmpty) return '姓名不能为空！';
                return null;
              },
              onSaved: (value) {
                _contactsName = value;
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
              inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
              validator: (String value) {
                return Validate.phone(value);
              },
              onSaved: (value) {
                _contactsMobile = value;
              },
              initialValue: _contactsMobile,
            ),
            const SizedBox(height: 10.0),
            Stack(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    isDense: true,
                    suffixIcon: Switch(
                        value: _negotiate,
                        onChanged: (bool value) {
                          setState(() {
                            _negotiate = value;
                          });
                        }),
                    filled: true,
                    icon: Icon(Icons.attach_money),
                    hintText: '若选择面议将不展示酬劳金额。',
                    labelText: '酬劳（人民币1至100000元）',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                  validator: (String value) {
                    if (value.isEmpty) return '请输入酬劳！';
                    int price = int.parse(value);
                    if (price < 1 || price > 100000) return '酬劳范围在1至100000元之间。';
                    return null;
                  },
                  onSaved: (value) {
                    _reward = int.parse(value);
                  },
                  initialValue: _reward.toString(),
                  // enabled: _negotiate,
                ),
                Positioned(
                  child: Text(
                    "是否面议",
                    style: TextStyle(fontSize: 10.0),
                  ),
                  right: 11.0,
                  top: 3.0,
                ),
                Positioned(
                  child: Text(
                    _negotiate ? "是" : "否",
                    style:
                        TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold),
                  ),
                  right: 24.0,
                  bottom: 3.0,
                )
              ],
            ),
            const SizedBox(height: 10.0),
            Container(
              child: RaisedButton.icon(
                onPressed: _handleSubmitted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                ),
                icon: Icon(
                  Icons.save,
                  color: Colors.white,
                ),
                label: Text(
                  "保存并发布",
                  style: TextStyle(color: Colors.white),
                ),
                color: Theme.of(context).primaryColor,
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.0),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputDropdown extends StatelessWidget {
  const _InputDropdown(
      {Key key,
      this.child,
      this.labelText,
      this.valueText,
      this.valueStyle,
      this.onPressed})
      : super(key: key);

  final String labelText;
  final String valueText;
  final TextStyle valueStyle;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          labelText: labelText,
          labelStyle: TextStyle(fontSize: 16.0),
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
  const _DateTimePicker(
      {Key key,
      this.labelText,
      this.selectedDate,
      this.selectedTime,
      this.selectDate,
      this.selectTime})
      : super(key: key);

  final String labelText;
  final DateTime selectedDate;
  final int selectedTime;
  final ValueChanged<DateTime> selectDate;
  final ValueChanged<int> selectTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        locale: Locale('zh', 'CH'),
        initialDate: selectedDate,
        firstDate: DateTime(2017),
        lastDate: DateTime.now());
    if (picked != null && picked != selectedDate) selectDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = Theme.of(context).textTheme.title;
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
                onChanged: selectTime,
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
