import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/pages/login.verification.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/basic/logo.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:onepay_app/widgets/input/password.dart';
import 'package:onepay_app/widgets/text/error.dart';
import 'package:recase/recase.dart';

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
  FocusNode _signUpFocusNode;

  TextEditingController _identifierController;
  TextEditingController _passwordController;

  bool _errorFlag = false;
  String _errorText = "";
  bool _loading = false;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _initAnimationControllers() {
    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
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

    _fadeController1.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        isLoggedIn().then((value) {
          if (value) {
            Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.authorizedRoute, (Route<dynamic> route) => false);
          } else {
            _slideController.forward();
            _fadeController2.forward();
          }
        });
      }
    });
  }

  void _initTween() {
    _slideTween = Tween<Offset>(begin: Offset(0, 0.7), end: Offset(0, -0.2));
    _sizeTween = Tween<double>(begin: 1, end: 0.7);
  }

  void _initTextFieldControllers() {
    _passwordFocusNode = FocusNode();
    _identifierFocusNode = FocusNode();
    _signUpFocusNode = FocusNode();

    _identifierController = TextEditingController();
    _passwordController = TextEditingController();
  }

  Future<void> _onSuccess(http.Response response) async {
    var jsonData = json.decode(response.body);

    if (jsonData["type"] == "Bearer") {
      var accessToken = AccessToken.fromJson(jsonData);

      OnePay.of(context).appStateController.add(accessToken);

      // Saving data to shared preferences
      await setLocalAccessToken(accessToken);
      await setLoggedIn(true);

      setState(() {
        _errorFlag = false;
      });

      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.authorizedRoute, (Route<dynamic> route) => false);
    } else if (jsonData["type"] == "OTP") {
      print(jsonData["messageID"]);
      String nonce = jsonData["nonce"];

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LoginVerification(nonce),
        ),
      );
    }
  }

  void _onError(http.Response response) {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        var jsonData = json.decode(response.body);
        error = jsonData["error"];
        switch (error) {
          case InvalidPasswordOrIdentifierErrorB:
            FocusScope.of(context).requestFocus(_passwordFocusNode);
            error = InvalidPasswordOrIdentifierError;
            break;
          case TooManyAttemptsErrorB:
            error = TooManyAttemptsError;
            break;
        }
        break;
      case HttpStatus.forbidden:
        error = response.body;
        switch (error) {
          case FrozenAccountErrorB:
            error = FrozenAccountError;
            break;
          case FrozenAPIClientErrorB:
            error = FrozenAPIClientError;
            break;
        }
        break;
      case HttpStatus.internalServerError:
        error = FailedOperationError;
        break;
      default:
        error = SomethingWentWrongError;
    }

    switch (response.statusCode) {
      case HttpStatus.badRequest:
      case HttpStatus.forbidden:
        setState(() {
          _errorText = ReCase(error).sentenceCase;
          _errorFlag = true;
        });
        break;
      case HttpStatus.internalServerError:
      default:
        showServerError(context, error);
    }
  }

  Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == HttpStatus.ok) {
      await _onSuccess(response);
    } else {
      _onError(response);
    }
  }

  Future<void> _makeRequest(BuildContext context) async {
    var requester = HttpRequester(path: "/oauth/login/app.json");

    try {
      var response =
          await http.post(requester.requestURL, headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      }, body: <String, String>{
        'identifier': _identifierController.text,
        'password': _passwordController.text,
      });

      // Removing loader after request
      setState(() {
        _loading = false;
      });

      await _handleResponse(response);
    } on SocketException {
      setState(() {
        _loading = false;
      });

      showUnableToConnectError(context);
    } catch (e) {
      setState(() {
        _loading = false;
      });

      showServerError(context, SomethingWentWrongError);
    }
  }

  void _login(BuildContext context) async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

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

    await _makeRequest(context);
  }

  @override
  void initState() {
    super.initState();

    _initAnimationControllers();
    _initTween();
    _initTextFieldControllers();

    Future.delayed(Duration(seconds: 1)).then((value) {
      _rotateController.forward();
      _fadeController1.forward();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryVariant,
      body: Builder(builder: (BuildContext context) {
        return SafeArea(
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
                          alignment: Alignment.center,
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Form(
                                    key: _formKey,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          15, 25, 15, 15),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: TextFormField(
                                                focusNode: _identifierFocusNode,
                                                controller:
                                                    _identifierController,
                                                decoration: InputDecoration(
                                                  floatingLabelBehavior:
                                                      FloatingLabelBehavior
                                                          .always,
                                                  labelText: "Phone number",
                                                ),
                                                keyboardType: TextInputType
                                                    .visiblePassword,
                                                textInputAction:
                                                    TextInputAction.next),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                            ),
                                            child: PasswordFormField(
                                              focusNode: _passwordFocusNode,
                                              controller: _passwordController,
                                              onFieldSubmitted: (_) =>
                                                  _login(context),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 10, bottom: 15),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Visibility(
                                                  child: ErrorText(_errorText),
                                                  visible: _errorFlag,
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: CupertinoButton(
                                                    child: Text(
                                                      "Forgot Password",
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontFamily: 'Roboto',
                                                          fontSize:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyText2
                                                                  .fontSize),
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    onPressed: _loading
                                                        ? null
                                                        : () {
                                                            Navigator.of(
                                                                    context)
                                                                .pushNamed(AppRoutes
                                                                    .forgotPasswordRoute);
                                                            FocusScope.of(
                                                                    context)
                                                                .requestFocus(
                                                                    _signUpFocusNode);
                                                          },
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5),
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
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    onPressed: () =>
                                                        _login(context),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 13),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 5),
                                                  child: Row(
                                                    textBaseline:
                                                        TextBaseline.alphabetic,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .baseline,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                          "Don't have Account? "),
                                                      CupertinoButton(
                                                        child: Text(
                                                          "Sign Up.",
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                              fontFamily:
                                                                  'Roboto',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              fontSize: 15),
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        minSize: 36,
                                                        onPressed: _loading
                                                            ? null
                                                            : () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pushNamed(
                                                                        AppRoutes
                                                                            .singUpRoute);
                                                                FocusScope.of(
                                                                        context)
                                                                    .requestFocus(
                                                                        _signUpFocusNode);
                                                              },
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
        );
      }),
    );
  }
}
