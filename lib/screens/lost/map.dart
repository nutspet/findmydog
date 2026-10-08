import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:find_dog/common/constants.dart';

const mapKey = Constants.amapWebKey;

class LostMap extends StatelessWidget {
  final String locationAddress;
  final String locationName;
  final String locationLatitude;
  final String locationLongitude;
  final String regionArea;
  final String regionCity;
  final String regionProvince;
  final String date;
  final String time;

  const LostMap({
    super.key,
    required this.locationName,
    required this.locationAddress,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.regionProvince,
    required this.regionArea,
    required this.regionCity,
    required this.time,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        title: const Text("失踪地点"),
      ),
      body: SafeArea(
        child: Column(children: <Widget>[
          const SizedBox(
            height: 60.0,
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: const Text(
              "详细失踪地点及地图",
              style: TextStyle(fontSize: 22.0),
            ),
          ),
          const SizedBox(
            height: 10.0,
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "失踪时间：$date $time",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(
            height: 1.0,
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "失踪地点：$regionProvince $regionCity $regionArea $locationAddress 附近",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(
            height: 20.0,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: CachedNetworkImage(
              imageUrl:
                  "https://restapi.amap.com/v3/staticmap?location=$locationLongitude,$locationLatitude&zoom=15&size=600*600&markers=large,,A:$locationLongitude,$locationLatitude&key=xxxxxxxxxx",
              placeholder: (context, url) => const CupertinoActivityIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          )
        ]),
      ),
    );
  }
}
