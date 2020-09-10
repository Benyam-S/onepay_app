import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/custom_icons_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:onepay_app/widgets/text/error.dart';
import 'package:recase/recase.dart';

class ViaOnePayID extends StatefulWidget {
  final Stream<int> clearErrorStream;

  ViaOnePayID({@required this.clearErrorStream});

  @override
  _ViaOnePayID createState() => _ViaOnePayID();
}

class _ViaOnePayID extends State<ViaOnePayID> {
  TextEditingController _amountController;
  TextEditingController _opIDController;
  FocusNode _amountFocusNode;
  FocusNode _opIDFocusNode;
  String _amountErrorText;
  String _opIDErrorText;
  String _errorText = "";
  bool _loading = false;
  bool _errorFlag = false;

  @override
  void initState() {
    super.initState();

    _amountFocusNode = FocusNode();
    _opIDFocusNode = FocusNode();

    _amountController = TextEditingController();
    _opIDController = TextEditingController();

    widget.clearErrorStream.listen((index) {
      if (index == 1 && mounted) {
        setState(() {
          _errorFlag = false;
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

  String autoValidateAmount(String amount) {
    if (amount.isEmpty) {
      return null;
    }

    return validateAmount(amount);
  }

  String validateAmount(String amount) {
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

  void send() async {
    var opID = _opIDController.text;
    var amount = _amountController.text;

    showLoaderDialog(context);

    var requester = HttpRequester(path: "/oauth/send/id.json");

    try {
      var response = await requester.post(context, <String, String>{
        'receiver_id': opID,
        'amount': amount,
      });

      // Removing the loading indicator
      setState(() {
        _loading = false;
      });

      // Removing loadingDialog
      Navigator.of(context).pop();

      if (!requester.isAuthorized(context, response, true)) {
        return;
      }

      if (response.statusCode == 200) {
        print("Successful..... inside send via onepay id");
      } else {
        String error = "";
        switch (response.statusCode) {
          case 400:
            var jsonData = json.decode(response.body);
            error = jsonData["error"];
            switch (error) {
              case TransactionBaseLimitError:
              case DailyTransactionLimitError:
              case InsufficientBalanceError:
                FocusScope.of(context).requestFocus(_amountFocusNode);
                this.setState(() {
                  _amountErrorText = ReCase(error).sentenceCase;
                });
                return;
              case ReceiverNotFoundError:
              case TransactionWSelfError:
                FocusScope.of(context).requestFocus(_opIDFocusNode);
                this.setState(() {
                  _opIDErrorText = ReCase(error).sentenceCase;
                });
                return;
              default:
                error = FailedOperationError;
            }
            break;
          case 500:
            error = FailedOperationError;
            break;
          default:
            error = SomethingWentWrongError;
        }

        this.setState(() {
          _errorFlag = true;
          _errorText = ReCase(error).sentenceCase;
        });
      }
    } on SocketException {
      // Removing loadingDialog
      Navigator.of(context).pop();

      setState(() {
        _loading = false;
        _errorFlag = false;
      });

      final snackBar = SnackBar(
        content: Text(ReCase(UnableToConnectError).sentenceCase),
      );
      Scaffold.of(context).showSnackBar(snackBar);
    } on AccessTokenNotFoundException {
      setState(() {
        _loading = false;
      });

      // Logging the use out
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.logInRoute, (Route<dynamic> route) => false);
    }
  }

  void verify() async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    var opID = _opIDController.text;
    var amount = _amountController.text;

    if (opID.isEmpty) {
      FocusScope.of(context).requestFocus(_opIDFocusNode);
      return;
    }

    if (amount.isEmpty) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
      return;
    }

    var amountError = validateAmount(amount);
    if (amountError != null) {
      setState(() {
        _amountErrorText = amountError;
      });
      return;
    }

    // Start loading process
    setState(() {
      _loading = true;
      _errorFlag = false;
    });

    showLoaderDialog(context);

    var requester = HttpRequester(path: "/oauth/user/$opID/profile.json");

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

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        var opUser = User.fromJson(jsonData);

        print("receiver profile found");
        print(opUser.firstName);
      } else {
        String error = "";
        switch (response.statusCode) {
          case 400:
            FocusScope.of(context).requestFocus(_opIDFocusNode);

            var jsonData = json.decode(response.body);
            error = jsonData["error"];

            this.setState(() {
              _opIDErrorText = ReCase(error).sentenceCase;
            });
            return;
          default:
            error = SomethingWentWrongError;
        }

        this.setState(() {
          _errorFlag = true;
          _errorText = ReCase(error).sentenceCase;
        });
      }
    } on SocketException {
      // Removing loadingDialog
      Navigator.of(context).pop();

      setState(() {
        _loading = false;
      });

      final snackBar =
          SnackBar(content: Text(ReCase(UnableToConnectError).sentenceCase));
      Scaffold.of(context).showSnackBar(snackBar);
    } on AccessTokenNotFoundException {
      setState(() {
        _loading = false;
      });

      // Logging the use out
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.logInRoute, (Route<dynamic> route) => false);
    }
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
                      size: vh * 0.054,
                    ),
                    SizedBox(
                      width: 15,
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
                Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _opIDController,
                        focusNode: _opIDFocusNode,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: "OnePay ID",
                          errorText: _opIDErrorText,
                        ),
                        autovalidate: true,
                        // validator: autoValidateFirstName,
                        onChanged: (_) => this.setState(() {
                          _opIDErrorText = null;
                        }),
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).nextFocus(),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.visiblePassword,
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                          focusNode: _amountFocusNode,
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 15, letterSpacing: 4),
                          textAlign: TextAlign.center,
                          autovalidate: true,
                          validator: autoValidateAmount,
                          decoration: InputDecoration(
                            hintText: "100.00",
                            suffixText: "ETB",
                            labelText: "Amount",
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelStyle:
                                TextStyle(fontSize: 12, letterSpacing: 1),
                            errorMaxLines: 2,
                            errorText: _amountErrorText,
                          ),
                          onFieldSubmitted: (_) => verify(),
                          onChanged: (_) => this.setState(() {
                                _amountErrorText = null;
                              })),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Visibility(
                    child: ErrorText(_errorText),
                    visible: _errorFlag,
                  ),
                ),
                SizedBox(
                  height: 25,
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
                    onPressed: _loading ? null : verify,
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
