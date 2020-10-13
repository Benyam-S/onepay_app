import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/linked.account.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/formatter.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/basic/dashed.border.dart';
import 'package:recase/recase.dart';

class RechargeDialog extends StatefulWidget {
  final LinkedAccount linkedAccount;
  final BuildContext context;
  final Future<void> Function(LinkedAccount) refreshAccountInfo;

  RechargeDialog(this.context, this.linkedAccount, this.refreshAccountInfo);

  @override
  _RechargeDialog createState() => _RechargeDialog();
}

class _RechargeDialog extends State<RechargeDialog> {
  TextEditingController _amountController;
  FocusNode _amountFocusNode;
  String _amount;
  String _amountErrorText;

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

      double.parse(amount);
    } catch (e) {
      return ReCase(InvalidAmountError).sentenceCase;
    }

    return null;
  }

  Future<void> _onRechargeSuccess(Response response) async {
    showSuccessDialog(widget.context,
        "You have successfully recharged your OnePay account with ${CurrencyInputFormatter().toCurrency(_amount)} ETB");

    await widget.refreshAccountInfo(widget.linkedAccount);
  }

  void _onRechargeError(Response response) {
    if (response.statusCode == HttpStatus.badRequest) {
      var jsonData = json.decode(response.body);
      var error = jsonData["error"];

      switch (error) {
        case LinkedAccountNotFoundB:
          error = LinkedAccountNotFound;
          break;
        case LinkedAccountInsufficientBalanceB:
          error = LinkedAccountInsufficientBalance;
          break;
      }

      showInternalError(widget.context, ReCase(error).sentenceCase);
    } else if (response.statusCode == HttpStatus.internalServerError) {
      showServerError(widget.context, FailedOperationError);
    } else {
      showServerError(widget.context, SomethingWentWrongError);
    }
  }

  Future<void> _makeRechargeRequest() async {
    var requester = HttpRequester(path: "/oauth/user/wallet/recharge.json");
    try {
      var response = await requester.put(widget.context, {
        "linked_account": widget.linkedAccount.id,
        "amount": CurrencyInputFormatter().toDouble(_amount),
      });

      // Removing loadingDialog
      Navigator.of(widget.context).pop();

      if (!isResponseAuthorized(widget.context, response, _recharge)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onRechargeSuccess(response);
      } else {
        _onRechargeError(response);
      }
    } on SocketException {
      // Removing loadingDialog
      Navigator.of(widget.context).pop();

      showUnableToConnectError(widget.context);
    } on AccessTokenNotFoundException {
      logout(widget.context);
    } catch (e) {
      // Removing loadingDialog
      Navigator.of(widget.context).pop();

      showServerError(widget.context, SomethingWentWrongError);
    }
  }

  void _recharge() async {
    // If this method is called after DEValidation skip
    if (mounted) {
      _amount = _amountController.text;

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
        _amountErrorText = null;
      });

      Navigator.of(context).pop();
    }

    showLoaderDialog(widget.context);

    await _makeRechargeRequest();
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _amountFocusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();

    _amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String amount = CurrencyInputFormatter()
        .toCurrency(this.widget.linkedAccount.amount?.toString());
    if (amount == null) {
      amount = "Undetermined";
    } else {
      amount += " ETB";
    }

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "--Please enter the preferred amount to deposit to your OnePay account.--",
            style: TextStyle(
                fontFamily: 'Segoe UI',
                color: Theme.of(context).iconTheme.color),
          ),
          SizedBox(height: 20),
          Text(
            widget.linkedAccount.accountProviderName,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.linkedAccount.accountID,
                style: TextStyle(color: Theme.of(context).iconTheme.color),
              ),
              Text(
                amount,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 25),
          Text(
            "Amount",
            style: TextStyle(fontSize: 14),
          ),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: TextFormField(
              focusNode: _amountFocusNode,
              controller: _amountController,
              inputFormatters: [
                CurrencyInputFormatter(),
              ],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, letterSpacing: 3),
              autofocus: true,
              autovalidate: true,
              validator: _autoValidateAmount,
              keyboardType: TextInputType.number,
              enableInteractiveSelection: false,
              decoration: InputDecoration(
                border: DashedInputBorder(),
                suffixIconConstraints: BoxConstraints(minWidth: 45),
                suffixIcon: Text(
                  "ETB",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      letterSpacing: 3,
                      color: Theme.of(context).iconTheme.color),
                ),
                errorMaxLines: 2,
                errorText: _amountErrorText,
              ),
              onFieldSubmitted: (_) => _recharge(),
              onChanged: (_) {
                this.setState(() {
                  _amountErrorText = null;
                });
              },
            ),
          ),
        ],
      ),
      actions: [
        CupertinoButton(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CustomIcons.alert,
                size: 35,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 5),
              Text(
                "Recharge",
                style: TextStyle(
                    fontSize: 15, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          onPressed: _recharge,
        ),
      ],
    );
  }
}
