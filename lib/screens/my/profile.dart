import 'package:flutter/material.dart';
import 'package:find_dog/models/profile.dart';
import 'package:flutter/services.dart';
import 'package:find_dog/utils/validate.dart';
import 'package:intl/intl.dart';
import 'package:find_dog/common/request.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';

class MyProfile extends StatefulWidget {
  final Profile profile;
  // 构造传递进来 扔给state
  MyProfile({@required this.profile});
  @override
  MyProfileState createState() => new MyProfileState();
}

class MyProfileState extends State<MyProfile> with TickerProviderStateMixin {
  // 用来出snackbar的
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // formkey
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // 手机key 联动需要
  final GlobalKey<FormFieldState<String>> _mobileKey =
      GlobalKey<FormFieldState<String>>();

  // 默认倒计时秒
  static const int verifySmsCountDownSeconds = 30;
  // 倒计时控制器
  AnimationController _controller;
  // 是否能发送短消息
  bool sendAble = true;

  String name = "";
  String mobile = "";
  DateTime birthday = DateTime.parse("1990-01-01");
  bool gender = false;
  bool mobileVerify = false;
  String verifyCode;

  // 是否表单修改过
  bool _formChanged = false;
  // 自动校验 默认关闭 只有在校验过一次之后才自动打开
  bool _autoValidate = false;

