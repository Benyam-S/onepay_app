import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoaderDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Container(
          height: 100,
          width: 100,
          alignment: Alignment.center,
          child: CupertinoActivityIndicator(
            radius: 18,
          ),
        ),
      ),
    );
  }
}
