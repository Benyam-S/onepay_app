import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/utils/currency.formatter.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/basic/dashed.border.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:recase/recase.dart';

class ViaQRCode extends StatefulWidget {
  _ViaQRCode createState() => _ViaQRCode();
}

class _ViaQRCode extends State<ViaQRCode> {
  TextEditingController _amountController;
  FocusNode _amountFocusNode;
  FocusNode _buttonFocusNode;
  String _amountErrorText;
  String _amountText;
  String _amountHint = '100.00';
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

  void _typeToField(String value) {
    if (!_amountFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
    }

    String currentValue = _amountController.text ?? "";
    if (value == "<") {
      currentValue = currentValue != ""
          ? currentValue.substring(0, currentValue.length - 1)
          : "";
    } else if (value == "." && currentValue.contains(".")) {
      return;
    } else {
      currentValue += value;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _amountController.addListener(() {});
      _amountController.text =
          CurrencyInputFormatter.transformAmount(currentValue);
    });
  }

  void _onError(Response response) {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        FocusScope.of(context).requestFocus(_amountFocusNode);
        var jsonData = json.decode(response.body);
        error = jsonData["error"];

        switch (error) {
          case AmountParsingErrorB:
            error = InvalidAmountError;
            break;
          case TransactionBaseLimitErrorB:
            error = TransactionBaseLimitError;
            break;
          case DailyTransactionLimitErrorB:
            error = DailyTransactionLimitSendError;
            break;
          case InsufficientBalanceErrorB:
            error = InsufficientBalanceError;
            break;
        }

        this.setState(() {
          _amountErrorText = ReCase(error).sentenceCase;
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

  void _handleResponse(Response response) {
    if (!isResponseAuthorized(context, response, _create)) {
      return;
    }

    if (response.statusCode == HttpStatus.ok) {
      var jsonData = json.decode(response.body);
      showQrCodeDialog(context, jsonData["code"], "send");
    } else {
      _onError(response);
    }
  }

  Future<void> _makeRequest(String amount) async {
    var requester = HttpRequester(path: "/oauth/send/code.json");

    try {
      var response = await requester.post(context, {
        'amount': CurrencyInputFormatter.toDouble(amount),
      });

      // Removing the loading indicator
      setState(() {
        _loading = false;
      });

      // Removing loadingDialog
      Navigator.of(context).pop();

      _handleResponse(response);
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

  void _create() async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    var amount = _amountController.text;
    if (amount.isEmpty) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
      return;
    }

    var amountError = _validateAmount(amount);
    if (amountError != null) {
      setState(() {
        _amountErrorText = amountError;
      });
      return;
    }

    // Start loading process
    setState(() {
      _loading = true;
      _amountErrorText = null;
    });

    showLoaderDialog(context);

    await _makeRequest(amount);
  }

  @override
  void initState() {
    super.initState();

    _amountFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();
    _amountController = TextEditingController();

    _amountController.addListener(() {
      // If there is no text change don't consider as change
      if (_amountText != _amountController.text) {
        setState(() {
          _amountErrorText = null;
        });
      }

      _amountText = _amountController.text;
      setState(() {
        _amountController.selection =
            TextSelection.collapsed(offset: _amountText.length);
      });
    });

    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus) {
        setState(() {
          _amountController.text =
              CurrencyInputFormatter.toCurrency(_amountController.text);
          _amountHint = '100.00';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var vh = MediaQuery.of(context).size.height;
    var verticalKeyPadding = vh * 0.014;
    var keyPadFontSize = vh * 0.039;
    var keyPadColor = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 25, right: 25),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      CustomIcons.barcode,
                      color: Theme.of(context).primaryColor,
                      // size: 40,
                      size: vh * 0.054,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      "Via Qr Code",
                      style: TextStyle(
                          fontSize: vh * 0.027,
                          // fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: "Raleway"),
                    ),
                  ],
                ),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 10),
                  height: 48,
                  child: Text(
                    "Please enter an amount that you prefer to send via the QR code.",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 70,
                        child: TextFormField(
                            focusNode: _amountFocusNode,
                            controller: _amountController,
                            autovalidateMode: AutovalidateMode.always,
                            validator: _autoValidateAmount,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 15, letterSpacing: 4),
                            textAlign: TextAlign.center,
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
                                suffixIconConstraints: BoxConstraints(),
                                // suffixText: "ETB",
                                errorMaxLines: 2,
                                errorText: _amountErrorText,
                                border: DashedInputBorder()),
                            readOnly: true,
                            showCursor: true,
                            enableInteractiveSelection: false,
                            onChanged: (_) => this.setState(() {
                                  _amountErrorText = null;
                                })),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ButtonTheme(
              shape: BeveledRectangleBorder(),
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: FlatButton(
                        onPressed: () => _typeToField("1"),
                        child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "1",
                              style: TextStyle(
                                fontSize: keyPadFontSize,
                                // fontSize: 30,
                                color: keyPadColor,
                                fontFamily: "Raleway",
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: FlatButton(
                        onPressed: () => _typeToField("2"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "2",
                              style: TextStyle(
                                fontSize: keyPadFontSize,
                                fontFamily: "Raleway",
                                color: keyPadColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: FlatButton(
                        onPressed: () => _typeToField("3"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "3",
                              style: TextStyle(
                                fontSize: keyPadFontSize,
                                fontFamily: "Raleway",
                                color: keyPadColor,
                              ),
                            )),
                      ),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: FlatButton(
                        onPressed: () => _typeToField("4"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "4",
                              style: TextStyle(
                                fontSize: keyPadFontSize,
                                fontFamily: "Raleway",
                                color: keyPadColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => _typeToField("5"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "5",
                              style: TextStyle(
                                fontSize: keyPadFontSize,
                                fontFamily: "Raleway",
                                color: keyPadColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => _typeToField("6"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "6",
                              style: TextStyle(
                                fontSize: keyPadFontSize,
                                fontFamily: "Raleway",
                                color: keyPadColor,
                              ),
                            )),
                      ),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: FlatButton(
                        onPressed: () => _typeToField("7"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "7",
                              style: TextStyle(
                                fontSize: keyPadFontSize,
                                fontFamily: "Raleway",
                                color: keyPadColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => _typeToField("8"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "8",
                              style: TextStyle(
                                fontSize: keyPadFontSize,
                                fontFamily: "Raleway",
                                color: keyPadColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => _typeToField("9"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "9",
                              style: TextStyle(
                                fontSize: keyPadFontSize,
                                fontFamily: "Raleway",
                                color: keyPadColor,
                              ),
                            )),
                      ),
                    ),
                  ]),
                  TableRow(
                    children: [
                      TableCell(
                        child: FlatButton(
                          onPressed: () => _typeToField("."),
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: verticalKeyPadding),
                              child: Text(
                                ".",
                                style: TextStyle(
                                  fontSize: keyPadFontSize,
                                  fontFamily: "Raleway",
                                  color: keyPadColor,
                                ),
                              )),
                        ),
                      ),
                      TableCell(
                        child: FlatButton(
                          onPressed: () => _typeToField("0"),
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: verticalKeyPadding),
                              child: Text(
                                "0",
                                style: TextStyle(
                                  fontSize: keyPadFontSize,
                                  fontFamily: "Raleway",
                                  color: keyPadColor,
                                ),
                              )),
                        ),
                      ),
                      TableCell(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                              child: FlatButton(
                                onLongPress: () => this.setState(() {
                                  _amountController.clear();
                                }),
                                onPressed: () => _typeToField("<"),
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: verticalKeyPadding),
                                    child: Icon(
                                      Icons.keyboard_arrow_left,
                                      size: keyPadFontSize,
                                      color: keyPadColor,
                                    )),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: LoadingButton(
                    focusNode: _buttonFocusNode,
                    loading: false,
                    child: Text(
                      "Create",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    onPressed: _loading
                        ? null
                        : () {
                            FocusScope.of(context)
                                .requestFocus(_buttonFocusNode);
                            _create();
                          },
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
