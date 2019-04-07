import 'package:flutter/material.dart';
import 'package:find_dog/models/dog_lost.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:find_dog/common/request.dart';
import 'package:flutter/cupertino.dart';
import 'contact.dart';
import 'map.dart';
import 'package:fluwx/fluwx.dart' as fluwx;

// 失踪狗狗详情
class LostDetail extends StatefulWidget {
  final DogLost dog;
  // 构造函数 pop的时候带参数过来
  LostDetail({
    @required this.dog, // 直接扔过来实例
  });

  @override
  createState() => new LostDetailState();
}

class LostDetailState extends State<LostDetail> {
  DogLost dog = new DogLost();

  @override
  void initState() {
    dog = widget.dog;
    super.initState();
  }

  // 没用
  void getDetail(int id) {
    Request api = Request();
    api.req("/lost/detail2/$id", success: (res) {
      setState(() {
        dog = DogLost.fromJson(res['result']);
      });
    });
  }

  // 微信小程序宣传
  void _showWxa() {
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          SimpleDialog(title: Text('特别说明'), children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text("该功能将直接调用手机上的微信打开我们寻狗小程序版本，生成精美海报的同时，更方便传播！"),
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
                    // 直接跳小程序
                    fluwx
                        .launchMiniProgram(
                      username: "gh_0c80acc3f473",
                      path: 'pages/lost/detail?id=${dog.id}',
                    )
                        .then((data) {
                          print(data);
                    });
                  },
                  icon: Icon(Icons.check),
                  label: Text("带我去看看吧！")),
              widthFactor: 0.9,
            )
          ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: new Color(0XFFf8f8f8),
      appBar: new AppBar(
        actions: <Widget>[
          Container(
            child: IconButton(icon: Icon(Icons.share), onPressed: _showWxa),
            margin: const EdgeInsets.only(
              right: 0.0,
            ),
          )
        ],
        title: new Text(
          '${dog.regionProvince}失踪汪详情',
          style: TextStyle(fontSize: 18.0),
        ),
      ),
      body: ListView(
        children: <Widget>[
          Card(
            elevation: 1.0,
            shape: RoundedRectangleBorder(),
            margin: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 10.0,
            ),
            child: Column(
              children: <Widget>[
                Container(
                  height: 330.0,
                  padding: EdgeInsets.all(20.0),
                  child: dog.pic.isNotEmpty
                      ? new Swiper(
                          itemBuilder: (BuildContext context, int index) {
                            return CachedNetworkImage(
                              imageUrl: dog.pic[index].link,
                              //placeholder: CupertinoActivityIndicator(),
                              //errorWidget: Icon(Icons.error),
                              fit: BoxFit.contain,
                            );
                          },
                          itemCount: dog.pic.length,
                          pagination: new SwiperPagination(
                            margin: EdgeInsets.symmetric(vertical: 0.0),
                          ),
                        )
                      : FlutterLogo(),
                ),
                Divider(
                  indent: 25.0,
                  color: Colors.grey.shade400,
                  height: 10.0,
                ),
                Column(
                  children: <Widget>[
                    SizedBox(
                      height: 5.0,
                    ),
                    Container(
                      child: Wrap(
                        children: <Widget>[
                          Container(
                            decoration: ShapeDecoration(
                              color: Color(0xff23c6c8),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8.0))),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 2.0, horizontal: 10.0),
                            margin: EdgeInsets.all(2.0),
                            child: Text(
                              "${dog.color} | ${dog.breed} | ${dog.age}岁 | ${dog.gender} | ${dog.weight}公斤",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            decoration: ShapeDecoration(
                              color: Color(0xff1c84c6),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8.0))),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 2.0, horizontal: 10.0),
                            margin: EdgeInsets.all(2.0),
                            child: Text(
                              "${dog.regionCity}-${dog.regionArea}",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            decoration: ShapeDecoration(
                              color: Color(0xff1ab394),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8.0))),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 2.0, horizontal: 10.0),
                            margin: EdgeInsets.all(2.0),
                            child: Text(
                              "走失时间 ${dog.date}${dog.time}",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 15.0),
                    ),
                    SizedBox(
                      height: 10.0,
                    )
                  ],
                )
              ],
            ),
          ),
          Card(
            elevation: 1.0,
            shape: RoundedRectangleBorder(),
            margin: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 10.0,
            ),
            child: Column(
              children: <Widget>[
                Container(
                  child: Text(
                    dog.found
                        ? "狗狗已找到"
                        : (dog.negotiate ? "赏金：面议" : "赏金：${dog.reward}元"),
                    style:
                        TextStyle(fontSize: 15.0, fontWeight: FontWeight.w900),
                  ),
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.only(
                    left: 12.0,
                    top: 12.0,
                    bottom: 3.0,
                  ),
                ),
                Divider(
                  indent: 25.0,
                  color: Colors.grey.shade400,
                  height: 10.0,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
                  child: Text(
                    dog.remark,
                    textAlign: TextAlign.justify,
                    style: TextStyle(fontSize: 14.0),
                  ),
                ),
                Container(
                  child: Text(
                    "识别：${dog.uuid}",
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 10.0),
                  ),
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
                ),
                Divider(
                  indent: 25.0,
                  color: Colors.grey.shade400,
                  height: 10.0,
                ),
                ListTile(
                  dense: true,
                  title: Text(
                    "查看详细丢失地址",
                    style: TextStyle(color: Colors.indigo, fontSize: 14.0),
                  ),
                  leading: CircleAvatar(
                    radius: 14.0,
                    child: Icon(
                      Icons.search,
                      size: 20.0,
                    ),
                  ),
                  trailing: Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      new MaterialPageRoute(
                        builder: (context) => new LostMap(
                              locationAddress: dog.locationAddress,
                              locationName: dog.locationName,
                              locationLatitude: dog.locationLatitude,
                              locationLongitude: dog.locationLongitude,
                              regionArea: dog.regionArea,
                              regionCity: dog.regionCity,
                              regionProvince: dog.regionProvince,
                              date: dog.date,
                              time: dog.time,
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 10.0,
            ),
            child: RaisedButton.icon(
              onPressed: _showWxa,
              color: Theme.of(context).primaryColor,
              icon: Icon(
                Icons.build,
                color: Colors.white,
              ),
              label: Text(
                "一键生成寻狗启事",
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: RaisedButton.icon(
                    color: Colors.red,
                    onPressed: () {
                      Navigator.push(
                        context,
                        new MaterialPageRoute(
                          builder: (context) => new LostContact(
                                contactsGender: dog.contactsGender,
                                contactsMobile: dog.contactsMobile,
                                contactsName: dog.contactsName,
                                negotiate: dog.negotiate,
                                reward: dog.reward,
                              ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.phone,
                      color: Colors.white,
                    ),
                    label: Text(
                      "联系失主",
                      style: TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Expanded(
                  child: RaisedButton.icon(
                    color: Colors.red,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.home,
                      color: Colors.white,
                    ),
                    label: Text(
                      "返回首页",
                      style: TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  ),
                )
              ],
            ),
          ),
//          Card(
//              elevation: 1.0,
//              shape: RoundedRectangleBorder(),
//              margin: EdgeInsets.only(
//                left: 20.0,
//                right: 20.0,
//                top: 10.0,
//              ),
//              child: Column(
//                children: <Widget>[
//                  Container(
//                    child: Text(
//                      "最新留言（线索）",
//                      style: TextStyle(fontSize: 20.0),
//                    ),
//                    alignment: Alignment.centerLeft,
//                    margin: EdgeInsets.only(
//                      left: 15.0,
//                      top: 15.0,
//                      bottom: 5.0,
//                    ),
//                  ),
//                  Divider(
//                    indent: 25.0,
//                    color: Colors.grey.shade400,
//                    height: 10.0,
//                  ),
//                  ListTile(
//                    title: Text(
//                      "查看全部留言（线索）",
//                      style: TextStyle(color: Colors.indigo),
//                    ),
//                    leading: CircleAvatar(
//                      radius: 16.0,
//                      child: Icon(
//                        Icons.face,
//                        size: 24.0,
//                      ),
//                    ),
//                    trailing: Icon(Icons.keyboard_arrow_right),
//                  )
//                ],
//              )),
//          SizedBox(
//            height: 20.0,
//          ),
        ],
      ),
    );
  }
}
