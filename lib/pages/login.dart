import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onepay_app/widgets/basic/dashed.border.dart';
import 'package:onepay_app/widgets/basic/logo.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:onepay_app/widgets/input/password.dart';

class Login extends StatefulWidget {
  @override
  _Login createState() => _Login();
}

class _Login extends State<Login> with TickerProviderStateMixin {
  AnimationController _rotateController;
  AnimationController _fadeController1;
  AnimationController _fadeController2;
  AnimationController _slideController;
  Tween<double> _sizeTween;
  Tween<Offset> _slideTween;
  FocusNode _identifierFocusNode;
  FocusNode _passwordFocusNode;
  TextEditingController _identifierController;
  TextEditingController _passwordController;
  bool _errorFlag = false;
  String _errorText = "";
  bool _loading = false;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _fadeController1 = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _fadeController2 = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _slideTween = Tween<Offset>(begin: Offset(0, 0.2), end: Offset(0, -1.2));
    _sizeTween = Tween<double>(begin: 1, end: 0.7);

    _fadeController1.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _slideController.forward();
        _fadeController2.forward();
      }
    });

    _passwordFocusNode = FocusNode();
    _identifierFocusNode = FocusNode();
    _identifierController = TextEditingController();
    _passwordController = TextEditingController();

    _rotateController.forward();
    _fadeController1.forward();
  }

  void login() async {
    if (_passwordController.text.isEmpty ||
        _identifierController.text.isEmpty) {
      setState(() {
        FocusScope.of(context).requestFocus(_identifierFocusNode);
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorFlag = false;
    });

    print("Making request ........");

    try {
      var response =
          await http.get(Uri.encodeFull("https://randomuser.me/api/"));
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        print(response.body);
        setState(() {
          _loading = false;
          _errorFlag = false;
        });
      } else {
        setState(() {
          _loading = false;
          _errorText = "Invalid password or identifier";
          _errorFlag = true;
        });
      }
    } on SocketException {
      setState(() {
        _loading = false;
        _errorText = "Unable to connect";
        _errorFlag = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: LayoutBuilder(builder:
            (BuildContext context, BoxConstraints viewportConstraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: viewportConstraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        child: SlideTransition(
                          position: _slideTween.animate(_slideController),
                          child: OPLogoAW(
                            rotateController: _rotateController,
                            fadeController: _fadeController1,
                            sizeController:
                                _sizeTween.animate(_slideController),
                            rotate: () {
                              _rotateController.dispose();
                              _rotateController = AnimationController(
                                vsync: this,
                                duration: Duration(seconds: 1),
                              );
                              setState(() {
                                _rotateController.forward();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      fit: FlexFit.loose,
                      child: FadeTransition(
                        opacity: _fadeController2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Form(
                                  key: _formKey,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 10, bottom: 10, right: 15),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8),
                                                child:
                                                    Icon(Icons.phone_android),
                                              ),
                                              Expanded(
                                                child: TextFormField(
                                                    focusNode:
                                                        _identifierFocusNode,
                                                    controller:
                                                        _identifierController,
                                                    style:
                                                        TextStyle(fontSize: 18),
                                                    decoration: InputDecoration(
                                                      border:
                                                          const DashedInputBorder(),
                                                      labelStyle: TextStyle(
                                                          color: Theme.of(
                                                                  context)
                                                              .primaryColor),
                                                      labelText: "Phone number",
                                                    ),
                                                    onFieldSubmitted: (_) =>
                                                        FocusScope.of(context)
                                                            .nextFocus(),
                                                    textInputAction:
                                                        TextInputAction.next),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 10, bottom: 10, right: 15),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: Icon(Icons.vpn_key),
                                              ),
                                              Expanded(
                                                child: PasswordFormField(
                                                  focusNode: _passwordFocusNode,
                                                  controller:
                                                      _passwordController,
                                                  onSubmit: (_) => login(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 10,
                                              top: 10,
                                              bottom: 20,
                                              right: 15),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Visibility(
                                                child: Text(
                                                  _errorText,
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .errorColor),
                                                ),
                                                visible: _errorFlag,
                                              ),
                                              GestureDetector(
                                                child: Text(
                                                  "Forgot Password",
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .primaryColor),
                                                ),
                                                onTap: _loading
                                                    ? null
                                                    : () => print(
                                                        "Forgot Password"),
                                              )
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 10, bottom: 25),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                fit: FlexFit.loose,
                                                child: LoadingButton(
                                                  loading: _loading,
                                                  child: Text(
                                                    "Log In",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0),
                                                  ),
                                                  onPressed:
                                                      _loading ? null : login,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 15),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 10.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                        "Don't have Account? "),
                                                    GestureDetector(
                                                      onTap: _loading
                                                          ? null
                                                          : () =>
                                                              print("Sign Up"),
                                                      child: Text(
                                                        "Sign Up.",
                                                        style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            fontSize: 17),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _identifierController.dispose();
    _rotateController.dispose();
    _fadeController2.dispose();
    _fadeController1.dispose();
    _slideController.dispose();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}
