import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/pages/forgot.password.dart';
import 'package:onepay_app/pages/inside/home.dart';
import 'package:onepay_app/pages/login.dart';
import 'package:onepay_app/pages/signup/signup.dart';
import 'package:onepay_app/utils/routes.dart';

void main() {
  runApp(OnePay());
}

class OnePay extends StatefulWidget {
  @override
  _OnePay createState() => _OnePay();

  static _OnePay of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppState>().appState;
  }
}

class _AppState extends InheritedWidget {
  final State<OnePay> appState;

  _AppState({Key key, @required Widget child, @required this.appState})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return oldWidget.child != this.child;
  }
}

class _OnePay extends State<OnePay> {
  StreamController _appStateController = StreamController.broadcast();
  Stream _accessTokenStream;
  Stream _userStream;
  AccessToken accessToken;
  User currentUser;

  Stream get accessTokenStream => this._accessTokenStream;
  Stream get userStream => this._userStream;
  StreamController get appStateController => this._appStateController;

  _OnePay() {
    this._accessTokenStream =
        _appStateController.stream.where((event) => event is AccessToken);

    this._userStream =
        _appStateController.stream.where((event) => event is User);

    this._accessTokenStream.listen((accessToken) {
      this.accessToken = accessToken as AccessToken;
    });

    this._userStream.listen((user) {
      this.currentUser = user as User;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AppState(
      appState: this,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            inputDecorationTheme: InputDecorationTheme(
              border: const OutlineInputBorder(),
              labelStyle: TextStyle(color: Color.fromRGBO(4, 148, 255, 1)),
              errorStyle: TextStyle(fontSize: 9, fontFamily: "Segoe UI"),
            ),
            snackBarTheme: SnackBarThemeData(
                backgroundColor: Color.fromRGBO(78, 78, 78, 1),
                contentTextStyle: TextStyle(fontSize: 11)),
            appBarTheme: AppBarTheme(color: Color.fromRGBO(6, 103, 208, 1)),
            tabBarTheme: TabBarTheme(
                labelPadding: EdgeInsets.zero,
                unselectedLabelColor: Color.fromRGBO(4, 148, 255, 1),
                labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Raleway"),
                unselectedLabelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Raleway")),
            iconTheme: IconThemeData(color: Color.fromRGBO(120, 120, 120, 1)),
            primaryColor: Color.fromRGBO(4, 148, 255, 1),
            backgroundColor: Color.fromRGBO(249, 250, 254, 1),
            textTheme: TextTheme(
                bodyText2: TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    fontFamily: "Segoe UI"),
                subtitle1:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                overline: TextStyle(fontSize: 9),
                headline3: Theme.of(context)
                    .textTheme
                    .headline6
                    .copyWith(fontSize: 10, fontFamily: "Segoe UI"),
                headline5: Theme.of(context)
                    .textTheme
                    .headline6
                    .copyWith(fontSize: 15, fontFamily: "Segoe UI"),
                headline6: Theme.of(context)
                    .textTheme
                    .headline6
                    .copyWith(fontSize: 14, fontFamily: "Segoe UI")),
            buttonTheme: Theme.of(context).buttonTheme.copyWith(
                buttonColor: Color.fromRGBO(4, 148, 255, 1),
                disabledColor: Color.fromRGBO(4, 148, 255, 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                )),
            colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Color.fromRGBO(4, 148, 255, 1),
                primaryVariant: Color.fromRGBO(6, 103, 208, 1),
                secondary: Color.fromRGBO(209, 87, 17, 1),
                surface: Color.fromRGBO(120, 120, 120, 1),
                secondaryVariant: Color.fromRGBO(153, 39, 0, 1))),
        routes: {
          AppRoutes.logInRoute: (context) => Home(),
          AppRoutes.singUpRoute: (context) => SignUp(),
          AppRoutes.forgotPasswordRoute: (context) => ForgotPassword(),
          AppRoutes.homeRoute: (context) => Home(),
        },
      ),
    );
  }

  @override
  void dispose() {
    _appStateController.close();
    super.dispose();
  }
}
