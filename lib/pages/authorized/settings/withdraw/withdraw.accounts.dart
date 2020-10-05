import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/linked.account.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/formatter.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:recase/recase.dart';

class WithdrawLinkedAccounts extends StatefulWidget {
  _WithdrawLinkedAccounts createState() => _WithdrawLinkedAccounts();
}

class _WithdrawLinkedAccounts extends State<WithdrawLinkedAccounts> {
  List<LinkedAccount> _linkedAccounts = List<LinkedAccount>();
  TextEditingController _amountController;
  FocusNode _amountFocusNode;
  String _amount;
  String _amountErrorText;
  String _amountHint = "100.00";
  LinkedAccount _selectedLinkedAccount;
  bool _loading = false;
  bool _isRefreshing = false;

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

  void _onSelectLinkedAccount(LinkedAccount selected) {
    setState(() {
      _selectedLinkedAccount = selected;
    });
  }

  String _autoValidateAmount(String amount) {
    if (amount.isEmpty) {
      return null;
    }

    return _validateAmount(amount);
  }

  String _validateAmount(String amount) {
    try {
      // Removing comma before parsing
      if (amount.contains(",")) {
        if (RegExp(r"^(\d{1,3}(,\d{3})*(\.\d*)?|\.\d*)$").hasMatch(amount)) {
          amount = amount.replaceAll(",", "");
        } else {
          return ReCase(InvalidAmountError).sentenceCase;
        }
      }

      var amountDouble = double.parse(amount);
      if (amountDouble < 5) {
        return ReCase(WithdrawBaseLimitError).sentenceCase;
      }
    } catch (e) {
      return ReCase(InvalidAmountError).sentenceCase;
    }

    return null;
  }

  Future<void> _onWithdrawSuccess(Response response) async {
    showSuccessDialog(context,
        "You have successfully withdrawn ${CurrencyInputFormatter().toCurrency(_amount)} ETB to linked account ${_selectedLinkedAccount.accountID}.");
  }

  void _onWithdrawError(Response response) {
    if (response.statusCode == HttpStatus.badRequest) {
      var jsonData = json.decode(response.body);
      var error = jsonData["error"];

      switch (error) {
        case LinkedAccountNotFoundB:
          error = LinkedAccountNotFound;
          break;
        case InsufficientBalanceErrorB:
          error = InsufficientBalanceError;
          continue inputError;
        case WithdrawBaseLimitErrorB:
          error = WithdrawBaseLimitError;
          continue inputError;
        inputError:
        case "":
          FocusScope.of(context).requestFocus(_amountFocusNode);
          setState(() {
            _amountErrorText = ReCase(error).sentenceCase;
          });
          return;
      }

      showInternalError(context, ReCase(error).sentenceCase);
    } else if (response.statusCode == HttpStatus.internalServerError) {
      showServerError(context, FailedOperationError);
    } else {
      showServerError(context, SomethingWentWrongError);
    }
  }

  Future<void> _makeWithdrawRequest() async {
    var requester = HttpRequester(path: "/oauth/user/wallet/withdraw.json");
    try {
      var response = await requester.put(context, {
        "linked_account": _selectedLinkedAccount.id,
        "amount": CurrencyInputFormatter().toDouble(_amount),
      });

      setState(() {
        _loading = false;
      });

      // Removing loadingDialog
      Navigator.of(context).pop();

      if (!isResponseAuthorized(context, response, _withdraw)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onWithdrawSuccess(response);
      } else {
        _onWithdrawError(response);
      }
    } on SocketException {
      setState(() {
        _loading = false;
      });

      // Removing loadingDialog
      Navigator.of(context).pop();

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

      // Removing loadingDialog
      Navigator.of(context).pop();

      showServerError(context, SomethingWentWrongError);
    }
  }

  void _withdraw() async {
    if (_loading) {
      return;
    }

    _amount = _amountController.text;

    if (_selectedLinkedAccount == null) {
      return;
    }

    if (_amount.isEmpty) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
      return;
    }

    var amountError = _validateAmount(_amount);
    if (amountError != null) {
      setState(() {
        _amountErrorText = amountError;
      });
      return;
    }

