import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/account.provider.dart';
import 'package:onepay_app/pages/authorized/settings/accounts/add.account.finish.dart';
import 'package:onepay_app/pages/authorized/settings/accounts/add.account.init.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';

class AddLinkedAccount extends StatefulWidget {
  _AddLinkedAccount createState() => _AddLinkedAccount();
}

class _AddLinkedAccount extends State<AddLinkedAccount>
    with SingleTickerProviderStateMixin {
  AnimationController _slideController;
  Tween _slideTween;
  int _currentCard = 0;

  StreamController _streamController;
  Stream _accountProviderStream;
  Stream _accountIDStream;
  Stream _clearStream;
  AccountProvider _selectedAccountProvider;
  String _accountID;
  String _nonce;

  List<AccountProvider> _accountProviders = List<AccountProvider>();

  void _back() {
    setState(() {
      _currentCard = 0;
    });
  }

  void _next(String nonce) {
    this._nonce = nonce;
    setState(() {
      _currentCard = 1;
    });

    //  This will clear the the second card
    _streamController.add(true);
  }

  void _onGetAccountProvidersSuccess(Response response) {
    List<dynamic> jsonData = json.decode(response.body);

    List<AccountProvider> accountProviders = List<AccountProvider>();
    jsonData.forEach((json) {
      AccountProvider accountProvider = AccountProvider.fromJson(json);
      accountProviders.add(accountProvider);
    });

    OnePay.of(context).appStateController.add(accountProviders);
    _accountProviders = OnePay.of(context).accountProviders;
    setState(() {});

    //  Saving to the local storage
    setLocalAccountProviders(json.encode(accountProviders));
  }

  Future<void> _getAccountProviders() async {
    HttpRequester requester =
        HttpRequester(path: "/oauth/user/linkedaccount/accountprovider.json");
    try {
      var response = await requester.get(context);

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onGetAccountProvidersSuccess(response);
      }
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {}
  }

  void _connectivityChecker() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        _getAccountProviders();
      }
    });
  }

  void _initAccountProviders() async {
    _accountProviders = OnePay.of(context).accountProviders.length == 0
        ? await getLocalAccountProviders()
        : OnePay.of(context).accountProviders;
    setState(() {});
  }

  void _initStreamControllers() {
    _streamController = StreamController.broadcast();

    _accountProviderStream =
        _streamController.stream.where((event) => event is AccountProvider);
    _accountIDStream =
        _streamController.stream.where((event) => event is String);
    _clearStream = _streamController.stream
        .where((event) => event is bool);

    _accountIDStream.listen((event) {
      _accountID = event as String;
    });

    _accountProviderStream.listen((event) {
      _selectedAccountProvider = event as AccountProvider;
    });
  }

  void _initAnimation() {
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _slideTween = Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0));

    _slideController.forward();
  }

  @override
  void initState() {
    super.initState();

    _initStreamControllers();
    _initAnimation();
    _connectivityChecker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _initAccountProviders();
    _getAccountProviders();
  }

  @override
  void dispose() {
    _streamController.close();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Account"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: SlideTransition(
          position: _slideTween.animate(_slideController),
          child: FadeTransition(
            opacity: _slideController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AddLinkedAccountInit(
                        accountProviders: _accountProviders,
                        visible: _currentCard == 0,
                        next: _next,
                        streamController: _streamController,
                        getAccountProviders: _getAccountProviders,
                      ),
                      AddLinkedAccountFinish(
                        visible: _currentCard == 1,
                        next: _next,
                        back: _back,
                        clearStream: _clearStream,
                        accountProvider: _selectedAccountProvider,
                        accountID: _accountID,
                        nonce: _nonce,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryVariant,
    );
  }
}