  // snackbar 提示
  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(value)));
  }

  // 发送验证码
  void _sendVerify() {
    // 如果手机号码合法
    if (_mobileKey.currentState.validate()) {
      _mobileKey.currentState.save();
      Request api = Request();
      api.req("/my/send_verify2", data: {"mobile": mobile}, auth: true,
          success: (res) {
        print(res);
      }).catchError((e) {
        showInSnackBar("发送验证码失败");
      });
      _controller.forward(from: 0.0);
    }
  }

  // 提交表单
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
      // 提交逻辑在这里处理 头像avatar没有传
      Map<String, dynamic> params = new Map();
      params['name'] = name;
      params['mobile'] = mobile;
      params['vcode'] = verifyCode;
      params['birthDay'] = DateFormat("yyyy-MM-dd").format(birthday);
      params['gender'] = gender ? 1 : 0;
      ;
      print(params);
      FormData formData = new FormData.from(params);
      Request api = Request();
      api.req('/my/update_profile2', auth: true, method: 'POST', data: formData,
          success: (res) {
        //print(res);
        // 把mask去掉
        Navigator.of(context).pop();
        // 回去list 要求刷新
        Navigator.of(context).pop(true);
      }, fail: (message) {
        // 把mask去掉
        Navigator.of(context).pop();
        showInSnackBar(message);
      });
    }
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

  @override
  void initState() {
    // 初始化数据
    name = widget.profile.name;
    mobileVerify = widget.profile.mobileVerify;
    gender = widget.profile.genderRaw;
    if (widget.profile.birthDay != null) {
      birthday = DateTime.parse(widget.profile.birthDay);
    }
    // 倒计时控制器初始化
    _controller = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: verifySmsCountDownSeconds),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          sendAble = true;
        });
      }
      if (status == AnimationStatus.forward) {
        setState(() {
          sendAble = false;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xfff8f8f8),
      appBar: AppBar(
        title: Text(
          "用户资料",
          style: TextStyle(fontSize: 16.0, color: Colors.white),
        ),
        elevation: 0.0,
        centerTitle: true,
        brightness: Brightness.dark,
        backgroundColor: Colors.blue,
      ),
      body: Form(
          key: _formKey,
          autovalidate: _autoValidate,
          onWillPop: _warnUserAboutInvalidData,
          onChanged: () {
            _formChanged = true;
            final FormState form = _formKey.currentState;
            form.save();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 30.0,
            ),
            child: SingleChildScrollView(
              child: Column(children: <Widget>[
                TextFormField(
                  textCapitalization: TextCapitalization.words,
                  initialValue: name,
                  decoration: InputDecoration(
                    isDense: true,
                    border: UnderlineInputBorder(),
                    icon: Icon(
                      Icons.person,
                      size: 24.0,
                    ),
                    hintText: '希望他人如何称呼您',
                    labelText: '昵称',
                  ),
                  validator: (String value) {
                    if (value.isEmpty) return '昵称不能为空！';
                    return null;
                  },
                  onSaved: (value) {
                    name = value;
                  },
                ),
                const SizedBox(height: 10.0),
                InputDecorator(
                  decoration: const InputDecoration(
                    icon: Icon(
                      Icons.spa,
                      size: 24.0,
                    ),
                    isDense: true,
                    labelText: "性别",
                    //contentPadding: EdgeInsets.zero,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<bool>(
                      value: gender,
                      onChanged: (bool newValue) {
                        setState(() {
                          gender = newValue;
                        });
                      },
                      items: Profile.UserGender.keys
                          .map<DropdownMenuItem<bool>>((bool key) {
                        return DropdownMenuItem<bool>(
                          value: key,
                          child: Text(
                            Profile.UserGender[key],
                            style: TextStyle(fontSize: 14.0),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                Theme(
                    data: Theme.of(context).copyWith(
                        primaryTextTheme:
                            TextTheme(display1: TextStyle(fontSize: 24.0))),
                    child: Builder(
                        builder: (context) => InkWell(
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: "生日",
                                  icon: Icon(
                                    Icons.today,
                                    size: 24.0,
                                  ),
                                  // contentPadding: EdgeInsets.all(5.0),
                                ),
                                child: Text(
                                  DateFormat("yyyy-MM-dd").format(birthday),
                                ),
                              ),
                              onTap: () async {
                                DateTime picked = await showDatePicker(
                                    context: context,
                                    locale: Locale('zh', 'CH'),
                                    initialDate: birthday,
                                    firstDate: DateTime(1900, 1),
                                    lastDate: DateTime.now());
                                if (picked != null && picked != birthday) {
                                  setState(() {
                                    birthday = picked;
                                  });
                                }
                              },
                            ))),
                const SizedBox(height: 10.0),
                mobileVerify
                    ? Container()
                    : TextFormField(
                        decoration: InputDecoration(
                          isDense: true,
                          border: UnderlineInputBorder(),
                          suffixIcon: FlatButton(
                            onPressed: sendAble ? _sendVerify : null,
                            child: sendAble
                                ? Text("验证码")
                                : new CountDown(
                                    animation: new StepTween(
                                            begin:
                                                verifySmsCountDownSeconds + 1,
                                            end: 1)
                                        .animate(_controller),
                                  ),
                          ),
                          icon: Icon(
                            Icons.phone,
                            size: 24.0,
                          ),
                          hintText: '请准确填写手机号码',
                          labelText: '手机',
                          prefixText: '+86',
                        ),
                        key: _mobileKey,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          WhitelistingTextInputFormatter.digitsOnly
                        ],
                        validator: (String value) {
                          return Validate.phone(value);
                        },
                        onSaved: (value) {
                          mobile = value;
                        },
                        initialValue: mobile,
                      ),
                mobileVerify ? Container() : const SizedBox(height: 10.0),
                mobileVerify
                    ? Container()
                    : TextFormField(
                        decoration: InputDecoration(
                          isDense: true,
                          border: UnderlineInputBorder(),
                          icon: Icon(
                            Icons.sms,
                            size: 24.0,
                          ),
                          hintText: '请输入收到的短信验证码',
                          labelText: '验证码',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          WhitelistingTextInputFormatter.digitsOnly
                        ],
                        validator: (String value) {
                          if (value.length != 4) return '验证码长度不对';
                          return null;
                        },
                        onSaved: (value) {
                          verifyCode = value;
                        },
                      ),
                const SizedBox(height: 30.0),
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
                      "更新个人资料",
                      style: TextStyle(color: Colors.white),
                    ),
                    color: Theme.of(context).primaryColor,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                ),
              ]),
            ),
          )),
    );
  }
}

// 倒计时控件
class CountDown extends AnimatedWidget {
  CountDown({Key key, this.animation}) : super(key: key, listenable: animation);
  final Animation<int> animation;

  @override
  build(BuildContext context) {
    return new Text(
      "${animation.value}秒",
      //style: new TextStyle(fontSize: 150.0),
    );
  }
}
