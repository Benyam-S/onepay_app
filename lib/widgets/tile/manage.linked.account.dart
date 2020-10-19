import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/linked.account.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/currency.formatter.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';

class ManageLinkedAccountTile extends StatefulWidget {
  final LinkedAccount linkedAccount;
  final Future<void> Function(LinkedAccount) refreshAccountInfo;
  final Function(LinkedAccount) removeLinkedAccount;

  ManageLinkedAccountTile(
      this.linkedAccount, this.refreshAccountInfo, this.removeLinkedAccount);

  _ManageLinkedAccountTile createState() => _ManageLinkedAccountTile();
}

class _ManageLinkedAccountTile extends State<ManageLinkedAccountTile> {
  bool _isRefreshing = false;

  Future<void> _refreshAccountInfo() async {
    setState(() {
      _isRefreshing = true;
    });

    await widget.refreshAccountInfo(widget.linkedAccount);

    setState(() {
      _isRefreshing = false;
    });
  }

  void _onRemoveLinkedAccountSuccess(Response response) {
    showSuccessDialog(context,
        "You have successfully unlinked account ${widget.linkedAccount.accountID} provided by ${widget.linkedAccount.accountProviderName}.");
    widget.removeLinkedAccount(widget.linkedAccount);
  }

  void _onRemoveLinkedAccountError(Response response) {
    showServerError(context, "Unable to unlink account");
  }

  Future<void> _removeLinkedAccount() async {
    showLoaderDialog(context);

    var requester = HttpRequester(path: "/oauth/user/linkedaccount.json");
    try {
      var response = await requester.delete(context, {
        "linked_account": widget.linkedAccount.id,
      });

      // Removing loadingDialog
      Navigator.of(context).pop();

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onRemoveLinkedAccountSuccess(response);
      } else {
        _onRemoveLinkedAccountError(response);
      }
    } on SocketException {
      // Removing loadingDialog
      Navigator.of(context).pop();

      showUnableToConnectError(context);
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {
      // Removing loadingDialog
      Navigator.of(context).pop();

      showServerError(context, SomethingWentWrongError);
    }
  }

  void _initRemoveLinkedAccount() {
    showRemoveLinkedAccountDialog(
        context, widget.linkedAccount, _removeLinkedAccount);
  }

  @override
  Widget build(BuildContext context) {
    String amount = CurrencyInputFormatter()
        .toCurrency(widget.linkedAccount.amount?.toString());
    double amountSize;

    if (amount == null) {
      amount = "Undetermined";
    } else {
      amount += " ETB";
      amountSize = 13;
    }

    return Stack(
      children: [
        InkWell(
          onLongPress: _refreshAccountInfo,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    widget.linkedAccount.accountProviderName.length > 1
                        ? widget.linkedAccount.accountProviderName[0]
                        : "",
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Theme.of(context).primaryColor)),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.linkedAccount.accountProviderName,
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 2 + (amountSize == null ? 2.0 : 0.0)),
                      Row(
                        textBaseline: TextBaseline.alphabetic,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.linkedAccount.accountID),
                          Row(
                            children: [
                              Visibility(
                                visible: !_isRefreshing,
                                child: Text(amount,
                                    style: TextStyle(
                                      fontSize: amountSize,
                                    )),
                              ),
                              Visibility(
                                visible: _isRefreshing,
                                child: Container(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 3),
                                  height: 20,
                                  width: 20,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 8,
          child: Container(
            padding: const EdgeInsets.only(right: 20),
            child: CupertinoButton(
              onPressed: _initRemoveLinkedAccount,
              padding: EdgeInsets.zero,
              minSize: 0,
              child: Icon(Icons.remove_circle_outline,
                  color: Colors.deepOrangeAccent),
            ),
          ),
        ),
      ],
    );
  }
}
