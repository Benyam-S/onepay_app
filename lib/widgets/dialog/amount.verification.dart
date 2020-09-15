import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AmountVerificationDialog extends StatelessWidget {
  final String amount;
  final String method;
  final Function okCallback;

  AmountVerificationDialog(this.amount, this.method, this.okCallback);

  Widget build(BuildContext context) {
    var displayMsg = "";
    if (method == 'pay') {
      displayMsg = "You will be charged with $amount ETB.";
    } else if (method == 'receive') {
      displayMsg = "Your account will be recharged with $amount ETB.";
    }

    return AlertDialog(
      contentPadding: EdgeInsets.only(bottom: 0, left: 20, right: 20, top: 20),
      content: Text(
        "Do you wish to proceed this transaction? $displayMsg",
      ),
      actions: [
        CupertinoButton(
          child: Text(
            "Ok",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            okCallback();
          },
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
