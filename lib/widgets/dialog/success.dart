import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  final String successMessage;

  SuccessDialog(this.successMessage);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Container(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                height: 100,
                width: 150,
                alignment: Alignment.center,
                child: FlareActor(
                  "assets/animations/check mark.flr",
                  animation: "check",
                  alignment: Alignment.center,
                ),
              ),
              Text(
                "Successful!",
                style: TextStyle(fontSize: 18),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 18, right: 18, top: 10),
                child: Text(
                  this.successMessage,
                  style: TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: CupertinoDialogAction(
                  child: Text(
                    "Cancel",
                    style: TextStyle(fontSize: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
