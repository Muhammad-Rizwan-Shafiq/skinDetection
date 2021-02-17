import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_cities_time/api/api_keys.dart';
import 'package:my_cities_time/api/http_exception.dart';
import 'package:my_cities_time/api/weather_api_client.dart';
import 'package:my_cities_time/bloc/weather_bloc.dart';
import 'package:my_cities_time/bloc/weather_event.dart';
import 'package:my_cities_time/bloc/weather_state.dart';
import 'package:my_cities_time/models/weather.dart' as weather;
import 'package:my_cities_time/repository/weather_repository.dart';
import 'package:my_cities_time/screens/Travel.dart';
import 'package:my_cities_time/screens/blog.dart';
import 'package:my_cities_time/screens/the_protection_shop.dart';
import 'package:my_cities_time/screens/the_skin_lab.dart';
import 'package:my_cities_time/screens/weather_screen.dart';
import 'package:my_cities_time/states/authstate.dart';
import 'package:my_cities_time/utils/WeatherIconMapper.dart';
import 'package:my_cities_time/utils/constants.dart';
import 'package:my_cities_time/widgets/weather_widget.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;
import 'package:weather/weather.dart';

import '../main.dart';

class Location extends StatefulWidget {
  final WeatherRepository weatherRepository = WeatherRepository(
      weatherApiClient: WeatherApiClient(
          httpClient: http.Client(), apiKey: ApiKey.OPEN_WEATHER_MAP));

  @override
  _LocationState createState() => _LocationState();
}

class _LocationState extends State<Location> {
  bool loader = false;
  String weather_temp, weather_desc, weather_icon, uvi_index;
  WeatherBloc _weatherBloc;
  String _cityName = 'karachi';

  _fetchWeatherWithLocation() async {
    var permissionHandler = PermissionHandler();
    var permissionResult = await permissionHandler
        .requestPermissions([PermissionGroup.locationWhenInUse]);

    switch (permissionResult[PermissionGroup.locationWhenInUse]) {
      case PermissionStatus.denied:
      case PermissionStatus.unknown:
        print('location permission denied');
        _showLocationDeniedDialog(permissionHandler);
        throw Error();
    }
    setState(() {
      loader = true;
    });
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.low);

    await getweather(position);

   await (onecallweatherdata(
          latitude: position.latitude, longitude: position.longitude));

    // _weatherBloc.dispatch(FetchWeather(
    //     longitude: position.longitude, latitude: position.latitude));
  }

  void _showLocationDeniedDialog(PermissionHandler permissionHandler) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Location is disabled :(',
                style: TextStyle(color: Colors.black)),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  'Enable!',
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
                onPressed: () {
                  permissionHandler.openAppSettings();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  getweather(Position position) async {
    WeatherFactory wf = new WeatherFactory(ApiKey.OPEN_WEATHER_MAP);
    Weather weather = await wf.currentWeatherByLocation(
        position.latitude, position.longitude);
    setState(() {
      weather_temp = weather.temperature.celsius.toString();
      weather_desc = weather.weatherDescription;
      weather_icon = weather.weatherIcon;
      loader = false;
    });
  }

  Future<String> onecallweatherdata({double latitude, double longitude}) async {
    final url =
        '${ApiKey.baseUrl}/data/2.5/onecall?lat=$latitude&lon=$longitude&appid=${ApiKey.OPEN_WEATHER_MAP}';
    print('fetching $url');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw HTTPException(res.statusCode, "unable to fetch weather data");
    }
    final weatherJson = json.decode(res.body);
    setState(() {
      uvi_index=weatherJson['current']['uvi'].toString();
    });
    return weatherJson['current']['uvi'].toString();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _weatherBloc = WeatherBloc(weatherRepository: widget.weatherRepository);
    _fetchWeatherWithLocation().catchError((error) {
      // _fetchWeatherWithCity();
    });
  }

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<AuthState>(context, listen: false);
    _cityName = state.skin == null ? "karachi" : state.skin.city;
    return Scaffold(
        drawer: ClipRRect(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(35), bottomRight: Radius.circular(35)),
          child: Drawer(
            child: ListView(padding: EdgeInsets.all(0.0), children: <Widget>[
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: fontOrange),

                currentAccountPicture: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          fit: BoxFit.fill,
                          image: AssetImage(
                            "assets/images/photo.jpg",
                          ))),
                ),

