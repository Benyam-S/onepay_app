import 'dart:convert';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/money.token.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/currency.formatter.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';

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
  String _method;
  String _amount;
  String _code;
  MoneyToken _moneyToken;
  String _codeHintText = "Code Here";
  String _codeErrorText;
  bool _isCameraOpened = false;
  bool _loading = false;

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

  Future<Response> _makeInfoRequest() async {
    HttpRequester requester;
    switch (_method) {
      case 'pay':
        requester = HttpRequester(path: "/oauth/pay/code.json?code=$_code");
        break;
      case 'receive':
        requester = HttpRequester(path: "/oauth/receive/code.json?code=$_code");
        break;
    }

    return await requester.get(context);
  }

  Future<Response> _makeProceedRequest() async {
    HttpRequester requester;

    switch (_method) {
      case 'pay':
        requester = HttpRequester(path: "/oauth/pay/code.json");
        break;
      case 'receive':
        requester = HttpRequester(path: "/oauth/receive/code.json");
        break;
    }

    return await requester.put(context, <String, String>{
      'code': _code,
    });
  }

  bool _isMethodValid(String method) {
    switch (method) {
      case 'pay':
      case 'receive':
        return true;
      default:
        return false;
    }
  }

  void _onInfoSuccess(Response response) {
    var jsonData = json.decode(response.body);
    _moneyToken = MoneyToken.fromJson(jsonData);
    var displayAmount =
        CurrencyInputFormatter().toCurrency(_moneyToken.amount.toString());

    showAmountVerificationDialog(context, displayAmount, _method, _proceed);
  }

  void _onProceedSuccess(Response response) {
    String successMsg;
    if (_method == 'pay') {
      successMsg =
          "You have successfully payed $_amount ETB to $_code code owner.";
    } else if (_method == 'receive') {
      successMsg =
          "You have successfully received $_amount ETB from $_code code owner.";
    }

    _codeController.clear();
    showSuccessDialog(context, successMsg);
    return;
  }

  void _onProceedError(Response response) {
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

  void _onInfoError(Response response) {
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

  Future<void> _handleResponse(
      Future<Response> Function() requester,
      Function(Response response) onSuccess,
      Function(Response response) onError) async {
    try {
      if (!_isMethodValid(_method)) {
        return;
      }

      var response = await requester();

      // Removing the loading indicator
      setState(() {
        _loading = false;
      });

      // Removing loadingDialog
      Navigator.of(context).pop();

      if (!isResponseAuthorized(context, response, _proceed)) {
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
      // Removing loadingDialog
      Navigator.of(context).pop();

      setState(() {
        _loading = false;
      });

      showServerError(context, SomethingWentWrongError);
    }
  }

  void _getCodeInfo(String method) async {
    if (_loading) {
      return;
    }

    _code = _codeController.text;
    _method = method;

    if (_code.isEmpty) {
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

    await _handleResponse(_makeInfoRequest, _onInfoSuccess, _onInfoError);
  }

  void _proceed() async {
    showLoaderDialog(context);

    _amount =
        CurrencyInputFormatter().toCurrency(_moneyToken.amount.toString());

    await _handleResponse(
        _makeProceedRequest, _onProceedSuccess, _onProceedError);
  }

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
                          padding: const EdgeInsets.only(top: 40, bottom: 15),
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
                                        _getCodeInfo('pay');
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
                                        _getCodeInfo('receive');
                                      },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 35),
                      ]),
                ),
              ),
              Positioned(
                top: 0,
                left: MediaQuery.of(context).size.width * 0.15,
                child: Container(
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    elevation: 1,
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
