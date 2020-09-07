import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/response/access.token.dart';
import 'package:onepay_app/utils/request.maker.dart';
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

        setState(() {
          _loading = false;
          _errorFlag = false;
        });

        // This is only used for checking the step 3 icon
        widget.changeStep(4);

        print(accessToken.accessToken);
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
            error = "unable to perform operation";
            break;
          default:
            error = "Oops something went wrong";
        }

        setState(() {
          _errorText = ReCase(error).sentenceCase;
          _errorFlag = true;
        });
      }
    } on SocketException {
      setState(() {
        _loading = false;
        _errorText = ReCase("Unable to connect").sentenceCase;
        _errorFlag = true;
      });
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
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Password",
                  labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  errorText: _newPasswordErrorText,
                  errorStyle: TextStyle(
                      fontSize: Theme.of(context).textTheme.overline.fontSize),
                ),
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
                  labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  errorText: _verifyPasswordErrorText,
                  errorStyle: TextStyle(
                      fontSize: Theme.of(context).textTheme.overline.fontSize),
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
