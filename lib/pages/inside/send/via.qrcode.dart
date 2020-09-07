import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/utils/custom_icons_icons.dart';
import 'package:onepay_app/widgets/basic/dashed.border.dart';
import 'package:onepay_app/widgets/button/loading.dart';

class ViaQRCode extends StatefulWidget {
  _ViaQRCode createState() => _ViaQRCode();
}

class _ViaQRCode extends State<ViaQRCode> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, bottom: 40),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      CustomIcons.barcode,
                      color: Colors.black,
                      size: 40,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      "Via Qr Code",
                      style: TextStyle(
                          fontSize: 20,
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
                          autofocus: true,
                          style: TextStyle(fontSize: 15, letterSpacing: 4),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                              hintText: "100.00",
                              suffixText: "ETB",
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
                        onPressed: () => print("1"),
                        child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "1",
                              style: TextStyle(
                                fontSize: 30,
                                color: Theme.of(context).primaryColor,
                                fontFamily: "Raleway",
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: FlatButton(
                        onPressed: () => print("2"),
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "2",
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: FlatButton(
                        onPressed: () => print("3"),
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "3",
                              style: TextStyle(
                                fontSize: 30,
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
                        onPressed: () => print("4"),
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "4",
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => print("5"),
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "5",
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => print("6"),
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "6",
                              style: TextStyle(
                                fontSize: 30,
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
                        onPressed: () => print("7"),
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "7",
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => print("8"),
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "8",
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: "Raleway",
                                color: Theme.of(context).primaryColor,
                              ),
                            )),
                      ),
                    ),
                    TableCell(
                      child: FlatButton(
                        onPressed: () => print("9"),
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "9",
                              style: TextStyle(
                                fontSize: 30,
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
                          onPressed: () => print("."),
                          child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                ".",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontFamily: "Raleway",
                                  color: Theme.of(context).primaryColor,
                                ),
                              )),
                        ),
                      ),
                      TableCell(
                        child: FlatButton(
                          onPressed: () => print("0"),
                          child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                "0",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontFamily: "Raleway",
                                  color: Theme.of(context).primaryColor,
                                ),
                              )),
                        ),
                      ),
                      TableCell(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            FlatButton(
                              onPressed: () => print("<"),
                              child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Icon(
                                    Icons.keyboard_arrow_left,
                                    size: 30,
                                    color: Theme.of(context).primaryColor,
                                  )),
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
                    onPressed: () => print("create"),
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
