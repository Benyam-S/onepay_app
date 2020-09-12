import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/models/user.dart';

class ReceiverVerificationDialog extends StatelessWidget {
  final String amount;
  final User user;
  final Function okCallback;

  ReceiverVerificationDialog(this.amount, this.user, this.okCallback);

  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Do you wish to proceed this transaction?",
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Text("Amount:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: 5,
              ),
              Text(
                this.amount,
              ),
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Row(
            children: [
              Text("OnePay ID:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: 5,
              ),
              Text(
                this.user.userID,
              ),
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Row(
            children: [
              Text("Receiver name:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: 5,
              ),
              Text(
                this.user.firstName + ' ' + this.user.lastName,
              ),
            ],
          ),
        ],
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
