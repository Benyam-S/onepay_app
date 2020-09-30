import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/money.token.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/formatter.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';

class MoneyTokenDialog extends StatelessWidget {
  final MoneyToken moneyToken;
  final BuildContext context;
  final Function removeMoneyToken;

  MoneyTokenDialog(this.context, this.moneyToken, this.removeMoneyToken);

  void _share(String code) {
    String msg = "";
    String subject = "";

    if (moneyToken.method == MethodTransferQRCodeB) {
      msg =
          "OnePay\n\nThe code: $code can be used to claim a credit provided by the sender.";
      subject = "OnePay Qr Code Value";
    } else if (moneyToken.method == MethodPaymentQRCodeB) {
      msg =
          "OnePay\n\nThe code: $code will charge the consumer with an amount held by it.";
      subject = "OnePay Qr Code Payment";
    }

    Share.share(msg, subject: subject);
  }

  void _onReclaimSuccess(Response response) {
    showSuccessDialog(context,
        "You have successfully Reclaimed ${CurrencyInputFormatter().toCurrency(moneyToken.amount.toString())} ETB.");
    removeMoneyToken(moneyToken);
  }

  void _onRemoveSuccess(Response response) {
    print("hello world");
    removeMoneyToken(moneyToken);
  }

  void _onReclaimError(Response response) {
    showServerError(context, "Unable to reclaim money token");
  }

  void _onRemoveError(Response response) {
    showServerError(context, "Unable to remove money token");
  }

  void _handleResponse(
      Future<Response> Function() requester,
      Function(Response response) onSuccess,
      Function(Response response) onError) async {
    try {
      Response response = await requester();

      // Removing loadingDialog
      Navigator.of(context).pop();

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        onSuccess(response);
      } else {
        onError(response);
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

  Future<Response> _makeReclaimMoneyTokenRequest() async {
    var requester = HttpRequester(path: "/oauth/user/moneytoken/reclaim.json");
    return requester.put(context, {"codes": moneyToken.code});
  }

  Future<Response> _makeRemoveMoneyTokenRequest() async {
    var requester = HttpRequester(path: "/oauth/user/moneytoken/remove.json");
    return requester.post(context, {"codes": moneyToken.code});
  }

  void _reclaimMoneyToken() {
    Navigator.of(context).pop();
    showLoaderDialog(context);
    _handleResponse(
        _makeReclaimMoneyTokenRequest, _onReclaimSuccess, _onReclaimError);
  }

  void _removeMoneyToken() {
    Navigator.of(context).pop();
    showLoaderDialog(context);
    _handleResponse(
        _makeRemoveMoneyTokenRequest, _onRemoveSuccess, _onRemoveError);
  }

  @override
  Widget build(BuildContext context) {
    String displayMessage = "";
    String method = "";
    String buttonName = "";
    Function callback;
    if (moneyToken.method == MethodTransferQRCodeB) {
      method = "Send Via QR Code";
      buttonName = "Reclaim";
      callback = _reclaimMoneyToken;
      displayMessage =
          "** The provided code can be collected by scanning the QR code or using the text code. ** ";
    } else if (moneyToken.method == MethodPaymentQRCodeB) {
      method = "Payment Via QR Code";
      buttonName = "Remove";
      callback = _removeMoneyToken;
      displayMessage =
          "** The provided code is used for making payment to this account, any account that uses this code "
          "will be charged with an amount held by this code. ** ";
    }

    return AlertDialog(
      title: Text(
        "Generated Code",
        style: Theme.of(context)
            .textTheme
            .headline5
            .copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onDoubleTap: () => _share(moneyToken.code),
              child: Container(
                width: 200,
                height: 200,
                child: QrImage(
                  data: moneyToken.code,
                  size: 200,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Table(
              columnWidths: {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          "Your code:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    GestureDetector(
                      child: SelectableText(moneyToken.code),
                      onDoubleTap: () {
                        Clipboard.setData(ClipboardData(text: moneyToken.code))
                            .then((value) => Fluttertoast.showToast(
                                  msg: "copied to clipboard",
                                  textColor: Colors.white,
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor:
                                      Color.fromRGBO(78, 78, 78, 1),
                                ));
                      },
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text("Created at:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                            DateFormat("yyyy-MM-dd").format(moneyToken.sentAt)),
                        Text(DateFormat(" hh:mm aaa").format(moneyToken.sentAt),
                            style: TextStyle(fontSize: 9))
                      ],
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text("Type: ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Text(method),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text("Expires at:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Row(
                      children: [
                        Text(DateFormat("yyyy-MM-dd")
                            .format(moneyToken.expirationDate)),
                        Text(
                            DateFormat(" hh:mm aaa")
                                .format(moneyToken.expirationDate),
                            style: TextStyle(fontSize: 9))
                      ],
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Text("Amount:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text(CurrencyInputFormatter()
                            .toCurrency(moneyToken.amount.toString()) +
                        " ETB"),
                  ],
                ),
              ],
            ),
          ),
          Text(
            displayMessage,
            style: TextStyle(fontFamily: "Segoe UI"),
          ),
        ],
      ),
      actions: [
        CupertinoButton(
          child: Text(
            buttonName,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
          onPressed: callback,
        ),
        CupertinoButton(
          child: Text(
            "Cancel",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],
    );
  }
}
