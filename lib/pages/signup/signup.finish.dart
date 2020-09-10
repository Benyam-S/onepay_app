import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/custom_icons_icons.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:onepay_app/widgets/input/password.dart';
import 'package:onepay_app/widgets/text/error.dart';
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;

class SignUpFinish extends StatefulWidget {
  final String nonce;
  final bool visible;
  final Function changeStep;
  final Stream<bool> isNewStream;

  SignUpFinish({
    this.nonce,
    this.visible,
    this.changeStep,
    this.isNewStream,
  });

  _SignUpFinish createState() => _SignUpFinish();
}

class _SignUpFinish extends State<SignUpFinish> {
  FocusNode _newPasswordFocusNode;
  FocusNode _verifyPasswordFocusNode;

  TextEditingController _newPasswordController;
  TextEditingController _verifyPasswordController;

  String nonce;
  String _newPasswordErrorText;
  String _verifyPasswordErrorText;
  String _errorText = "";
  bool _errorFlag = false;
  bool _loading = false;

  GlobalKey<FormState> _formKey;

  void initState() {
    super.initState();

    _newPasswordFocusNode = FocusNode();
    _verifyPasswordFocusNode = FocusNode();

    _newPasswordController = TextEditingController();
    _verifyPasswordController = TextEditingController();

    _formKey = GlobalKey<FormState>();

    _newPasswordFocusNode.addListener(() {
      if (!_newPasswordFocusNode.hasFocus) {
        var newPassword = _newPasswordController.text;
        if (newPassword != null && newPassword.isNotEmpty) {
          setState(() {
            _newPasswordErrorText = validateNewPassword(newPassword);
          });
        }
      }
    });

    _verifyPasswordFocusNode.addListener(() {
      if (!_verifyPasswordFocusNode.hasFocus) {
        var verifyPassword = _verifyPasswordController.text;
        if (verifyPassword != null && verifyPassword.isNotEmpty) {
          setState(() {
            _verifyPasswordErrorText = validateVerifyPassword();
          });
        }
      }
    });

    widget.isNewStream?.listen((event) {
      if (event) {
        setState(() {
          _newPasswordController.clear();
          _verifyPasswordController.clear();

          _newPasswordErrorText = null;
          _verifyPasswordErrorText = null;

          _errorText = "";
          _errorFlag = false;
          _loading = false;
        });
      }
    });
  }

  // autoValidateNewPassword checks for invalid characters only
  String autoValidateNewPassword(String value) {
    if (value.isEmpty) {
      return null;
    }
    var exp = RegExp(r"^[a-zA-Z0-9\._\-&!?=#]*$");

    if (!exp.hasMatch(value)) {
      return ReCase("invalid characters used in password").sentenceCase;
    }

    return null;
  }

  String validateNewPassword(String value) {
    if (value.length < 8) {
      return ReCase("password should contain at least 8 characters")
          .sentenceCase;
    }

    var exp = RegExp(r"^[a-zA-Z0-9\._\-&!?=#]{8}[a-zA-Z0-9\._\-&!?=#]*$");

    if (!exp.hasMatch(value)) {
      return ReCase("invalid characters used in password").sentenceCase;
    }

    return null;
  }

  String validateVerifyPassword() {
    var newPassword = _newPasswordController.text;
    var verifyPassword = _verifyPasswordController.text;

    if (newPassword != verifyPassword) {
      return ReCase("password doesn't match").sentenceCase;
    }

    return null;
  }

  void signUpFinish() async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    nonce = widget.nonce ?? this.nonce;
    var newPassword = _newPasswordController.text;
    var verifyPassword = _verifyPasswordController.text;

    var newPasswordError = validateNewPassword(newPassword);
    var verifyPasswordError = validateVerifyPassword();

    if (newPasswordError != null) {
      setState(() {
        _newPasswordErrorText = newPasswordError;
      });
    }

    if (verifyPasswordError != null) {
      setState(() {
        _verifyPasswordErrorText = verifyPasswordError;
      });
    }

    if (newPasswordError != null || verifyPasswordError != null) {
      return;
    }

    // Removing the final error at the start
    setState(() {
      _loading = true;
      _errorFlag = false;
    });

