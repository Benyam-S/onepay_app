import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:onepay_app/widgets/input/password.dart';
import 'package:recase/recase.dart';

class ChangePassword extends StatefulWidget {
  _ChangePassword createState() => _ChangePassword();
}

class _ChangePassword extends State<ChangePassword> {
  FocusNode _oldPasswordFocusNode;
  FocusNode _newPasswordFocusNode;
  FocusNode _verifyPasswordFocusNode;

  TextEditingController _oldPasswordController;
  TextEditingController _newPasswordController;
  TextEditingController _verifyPasswordController;

  String _oldPasswordErrorText;
  String _newPasswordErrorText;
  String _verifyPasswordErrorText;
  bool _loading = false;

  String _autoValidateNewPassword(String value) {
    if (value.isEmpty) {
      return null;
    }
    var exp = RegExp(r"^[a-zA-Z0-9\._\-&!?=#]*$");

    if (!exp.hasMatch(value)) {
      return ReCase("invalid characters used in password").sentenceCase;
    }

    return null;
  }

  String _validateNewPassword(String value) {
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

  String _validateVerifyPassword() {
    var newPassword = _newPasswordController.text;
    var verifyPassword = _verifyPasswordController.text;

    if (newPassword != verifyPassword) {
      return ReCase("password doesn't match").sentenceCase;
    }

    return null;
  }

  Future<void> _onSuccess(BuildContext context, Response response) async {
    Navigator.of(context).pop();
    showSuccessDialog(context, "You have successfully updated your password.");
  }

  Future<void> _onError(BuildContext context, Response response) async {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        var jsonData = json.decode(response.body);
        error = jsonData["error"];

        switch (error) {
          case "invalid old password used":
            setState(() {
              _oldPasswordErrorText = ReCase(InvalidPasswordError).sentenceCase;
            });
            break;
          case PasswordLengthErrorB:
            setState(() {
              _newPasswordErrorText = ReCase(PasswordLengthError).sentenceCase;
            });
            break;
          case InvalidCharacterInPasswordErrorB:
            setState(() {
              _newPasswordErrorText =
                  ReCase(InvalidCharacterInPasswordError).sentenceCase;
            });
            break;
          case PasswordDontMatchErrorB:
            setState(() {
              _verifyPasswordErrorText =
                  ReCase(PasswordDontMatchError).sentenceCase;
            });
            break;
          case IdenticalPasswordErrorB:
            setState(() {
              _newPasswordErrorText =
                  ReCase(IdenticalPasswordErrorB).sentenceCase;
            });
            break;
          default:
            showServerError(context, SomethingWentWrongError);
        }
        return;
      case HttpStatus.internalServerError:
        error = FailedOperationError;
        break;
      default:
        error = SomethingWentWrongError;
    }

    showServerError(context, error);
  }

  Future<void> _handleResponse(BuildContext context, Response response) async {
    if (response.statusCode == HttpStatus.ok) {
      await _onSuccess(context, response);
    } else {
      await _onError(context, response);
    }
  }

  Future<void> _makeRequest(BuildContext context, String oldPassword,
      String newPassword, String verifyPassword) async {
    var requester = HttpRequester(path: "/oauth/user/password.json");
    try {
      var response = await requester.put(context, {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_vPassword': verifyPassword,
      });

      // Stop loading after response received
      setState(() {
        _loading = false;
      });

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      await _handleResponse(context, response);
    } on SocketException {
      setState(() {
        _loading = false;
      });

      showUnableToConnectError(context);
    } on AccessTokenNotFoundException {
      setState(() {
        _loading = false;
      });

      logout(context);
    } catch (e) {
      setState(() {
        _loading = false;
      });

      showServerError(context, SomethingWentWrongError);
    }
  }

  void _changePassword(BuildContext context) async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    var oldPassword = _oldPasswordController.text;
    var newPassword = _newPasswordController.text;
    var verifyPassword = _verifyPasswordController.text;

    var newPasswordError = _validateNewPassword(newPassword);
    var verifyPasswordError = _validateVerifyPassword();

    if (oldPassword.isEmpty) {
      _oldPasswordErrorText = ReCase(EmptyEntryError).sentenceCase;
    }

    if (newPasswordError != null) {
      _newPasswordErrorText = newPasswordError;
    }

    if (verifyPasswordError != null) {
      _verifyPasswordErrorText = verifyPasswordError;
    }

    if (newPasswordError != null ||
        verifyPasswordError != null ||
        oldPassword.isEmpty) {
      setState(() {});
      return;
    }

    setState(() {
      _loading = true;
      _oldPasswordErrorText = null;
      _newPasswordErrorText = null;
      _verifyPasswordErrorText = null;
    });

    await _makeRequest(context, oldPassword, newPassword, verifyPassword);
  }

  void initState() {
    super.initState();

    _oldPasswordFocusNode = FocusNode();
    _newPasswordFocusNode = FocusNode();
    _verifyPasswordFocusNode = FocusNode();

    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _verifyPasswordController = TextEditingController();

    _newPasswordFocusNode.addListener(() {
      if (!_newPasswordFocusNode.hasFocus) {
        var newPassword = _newPasswordController.text;
        if (newPassword != null && newPassword.isNotEmpty) {
          setState(() {
            _newPasswordErrorText = _validateNewPassword(newPassword);
          });
        }
      }
    });

    _verifyPasswordFocusNode.addListener(() {
      if (!_verifyPasswordFocusNode.hasFocus) {
        var verifyPassword = _verifyPasswordController.text;
        if (verifyPassword != null && verifyPassword.isNotEmpty) {
          setState(() {
            _verifyPasswordErrorText = _validateVerifyPassword();
          });
        }
      }
    });
  }

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Password")),
      body: Builder(
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(bottom: 15, top: 15, left: 5),
                      child: Text(
                        "Inorder to change your password, you have to provide your current password so as to verify your identity.",
                        style: Theme.of(context).textTheme.headline3,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 20),
                    child: PasswordFormField(
                      labelText: "Old Password",
                      focusNode: _oldPasswordFocusNode,
                      controller: _oldPasswordController,
                      errorText: _oldPasswordErrorText,
                      onChanged: (_) => this.setState(() {
                        _oldPasswordErrorText = null;
                      }),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 20),
                    child: PasswordFormField(
                      labelText: "New Password",
                      focusNode: _newPasswordFocusNode,
                      controller: _newPasswordController,
                      errorText: _newPasswordErrorText,
                      autoValidate: true,
                      validator: _autoValidateNewPassword,
                      onChanged: (_) => this.setState(() {
                        _newPasswordErrorText = null;
                      }),
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
                      onFieldSubmitted: (_) => _changePassword(context),
                      keyboardType: TextInputType.visiblePassword,
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
                        onPressed: () => _changePassword(context),
                        padding: EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
