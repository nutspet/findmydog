import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:find_dog/common/request.dart';
import 'package:find_dog/models/dog.dart';
import 'package:find_dog/models/dog_lost.dart';
import 'package:find_dog/models/location.dart';
import 'detail.dart';
import 'report.dart';

// 失踪汪救助中心
class LostList extends StatefulWidget {
  const LostList({super.key});

  @override
  LostListState createState() => LostListState();
}

// SingleTickerProviderStateMixin 用来做动画
class LostListState extends State<LostList> with SingleTickerProviderStateMixin {
  // TAB控制器（在 initState 里赋值，所以用 late）
  late TabController controller;

  // 用来控制snackbar
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 进度的菊花
  final GlobalKey<RefreshIndicatorState> _refreshLatestIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshTopIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshNearByIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // 列表配置 小图后缀
  final String _listImgSuffix = "?imageView2/2/w/180/h/180/q/90/format/webp";

  // 选项 没有es6的...展开方便
  List<String> dogGender = ["全部性别"]..addAll(DogLost.DogGender.values.toList());
  List<String> dogColor = ["全部颜色"]..addAll(Dog.DogColor);
  List<Map<String, List>> dogSizeBreed = [
    {
      '全部': ['全部品种'],
    }
  ]..addAll(Dog.DogSizeBreed);

  // drawer里面的彩蛋
  bool _lianDong = false;
  int _defaultPageSize = 25;

  // 最新失踪狗狗列表
  int _lostLatestPage = 1;
  int _lostLatestPageSize = 25;
  bool _lostLatestEnd = false;
  List<DogLost> _lostLatestList = [];

  // 最新选项
  static const _pickerExtra = "全部区域";
  String _lostLatestPickerText = _pickerExtra;
  String _lostLatestProvince = _pickerExtra;
  String _lostLatestCity = _pickerExtra;
  String _lostLatestArea = _pickerExtra;
  // 记录地区选择器上次的选中项，供 Picker 的 selecteds 复用（该能力目前在 UI 上是关掉的，
  // 所以只写不读；保留字段是为了随时能把 selecteds 打开）。
  // ignore: unused_field
  List<int> _lostLatestPicker = [0, 0, 0];
  int _lostLatestGender = 0;
  int _lostLatestColor = 0;
  int _lostLatestSize = 0;
  String _lostLatestSizeName = '全部';
  int _lostLatestBreed = 0;

  // 附近
  List<DogLost> _lostNearByList = [];

  //  悬赏最高狗狗列表
  int _lostTopPage = 1;
  int _lostTopPageSize = 25;
  bool _lostTopEnd = false;
  List<DogLost> _lostTopList = [];

  LostListState() {
    // 数据获取测试 第一次不出snack 舒服点
    _refreshLatest(showSnack: false);
    _refreshTop(showSnack: false);
  }

  @override
  void initState() {
    // 初始化TAB控制器
    controller = TabController(length: 3, vsync: this);
    // 加入监听 到了附近tab获取位置
    controller.addListener(() {
      if (controller.indexIsChanging && controller.index == 2) {
        _refreshNearBy(showSnack: false);
      }
    });
    super.initState();
  }

  Future<void>? _futureNearBy;

