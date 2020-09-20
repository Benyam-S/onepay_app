import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:recase/recase.dart';

class DEValidationDialog extends StatefulWidget {
  // Since the DEValidationDialog interrupts a certain request flow we have to resume that flow if the validation is successful
  final Function callback;

  DEValidationDialog(this.callback);

  _DEValidationDialog createState() => _DEValidationDialog();
}

class _DEValidationDialog extends State<DEValidationDialog> {
  FocusNode _passwordFocusNode;
  TextEditingController _passwordController;
  String _passwordErrorText;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _passwordFocusNode = FocusNode();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void refresh() async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    var password = _passwordController.text;
    if (password.isEmpty) {
      FocusScope.of(context).requestFocus(_passwordFocusNode);
      return;
    }

    // Removing the final error at the start
    setState(() {
      _loading = true;
      _passwordErrorText = null;
    });

    var requester = HttpRequester(path: "/oauth/refresh.json");
    try {
      var response = await requester.post(context, <String, String>{
        'password': password,
      });

      // Since the dialog can be cancelled checking for availability on the tree
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      // Since it is in the validation dialog we don't have to get another dialog
      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == 200) {
        Navigator.of(context).pop();

        // Resuming the previous request flow
        if (widget.callback != null) {
          widget.callback();
        }
        return;
      } else {
        if (response.statusCode == HttpStatus.badRequest) {
          String error = "";

          FocusScope.of(context).requestFocus(_passwordFocusNode);
          var jsonData = json.decode(response.body);
          error = jsonData["error"];
          switch (error) {
            case TooManyAttemptsErrorB:
              error = TooManyAttemptsError;
              break;
            case InvalidPasswordErrorB:
              error = InvalidPasswordError;
              break;
          }
          setState(() {
            _passwordErrorText = ReCase(error).sentenceCase;
          });
        } else {
          showServerError(context, SomethingWentWrongError);
        }
      }
    } on SocketException {
      setState(() {
        _loading = false;
      });

      showUnableToConnectError(context);
    } on AccessTokenNotFoundException {
      setState(() {
        _loading = false;
      });

      // Logging the use out
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.logInRoute, (Route<dynamic> route) => false);
    } catch (e) {
      setState(() {
        _loading = false;
      });

      showServerError(context, SomethingWentWrongError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Refresh Session",
                        textAlign: TextAlign.start,
                        // style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600),
                        style: Theme.of(context)
                            .textTheme
                            .headline5
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                          child: Text(
                            "Your daily session has expired, please enter your password to refresh your session.",
                            style: Theme.of(context).textTheme.headline3,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 15),
                          child: TextFormField(
                            obscureText: true,
                            focusNode: _passwordFocusNode,
                            controller: _passwordController,
                            autofocus: true,
                            decoration: InputDecoration(
                              suffix: _loading
                                  ? Container(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ))
                                  : null,
                              enabled: !_loading,
                              labelText: "Password",
                              errorText: _passwordErrorText,
                              border: OutlineInputBorder(),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                            ),
                            onChanged: (_) => this.setState(() {
                              _passwordErrorText = null;
                            }),
                            onFieldSubmitted: (_) => refresh(),
                            keyboardType: TextInputType.visiblePassword,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CupertinoButton(
                          child: Text(
                            "Refresh",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          onPressed: _loading ? null : refresh,
                        ),
                        CupertinoButton(
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
