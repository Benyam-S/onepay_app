import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/utils/custom_icons_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/widgets/basic/dashed.border.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:recase/recase.dart';

class ViaQRCode extends StatefulWidget {
  final Stream<int> clearErrorStream;

  ViaQRCode({@required this.clearErrorStream});

  _ViaQRCode createState() => _ViaQRCode();
}

class _ViaQRCode extends State<ViaQRCode> {
  TextEditingController _amountController;
  FocusNode _amountFocusNode;
  String _amountErrorText;
  String _amountText;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _amountFocusNode = FocusNode();
    _amountController = TextEditingController();

    _amountController.addListener(() {
      // If there is no text change don't consider as change
      if (_amountText != _amountController.text) {
        setState(() {
          _amountErrorText = null;
        });
      }

      _amountText = _amountController.text;
    });

    widget.clearErrorStream.listen((index) {
      if (index == 0 && mounted) {
        setState(() {
          _amountErrorText = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
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
        return ReCase(TransactionBaseLimitError)
            .sentenceCase;
      }
    } catch (e) {
      return ReCase(InvalidAmountError).sentenceCase;
    }

    return null;
  }

  void typeToField(String value) {
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

    setState(() {
      _amountController.addListener(() {});
      _amountController.text = currentValue;
    });
  }

  void create() async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    var amount = _amountController.text;
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
      _amountErrorText = null;
    });

    showLoaderDialog(context);

    var requester = HttpRequester(path: "/oauth/send/code.json");

    try {
      var response = await requester.post(context, {
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
        var jsonData = json.decode(response.body);
        showQrCodeDialog(context, jsonData["code"], "send");
      } else {
        String error = "";
        switch (response.statusCode) {
          case 400:
            FocusScope.of(context).requestFocus(_amountFocusNode);
            var jsonData = json.decode(response.body);
            error = jsonData["error"];
            break;
          case 500:
            error = FailedOperationError;
            break;
          default:
            error = SomethingWentWrongError;
        }

        this.setState(() {
          _amountErrorText = ReCase(error).sentenceCase;
        });
      }
    } on SocketException {
      // Removing loadingDialog
      Navigator.of(context).pop();

      setState(() {
        _loading = false;
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

  @override
  Widget build(BuildContext context) {
    var vh = MediaQuery.of(context).size.height;
    var verticalKeyPadding = vh * 0.014;
    var keyPaddingFontSize = vh * 0.039;

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
                      color: Colors.black,
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
                Padding(
                  padding: const EdgeInsets.only(top: 15),
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
                            autofocus: true,
                            autovalidate: true,
                            validator: autoValidateAmount,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 15, letterSpacing: 4),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                                isDense: true,
                                hintText: "100.00",
                                suffixText: "ETB",
                                errorMaxLines: 2,
                                errorText: _amountErrorText,
                                border: DashedInputBorder()),
                            readOnly: true,
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
                        onPressed: () => typeToField("1"),
                        child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "1",
                              style: TextStyle(
                                fontSize: keyPaddingFontSize,
                                // fontSize: 30,
                                color: Theme.of(context).primaryColor,
                                fontFamily: "Raleway",
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: FlatButton(
                        onPressed: () => typeToField("2"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "2",
                              style: TextStyle(
                                fontSize: keyPaddingFontSize,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: FlatButton(
                        onPressed: () => typeToField("3"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "3",
                              style: TextStyle(
                                fontSize: keyPaddingFontSize,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: FlatButton(
                        onPressed: () => typeToField("4"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "4",
                              style: TextStyle(
                                fontSize: keyPaddingFontSize,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => typeToField("5"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "5",
                              style: TextStyle(
                                fontSize: keyPaddingFontSize,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => typeToField("6"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "6",
                              style: TextStyle(
                                fontSize: keyPaddingFontSize,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: FlatButton(
                        onPressed: () => typeToField("7"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "7",
                              style: TextStyle(
                                fontSize: keyPaddingFontSize,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => typeToField("8"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "8",
                              style: TextStyle(
                                fontSize: keyPaddingFontSize,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => typeToField("9"),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: verticalKeyPadding),
                            child: Text(
                              "9",
                              style: TextStyle(
                                fontSize: keyPaddingFontSize,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                  ]),
                  TableRow(
                    children: [
                      TableCell(
                        child: FlatButton(
                          onPressed: () => typeToField("."),
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: verticalKeyPadding),
                              child: Text(
                                ".",
                                style: TextStyle(
                                  fontSize: keyPaddingFontSize,
                                  fontFamily: "Raleway",
                                  color: Theme.of(context).primaryColor,
                                ),
                              )),
                        ),
                      ),
                      TableCell(
                        child: FlatButton(
                          onPressed: () => typeToField("0"),
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: verticalKeyPadding),
                              child: Text(
                                "0",
                                style: TextStyle(
                                  fontSize: keyPaddingFontSize,
                                  fontFamily: "Raleway",
                                  color: Theme.of(context).primaryColor,
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
                                onPressed: () => typeToField("<"),
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: verticalKeyPadding),
                                    child: Icon(
                                      Icons.keyboard_arrow_left,
                                      size: keyPaddingFontSize,
                                      color: Theme.of(context).primaryColor,
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
                    loading: false,
                    child: Text(
                      "Create",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    onPressed: _loading ? null : create,
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