  // 处理地址位置
  // 因为没有load more 读取时间长 所以用future builder展示
  void _refreshNearBy({bool showSnack = true}) async {
    print("location");
//    double longitude = 121.4402864;
//    double latitude = 31.365503;
    try {
      final Position? position =
          await Geolocator.getLastKnownPosition();
      // 异步跑下次可以获取到（火并忘，避免阻塞主流程）
      Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).then((_) {}, onError: (Object e) {
        print("current position");
      });
      if (position == null) {
        _showSnack("获取位置失败！请稍后重试！");
        return;
      }
      print(position.longitude);
      print(position.latitude);
      Request api = Request();
      _futureNearBy = api.req("/lost/nearby2", data: {
        "longitude": position.longitude,
        "latitude": position.latitude
      }, success: (res) {
        // 加载数据
        List list = res["list"];
        List<DogLost> apiList = list.map((e) {
          return DogLost.fromJson(e);
        }).toList();
        this.setState(() {
          _lostNearByList = apiList;
          //_lostEnd = true;
          // 提示
          if (showSnack) {
            _showSnack("数据加载完成！");
          }
        });
      }, fail: (message) {
        _showSnack("错误：$message");
      });
    } catch (e) {
      _showSnack("获取位置失败！请稍后重试！");
    }
  }

  @override
  void dispose() {
    // Dispose of the Tab Controller
    controller.dispose();
    super.dispose();
  }

  // 获取最新迷路狗狗数据
  void _refreshLatest({bool reset = false, bool showSnack = true}) {
    if (reset) _lostLatestPage = 1;
    Request api = Request();
    Map<String, dynamic> data = {
      "page": _lostLatestPage++,
      "pageSize": _lostLatestPageSize,
    };
    if (_lostLatestColor != 0) {
      data["color"] = _lostLatestColor - 1;
    }
    if (_lostLatestGender != 0) {
      data["gender"] = _lostLatestGender - 1;
    }
    if (_lostLatestSize != 0) {
      data["size"] = _lostLatestSize - 1;
    }
    if (_lostLatestBreed != 0) {
      data["breed"] = _lostLatestBreed - 1;
    }
    if (_lostLatestProvince != _pickerExtra) {
      data["reionProvince"] = _lostLatestProvince;
    }
    if (_lostLatestCity != _pickerExtra) {
      data["regionCity"] = _lostLatestCity;
    }
    if (_lostLatestArea != _pickerExtra) {
      data["regionArea"] = _lostLatestArea;
    }

    print(data);

    // 增加一个返回值 可以让future builder使用起来
    api.req("/lost/latest2", data: data, success: (res) {
      // 加载数据
      List list = res["list"];
      List<DogLost> apiList = list.map((e) {
        return DogLost.fromJson(e);
      }).toList();
      this.setState(() {
        if (reset) {
          // 替换
          _lostLatestList = apiList;
        } else {
          // 合并
          _lostLatestList.addAll(apiList);
        }

        // 是否加载完毕
        _lostLatestEnd = res["list"].length < _lostLatestPageSize;
        //_lostEnd = true;
        // 提示
        if (showSnack) {
          _showSnack("数据加载完成！");
        }
      });
    }, fail: (message) {
      _showSnack("错误：$message");
    });
  }

  // 提示
  void _showSnack(String txt) {
    // ScaffoldState.showSnackBar 已在 Flutter 3.x 中移除，改用 ScaffoldMessenger。
    // 这里额外判断 mounted：LostListState 的构造函数里就会发起首次请求，
    // 回调返回时组件可能尚未挂载（或已被销毁）。
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(txt),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // 获取赏金最高狗狗数据
  void _refreshTop({bool reset = false, bool showSnack = true}) {
    if (reset) _lostTopPage = 1;
    Request api = Request();
    api.req("/lost/top_reward2", data: {
      "page": _lostTopPage++,
      "pageSize": _lostTopPageSize,
    }, success: (res) {
      // 加载数据
      List list = res["list"];
      List<DogLost> apiList = list.map((e) {
        return DogLost.fromJson(e);
      }).toList();
      this.setState(() {
        if (reset) {
          // 替换
          _lostTopList = apiList;
        } else {
          // 合并
          _lostTopList.addAll(apiList);
        }

        // 是否加载完毕
        _lostTopEnd = res["list"].length < _lostTopPageSize;
        // 提示
        if (showSnack) {
          _showSnack("数据加载完成！");
        }
      });
    }, fail: (message) {
      _showSnack("错误：$message");
    });
  }

  // 获得tabbar
  TabBar getTabBar() {
    return TabBar(
      labelColor: Theme.of(context).secondaryHeaderColor,
      unselectedLabelColor: Theme.of(context).secondaryHeaderColor,
      labelStyle: const TextStyle(
        fontSize: 14.0,
      ),
      tabs: const <Tab>[
        Tab(
          // set icon to the tab
          text: "最新发布",
        ),
        Tab(
          text: "悬赏最高",
        ),
        Tab(
          text: "附近",
        ),
      ],
      // setup the controller
      controller: controller,
    );
  }

  // 获得tabview本体
  TabBarView getTabBarView(List<Tab> tabs) {
    return TabBarView(
      // Add tabs as widgets
      children: tabs,
      // set the controller
      controller: controller,
    );
  }

  // 生成单条数据的回调
  // 追求MD的风格用loadmore的按钮 思考了很久
  // "上海市 闸北区第一中学小学附近 2岁黑色 卡哇伊（公）"
  Widget _rowBuilder(BuildContext context, int index, List<DogLost> list,
      bool end, VoidCallback? onPress) {
    if (index == list.length) {
      return Container(
        width: 60.0,
        padding: const EdgeInsets.all(10.0),
        child: ElevatedButton.icon(
          onPressed: end ? null : onPress,
          label: end ? const Text("已到最底部") : const Text("加载更多数据"),
          icon: end ? const Icon(Icons.done) : const Icon(Icons.expand_more),
        ),
      );
    } else {
      return ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LostDetail(
                dog: list[index],
              ),
            ),
          );
        },
        isThreeLine: true,
        dense: true,
        leading: Container(
          width: 60.0,
          height: 60.0,
          child: list[index].pic.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: "${list[index].pic[0].link}$_listImgSuffix",
                  placeholder: (context, url) =>
                      const CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                )
              : const FlutterLogo(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 5.0, top: 1.0),
          child: Text(
            "${list[index].regionCity} ${list[index].locationName}附近 ${list[index].age}岁${list[index].color} ${list[index].breed}(${list[index].gender})",
            overflow: TextOverflow.fade,
            style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
        ),
        subtitle: Row(
          children: <Widget>[
            Text("失踪时间 ${list[index].date} ${list[index].time}",
                style: const TextStyle(
                  fontSize: 12.0,
                )),
            Container(
              height: 16.0,
              width: 1.0,
              color: Colors.black12,
              margin: const EdgeInsets.only(left: 5.0, right: 5.0),
            ),
            list[index].negotiate
                ? const Text(
                    "面议",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12.0,
                    ),
                    overflow: TextOverflow.fade,
                  )
                : Text(
                    "¥ ${list[index].reward}",
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12.0,
                    ),
                    overflow: TextOverflow.fade,
                  ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Picker locationPicker = Picker(
        adapter:
            PickerDataAdapter<String>(pickerData: convertPickerData(locations)),
        changeToFirst: true,
        textAlign: TextAlign.left,
        confirmText: "确认",
        cancelText: "取消",
        columnPadding: const EdgeInsets.all(8.0),
        // selecteds: _lostLatestPicker,
        onConfirm: (Picker picker, List<int> value) {
          print(value.toString());
          print(picker.getSelectedValues());

          setState(() {
            _lostLatestProvince = picker.getSelectedValues()[0];
            _lostLatestCity = picker.getSelectedValues()[1];
            _lostLatestArea = picker.getSelectedValues()[2];
            _lostLatestPicker = value;
            // 展示字的逻辑
            if (_lostLatestArea == _pickerExtra) {
              if (_lostLatestCity == _pickerExtra) {
                _lostLatestPickerText = _lostLatestProvince;
              } else {
                _lostLatestPickerText = _lostLatestCity;
              }
            } else {
              _lostLatestPickerText = _lostLatestArea;
            }

            _refreshLatest(reset: true);
          });
        });
    // print(MediaQuery.of(context));
    return Scaffold(
        key: _scaffoldKey,
        body: getTabBarView(<Tab>[
          Tab(
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          // 三级联动地区选择
                          locationPicker.showModal(context);
                        },
                        child: Text(
                          _lostLatestPickerText,
                          style: const TextStyle(
                              fontSize: 12.0, color: Colors.black54),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Picker(
                              adapter: PickerDataAdapter<String>(
                                  pickerData: dogSizeBreed),
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
                                  _lostLatestSize = value[0];
                                  _lostLatestSizeName =
                                      picker.getSelectedValues()[0];
                                  _lostLatestBreed = value[1];
                                  _refreshLatest(reset: true);
                                });
                              }).showModal(context);
                        },
                        child: Text(
                          '${dogSizeBreed[_lostLatestSize][_lostLatestSizeName]?[_lostLatestBreed] ?? ''}',
                          style: const TextStyle(
                              fontSize: 12.0, color: Colors.black54),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Picker(
                              adapter: PickerDataAdapter<String>(
                                  pickerData: [dogColor], isArray: true),
                              // hideHeader: false,
                              selecteds: [_lostLatestColor],
                              confirmText: "确认",
                              cancelText: "取消",
                              // onSelect: ,
                              // title: Text("选择颜色"),
                              onConfirm: (Picker picker, List<int> value) {
                                print(value.toString());
                                print(picker.getSelectedValues());
                                setState(() {
                                  _lostLatestColor = value[0];
                                  _refreshLatest(reset: true);
                                });
                              }).showModal(context);
                        },
                        child: Text(
                          dogColor[_lostLatestColor],
                          style: const TextStyle(
                              fontSize: 12.0, color: Colors.black54),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Picker(
                              adapter: PickerDataAdapter<String>(
                                  pickerData: [dogGender], isArray: true),
                              // hideHeader: true,
                              selecteds: [_lostLatestGender],
                              confirmText: "确认",
                              cancelText: "取消",
                              // onSelect: ,
                              // title: Text("选择性别"),
                              onConfirm: (Picker picker, List<int> value) {
                                print(value.toString());
                                print(picker.getSelectedValues());
                                setState(() {
                                  _lostLatestGender = value[0];
                                  _refreshLatest(reset: true);
                                });
                              }).showModal(context);
                        },
                        child: Text(
                          dogGender[_lostLatestGender],
                          style: const TextStyle(
                              fontSize: 12.0, color: Colors.black54),
                        ),
                      ),
                    )
                  ],
                ),
                // 一定要撑开
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(5.0),
                    //color: Colors.red,
                    child: RefreshIndicator(
                      key: _refreshLatestIndicatorKey,
                      child: _lostLatestList.length != 0
                          ? ListView.separated(
                              // 这个pagestorage可以保持页面位置
                              key: const PageStorageKey<String>("LostLatestList"),
                              itemCount: _lostLatestList.length + 1,
                              separatorBuilder: (context, i) => const Divider(),
                              itemBuilder: (context, index) => _rowBuilder(
                                    context,
                                    index,
                                    _lostLatestList,
                                    _lostLatestEnd,
                                    _refreshLatest,
                                  ),
                            )
                          : Center(
                              child: OutlinedButton(
                                onPressed: () async =>
                                    _refreshLatest(reset: true),
                                child: const Text("没有数据，重新加载！"),
                              ),
                            ),
                      onRefresh: () async => _refreshLatest(reset: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Container(
              margin: const EdgeInsets.all(5.0),
              //color: Colors.red,
              child: RefreshIndicator(
                key: _refreshTopIndicatorKey,
                child: _lostTopList.length != 0
                    ? ListView.separated(
                        // 这个pagestorage可以保持页面位置
                        key: const PageStorageKey<String>("LostTopList"),
                        itemCount: _lostTopList.length + 1,
                        separatorBuilder: (context, i) => const Divider(),
                        itemBuilder: (context, index) => _rowBuilder(context,
                            index, _lostTopList, _lostTopEnd, _refreshTop),
                      )
                    : Center(
                        child: OutlinedButton(
                          onPressed: () async => _refreshTop(reset: true),
                          child: const Text("没有数据，重新加载！"),
                        ),
                      ),
                onRefresh: () async => _refreshTop(reset: true),
              ),
            ),
          ),
          Tab(
            child: Container(
              margin: const EdgeInsets.all(5.0),
              child: RefreshIndicator(
                key: _refreshNearByIndicatorKey,
                child: FutureBuilder<void>(
                  future:
                      _futureNearBy, // a previously-obtained Future<String> or null
                  builder:
                      (BuildContext context, AsyncSnapshot<void> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                        return const Text('获取位置中');
                      case ConnectionState.active:
                      case ConnectionState.waiting:
                        return const CupertinoActivityIndicator();
                      case ConnectionState.done:
                        if (snapshot.hasError) return const Text('Future错误');
                        return _lostNearByList.length != 0
                            ? ListView.separated(
                                // 这个pagestorage可以保持页面位置
                                key: const PageStorageKey<String>(
                                    "LostNearByList"),
                                itemCount: _lostNearByList.length,
                                separatorBuilder: (context, i) =>
                                    const Divider(),
                                itemBuilder: (context, index) => _rowBuilder(
                                    context,
                                    index,
                                    _lostNearByList,
                                    true,
                                    null),
                              )
                            : Center(
                                child: OutlinedButton(
                                  onPressed: () async => _refreshNearBy(),
                                  child: const Text("没有数据，重新加载！"),
                                ),
                              );
                    }
                  },
                ),
                onRefresh: () async => _refreshNearBy(),
              ),
            ),
          )
        ]),
        appBar: AppBar(
          title: getTabBar(),
          centerTitle: true,
//          actions: <Widget>[
//            Container(
//              child: IconButton(
//                icon: Icon(Icons.share),
//                onPressed: () {
//                  showDialog(
//                    context: context,
//                    builder: (_) => AlertDialog(
//                            title: Text("分享测试"),
//                            content: Text("领袖门徒测试中"),
//                            actions: <Widget>[
//                              TextButton(
//                                child: Text("取消"),
//                                onPressed: () {
//                                  Navigator.of(context).pop();
//                                },
//                              ),
//                              TextButton(
//                                child: Text("确定"),
//                                onPressed: () {
//                                  Navigator.of(context).pop();
//                                },
//                              )
//                            ]),
//                  );
//                },
//              ),
//              alignment: Alignment.centerLeft,
//              margin: const EdgeInsets.only(
//                right: 15.0,
//              ),
//            ),
//          ],
          // bottom: getTabBar(),
        ),
        // 设置放在这里
        drawer: Drawer(
          child: Container(
            color: Colors.white,
            child: ListView(
              children: <Widget>[
                Container(
                  height: 80.0,
                  margin: const EdgeInsets.all(0.0),
                  padding: const EdgeInsets.all(0.0),
                  child: DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                    child: const Text(
                      "系统设置",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text("重置列表"),
                  leading: const Icon(Icons.settings_backup_restore),
                  onTap: () {
                    _refreshLatest(reset: true, showSnack: false);
                    _refreshTop(reset: true, showSnack: false);
                    _showSnack("全部重置完毕！");
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.settings_remote),
                  title: const Text('单次请求条数'),
                  trailing: DropdownButton<int>(
                    value: _defaultPageSize,
                    isDense: true,
                    onChanged: (int? newValue) {
                      if (newValue == null) return;
                      _defaultPageSize = newValue;
                      _lostLatestPageSize = newValue;
                      _lostTopPageSize = newValue;
                      _refreshLatest(reset: true, showSnack: false);
                      _refreshTop(reset: true, showSnack: false);
                      _showSnack("设置成功（$newValue条单次），并且全部重置完毕！");
                      Navigator.pop(context);
                    },
                    items: <int>[25, 45, 80]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(
                          "$value条",
                          style: const TextStyle(fontSize: 12.0),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text("获取位置（GPS热身）"),
                  leading: const Icon(Icons.my_location),
                  onTap: () {
                    _showSnack("已请求GPS。");
                    Geolocator.getCurrentPosition(
                            locationSettings: const LocationSettings(
                                accuracy: LocationAccuracy.high))
                        .then((_) {
                      _showSnack("GPS热身完成");
                    }).catchError((e) {
                      _showSnack("GPS热身失败");
                    });
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  dense: true,
                  value: _lianDong,
                  onChanged: (value) {
                    setState(() {
                      _lianDong = value;
                    });
                  },
                  title: const Text("领袖门徒模式"),
                  secondary: const Icon(Icons.landscape),
                ),
//                SizedBox(
//                  height: 40.0,
//                ),
//                Center(
//                  child: Image(
//                    image: AssetImage("data_repo/img/logo/logo.png"),
//                    width: 100.0,
//                    height: 100.0,
//                  ),
//                )
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          elevation: 4.0,
          icon: const Icon(
            Icons.flash_on,
            size: 18.0,
          ),
          label: const Text(
            '立即发布',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
          ),
          onPressed: () async {
            ReportAction? result = await Navigator.push(
              context,
              MaterialPageRoute<ReportAction>(
                builder: (context) => LostReport(),
                fullscreenDialog: true,
              ),
            );
            print(result);
            // 如果新增成功了 刷新页面
            if (result == ReportAction.success) {
              _refreshLatest(reset: true, showSnack: false);
              _refreshTop(reset: true, showSnack: false);
              _showSnack("全部重置完毕！");
            }
          },
        ));
  }
}
