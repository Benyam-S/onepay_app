import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/account.info.dart';
import 'package:onepay_app/models/linked.account.dart';
import 'package:onepay_app/models/preferences.state.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/widgets/tile/manage.linked.account.dart';

class ManageAccounts extends StatefulWidget {
  _ManageAccounts createState() => _ManageAccounts();
}

class _ManageAccounts extends State<ManageAccounts> {
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

  void _removeLinkedAccount(LinkedAccount linkedAccount) {
    _linkedAccounts.removeWhere((deleteLinkedAccount) {
      if (deleteLinkedAccount.id == linkedAccount.id) return true;
      return false;
    });

    OnePay.of(context).appStateController.add(_linkedAccounts);
    setState(() {});
    setLocalLinkedAccounts(json.encode(_linkedAccounts));
  }

  Future<void> _handleResponse(
      BuildContext context,
      Future<Response> Function() requester,
      Future<void> Function(Response response) onSuccess,
      Function(Response response) onError) async {
    try {
      var response = await requester();

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        await onSuccess(response);
      } else {
        onError(response);
      }
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {}
  }

  Future<void> _onGetAccountInfoSuccess(Response response) async {
    Map<String, dynamic> jsonData = json.decode(response.body);
    AccountInfo accountInfo = AccountInfo.fromJson(jsonData);
    for (var i = 0; i < _linkedAccounts.length; i++) {
      if (_linkedAccounts[i].accountProviderID ==
              accountInfo.accountProviderID &&
          _linkedAccounts[i].accountID == accountInfo.accountID) {
        _linkedAccounts[i].amount = accountInfo.amount;
      }
    }

    OnePay.of(context).appStateController.add(_linkedAccounts);
    setState(() {});

    //  Saving to the local storage
    setLocalLinkedAccounts(json.encode(_linkedAccounts));
  }

  Future<Response> _makeGetAccountInfoRequest(String linkedAccountID) async {
    var requester = HttpRequester(
        path: "/oauth/user/linkedaccount/accountinfo/$linkedAccountID.json");
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

  Future<void> _onGetLinkedAccountsSuccess(Response response) async {
    List<dynamic> jsonData = json.decode(response.body);

    // Have to rest _linkedAccounts since the incoming linked accounts may not be compatible with the local one
    _linkedAccounts = List<LinkedAccount>();

    jsonData.forEach((json) {
      LinkedAccount linkedAccount = LinkedAccount.fromJson(json);
      _filterAndAdd(linkedAccount);
    });

    // Sorting linked accounts
    _linkedAccounts.sort((LinkedAccount a, LinkedAccount b) {
      return a.accountProviderName.compareTo(b.accountProviderName);
    });

    OnePay.of(context).appStateController.add(_linkedAccounts);
    setState(() {});
    setLocalLinkedAccounts(json.encode(_linkedAccounts));

    // Aborting if data-saver is enabled
    DataSaverState dataSaverState =
        OnePay.of(context).dataSaverState ?? await getLocalDataSaverState();
    if (dataSaverState == DataSaverState.Enabled) return;

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
    _linkedAccounts = OnePay.of(context).linkedAccounts.length == 0
        ? await getLocalLinkedAccounts()
        : OnePay.of(context).linkedAccounts;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _connectivityChecker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    OnePay.of(context).linkedAccountStream.listen((event) {
      // linked accounts has been updated
      if (event.length > _linkedAccounts.length) _initLinkedAccounts();
    });

    _initLinkedAccounts();
    _getLinkedAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage"),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _linkedAccounts.length == 0
            ? Stack(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.only(left: 8, right: 8, bottom: 10),
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
                  ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                  ), // This ListView is used for showing the refreshIndicator
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, left: 20, bottom: 10),
                    child: Text(
                      "Linked Accounts",
                      style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Roboto',
                          color: Theme.of(context).iconTheme.color),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      key: PageStorageKey('recharge'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _linkedAccounts.length,
                      itemBuilder: (context, index) {
                        return ManageLinkedAccountTile(_linkedAccounts[index],
                            _getLinkedAccountAccountInfo, _removeLinkedAccount);
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addAccount),
        child: Icon(
          Icons.add,
          size: 30,
          color: Theme.of(context).primaryColor,
        ),
        backgroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
