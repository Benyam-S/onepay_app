import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ff_navigation_bar/ff_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/pages/inside/send/send.dart';
import 'package:onepay_app/utils/custom_icons_icons.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/request.maker.dart';

class Home extends StatefulWidget {
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  int _currentIndex = 1;
  String _appBarTitle = "";
  List<Widget> _listOfSections;
  PageStorageBucket _bucket = PageStorageBucket();

  void getUserProfile() async {
    var requester = HttpRequester(path: "/oauth/user/profile.json");

    try {
      var accessToken =
          OnePay.of(context).accessToken ?? await getLocalAccessToken();

      String basicAuth = 'Basic ' +
          base64Encode(
              utf8.encode('${accessToken.apiKey}:${accessToken.accessToken}'));
      var response =
          await http.get(requester.requestURL, headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'authorization': basicAuth,
      });

      // If the request is not authorized then exit
      if (!requester.isAuthorized(context, response, false)) {
        return;
      }

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        var opUser = User.fromJson(jsonData);

        // Add current user to the stream and shared preference
        OnePay.of(context).appStateController.add(opUser);
        setLocalUserProfile(opUser);
      }
    } on SocketException {}
  }

  @override
  void initState() {
    super.initState();

    _listOfSections = [
      Container(
        key: PageStorageKey("exchange"),
      ),
      Send(),
      Container(),
      Container(
        key: PageStorageKey("wallet"),
      ),
      Container(
        key: PageStorageKey("settings"),
      )
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //  Fetching data on background
    getUserProfile();
  }

  void changeSection(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        _appBarTitle = "OnePay";
        break;
      case 1:
        _appBarTitle = "Send";
        break;
      case 2:
        _appBarTitle = "Receive";
        break;
      case 3:
        _appBarTitle = "Wallet";
        break;
      case 4:
        _appBarTitle = "Settings";
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
      ),
      body: PageStorage(
        child: _listOfSections[_currentIndex],
        bucket: _bucket,
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      bottomNavigationBar: FFNavigationBar(
        theme: FFNavigationBarTheme(
            barBackgroundColor: Colors.white,
            selectedItemBackgroundColor: Theme.of(context).primaryColor,
            selectedItemIconColor: Colors.white,
            selectedItemLabelColor: Theme.of(context).primaryColor,
            unselectedItemIconColor: Theme.of(context).colorScheme.surface,
            unselectedItemLabelColor: Theme.of(context).colorScheme.surface,
            selectedItemTextStyle: TextStyle(fontSize: 11),
            unselectedItemTextStyle: TextStyle(fontSize: 9)),
        selectedIndex: _currentIndex,
        onSelectTab: (index) => changeSection(index),
        items: [
          FFNavigationBarItem(
            iconData: Icons.show_chart,
            label: 'Exchange',
          ),
          FFNavigationBarItem(
            iconData: CustomIcons.paper_plane,
            label: 'Send',
          ),
          FFNavigationBarItem(
            iconData: CustomIcons.save_money_filled,
            label: 'Receive',
          ),
          FFNavigationBarItem(
            iconData: Icons.account_balance_wallet,
            label: 'Wallet',
          ),
          FFNavigationBarItem(
            iconData: CustomIcons.gear,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
