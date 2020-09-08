import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/utils/custom_icons_icons.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/widgets/basic/dashed.border.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:recase/recase.dart';

class ViaQRCode extends StatefulWidget {
  _ViaQRCode createState() => _ViaQRCode();
}

class _ViaQRCode extends State<ViaQRCode> {
  TextEditingController _amountController;
  FocusNode _amountFocusNode;
  String _amountErrorText;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _amountFocusNode = FocusNode();
    _amountController = TextEditingController();

    // Setting on change handler for the textField
    _amountController.addListener(() {
      setState(() {
        _amountErrorText = null;
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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

    try {
      var amountDouble = double.parse(amount);
      if (amountDouble == 0) {
        FocusScope.of(context).requestFocus(_amountFocusNode);
        return;
      }

      if (amountDouble < 1) {
        setState(() {
          _amountErrorText =
              ReCase("Amount is less than transaction base limit").sentenceCase;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _amountErrorText = ReCase("invalid amount").sentenceCase;
      });
      return;
    }

    // Start loading process
    setState(() {
      _loading = true;
    });

    print("Making request ........");
    var requester = HttpRequester(path: "/oauth/send/code.json");

    try {
      var accessToken = OnePay.of(context).accessToken ?? await getLocalAccessToken();

      String basicAuth = 'Basic ' +
          base64Encode(
              utf8.encode('${accessToken.apiKey}:${accessToken.accessToken}'));
      var response =
          await http.post(requester.requestURL, headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'authorization': basicAuth,
      }, body: <String, String>{
        'amount': amount,
      });

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        setState(() {
          _loading = false;
        });
      } else {
        String error = "";
        switch (response.statusCode) {
          case 400:
            FocusScope.of(context).requestFocus(_amountFocusNode);
            var jsonData = json.decode(response.body);
            error = jsonData["error"];
            break;
          case 500:
            error = response.body;
            break;
          case 403:
            error = response.body;
            break;
          default:
            error = "Oops something went wrong";
        }

        setState(() {
          _loading = false;
        });
      }
    } on SocketException {
      setState(() {
        _loading = false;
      });
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
            padding: _amountErrorText != null
                ? EdgeInsets.only(left: 25, right: 25, bottom: 15)
                : EdgeInsets.only(left: 25, right: 25, bottom: 25),
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
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          focusNode: _amountFocusNode,
                          controller: _amountController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 15, letterSpacing: 4),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                              isDense: true,
                              hintText: "100.00",
                              suffixText: "ETB",
                              errorMaxLines: 2,
                              errorStyle: TextStyle(
                                  color: Theme.of(context).errorColor,
                                  fontSize: Theme.of(context)
                                      .textTheme
                                      .overline
                                      .fontSize),
                              errorText: _amountErrorText,
                              border: DashedInputBorder()),
                          readOnly: true,
                        ),
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
