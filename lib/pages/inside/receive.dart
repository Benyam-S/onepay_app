import 'dart:convert';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/money.token.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/formatter.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/basic/dashed.border.dart';
import 'package:recase/recase.dart';

class Receive extends StatefulWidget {
  _Receive createState() => _Receive();
}

class _Receive extends State<Receive> {
  FocusNode _codeFocusNode;
  FocusNode _buttonFocusNode;
  TextEditingController _codeController;
  String _codeHintText = "Code Here";
  String _codeErrorText;
  bool _isCameraOpened = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _codeFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();
    _codeController = TextEditingController();

    _codeFocusNode.addListener(() {
      if (_codeFocusNode.hasFocus) {
        setState(() {
          _codeHintText = null;
        });
      } else {
        setState(() {
          _codeHintText = "Code Here";
        });
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void scan() async {
    if (_isCameraOpened) {
      return;
    }
    try {
      setState(() {
        _isCameraOpened = true;
      });
      var qrResult = await BarcodeScanner.scan();
      setState(() {
        _codeController.text = qrResult.rawContent;
        _isCameraOpened = false;
      });
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

  void getCodeInfo(String method) async {
    if (_loading) {
      return;
    }

    var code = _codeController.text;

    if (code.isEmpty) {
      FocusScope.of(context).requestFocus(_codeFocusNode);
      return;
    }

    // Start loading process
    setState(() {
      _loading = true;

      //  Removing entry errors
      _codeErrorText = null;
    });

    showLoaderDialog(context);

    var requester;
    if (method == 'pay') {
      requester = HttpRequester(path: "/oauth/pay/code.json?code=$code");
    } else if (method == 'receive') {
      requester = HttpRequester(path: "/oauth/receive/code.json?code=$code");
    } else {
      // Removing the loading indicator
      setState(() {
        _loading = false;
      });

      // Removing loadingDialog
      Navigator.of(context).pop();
      return;
    }

    try {
      var response = await requester.get(context);

      // Removing the loading indicator
      setState(() {
        _loading = false;
      });

      // Removing loadingDialog
      Navigator.of(context).pop();

      if (!requester.isAuthorized(context, response, false)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        var jsonData = json.decode(response.body);
        var moneyToken = MoneyToken.fromJson(jsonData);
        var displayAmount =
            CurrencyInputFormatter().toCurrency(moneyToken.amount.toString());

        showAmountVerificationDialog(
            context, displayAmount, method, () => proceed(moneyToken, method));
      } else {
        String error = "";
        switch (response.statusCode) {
          case HttpStatus.badRequest:
            FocusScope.of(context).requestFocus(_codeFocusNode);

            var jsonData = json.decode(response.body);
            error = jsonData["error"];

            switch (error) {
              case InvalidMoneyTokenErrorB:
                error = InvalidMoneyTokenError;
                break;
              case ExpiredMoneyTokenErrorB:
                error = ExpiredMoneyTokenError;
                break;
              case TransactionBaseLimitErrorB:
                error = TransactionBaseLimitError;
                break;
              case TransactionWSelfErrorB:
                error = TransactionWSelfError;
                break;
              case InvalidMethodErrorB:
                error = InvalidMoneyTokenError;
                break;
              case TooManyAttemptsErrorB:
                error = TooManyAttemptsError;
                break;
            }

            this.setState(() {
              _codeErrorText = ReCase(error).sentenceCase;
            });
            return;
          default:
            error = SomethingWentWrongError;
        }

        showServerError(context, error);
      }
    } on SocketException {
      // Removing loadingDialog
      Navigator.of(context).pop();

      setState(() {
        _loading = false;
      });

      showUnableToConnectError(context);
    } on AccessTokenNotFoundException {
      setState(() {
        _loading = false;
      });

      // Logging the use out
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.logInRoute, (Route<dynamic> route) => false);
    } catch (e) {
      // Removing loadingDialog
      Navigator.of(context).pop();

      setState(() {
        _loading = false;
      });

      showServerError(context, SomethingWentWrongError);
    }
  }

  void proceed(MoneyToken moneyToken, String method) async {
    var code = _codeController.text;

    showLoaderDialog(context);
    var requester;
    var successMsg;
    var amount =
        CurrencyInputFormatter().toCurrency(moneyToken.amount.toString());

    if (method == 'pay') {
      requester = HttpRequester(path: "/oauth/pay/code.json");
      successMsg =
          "You have successfully payed $amount ETB to $code code owner.";
    } else if (method == 'receive') {
      requester = HttpRequester(path: "/oauth/receive/code.json");
      successMsg =
          "You have successfully received $amount ETB from $code code owner.";
    } else {
      // Removing the loading indicator
      setState(() {
        _loading = false;
      });

      // Removing loadingDialog
      Navigator.of(context).pop();

      return;
    }

    try {
      var response = await requester.put(context, <String, String>{
        'code': code,
      });

      // Removing the loading indicator
      setState(() {
        _loading = false;
      });

      // Removing loadingDialog
      Navigator.of(context).pop();

      if (!requester.isAuthorized(
          context, response, true, () => proceed(moneyToken, method))) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _codeController.clear();
        showSuccessDialog(context, successMsg);
        return;
      } else {
        String error = "";
        switch (response.statusCode) {
          case HttpStatus.badRequest:
            FocusScope.of(context).requestFocus(_codeFocusNode);
            var jsonData = json.decode(response.body);
            error = jsonData["error"];

            switch (error) {
              case ReceiverNotFoundErrorB:
                error = ReceiverNotFoundError;
                break;
              case InvalidMoneyTokenErrorB:
                error = InvalidMoneyTokenError;
                break;
              case ExpiredMoneyTokenErrorB:
                error = ExpiredMoneyTokenError;
                break;
              case TransactionBaseLimitErrorB:
                error = TransactionBaseLimitError;
                break;
              case DailyTransactionLimitErrorB:
                error = DailyTransactionLimitSendError;
                break;
              case TransactionWSelfErrorB:
                error = TransactionWSelfError;
                break;
              case InvalidMethodErrorB:
                error = InvalidMoneyTokenError;
                break;
              case SenderNotFoundErrorB:
                error = SenderNotFoundError;
                break;
              case InsufficientBalanceErrorB:
                error = InsufficientBalanceError;
                break;
              case TooManyAttemptsErrorB:
                error = TooManyAttemptsError;
                break;
            }

            this.setState(() {
              _codeErrorText = ReCase(error).sentenceCase;
            });
            return;
          case HttpStatus.internalServerError:
            error = FailedOperationError;
            break;
          default:
            error = SomethingWentWrongError;
        }

        showServerError(context, error);
      }
    } on SocketException {
      // Removing loadingDialog
      Navigator.of(context).pop();

      setState(() {
        _loading = false;
      });

      showUnableToConnectError(context);
    } on AccessTokenNotFoundException {
      setState(() {
        _loading = false;
      });

      // Logging the use out
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.logInRoute, (Route<dynamic> route) => false);
    } catch (e) {
      // Removing loadingDialog
      Navigator.of(context).pop();

      setState(() {
        _loading = false;
      });

      showServerError(context, SomethingWentWrongError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(color: Theme.of(context).colorScheme.primaryVariant),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                      )
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 35, bottom: 15),
                          child: Text(
                              "Please enter code that you receive here to make payment or receive the amount held by the code."),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: TextFormField(
                            focusNode: _codeFocusNode,
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 15, letterSpacing: 3),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              errorMaxLines: 2,
                              hintText: _codeHintText,
                              errorText: _codeErrorText,
                              border: DashedInputBorder(),
                            ),
                            onChanged: (_) => this.setState(() {
                              _codeErrorText = null;
                            }),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              CupertinoButton(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Pay",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Icon(
                                      CustomIcons.enter,
                                      color: Theme.of(context).primaryColor,
                                    )
                                  ],
                                ),
                                onPressed: _loading
                                    ? null
                                    : () {
                                        FocusScope.of(context)
                                            .requestFocus(_buttonFocusNode);
                                        getCodeInfo('pay');
                                      },
                              ),
                              CupertinoButton(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Receive",
                                      style: TextStyle(
                                          fontSize: 15, fontFamily: 'Roboto'),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Transform.rotate(
                                      angle: -10,
                                      child: Icon(
                                        CustomIcons.enter,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    )
                                  ],
                                ),
                                onPressed: _loading
                                    ? null
                                    : () {
                                        FocusScope.of(context)
                                            .requestFocus(_buttonFocusNode);
                                        getCodeInfo('receive');
                                      },
                              ),
                            ],
                          ),
                        )
                      ]),
                ),
              ),
              Positioned(
                top: 0,
                left: MediaQuery.of(context).size.width * 0.15,
                child: Container(
                  // margin: const EdgeInsets.only(left: 50),
                  // padding: const EdgeInsets.all(15),
                  // decoration: BoxDecoration(
                  //   color: Colors.white,
                  //   shape: BoxShape.circle,
                  // ),
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    ),
                    onPressed: _isCameraOpened
                        ? null
                        : () {
                            FocusScope.of(context)
                                .requestFocus(_buttonFocusNode);
                            scan();
                          },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
