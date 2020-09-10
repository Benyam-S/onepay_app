import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';

class QrCodeDialog extends StatelessWidget {
  final String code;
  final String type;

  QrCodeDialog.forSend(this.code, {this.type = "send"});

  QrCodeDialog.forPayment(this.code, {this.type = "payment"});

  void share(String code) {
    String msg = "";
    String subject = "";

    if (type == "send") {
      msg =
          "OnePay\n\nThe code: $code can be used to claim a credit provided by the sender.";
      subject = "OnePay Qr Code Value";
    } else {}

    Share.share(msg, subject: subject);
  }

  @override
  Widget build(BuildContext context) {
    String displayMessage = "";
    if (type == "send") {
      displayMessage =
          "** The provided code can be collected by scanning the QR code or using the text code. ** ";
    } else {}

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
            child: Container(
              width: 200,
              height: 200,
              child: QrImage(
                data: this.code,
                size: 200,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Your code:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 5,
                ),
                GestureDetector(
                  child: SelectableText(this.code),
                  onDoubleTap: () {
                    Clipboard.setData(ClipboardData(text: this.code))
                        .then((value) => Fluttertoast.showToast(
                              msg: "copied to clipboard",
                              textColor: Colors.white,
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Color.fromRGBO(78, 78, 78, 1),
                            ));
                  },
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
            "Share",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
          onPressed: this.code != null ? () => share(this.code) : null,
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
