import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:find_dog/models/dog_lost.dart';

import 'detail.dart';

/// 列表里的单条失踪狗。
///
/// 视觉与改造前 `LostListState._rowBuilder` 的列表项分支**逐行一致**
/// （行高、字号、颜色、间距、占位图全部照搬），本次只是把它抽成独立组件、
/// 并把原来的 `list[index]` 换成构造参数 [dog]。
class LostListItem extends StatelessWidget {
  const LostListItem({super.key, required this.dog});

  /// 列表配置 小图后缀
  static const String _listImgSuffix =
      "?imageView2/2/w/180/h/180/q/90/format/webp";

  final DogLost dog;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LostDetail(dog: dog),
          ),
        );
      },
      isThreeLine: true,
      dense: true,
      leading: Container(
        width: 60.0,
        height: 60.0,
        child: dog.pic.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: "${dog.pic[0].link}$_listImgSuffix",
                placeholder: (context, url) => const CupertinoActivityIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
            : const FlutterLogo(),
      ),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 5.0, top: 1.0),
        child: Text(
          "${dog.regionCity} ${dog.locationName}附近 ${dog.age}岁${dog.color} ${dog.breed}(${dog.gender})",
          overflow: TextOverflow.fade,
          style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
              color: Colors.black87),
        ),
      ),
      subtitle: Row(
        children: <Widget>[
          Text("失踪时间 ${dog.date} ${dog.time}",
              style: const TextStyle(
                fontSize: 12.0,
              )),
          Container(
            height: 16.0,
            width: 1.0,
            color: Colors.black12,
            margin: const EdgeInsets.only(left: 5.0, right: 5.0),
          ),
          dog.negotiate
              ? const Text(
                  "面议",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12.0,
                  ),
                  overflow: TextOverflow.fade,
                )
              : Text(
                  "¥ ${dog.reward}",
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
