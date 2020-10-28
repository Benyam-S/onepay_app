import 'dart:async';
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:ff_navigation_bar/ff_navigation_bar.dart';
import 'package:ff_navigation_bar/ff_navigation_bar_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/models/history.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/models/wallet.dart';
import 'package:onepay_app/pages/authorized/receive/receive.dart';
import 'package:onepay_app/pages/authorized/send/send.dart';
import 'package:onepay_app/pages/authorized/settings/settings.dart';
import 'package:onepay_app/pages/authorized/wallet/wallet.dart';
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
  int _currentIndex = 4;
  Widget _appBar;
  List<Widget> _listOfSections;
  PageStorageBucket _bucket = PageStorageBucket();
  bool _showWalletBadge = false;
  bool _haveUnseenHistories = false;
  Stream<bool> _unseenHistoryStream;
  StreamController<bool> _unseenHistoryStreamController = StreamController();
  int _profileState = 0;
  int _socketState = 0;
  IOWebSocketChannel channel;
  StreamSubscription _pollingStreamSubscription;
  StreamSubscription _connectivitySubscription;

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

  Future<void> _markHistoriesAsSeen() async {
    if (_currentIndex != 3 && _haveUnseenHistories) {
      User user = OnePay.of(context).currentUser ?? await getLocalUserProfile();

      OnePay.of(context).histories.forEach((history) {
        if (history.senderID == user.userID && !history.senderSeen) {
          history.senderSeen = true;
        } else if (history.receiverID == user.userID && !history.receiverSeen) {
          history.receiverSeen = true;
        }
      });

      Future<Response> makeRequest() {
        var requester = HttpRequester(path: "/oauth/user/history.json");
        return requester.put(context, null);
      }

      await _handleResponse(makeRequest, null);
      _haveUnseenHistories = false;
    }
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
          'ws://$Host/api/v1/connect.json/${accessToken.apiKey}/${accessToken.accessToken}');
      channel.stream.listen(_onNotificationReceived,
          onDone: _onSocketClosed, onError: _onSocketError);
    } catch (e) {
      _socketState = 0;
    }
  }

  void _onNotificationReceived(response) {
    var jsonMap = json.decode(response);
    if (jsonMap["Type"] == "user") {
      var user = User.fromJson(jsonMap["Body"]);

      OnePay.of(context).appStateController.add(user);
      setLocalUserProfile(user);
    }

    if (jsonMap["Type"] == "wallet") {
      var wallet = Wallet.fromJson(jsonMap["Body"]);

      setState(() {
        _showWalletBadge = true;
      });

      OnePay.of(context).appStateController.add(wallet);
      setLocalUserWallet(wallet);
    }

    if (jsonMap["Type"] == "history") {
      var history = History.fromJson(jsonMap["Body"]);

      OnePay.of(context).appStateController.add([history]);
    }
  }

  void _onSocketClosed() {
    _socketState = 0;
  }

  void _onSocketError(error) {
    _socketState = 0;
  }

  void _connectivityListener() {
    // Since this listener will be fired every time the connection is changed and on restart,
    // it would be the best place to make background fetch
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
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

  // continuousPolling is used for making sure the connection is still alive
  // if the connection is down for what ever reasons
  void _continuousPolling() {
    _pollingStreamSubscription =
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
      WalletView(_unseenHistoryStreamController),
      Settings(),
    ];

    _unseenHistoryStream = _unseenHistoryStreamController.stream;
    _unseenHistoryStream.listen((unseen) {
      if (unseen) {
        _haveUnseenHistories = true;
      }
    });

    _connectivityListener();
    _continuousPolling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _getUserProfile();
    _getUserWallet();
    _startSocketConn();
  }

  @override
  void dispose() {
    _unseenHistoryStreamController.close();
    channel.sink.close();
    _pollingStreamSubscription.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        _appBar = AppBar(
          title: Text("OnePay"),
          elevation: 0,
        );
        break;
      case 1:
        _appBar = AppBar(
          title: Text("Send"),
        );
        break;
      case 2:
        _appBar = AppBar(
          title: Text("Receive"),
          elevation: 0,
        );
        break;
      case 3:
        _appBar = AppBar(
          title: Text("Wallet"),
          elevation: 0,
        );
        if (_showWalletBadge) {
          _showWalletBadge = false;
          markLocalUserWallet(true);
          _markWalletAsSeen();
        }
        break;
      case 4:
        _appBar = null;
        break;
    }

    _markHistoriesAsSeen();

    return Scaffold(
      appBar: _appBar,
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
