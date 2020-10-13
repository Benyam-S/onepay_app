import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/models/linked.account.dart';

class RemoveLinkedAccountDialog extends StatelessWidget {
  final LinkedAccount linkedAccount;
  final Function okCallback;

  RemoveLinkedAccountDialog(this.linkedAccount, this.okCallback);

  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Are you sure you want to unlink the selected Account?",
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Text("Account Provider:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: 5,
              ),
              Text(
                this.linkedAccount.accountProviderName,
              ),
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Row(
            children: [
              Text("Account ID:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: 5,
              ),
              Text(this.linkedAccount.accountID),
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