// decoration: BoxDecoration(
//   color: fontOrange
// ),

                accountName: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.userModel == null ? '' : state.userModel.username,
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          fontSize: 22.0),
                    ),
                  ],
                ),
                arrowColor: Colors.transparent,

                // currentAccountPicture: CircleAvatar(
                //
                //   backgroundImage: AssetImage("assets/images/img.jpeg"),
                //   backgroundColor: Colors.transparent,
                //   radius: 30,
                // ),
                onDetailsPressed: () {},
              ),
              SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TheSkinLab(),
                      ));
                },
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                      'The Skin Lab',
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 20,
                          color: white,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
              ),
              Divider(
                color: white,
                thickness: 0.5,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Location(),
                      ));
                },
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                      'Location',
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 20,
                          color: white,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
              ),
              Divider(
                color: white,
                thickness: 0.5,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Travel(),
                      ));
                },
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                      'Travel',
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 20,
                          color: white,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
              ),
              Divider(
                color: white,
                thickness: 0.5,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TheProtectionShop(),
                      ));
                },
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                      'The Protection Shop',
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 20,
                          color: white,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
              ),
              Divider(
                color: white,
                thickness: 0.5,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Blog(),
                      ));
                },
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                      'Blog Section',
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 20,
                          color: white,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
              ),
              Divider(
                color: white,
                thickness: 0.5,
              ),
            ]),
          ),
        ),
        body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/bggg.png"),
                    fit: BoxFit.fill,
                  ),
                ),
                child: loader
                    ? SpinKitRipple(
                  color: fontOrange,
                  size: 40,
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 100, left: 40, right: 8),
                      child: Text(
                        "Location",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 32,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: Text(
                        state.skin == null ? "" : state.skin.city,
                        style: TextStyle(
                            color: fontOrange,
                            fontSize: 32,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => WeatherScreen()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 12.0, right: 12.0, bottom: 5),
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.23,
                                child: Card(
                                    color: cardColor,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          bottomRight: Radius.circular(15),
                                          topRight: Radius.circular(15),
                                          topLeft: Radius.circular(15),
                                          bottomLeft: Radius.circular(15)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 20.0,
                                          left: 30,
                                          bottom: 20,
                                          right: 20),
                                      child: Row(
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "UV Index : ",
                                                    style: TextStyle(
                                                        color: fontOrange,
                                                        fontFamily: "Poppins",
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 16),
                                                  ),
                                                  //state.skin==null?"":state.skin.uv_level
                                                  Text(
                                                    uvi_index == null
                                                        ? ""
                                                        : uvi_index,
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontFamily: "Poppins",
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Temperature : ",
                                                    style: TextStyle(
                                                        color: fontOrange,
                                                        fontFamily: "Poppins",
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 16),
                                                  ),
                                                  Text(
                                                    weather_temp==null?"":weather_temp + "",
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontFamily: "Poppins",
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Weather : ",
                                                    style: TextStyle(
                                                        color: fontOrange,
                                                        fontFamily: "Poppins",
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 16),
                                                  ),
                                                  Text(
                                                   weather_desc==null?"": weather_desc + "",
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontFamily: "Poppins",
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                              // SizedBox(
                                              //   height: 5,
                                              // ),
                                              // Row(
                                              //   children: [
                                              //     Text(
                                              //       "Peak UVI Time : ",
                                              //       style: TextStyle(
                                              //           color: fontOrange,
                                              //           fontFamily: "Poppins",
                                              //           fontWeight:
                                              //               FontWeight.w700,
                                              //           fontSize: 16),
                                              //     ),
                                              //     Text(
                                              //       "2:10 PM",
                                              //       style: TextStyle(
                                              //           color: Colors.black,
                                              //           fontFamily: "Poppins",
                                              //           fontWeight:
                                              //               FontWeight.w700,
                                              //           fontSize: 16),
                                              //     ),
                                              //   ],
                                              // ),
                                            ],
                                          ),
                                          Icon(
                                            getIconData(weather_icon),
                                            color: Colors.black,
                                            size: 70,
                                          ),
                                          // Image.asset(
                                          //   'assets/images/sun.png',
                                          //   width: 100,
                                          //   height: 100,
                                          //   fit: BoxFit.cover,
                                          // ),
                                        ],
                                      ),
                                    )),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 12.0, right: 12.0, bottom: 5),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.24,
                              child: Card(
                                  color: cardColor,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                        topLeft: Radius.circular(15),
                                        bottomLeft: Radius.circular(15)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20.0,
                                        left: 30,
                                        bottom: 20,
                                        right: 20),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "👨  Your Skin Type : ",
                                              style: TextStyle(
                                                  color: fontOrange,
                                                  fontFamily: "Poppins",
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16),
                                            ),
                                            Container(
                                              width: 40.0,
                                              height: 20.0,
                                              child: Container(
                                                decoration: new BoxDecoration(
                                                  color: state.skin == null
                                                      ? Colors.transparent
                                                      : Color(int.parse(state
                                                          .skin.skincolor
                                                          .replaceAll(
                                                              '#', '0xff'))),
                                                  shape: BoxShape.rectangle,
                                                ),
                                              ),
                                            ),
                                            // Text("no. "+(state.skin==null?"":state.skin.skintype),style: TextStyle(
                                            //     color: Colors.black,
                                            //     fontFamily: "Poppins",
                                            //     fontWeight: FontWeight.w700,
                                            //     fontSize: 16),),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "💪  Time To Sunburn : ",
                                              style: TextStyle(
                                                  color: fontOrange,
                                                  fontFamily: "Poppins",
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 17),
                                            ),
                                            Text(
                                              "${state.skin == null ? "" : state.skin.recommended_timing}",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontFamily: "Poppins",
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 17),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "⏰  SPF : ",
                                              style: TextStyle(
                                                  color: fontOrange,
                                                  fontFamily: "Poppins",
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 17),
                                            ),
                                            Text(
                                              (state.skin == null
                                                  ? ""
                                                  : state.skin.spf),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontFamily: "Poppins",
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 17),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),

                          Padding(
                            padding: const EdgeInsets.only(
                                top: 12.0, bottom: 12.0, right: 40, left: 40),
                            child: Container(
                              height: 50,
                              width: 70,
                              child: RaisedButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                onPressed: () {_showIntDialog();},
                                color: fontOrange,
                                textColor: Colors.white,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.alarm),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text("Set Up Your UV Alarm",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: "Poppins")),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 3.0, bottom: 12.0, right: 40, left: 40),
                            child: Container(
                              height: 50,
                              width: 70,
                              child: RaisedButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                onPressed: () {
                                  Time notificationtime=Time(23,8,0);
                                  const AndroidNotificationDetails androidPlatformChannelSpecifics =
                                  AndroidNotificationDetails(
                                      'your channel id', 'your channel name', 'your channel description',
                                      importance: Importance.max,
                                      priority: Priority.high,
                                      showWhen: false);
                                  const NotificationDetails platformChannelSpecifics =
                                  NotificationDetails(android: androidPlatformChannelSpecifics);
                                  flutterLocalNotificationsPlugin.showDailyAtTime(0, "testing","testing", notificationtime,platformChannelSpecifics);
                                   AndroidAlarmManager.periodic(
    const Duration(seconds: 5),
    // Ensure we have a unique alarm ID.
    Random().nextInt(pow(2, 31).toInt()),
    printHello,
    );

                                },
                                color: fontOrange,
                                textColor: Colors.white,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [

                                    Text("Set up sunscreen Reminder",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: "Poppins")),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 25.0, right: 12.0, bottom: 5, top: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "NOTE : ",
                                  style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.w700),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    Container(
                                      height: 10.0,
                                      width: 10.0,
                                      decoration: new BoxDecoration(
                                        color: fontOrange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      "Reapply Every ${(state.skin == null ? "" : state.skin.recommended_timing)} minutes",
                                      style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                                Container(
                                    margin: const EdgeInsets.only(
                                        left: 20.0, right: 10.0),
                                    child: Divider(
                                      color: fontOrange,
                                      height: 10,
                                      thickness: 1.5,
                                    )),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    Container(
                                      height: 10.0,
                                      width: 10.0,
                                      decoration: new BoxDecoration(
                                        color: fontOrange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      "Choose Broad Spectrum Sunscream",
                                      style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                                Container(
                                    margin: const EdgeInsets.only(
                                        left: 20.0, right: 10.0),
                                    child: Divider(
                                      color: fontOrange,
                                      height: 10,
                                      thickness: 1.5,
                                    )),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    Container(
                                      height: 10.0,
                                      width: 10.0,
                                      decoration: new BoxDecoration(
                                        color: fontOrange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      "Choose Broad Spectrum Sunscream",
                                      style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 15,
                                ),

                                // Row(
                                //   children: [
                                //     Text(
                                //       "Risk For Skin Cancer",
                                //       style: TextStyle(
                                //         fontFamily: "Poppins",
                                //         fontWeight: FontWeight.w700,
                                //         color: fontOrange,
                                //         fontSize: 20,
                                //       ),
                                //     ),
                                //     SizedBox(
                                //       width: 10,
                                //     ),
                                //     Text(
                                //       ": ${state.skin == null ? "" : state.skin.cancer_risk}",
                                //       style: TextStyle(
                                //         fontFamily: "Poppins",
                                //         fontWeight: FontWeight.w700,
                                //         color: Colors.black,
                                //         fontSize: 20,
                                //       ),
                                //     ),
                                //   ],
                                // ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                    )
                  ],
                ),
              ));
  }

  IconData getIconData(String iconCode) {
    switch (iconCode) {
      case '01d':
        return WeatherIcons.clear_day;
      case '01n':
        return WeatherIcons.clear_night;
      case '02d':
        return WeatherIcons.few_clouds_day;
      case '02n':
        return WeatherIcons.few_clouds_day;
      case '03d':
      case '04d':
        return WeatherIcons.clouds_day;
      case '03n':
      case '04n':
        return WeatherIcons.clear_night;
      case '09d':
        return WeatherIcons.shower_rain_day;
      case '09n':
        return WeatherIcons.shower_rain_night;
      case '10d':
        return WeatherIcons.rain_day;
      case '10n':
        return WeatherIcons.rain_night;
      case '11d':
        return WeatherIcons.thunder_storm_day;
      case '11n':
        return WeatherIcons.thunder_storm_night;
      case '13d':
        return WeatherIcons.snow_day;
      case '13n':
        return WeatherIcons.snow_night;
      case '50d':
        return WeatherIcons.mist_day;
      case '50n':
        return WeatherIcons.mist_night;
      default:
        return WeatherIcons.clear_day;
    }
  }
  Future _showIntDialog() async {
    await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return new NumberPickerDialog.integer(
          minValue: 1,
          maxValue: 10,
          step: 1,
          initialIntegerValue: 1,
        );
      },
    ).then((num value) {
      // if (value != null) {
      //   setState(() => _currentIntValue = value);
      //   integerNumberPicker.animateInt(value);
      // }
    });
  }
  void printHello() {
    final DateTime now = DateTime.now();
    final int isolateId = Isolate.current.hashCode;
    print("[$now] Hello, world! isolate=${isolateId} function='$printHello'");
  }


}

class _IconData extends IconData {
  const _IconData(int codePoint)
      : super(
          codePoint,
          fontFamily: 'WeatherIcons',
        );
}
