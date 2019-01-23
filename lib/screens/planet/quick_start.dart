import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class QuickStart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "快速入门",
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
      body: WebView(
        initialUrl: "https://h5.91xungou.com/#/howtouse",
        javaScriptMode: JavaScriptMode.unrestricted, // 默认关闭 要打开
        onWebViewCreated: (_) {
          // print("test");
        },
      ),
    );
  }
}