    var requester = HttpRequester(path: "/oauth/user/register/finish.json");
    try {
      var response =
          await http.post(requester.requestURL, headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      }, body: <String, String>{
        'password': newPassword,
        'vPassword': verifyPassword,
        'nonce': nonce,
      });

      // Stop loading after response received
      setState(() {
        _loading = false;
      });

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        var accessToken = AccessToken.fromJson(jsonData);

        OnePay.of(context).appStateController.add(accessToken);

        // Saving data to shared preferences
        await setLocalAccessToken(accessToken);
        await setLoggedIn(true);

        setState(() {
          _loading = false;
          _errorFlag = false;
        });

        // This is only used for checking the step 3 icon
        widget.changeStep(4);

        // This delay is used to make the use comfortable with registration process
        Future.delayed(Duration(seconds: 4)).then((value) =>
            Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.homeRoute, (Route<dynamic> route) => false));
        return;
      } else {
        String error = "";
        switch (response.statusCode) {
          case 400:
            var jsonData = json.decode(response.body);

            switch (jsonData["error"]) {
              case "password should contain at least 8 characters":
                setState(() {
                  _newPasswordErrorText =
                      ReCase(jsonData["error"]).sentenceCase;
                });
                break;
              case "password should contain at least 8 characters":
                setState(() {
                  _newPasswordErrorText =
                      ReCase(jsonData["error"]).sentenceCase;
                });
                break;
              case "password does not match":
                setState(() {
                  _verifyPasswordErrorText =
                      ReCase(jsonData["error"]).sentenceCase;
                });
                break;
              default:
                setState(() {
                  _errorText = ReCase(jsonData["error"]).sentenceCase;
                  _errorFlag = true;
                });
            }
            return;
          case 500:
            error = FailedOperationError;
            break;
          default:
            error = SomethingWentWrongError;
        }

        setState(() {
          _errorText = ReCase(error).sentenceCase;
          _errorFlag = true;
        });
      }
    } on SocketException {
      setState(() {
        _loading = false;
      });

      final snackBar = SnackBar(
        content: Text(ReCase(UnableToConnectError).sentenceCase),
      );
      Scaffold.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.visible ?? false,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(
                  "Secure your account with robust password, password should be contain at least 8 characters.",
                  style: Theme.of(context).textTheme.headline3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 20),
              child: PasswordFormField(
                focusNode: _newPasswordFocusNode,
                controller: _newPasswordController,
                errorText: _newPasswordErrorText,
                autoValidate: true,
                validator: autoValidateNewPassword,
                onChanged: (_) => this.setState(() {
                  _newPasswordErrorText = null;
                }),
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                textInputAction: TextInputAction.next,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 20),
              child: TextFormField(
                focusNode: _verifyPasswordFocusNode,
                controller: _verifyPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Verify Password",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  errorText: _verifyPasswordErrorText,
                ),
                onChanged: (_) => this.setState(() {
                  _verifyPasswordErrorText = null;
                }),
                onFieldSubmitted: (_) => signUpFinish(),
                keyboardType: TextInputType.visiblePassword,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Visibility(
                      child: ErrorText(_errorText),
                      visible: _errorFlag,
                    ),
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: LoadingButton(
                      loading: _loading,
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      onPressed: signUpFinish,
                      padding: EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpCompleted extends StatelessWidget {
  final bool visible;
  final AnimationController controller;

  SignUpCompleted({this.visible, @required this.controller});

  @override
  Widget build(BuildContext context) {
    final Animation<double> offsetAnimation = Tween(begin: 0.0, end: 24.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(controller)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              controller.reverse();
            }
          });

    return Visibility(
      visible: visible ?? false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
                animation: offsetAnimation,
                builder: (buildContext, child) {
                  return Container(
                    padding: EdgeInsets.only(
                        left: offsetAnimation.value + 24.0,
                        right: 24.0 - offsetAnimation.value,
                        bottom: 10),
                    child: Center(
                      child: Icon(
                        CustomIcons.complete,
                        size: 80,
                        color: Colors.black,
                      ),
                    ),
                  );
                }),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Completed",
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
            ),
            Text(
              "Congratulations, you have taken the first step towards better controlling your personal finances!",
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}