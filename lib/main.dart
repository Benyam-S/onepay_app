import 'package:flutter/material.dart';
import 'package:onepay_app/pages/login.dart';

void main() {
  runApp(OnePay());
}

class OnePay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          iconTheme: IconThemeData(color: Color.fromRGBO(120, 120, 120, 1)),
          primaryColor: Color.fromRGBO(6, 103, 208, 1),
          colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Color.fromRGBO(6, 103, 208, 1),
              primaryVariant: Color.fromRGBO(4, 148, 255, 1),
              secondary: Color.fromRGBO(209, 87, 17, 1),
              secondaryVariant: Color.fromRGBO(153, 39, 0, 1))),
      home: Login(),
    );
  }
}
