import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  LostMap({
    this.locationName,
    this.locationAddress,
    this.locationLatitude,
    this.locationLongitude,
    this.regionProvince,
    this.regionArea,
    this.regionCity,
    this.time,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff8f8f8),
      appBar: AppBar(
        title: Text("失踪地点"),
      ),
      body: SafeArea(
        child: Column(children: <Widget>[
          SizedBox(
            height: 60.0,
          ),
          Container(
            child: Text(
              "详细失踪地点及地图",
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
              "失踪时间：$date $time",
              style: TextStyle(color: Colors.grey),
            ),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 40.0),
          ),
          SizedBox(
            height: 1.0,
          ),
          Container(
            child: Text(
              "失踪地点：$regionProvince $regionCity $regionArea $locationAddress 附近",
              style: TextStyle(color: Colors.grey),
            ),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 40.0),
          ),
          SizedBox(
            height: 20.0,
          ),
          Container(
            child: CachedNetworkImage(
              imageUrl:
                  "https://restapi.amap.com/v3/staticmap?location=$locationLongitude,$locationLatitude&zoom=15&size=600*600&markers=large,,A:$locationLongitude,$locationLatitude&key=xxxxxxxxxx",
              placeholder: (context, url) => CupertinoActivityIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
            padding: EdgeInsets.symmetric(horizontal: 40.0),
          )
        ]),
      ),
    );
  }
}
