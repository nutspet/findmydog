import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:find_dog/common/request.dart';
import 'package:find_dog/models/profile.dart';
import 'package:find_dog/utils/validate.dart';

class MyProfile extends StatefulWidget {
  final Profile profile;

  // 构造传递进来 扔给state
  const MyProfile({super.key, required this.profile});

  @override
  MyProfileState createState() => MyProfileState();
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
  // 倒计时控制器（initState 里初始化，所以用 late）
  late AnimationController _controller;
  // 是否能发送短消息
  bool sendAble = true;

  String name = "";
  String mobile = "";
  DateTime birthday = DateTime.parse("1990-01-01");
  bool gender = false;
  bool mobileVerify = false;
  String verifyCode = '';

  // 是否表单修改过
  bool _formChanged = false;
  // 自动校验 默认关闭 只有在校验过一次之后才自动打开
  bool _autoValidate = false;

  // snackbar 提示
  void showInSnackBar(String value) {
    // ScaffoldState.showSnackBar 已在 Flutter 3.x 中移除，改用 ScaffoldMessenger。
    // mounted 判断用于替代旧写法里 `?.` 的空安全保护：异步回调返回时页面可能已销毁。
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  // 发送验证码
  void _sendVerify() {
    final FormFieldState<String>? mobileState = _mobileKey.currentState;
    // 如果手机号码合法
    if (mobileState != null && mobileState.validate()) {
      mobileState.save();
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
          return const Dialog(
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
      Map<String, dynamic> params = <String, dynamic>{};
      params['name'] = name;
      params['mobile'] = mobile;
      params['vcode'] = verifyCode;
      params['birthDay'] = DateFormat("yyyy-MM-dd").format(birthday);
      params['gender'] = gender ? 1 : 0;
      print(params);
      FormData formData = FormData.fromMap(params);
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

  @override
  void initState() {
    // 初始化数据
    name = widget.profile.name;
    mobileVerify = widget.profile.mobileVerify;
    gender = widget.profile.genderRaw;
    if (widget.profile.birthDay.isNotEmpty) {
      birthday = DateTime.parse(widget.profile.birthDay);
    }
    // 倒计时控制器初始化
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: verifySmsCountDownSeconds),
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
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        title: const Text(
          "用户资料",
          style: TextStyle(fontSize: 16.0, color: Colors.white),
        ),
        elevation: 0.0,
        centerTitle: true,
        // AppBar.brightness 已被移除，等价写法是设置状态栏图标风格
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.blue,
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
          autovalidateMode: _autoValidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          onChanged: () {
            _formChanged = true;
            final FormState? form = _formKey.currentState;
            form?.save();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 30.0,
            ),
            child: SingleChildScrollView(
              child: Column(children: <Widget>[
                TextFormField(
                  textCapitalization: TextCapitalization.words,
                  initialValue: name,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: UnderlineInputBorder(),
                    icon: Icon(
                      Icons.person,
                      size: 24.0,
                    ),
                    hintText: '希望他人如何称呼您',
                    labelText: '昵称',
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) return '昵称不能为空！';
                    return null;
                  },
                  onSaved: (String? value) {
                    name = value ?? '';
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
                      onChanged: (bool? newValue) {
                        if (newValue == null) return;
                        setState(() {
                          gender = newValue;
                        });
                      },
                      items: Profile.UserGender.keys
                          .map<DropdownMenuItem<bool>>((bool key) {
                        return DropdownMenuItem<bool>(
                          value: key,
                          child: Text(
                            Profile.UserGender[key] ?? '',
                            style: const TextStyle(fontSize: 14.0),
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
                    // TextTheme 的 display1 已废弃，对应新名 headlineMedium
                    data: Theme.of(context).copyWith(
                        primaryTextTheme: const TextTheme(
                            headlineMedium: TextStyle(fontSize: 24.0))),
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
                                DateTime? picked = await showDatePicker(
                                    context: context,
                                    locale: const Locale('zh', 'CH'),
                                    initialDate: birthday,
                                    firstDate: DateTime(1900, 1),
                                    lastDate: DateTime.now());
                                if (picked != null && picked != birthday) {
                                  setState(() {
                                    // picked 已被上面的 != null 提升为 DateTime，
                                    // 无需再用 `!`
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
                          border: const UnderlineInputBorder(),
                          suffixIcon: TextButton(
                            onPressed: sendAble ? _sendVerify : null,
                            child: sendAble
                                ? const Text("验证码")
                                : CountDown(
                                    animation: StepTween(
                                            begin:
                                                verifySmsCountDownSeconds + 1,
                                            end: 1)
                                        .animate(_controller),
                                  ),
                          ),
                          icon: const Icon(
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
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (String? value) {
                          return Validate.phone(value ?? '');
                        },
                        onSaved: (String? value) {
                          mobile = value ?? '';
                        },
                        initialValue: mobile,
                      ),
                mobileVerify ? Container() : const SizedBox(height: 10.0),
                mobileVerify
                    ? Container()
                    : TextFormField(
                        decoration: const InputDecoration(
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
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (String? value) {
                          if (value == null || value.length != 4) {
                            return '验证码长度不对';
                          }
                          return null;
                        },
                        onSaved: (String? value) {
                          verifyCode = value ?? '';
                        },
                      ),
                const SizedBox(height: 30.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton.icon(
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
                      "更新个人资料",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ]),
            ),
          )),
    );
  }
}

// 倒计时控件
class CountDown extends AnimatedWidget {
  const CountDown({super.key, required this.animation})
      : super(listenable: animation);
  final Animation<int> animation;

  @override
  Widget build(BuildContext context) {
    return Text(
      "${animation.value}秒",
      //style: new TextStyle(fontSize: 150.0),
    );
  }
}
