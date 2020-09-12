import 'package:flutter/material.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:recase/recase.dart';

void showUnableToConnectError(BuildContext context) {
  final snackBar = SnackBar(
    content: Text(
      ReCase(UnableToConnectError).sentenceCase,
      style: TextStyle(color: Colors.orange),
    ),
  );
  Scaffold.of(context).showSnackBar(snackBar);
}

void showServerError(BuildContext context, String content) {
  final snackBar = SnackBar(
    content: Text(
      ReCase(content).sentenceCase,
      style: TextStyle(color: Colors.orange),
    ),
  );
  Scaffold.of(context).showSnackBar(snackBar);
}
