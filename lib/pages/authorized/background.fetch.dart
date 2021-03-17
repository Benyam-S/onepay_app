import 'dart:convert';
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/app.meta.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/models/currency.rate.dart';
import 'package:onepay_app/models/history.dart';
import 'package:onepay_app/models/preferences.state.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/pages/authorized/authorized.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/notification.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void headlessBackgroundFetch(String taskID) async {
  print("Preforming background fetching .....................");
  // await handleCurrencyRatesBackgroundFetch();
  // await handleNotificationsBackgroundFetch();

  BackgroundFetch.finish(taskID);
}

Future<void> handleCurrencyRatesBackgroundFetch() async {
  Future<void> _onSuccess(http.Response response) async {
    List<CurrencyRate> currencyRates = List<CurrencyRate>();
    List<dynamic> jsonData = json.decode(response.body);
    jsonData.forEach((element) {
      CurrencyRate currencyRate = CurrencyRate.fromJson(element);
      currencyRates.add(currencyRate);
    });

    setLocalCurrencyRates(currencyRates);
  }

  Future<void> _makeRequest() async {
    var requestURL = "http://$Host/api/v1/oauth/currency/rates/ETB.json";

    try {
      AccessToken accessToken = await getLocalAccessToken();
      AppMeta appMeta = await getAppMeta();

      if (accessToken == null) {
        return;
      }

      String basicAuth = 'Basic ' +
          base64Encode(
              utf8.encode('${accessToken.apiKey}:${accessToken.accessToken}'));

      http.Response response =
          await http.get(requestURL, headers: <String, String>{
        'User-Agent': "${appMeta.name} ${appMeta.version} ${appMeta.userAgent}",
        'Content-Type': 'application/x-www-form-urlencoded',
        'authorization': basicAuth,
      }).timeout(Duration(minutes: 1));

      if (response.statusCode == HttpStatus.ok) {
        await _onSuccess(response);
      }
    } catch (e) {}
  }

  var listOfCurrencyRates = await getRecentLocalCurrencyRates();
  if (listOfCurrencyRates.length == 0) {
    await _makeRequest();
  }
}

Future<void> handleNotificationsBackgroundFetch() async {
  Future _selectNotification(String payload) async {
    bool loggedIn = await isLoggedIn();
    final navKey = new GlobalKey<NavigatorState>();

    if (loggedIn) {
      await navKey.currentState.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => Authorized(index: 3),
          ),
          (Route<dynamic> route) => false);
    } else {
      await navKey.currentState.pushNamedAndRemoveUntil(
          AppRoutes.logInRoute, (Route<dynamic> route) => false);
    }
  }

  Future<void> _onSuccess(http.Response response) async {
    // Instantiating android notification channel
    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    var styleInformation = BigTextStyleInformation('', htmlFormatContent: true);
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            OnePayHistoryChannelID, OnePayHistoryChannelName, '',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
            color: Color.fromRGBO(4, 148, 255, 1),
            styleInformation: styleInformation);

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _selectNotification);
    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    List<History> histories = List<History>();
    var jsonData = json.decode(response.body);
    List<dynamic> recentHistories = jsonData['Histories'];

    final preferences = await SharedPreferences.getInstance();
    List<History> localHistories =
        await getRecentLocalHistories(preferences: preferences);

    recentHistories.forEach((element) async {
      History history = History.fromJson(element);
      bool registered = false;

      localHistories.forEach((element) {
        if (element.id == history.id) {
          registered = true;
          return;
        }
      });

      if (!registered) {
        histories.add(history);

        // Previewing notification
        User user = await getLocalUserProfile();
        var notification = makeHistoryNotification(history, user);
        if (notification != null) {
          flutterLocalNotificationsPlugin.show(history.id, notification.title,
              notification.description, platformChannelSpecifics,
              payload: history.id.toString());
        }
      }
    });

    setRecentLocalHistories(histories, preferences: preferences);
  }

  var requestURL = "http://$Host/api/v1/oauth/user/notifications.json";

  try {
    // Aborting if foreground notification is disabled
    BackgroundNotificationState backgroundNotificationState =
        await getLocalBackgroundNotificationState();
    if (backgroundNotificationState == BackgroundNotificationState.Disabled)
      return;

    AccessToken accessToken = await getLocalAccessToken();
    AppMeta appMeta = await getAppMeta();

    if (accessToken == null) {
      return;
    }

    String basicAuth = 'Basic ' +
        base64Encode(
            utf8.encode('${accessToken.apiKey}:${accessToken.accessToken}'));

    http.Response response =
        await http.get(requestURL, headers: <String, String>{
      'User-Agent': "${appMeta.name} ${appMeta.version} ${appMeta.userAgent}",
      'Content-Type': 'application/x-www-form-urlencoded',
      'authorization': basicAuth,
    }).timeout(Duration(minutes: 1));

    if (response.statusCode == HttpStatus.ok) {
      await _onSuccess(response);
    }
  } catch (e) {}
}
