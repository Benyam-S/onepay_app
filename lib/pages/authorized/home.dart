import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:ff_navigation_bar/ff_navigation_bar.dart';
import 'package:ff_navigation_bar/ff_navigation_bar_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/models/wallet.dart';
import 'package:onepay_app/pages/authorized/receive.dart';
import 'package:onepay_app/pages/authorized/send/send.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:web_socket_channel/io.dart';

class Home extends StatefulWidget {
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  int _currentIndex = 2;
  String _appBarTitle = "";
  List<Widget> _listOfSections;
  PageStorageBucket _bucket = PageStorageBucket();
  bool _showWalletBadge = false;
  int _profileState = 0;
  int _socketState = 0;
  IOWebSocketChannel channel;

  Future<void> _getUserProfile() async {
    // This is used to stop any request from starting if a request has already been sent
    if (_profileState > 0) {
      return;
    }

    Future<Response> makeRequest() {
      var requester = HttpRequester(path: "/oauth/user/profile.json");
      _profileState = 1;
      return requester.get(context);
    }

    void onSuccess(Response response) {
      var jsonData = json.decode(response.body);
      var opUser = User.fromJson(jsonData);

      // Add current user to the stream and shared preference
      OnePay.of(context).appStateController.add(opUser);
      setLocalUserProfile(opUser);
    }

    _handleResponse(makeRequest, onSuccess);
  }

  Future<void> _getUserWallet() async {
    Future<Response> makeRequest() {
      var requester = HttpRequester(path: "/oauth/user/wallet.json");
      return requester.get(context);
    }

    void onSuccess(Response response) async {
      var jsonData = json.decode(response.body);
      var wallet = Wallet.fromJson(jsonData);

      if (!wallet.seen) {
        Wallet prevWallet = await getLocalUserWallet();
        if (prevWallet == null ||
            (!prevWallet.seen || prevWallet.updatedAt != wallet.updatedAt)) {
          setState(() {
            _showWalletBadge = true;
          });

          setLocalUserWallet(wallet);
        } else {
          wallet.seen = true;
          _markWalletAsSeen();
        }
      }

      // Add current user to the stream and shared preference
      OnePay.of(context).appStateController.add(wallet);
    }

    _handleResponse(makeRequest, onSuccess);
  }

  Future<void> _markWalletAsSeen() async {
    Future<Response> makeRequest() {
      var requester = HttpRequester(path: "/oauth/user/wallet.json");
      return requester.put(context, null);
    }

    _handleResponse(makeRequest, null);
  }

  // handleResponse is a function that handles a response coming from request
  Future<void> _handleResponse(Future<Response> Function() requester,
      Function(Response response) onSuccess) async {
    try {
      var response = await requester();

      // If the request is not authorized then exit
      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == 200) {
        if (onSuccess != null) onSuccess(response);
      }
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {
      //  do nothing
    }
  }

  Future<void> _startSocketConn() async {
    // Aborting if connection is already started/established
    if (_socketState > 0) {
      return;
    }

    AccessToken accessToken =
        OnePay.of(context).accessToken ?? await getLocalAccessToken();

    if (accessToken == null) {
      // Logging the use out
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.logInRoute, (Route<dynamic> route) => false);
      return;
    }

    _socketState = 1;
    try {
      channel = IOWebSocketChannel.connect(
          'ws://192.168.1.3:8080/api/v1/connect.json/${accessToken.apiKey}/${accessToken.accessToken}');
      channel.stream.listen(_onNotificationReceived,
          onDone: _onSocketClosed, onError: _onSocketError);
    } catch (e) {
      _socketState = 0;
    }
  }

  void _onNotificationReceived(response) {
    var jsonMap = json.decode(response);
    if (jsonMap["Type"] == "wallet") {
      var wallet = Wallet.fromJson(jsonMap["Body"]);

      setState(() {
        _showWalletBadge = true;
      });

      // Add current user to the stream and shared preference
      OnePay.of(context).appStateController.add(wallet);
      setLocalUserWallet(wallet);
    }
  }

  void _onSocketClosed() {
    _socketState = 0;
  }

  void _onSocketError(error) {
    _socketState = 0;
  }

  void _connectivityChecker() {
    // Since this listener will be fired every time the connection is changed and on restart,
    // it would be the best place to make background fetch
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        //  Fetching data on background
        _getUserProfile();
        _getUserWallet();
        // Starting socket connection
        _startSocketConn();
      }
    });
  }

  // continuousPolling is used for making sure the connection is still alive if the connection is down for what ever reasons
  void _continuousPolling() {
    Stream.periodic(Duration(minutes: 1)).listen((event) {
      _startSocketConn();
    });
  }

  void _changeSection(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    _listOfSections = [
      Container(
        key: PageStorageKey("exchange"),
      ),
      Send(),
      Receive(),
      Container(
        key: PageStorageKey("wallet"),
      ),
      Container(
        key: PageStorageKey("settings"),
      )
    ];

    _connectivityChecker();
    _continuousPolling();
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
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
        if (_showWalletBadge) {
          _showWalletBadge = false;
          markLocalUserWallet(true);
          _markWalletAsSeen();
        }
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
        onSelectTab: (index) => _changeSection(index),
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
            showBadge: _showWalletBadge,
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