    setState(() {
      _loading = true;
      _amountErrorText = null;
    });

    showLoaderDialog(context);
    await _makeWithdrawRequest();
  }

  void _onGetLinkedAccountsSuccess(Response response) {
    List<dynamic> jsonData = json.decode(response.body);

    jsonData.forEach((json) {
      LinkedAccount linkedAccount = LinkedAccount.fromJson(json);
      // It can be used to point amount has been received yet
      linkedAccount.amount = null;
      _filterAndAdd(linkedAccount);
    });

    // Since we can't set _linkedAccounts to empty set
    // Removing all the previous linked account not found in the current response
    _linkedAccounts.removeWhere((prevLinkedAccount) {
      bool removeFlag = true;

      jsonData.forEach((json) {
        LinkedAccount newLinkedAccount = LinkedAccount.fromJson(json);
        if (prevLinkedAccount.id == newLinkedAccount.id) {
          removeFlag = false;
          return;
        }
      });

      return removeFlag;
    });

    // Sorting linked accounts
    _linkedAccounts.sort((LinkedAccount a, LinkedAccount b) {
      return a.accountProvider.compareTo(b.accountProvider);
    });

    setState(() {});

    //  Saving to the local storage
    setLocalLinkedAccounts(json.encode(_linkedAccounts));
  }

  Future<void> _makeGetLinkedAccountsRequest() async {
    var requester = HttpRequester(path: "/oauth/user/linkedaccount.json");

    try {
      var response = await requester.get(context);

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onGetLinkedAccountsSuccess(response);
      }
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {}
  }

  Future<void> _getLinkedAccounts() async {
    await _makeGetLinkedAccountsRequest();
  }

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _getLinkedAccounts();
    setState(() {
      _isRefreshing = false;
    });
  }

  void _connectivityChecker() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        _getLinkedAccounts();
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

    _amountFocusNode = FocusNode();
    _amountController = TextEditingController();

    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus) {
        setState(() {
          _amountController.text =
              CurrencyInputFormatter().toCurrency(_amountController.text);
          _amountHint = "100.00";
        });
      } else {
        setState(() {
          _amountHint = null;
        });
      }
    });

    _connectivityChecker();
    _initLinkedAccounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _getLinkedAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onLongPress: _refresh,
              child: Stack(
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: DropdownButton<LinkedAccount>(
                        value: _selectedLinkedAccount,
                        items: _linkedAccounts
                            .map(
                              (linkedAccount) =>
                                  DropdownMenuItem<LinkedAccount>(
                                value: linkedAccount,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      linkedAccount.accountProvider,
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    Text(linkedAccount.accountID,
                                        style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged:
                            _isRefreshing ? null : _onSelectLinkedAccount,
                        underline: SizedBox(),
                        isExpanded: true,
                        hint:
                            Text("Choose Account", textAlign: TextAlign.center),
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
              focusNode: _amountFocusNode,
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 15, letterSpacing: 4),
              textAlign: TextAlign.center,
              autovalidate: true,
              validator: _autoValidateAmount,
              enableInteractiveSelection: false,
              decoration: InputDecoration(
                isDense: true,
                hintText: _amountHint,
                suffixIcon: Text(
                  "ETB",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      letterSpacing: 4,
                      color: Theme.of(context).iconTheme.color),
                ),
                suffixIconConstraints: BoxConstraints(minWidth: 56),
                labelText: "Amount",
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: Theme.of(context)
                    .inputDecorationTheme
                    .labelStyle
                    .copyWith(fontSize: 12, letterSpacing: 0),
                errorMaxLines: 2,
                errorText: _amountErrorText,
              ),
              inputFormatters: [
                CurrencyInputFormatter(),
              ],
              onFieldSubmitted: (_) => _withdraw(),
              onChanged: (_) {
                this.setState(() {
                  _amountErrorText = null;
                });
              },
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: _loading ? null : _withdraw,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: pi,
                      child: Icon(
                        CustomIcons.alert,
                        size: 35,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Withdraw",
                      style: TextStyle(
                          fontSize: 15, color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
                // onPressed: _recharge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
