import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/models/account.provider.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:recase/recase.dart';

class AddLinkedAccountInit extends StatefulWidget {
  final List<AccountProvider> accountProviders;
  final bool visible;
  final Function(String) next;
  final StreamController streamController;
  final Future<void> Function() getAccountProviders;

  AddLinkedAccountInit(
      {@required this.accountProviders,
      this.visible,
      this.next,
      this.streamController,
      this.getAccountProviders});

  _AddLinkedAccountInit createState() => _AddLinkedAccountInit();
}

class _AddLinkedAccountInit extends State<AddLinkedAccountInit> {
  FocusNode _accountIDFocusNode;
  FocusNode _buttonFocusNode;
  TextEditingController _accountIDController;
  String _accountIDErrorText;
  bool _isRefreshing = false;
  bool _loading = false;

  AccountProvider _selectedAccountProvider;

  void _onSelectAccountProvider(AccountProvider selected) {
    setState(() {
      _selectedAccountProvider = selected;
    });

    widget.streamController.add(_selectedAccountProvider);
  }

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await widget.getAccountProviders();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _onSuccess(Response response) {
    var jsonData = json.decode(response.body);
    widget.next(jsonData["nonce"]);
  }

  void _onError(Response response) {
    if (response.statusCode == HttpStatus.badRequest) {
      var jsonData = json.decode(response.body);
      String error = jsonData["error"];
      switch (error) {
        case AccountProviderNotFoundB:
          showServerError(
              context, ReCase(AccountProviderNotFound).sentenceCase);
          break;
        case AccountAlreadyLinkedErrorB:
          setState(() {
            _accountIDErrorText =
                ReCase(AccountAlreadyLinkedError).sentenceCase;
          });
          break;
        default:
          showServerError(context, SomethingWentWrongError);
      }
    } else {
      showServerError(context, SomethingWentWrongError);
    }
  }

  Future<void> _makeAddLinkedAccountInitRequest(String accountID) async {
    HttpRequester requester =
        HttpRequester(path: "/oauth/user/linkedaccount/init.json");
    try {
      var response = await requester.post(context, {
        "account_provider_id": _selectedAccountProvider.id,
        "account_id": accountID,
      });

      setState(() {
        _loading = false;
      });

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onSuccess(response);
      } else {
        _onError(response);
      }
    } on SocketException {
      setState(() {
        _loading = false;
      });

      showUnableToConnectError(context);
    } on AccessTokenNotFoundException {
      setState(() {
        _loading = false;
      });

      logout(context);
    } catch (e) {
      setState(() {
        _loading = false;
      });

      showServerError(context, SomethingWentWrongError);
    }
  }

  void _addLinkedAccountInit() async {
    if (_selectedAccountProvider == null || _loading) {
      return;
    }

    String accountID = _accountIDController.text;
    if (accountID.isEmpty) {
      FocusScope.of(context).requestFocus(_accountIDFocusNode);
      return;
    }

    widget.streamController.add(accountID);

    setState(() {
      _loading = true;
      _accountIDErrorText = null;
    });

    await _makeAddLinkedAccountInitRequest(accountID);
  }

  @override
  void initState() {
    super.initState();

    _accountIDFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();

    _accountIDController = TextEditingController();
  }

  @override
  void dispose() {
    _accountIDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.visible ?? false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              "Select the preferred account provider and enter respective account id to link the need account.",
              style: Theme.of(context).textTheme.headline3,
            ),
          ),
          SizedBox(height: 15),
          InkWell(
            onLongPress: _refresh,
            child: Stack(
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: DropdownButton(
                      value: _selectedAccountProvider,
                      items: widget.accountProviders
                          .map(
                            (accountProvider) =>
                                DropdownMenuItem<AccountProvider>(
                              value: accountProvider,
                              child: Text(
                                accountProvider.name,
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged:
                          _isRefreshing ? null : _onSelectAccountProvider,
                      underline: SizedBox(),
                      isExpanded: true,
                      hint:
                          Text("Choose Provider", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: Visibility(
                      visible: _isRefreshing,
                      child: Container(
                        child: CircularProgressIndicator(strokeWidth: 2),
                        height: 20,
                        width: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 35),
          TextFormField(
            focusNode: _accountIDFocusNode,
            controller: _accountIDController,
            keyboardType: TextInputType.visiblePassword,
            style: TextStyle(fontSize: 15, letterSpacing: 4),
            decoration: InputDecoration(
              labelText: "Account ID",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle: Theme.of(context)
                  .inputDecorationTheme
                  .labelStyle
                  .copyWith(fontSize: 12, letterSpacing: 0),
              errorMaxLines: 2,
              errorText: _accountIDErrorText,
            ),
            onFieldSubmitted: (_) => _addLinkedAccountInit(),
            onChanged: (_) {
              this.setState(() {
                _accountIDErrorText = null;
              });
            },
          ),
          SizedBox(height: 30),
          Flexible(
            fit: FlexFit.loose,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: LoadingButton(
                loading: _loading,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Continue",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    )
                  ],
                ),
                onPressed: () {
                  FocusScope.of(context).requestFocus(_buttonFocusNode);
                  _addLinkedAccountInit();
                },
                padding: EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          )
        ],
      ),
    );
  }
}
