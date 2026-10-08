import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class QuickStart extends StatefulWidget {
  const QuickStart({super.key});

  @override
  State<QuickStart> createState() => _QuickStartState();
}

class _QuickStartState extends State<QuickStart> {
  // webview_flutter 4.x 起，WebView 改为「控制器 + Widget」两段式：
  // 控制器只创建一次（initState），Widget 侧仅做渲染
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      // 该页面是 React 单页应用（<div id="ice-container"> + /js/index.js），
      // 不开启 JavaScript 会渲染成整页空白，因此这里必须打开
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("https://h5.91xungou.com/#/howtouse"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "快速入门",
          style: TextStyle(fontSize: 16.0, color: Colors.black),
        ),
        elevation: 0.0,
        leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        // AppBar.brightness 已在 Flutter 3.x 移除，改用 systemOverlayStyle
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: const Color(0xfff8f8f8),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
