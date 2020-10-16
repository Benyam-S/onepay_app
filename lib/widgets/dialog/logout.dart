import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/utils/logout.dart';

class LogoutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Are you sure you want to log out of this account?",
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CupertinoButton(
                child: Text(
                  "Log Out",
                  style: TextStyle(fontSize: 14),
                ),
                minSize: 0,
                padding: EdgeInsets.zero,
                onPressed: () => logout(context),
              ),
              CupertinoButton(
                child: Text(
                  "Cancel",
                  style: TextStyle(fontSize: 14),
                ),
                minSize: 0,
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
