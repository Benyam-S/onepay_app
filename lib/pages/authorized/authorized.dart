import 'dart:async';
import 'dart:convert';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:connectivity/connectivity.dart';
import 'package:ff_navigation_bar/ff_navigation_bar.dart';
import 'package:ff_navigation_bar/ff_navigation_bar_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/history.dart';
import 'package:onepay_app/models/preferences.state.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/models/user.preference.dart';
import 'package:onepay_app/models/wallet.dart';
import 'package:onepay_app/pages/authorized/home/home.dart';
import 'package:onepay_app/pages/authorized/receive/receive.dart';
import 'package:onepay_app/pages/authorized/send/send.dart';
import 'package:onepay_app/pages/authorized/settings/settings.dart';
import 'package:onepay_app/pages/authorized/wallet/wallet.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/notification.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:web_socket_channel/io.dart';

class Authorized extends StatefulWidget {
  final int index;

  Authorized({this.index});

  _Authorized createState() => _Authorized();
}

class _Authorized extends State<Authorized>
    with SingleTickerProviderStateMixin {
  int _currentIndex;
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

  bool _isCameraOpened = false;
  ScrollController _scrollController = ScrollController();
  AnimationController _fabAnimationController;

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

  Future<void> _getUserPreference() async {
    Future<Response> makeRequest() {
      var requester =
          HttpRequester(path: "/oauth/user/profile/preference.json");
      return requester.get(context);
    }

    void onSuccess(Response response) {
      var jsonData = json.decode(response.body);
      var userPreference = UserPreference.fromJson(jsonData);

      // Add current user preference to the stream and shared preference
      OnePay.of(context).appStateController.add(userPreference);
      setLocalUserPreference(userPreference);
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

    // Aborting if data-saver is enabled
    DataSaverState dataSaverState =
        OnePay.of(context).dataSaverState ?? await getLocalDataSaverState();
    if (dataSaverState == DataSaverState.Enabled) return;

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

  void _onNotificationReceived(response) async {
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

      // Aborting if foreground notification is disabled
      ForegroundNotificationState foregroundNotificationState =
          OnePay.of(context).fNotificationState ??
              await getLocalForegroundNotificationState();
      if (foregroundNotificationState == ForegroundNotificationState.Disabled)
        return;

      User user = OnePay.of(context).currentUser ?? await getLocalUserProfile();
      var notification = makeHistoryNotification(context, history, user);
      if (notification != null) {
        showNotification(
            context,
            history.id,
            OnePayHistoryChannelID,
            OnePayHistoryChannelName,
            notification.title,
            notification.description,
            playLoad: history.id.toString());
      }
    }

    if (jsonMap["Type"] == "preference") {
      var userPreference = UserPreference.fromJson(jsonMap["Body"]);

      OnePay.of(context).appStateController.add(userPreference);
      setLocalUserPreference(userPreference);
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
        _getUserPreference();
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
    // Set receive widget to default if clicked on the bottom nav
    if (index == 2) _listOfSections[2] = Receive();
    setState(() {
      _currentIndex = index;
    });
  }

  void _scan(BuildContext context) async {
    if (_isCameraOpened) {
      return;
    }
    try {
      setState(() {
        _isCameraOpened = true;
      });
      var qrResult = await BarcodeScanner.scan();
      String code = qrResult.rawContent;
      _isCameraOpened = false;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _listOfSections[2] = Receive(code: code);
          _currentIndex = 2;
        });
      }
    } on PlatformException catch (ex) {
      setState(() {
        _isCameraOpened = false;
      });
      var error = "";
      if (ex.code == BarcodeScanner.cameraAccessDenied) {
        error = "Access Denied";
      } else {
        error = "Unable to open qr code scanner";
      }

      showInternalError(context, error);
    } catch (ex) {
      setState(() {
        _isCameraOpened = false;
      });
      showInternalError(context, SomethingWentWrongError);
    }
  }

  void _scrollListener() {
    if (_scrollController.offset > 175 &&
        _scrollController.position.userScrollDirection ==
            ScrollDirection.reverse) {
      _fabAnimationController.forward();
    } else if (_scrollController.offset > 175 &&
        _scrollController.position.userScrollDirection ==
            ScrollDirection.forward) {
      _fabAnimationController.reverse();
    }
  }

  void _initAppBar() {
    switch (_currentIndex) {
      case 0:
        _appBar = null;
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
  }

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.index ?? 0;
    _scrollController.addListener(_scrollListener);
    _fabAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    _listOfSections = [
      Home(_scrollController),
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
    _getUserPreference();
    _getUserWallet();
    _startSocketConn();

    OnePay.of(context).dataSaverStream.listen((dataSaverState) {
      if ((dataSaverState as DataSaverState) == DataSaverState.Disabled) {
        _startSocketConn();
      } else if ((dataSaverState as DataSaverState) == DataSaverState.Enabled) {
        _socketState = 0;
        channel.sink.close();
      }
    });
  }

  @override
  void dispose() {
    _unseenHistoryStreamController.close();
    channel.sink.close();
    _pollingStreamSubscription.cancel();
    _connectivitySubscription.cancel();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initAppBar();
    _markHistoriesAsSeen();

    return Scaffold(
      appBar: _appBar,
      body: PageStorage(
        child: _listOfSections[_currentIndex],
        bucket: _bucket,
      ),
      floatingActionButton: _currentIndex == 0
          ? Builder(builder: (context) {
              return FadeTransition(
                opacity: Tween(begin: 1.0, end: 0.0)
                    .animate(_fabAnimationController),
                child: FloatingActionButton(
                  child: Icon(
                    CustomIcons.barcode,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _scan(context),
                ),
              );
            })
          : null,
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
            label: 'Home',
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
