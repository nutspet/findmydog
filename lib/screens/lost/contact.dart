import 'package:flutter/material.dart';

class LostContact extends StatelessWidget {
  final bool negotiate;
  final int reward;
  final String contactsName;
  final String contactsGender;
  final String contactsMobile;

  const LostContact({
    super.key,
    required this.contactsName,
    required this.contactsMobile,
    required this.negotiate,
    required this.reward,
    required this.contactsGender,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        title: const Text("联系方式"),
      ),
      body: SafeArea(
          child: Column(
        children: <Widget>[
          const SizedBox(
            height: 60.0,
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: const Text(
              "失主联系方式",
              style: TextStyle(fontSize: 22.0),
            ),
          ),
          const SizedBox(
            height: 10.0,
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: const Text(
              "帮助狗狗回家，立即拨打电话联系失主。",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(
            height: 30.0,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30.0),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                        child: const Text("目标赏金"),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                        child: Text(
                          negotiate ? "面议" : "$reward元",
                          textAlign: TextAlign.right,
                        ),
                      )
                    ],
                  ),
                  TableRow(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                        child: const Text("失主姓名"),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                        child: Text(
                          "$contactsName（$contactsGender）",
                          textAlign: TextAlign.right,
                        ),
                      )
                    ],
                  ),
                  TableRow(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                        child: const Text("联系方式"),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                        child: Text(
                          "$contactsMobile",
                          textAlign: TextAlign.right,
                        ),
                      )
                    ],
                  )
                ]),
          ),
          const SizedBox(
            height: 30.0,
          ),
//          Container(
//            child: ElevatedButton.icon(
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
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 60.0),
            child: const Text(
              "注意：此信息目的在于流传更多信息，与本平台立场无关。内容来自平台使用者，不保证该信息（包含但不限于文字、图片、图表及数据）的准确性、真实性、完整性、有效性、实时性、原创性等。",
              //style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      )),
    );
  }
}
