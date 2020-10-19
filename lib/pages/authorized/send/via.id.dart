import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/currency.formatter.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:recase/recase.dart';

class ViaOnePayID extends StatefulWidget {
  @override
  _ViaOnePayID createState() => _ViaOnePayID();
}

class _ViaOnePayID extends State<ViaOnePayID> {
  TextEditingController _amountController;
  TextEditingController _opIDController;
  FocusNode _amountFocusNode;
  FocusNode _opIDFocusNode;
  String _amount;
  String _opID;
  String _amountErrorText;
  String _amountHint = "100.00";
  String _opIDErrorText;
  bool _loading = false;

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
      if (amountDouble < 1) {
        return ReCase(TransactionBaseLimitError).sentenceCase;
      }
    } catch (e) {
      return ReCase(InvalidAmountError).sentenceCase;
    }

    return null;
  }

  void _onSendError(Response response) {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        var jsonData = json.decode(response.body);
        error = jsonData["error"];

        switch (error) {
          case AmountParsingErrorB:
            error = InvalidAmountError;
            continue amountError;
          case TransactionBaseLimitErrorB:
            error = TransactionBaseLimitError;
            continue amountError;
          case DailyTransactionLimitErrorB:
            error = DailyTransactionLimitSendError;
            continue amountError;
          case InsufficientBalanceErrorB:
            error = InsufficientBalanceError;
            continue amountError;
          amountError:
          case TransactionBaseLimitErrorB:
            FocusScope.of(context).requestFocus(_amountFocusNode);
            this.setState(() {
              _amountErrorText = ReCase(error).sentenceCase;
            });
            return;
          case FrozenAccountErrorB:
            error = FrozenReceiverAccountError;
            continue opIDError;
          case ReceiverNotFoundErrorB:
            error = ReceiverNotFoundError;
            continue opIDError;
          case TransactionWSelfErrorB:
            error = TransactionWSelfError;
            continue opIDError;
          opIDError:
          case TransactionWSelfErrorB:
            FocusScope.of(context).requestFocus(_opIDFocusNode);
            this.setState(() {
              _opIDErrorText = ReCase(error).sentenceCase;
            });
            return;
        }
        break;
      case HttpStatus.internalServerError:
        error = FailedOperationError;
        break;
      default:
        error = SomethingWentWrongError;
    }

    showServerError(context, error);
  }

  void _onVerifyError(Response response) {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        FocusScope.of(context).requestFocus(_opIDFocusNode);

        var jsonData = json.decode(response.body);
        error = jsonData["error"];

        switch (error) {
          case "user not found":
            error = ReceiverNotFoundError;
            break;
          case FrozenAccountErrorB:
            error = FrozenReceiverAccountError;
            break;
        }

        this.setState(() {
          _opIDErrorText = ReCase(error).sentenceCase;
        });
        return;
      default:
        error = SomethingWentWrongError;
    }

    showServerError(context, error);
  }

  void _onSendSuccess(Response response) {
    showSuccessDialog(context,
        "You have successfully transferred $_amount ETB to ${_opID.toUpperCase()}.");
  }

  void _onVerifySuccess(Response response) {
    var jsonData = json.decode(response.body);
    var opUser = User.fromJson(jsonData);
    var displayAmount = CurrencyInputFormatter().toCurrency(_amount);
    showReceiverVerificationDialog(context, displayAmount, opUser, _send);
  }

  // handleResponse is a function that handles a response coming from request
  Future<void> _handleResponse(
      Future<Response> Function() requester,
      Function(Response response) onSuccess,
      Function(Response response) onError) async {
    try {
      var response = await requester();

      // Removing the loading indicator
      setState(() {
        _loading = false;
      });

      // Removing loadingDialog
      Navigator.of(context).pop();

      if (!isResponseAuthorized(context, response, _send)) {
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

  Future<Response> _makeSendRequest() async {
    var requester = HttpRequester(path: "/oauth/send/id.json");

    return await requester.post(context, <String, String>{
      'receiver_id': _opID,
      'amount': CurrencyInputFormatter().toDouble(_amount),
    });
  }

  Future<Response> _makeVerifyRequest() async {
    var requester = HttpRequester(path: "/oauth/user/$_opID/profile.json");
    return await requester.get(context);
  }

  void _send() async {
    showLoaderDialog(context);
    await _handleResponse(_makeSendRequest, _onSendSuccess, _onSendError);
  }

  void _verify() async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    _opID = _opIDController.text;
    _amount = _amountController.text;

    if (_opID.isEmpty) {
      FocusScope.of(context).requestFocus(_opIDFocusNode);
      return;
    }

    if (_amount.isEmpty) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
      return;
    }

    // Adding prefix if not added
    if (!_opID.toLowerCase().startsWith("op-")) {
      _opID = "op-" + _opID;
    }

    var amountError = _validateAmount(_amount);
    if (amountError != null) {
      setState(() {
        _amountErrorText = amountError;
      });
      return;
    }

    // Checking transaction with your own
    if (OnePay.of(context).currentUser?.userID?.toLowerCase() ==
        _opID.toLowerCase()) {
      FocusScope.of(context).requestFocus(_opIDFocusNode);
      setState(() {
        _opIDErrorText = TransactionWSelfError.sentenceCase;
      });
      return;
    }

    // Start loading process
    setState(() {
      _loading = true;

      //  Removing entry errors
      _amountErrorText = null;
      _opIDErrorText = null;
    });

    showLoaderDialog(context);

    await _handleResponse(_makeVerifyRequest, _onVerifySuccess, _onVerifyError);
  }

  @override
  void initState() {
    super.initState();

    _amountFocusNode = FocusNode();
    _opIDFocusNode = FocusNode();

    _amountController = TextEditingController();
    _opIDController = TextEditingController();

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
  }

  @override
  void dispose() {
    _amountController.dispose();
    _opIDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var vh = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      CustomIcons.onepay_logo,
                      color: Theme.of(context).primaryColor,
                      // size: 40,
                      size: vh * 0.06,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      "Via OnePay ID",
                      style: TextStyle(
                          fontSize: vh * 0.027,
                          // fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: "Raleway"),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    "Please enter an amount that you prefer to send using OnePay ID.",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                Container(
                  height: 220,
                  padding: const EdgeInsets.only(top: 25),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _opIDController,
                        focusNode: _opIDFocusNode,
                        style: TextStyle(letterSpacing: 2),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: "OnePay ID",
                          labelStyle: Theme.of(context)
                              .inputDecorationTheme
                              .labelStyle
                              .copyWith(letterSpacing: 0),
                          errorText: _opIDErrorText,
                          prefixText: "OP-",
                        ),
                        onChanged: (_) => this.setState(() {
                          _opIDErrorText = null;
                        }),
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).nextFocus(),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.visiblePassword,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        focusNode: _amountFocusNode,
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 15, letterSpacing: 4),
                        textAlign: TextAlign.center,
                        autovalidateMode: AutovalidateMode.always,
                        validator: _autoValidateAmount,
                        enableInteractiveSelection: false,
                        decoration: InputDecoration(
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
                          // suffixText: "ETB",
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
                        onFieldSubmitted: (_) => _verify(),
                        onChanged: (_) {
                          this.setState(() {
                            _amountErrorText = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, top: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: vh * 0.112,
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: LoadingButton(
                    loading: false,
                    child: Text(
                      "Send",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    onPressed: _loading ? null : _verify,
                    padding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
