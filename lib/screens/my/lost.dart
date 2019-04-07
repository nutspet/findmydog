import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:find_dog/common/request.dart';
import 'package:find_dog/screens/lost/detail.dart';
import 'package:find_dog/models/dog_lost.dart';

// 失踪汪救助中心
class MyLost extends StatefulWidget {
  @override
  MyLostState createState() => new MyLostState();
}

class MyLostState extends State<MyLost> {
  // 用来控制snackbar
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 列表配置 小图后缀
  final String _listImgSuffix = "?imageView2/2/w/180/h/180/q/90/format/webp";

  // 列表数据
  List<DogLost> _myList = [];

  MyLostState() {
    _refreshList();
  }

  @override
  void initState() {
    super.initState();
  }

  // 加载列表
  void _refreshList({bool showSnack = true}) {
    Request api = Request();
    api.req("/my/lost2", auth: true, success: (res) {
      // 加载数据
      List list = res["result"];
      List<DogLost> apiList = list.map((e) {
        return new DogLost.fromJson(e);
      }).toList();
      setState(() {
        _myList = apiList;
      });
      if (showSnack) {
        _showSnack("数据加载完成！");
      }
    }, fail: (message) {
      _showSnack("错误：$message");
    });
  }

  // 确认找到
  void _confirmLost(int id) {
    Request api = Request();
    api.req("/my/confirm_lost2/$id", auth: true, success: (res) {
      _showSnack("确认找到成功！${res['uuid']}");
      _refreshList(showSnack: false);
    }).catchError((e) {
      print(e);
      _showSnack("确认找到出错！");
    });
  }

  // 提示
  void _showSnack(String txt) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(txt),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // 单条生成器
  Widget _rowBuilder(BuildContext context, int index, List<DogLost> list) {
    return ListTile(
      onTap: () {
        showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) {
            return CupertinoActionSheet(
                title: const Text('请注意！'),
                message: const Text('对失踪汪报告进行操作，一旦执行确认找到，首页列表将不再展示失踪汪报告！'),
                actions: <Widget>[
                  CupertinoActionSheetAction(
                    child: const Text('查看详情'),
                    onPressed: () {
                      print("view detail");
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        new MaterialPageRoute(
                          builder: (context) => new LostDetail(
                                dog: list[index],
                              ),
                        ),
                      );
                    },
                  ),
                  list[index].found
                      ? Container()
                      : CupertinoActionSheetAction(
                          child: const Text('确认找到'),
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmLost(list[index].id);
                          },
                        ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  child: const Text('取消'),
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ));
          },
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
                placeholder: (context, url) => CupertinoActivityIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              )
            : FlutterLogo(),
      ),
      title: Text(
        "${list[index].regionCity} ${list[index].locationName}附近 ${list[index].age}岁${list[index].color} ${list[index].breed}(${list[index].gender}) ${list[index].found ? '已找到' : '尚未找到'}",
        overflow: TextOverflow.fade,
        style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
            color: list[index].found ? Colors.grey : Colors.black87),
      ),
      subtitle: Row(
        children: <Widget>[
          Text("失踪时间 ${list[index].date} ${list[index].time}",
              style: TextStyle(
                fontSize: 12.0,
              )),
          Container(
            height: 16.0,
            width: 1.0,
            color: Colors.black12,
            margin: EdgeInsets.only(left: 5.0, right: 5.0),
          ),
          list[index].negotiate
              ? Text(
                  "面议",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12.0,
                  ),
                  overflow: TextOverflow.fade,
                )
              : Text(
                  "¥ ${list[index].reward}元",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12.0,
                  ),
                  overflow: TextOverflow.fade,
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            "我的失踪汪报告",
            style: TextStyle(fontSize: 16.0, color: Colors.black),
          ),
          elevation: 0.0,
          leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          brightness: Brightness.light,
          backgroundColor: Color(0xfff8f8f8),
        ),
        body: _myList.length != 0
            ? Padding(
                padding: EdgeInsets.all(5.0),
                child: ListView.separated(
                  itemCount: _myList.length,
                  separatorBuilder: (context, i) => new Divider(),
                  itemBuilder: (context, index) => _rowBuilder(
                        context,
                        index,
                        _myList,
                      ),
                ),
              )
            : Center(
                child: Text("暂无数据"),
              ));
  }
}
