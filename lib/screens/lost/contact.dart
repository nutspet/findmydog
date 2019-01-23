import 'package:flutter/material.dart';

class LostContact extends StatelessWidget {
  final bool negotiate;
  final int reward;
  final String contactsName;
  final String contactsGender;
  final contactsMobile;

  LostContact(
      {this.contactsName,
      this.contactsMobile,
      this.negotiate,
      this.reward,
      this.contactsGender});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff8f8f8),
      appBar: AppBar(
        title: Text("联系方式"),
      ),
      body: SafeArea(
          child: Column(
        children: <Widget>[
          SizedBox(
            height: 60.0,
          ),
          Container(
            child: Text(
              "失主联系方式",
              style: TextStyle(fontSize: 22.0),
            ),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 40.0),
          ),
          SizedBox(
            height: 10.0,
          ),
          Container(
            child: Text(
              "帮助狗狗回家，立即拨打电话联系失主。",
              style: TextStyle(color: Colors.grey),
            ),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 40.0),
          ),
          SizedBox(
            height: 30.0,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 30.0),
            child: Table(
                border: TableBorder(
                  top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.0,
                      style: BorderStyle.solid),
                  bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.0,
                      style: BorderStyle.solid),
                ),
                children: [
                  TableRow(
                    children: [
                      Container(
                        child: Text("目标赏金"),
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                      ),
                      Container(
                        child: Text(
                          negotiate ? "面议" : "$reward元",
                          textAlign: TextAlign.right,
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                      )
                    ],
                  ),
                  TableRow(
                    children: [
                      Container(
                        child: Text("失主姓名"),
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                      ),
                      Container(
                        child: Text(
                          "$contactsName（$contactsGender）",
                          textAlign: TextAlign.right,
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                      )
                    ],
                  ),
                  TableRow(
                    children: [
                      Container(
                        child: Text("联系方式"),
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                      ),
                      Container(
                        child: Text(
                          "$contactsMobile",
                          textAlign: TextAlign.right,
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                      )
                    ],
                  )
                ]),
          ),
          SizedBox(
            height: 30.0,
          ),
//          Container(
//            child: RaisedButton.icon(
//                onPressed: () async {
//                  String url = "tel://$contactsMobile";
//                  print(url);
//                  if (await canLaunch(url)) {
//                    await launch(url);
//                  } else {
//                    throw 'Could not launch $url';
//                  }
//                },
//                icon: Icon(Icons.phone_iphone),
//                label: Text("拨打电话")),
//          ),
//          SizedBox(
//            height: 30.0,
//          ),
          Container(
            child: Text(
              "注意：此信息目的在于流传更多信息，与本平台立场无关。内容来自平台使用者，不保证该信息（包含但不限于文字、图片、图表及数据）的准确性、真实性、完整性、有效性、实时性、原创性等。",
              //style: TextStyle(color: Colors.grey),
            ),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 60.0),
          ),
        ],
      )),
    );
  }
}
