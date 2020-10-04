import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/models/account.info.dart';
import 'package:onepay_app/models/linked.account.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/widgets/tile/recharge.linked.account.dart';

class RechargeLinkedAccounts extends StatefulWidget {
  _RechargeLinkedAccounts createState() => _RechargeLinkedAccounts();
}

class _RechargeLinkedAccounts extends State<RechargeLinkedAccounts> {
  List<LinkedAccount> _linkedAccounts = List<LinkedAccount>();

  void _filterAndAdd(LinkedAccount linkedAccount) {
    bool addFlag = true;
    _linkedAccounts.forEach((filteredLinkedAccount) {
      if (linkedAccount.id == filteredLinkedAccount.id) {
        addFlag = false;
        return;
      }
    });

    if (addFlag) {
      _linkedAccounts.add(linkedAccount);
    }
  }

  Future<void> _handleResponse(
      BuildContext context,
      Future<Response> Function() requester,
      Function(Response response) onSuccess,
      Function(Response response) onError) async {
    try {
      var response = await requester();

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        onSuccess(response);
      } else {
        onError(response);
      }
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {}
  }

  void _onGetAccountInfoSuccess(Response response) {
    Map<String, dynamic> jsonData = json.decode(response.body);
    AccountInfo accountInfo = AccountInfo.fromJson(jsonData);
    for (var i = 0; i < _linkedAccounts.length; i++) {
      if (_linkedAccounts[i].accountProvider == accountInfo.accountProvider &&
          _linkedAccounts[i].accountID == accountInfo.accountID) {
        _linkedAccounts[i].amount = accountInfo.amount;
      }
    }

    setState(() {});

    //  Saving to the local storage
    setLocalLinkedAccounts(json.encode(_linkedAccounts));
  }

  Future<Response> _makeGetAccountInfoRequest(String linkedAccountID) async {
    var requester =
        HttpRequester(path: "/oauth/user/linkedaccount/$linkedAccountID.json");
    return requester.get(context);
  }

  Future<void> _getLinkedAccountsAccountInfo() async {
    for (var i = 0; i < _linkedAccounts.length; i++) {
      await _handleResponse(
          context,
          () => _makeGetAccountInfoRequest(_linkedAccounts[i].id),
          _onGetAccountInfoSuccess,
          (_) => null);
    }
  }

  Future<void> _getLinkedAccountAccountInfo(LinkedAccount linkedAccount) async {
    await _handleResponse(
        context,
        () => _makeGetAccountInfoRequest(linkedAccount.id),
        _onGetAccountInfoSuccess,
        (_) => null);
  }

  void _onGetLinkedAccountsSuccess(Response response) {
    List<dynamic> jsonData = json.decode(response.body);
    // Have to rest _linkedAccounts since the incoming linked accounts may not be compatible with the local one
    _linkedAccounts = List<LinkedAccount>();

    jsonData.forEach((json) {
      LinkedAccount linkedAccount = LinkedAccount.fromJson(json);
      // It can be used to point amount has been received yet
      linkedAccount.amount = null;
      _filterAndAdd(linkedAccount);
    });

    // Sorting linked accounts
    _linkedAccounts.sort((LinkedAccount a, LinkedAccount b) {
      return a.accountProvider.compareTo(b.accountProvider);
    });

    setState(() {});

    //  Saving to the local storage
    setLocalLinkedAccounts(json.encode(_linkedAccounts));

    //  Getting linked accounts info
    _getLinkedAccountsAccountInfo();
  }

  Future<Response> _makeGetLinkedAccountsRequest() async {
    var requester = HttpRequester(path: "/oauth/user/linkedaccount.json");
    return requester.get(context);
  }

  Future<void> _getLinkedAccounts() async {
    await _handleResponse(context, _makeGetLinkedAccountsRequest,
        _onGetLinkedAccountsSuccess, (_) => null);
  }

  Future<void> _refresh() async {
    await _getLinkedAccounts();
  }

  void _connectivityChecker() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        _refresh();
      }
    });
  }

  void _initLinkedAccounts() async {
    _linkedAccounts = await getLocalLinkedAccounts();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _connectivityChecker();
    _initLinkedAccounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _getLinkedAccounts();
  }

  @override
  Widget build(BuildContext context) {
    double cardRadius = 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Text(
            "Linked Accounts",
            style: TextStyle(
                fontSize: 15,
                fontFamily: 'Roboto',
                color: Theme.of(context).iconTheme.color),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _linkedAccounts.length == 0
                ? Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(
                            left: 8, right: 8, bottom: 10),
                        child: DottedBorder(
                          color: Theme.of(context).iconTheme.color,
                          strokeWidth: 1,
                          radius: Radius.circular(cardRadius),
                          dashPattern: [5, 3],
                          customPath: (size) {
                            return Path()
                              ..moveTo(cardRadius, 0)
                              ..lineTo(size.width - cardRadius, 0)
                              ..arcToPoint(Offset(size.width, cardRadius),
                                  radius: Radius.circular(cardRadius))
                              ..lineTo(size.width, size.height - cardRadius)
                              ..arcToPoint(
                                  Offset(size.width - cardRadius, size.height),
                                  radius: Radius.circular(cardRadius))
                              ..lineTo(cardRadius, size.height)
                              ..arcToPoint(Offset(0, size.height - cardRadius),
                                  radius: Radius.circular(cardRadius))
                              ..lineTo(0, cardRadius)
                              ..arcToPoint(Offset(cardRadius, 0),
                                  radius: Radius.circular(cardRadius));
                          },
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(CustomIcons.box, size: 60),
                                SizedBox(height: 10),
                                Text(
                                  "Nothing to show yet!",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).iconTheme.color),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                      ), // This ListView is used for showing the refreshIndicator
                    ],
                  )
                : ListView.builder(
                    key: PageStorageKey('history'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _linkedAccounts.length,
                    itemBuilder: (context, index) {
                      return RechargeLinkedAccountTile(
                          _linkedAccounts[index], _getLinkedAccountAccountInfo);
                    },
                  ),
          ),
        )
      ],
    );
  }
}
