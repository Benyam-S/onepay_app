import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:recase/recase.dart';

class DEValidationDialog extends StatefulWidget {
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
      var accessToken =
          OnePay.of(context).accessToken ?? await getLocalAccessToken();

      String basicAuth = 'Basic ' +
          base64Encode(
              utf8.encode('${accessToken.apiKey}:${accessToken.accessToken}'));
      var response =
          await http.post(requester.requestURL, headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'authorization': basicAuth,
      }, body: <String, String>{
        'password': password,
      });

      // Since it is in the validation dialog we don't have to get another dialog
      if (!requester.isAuthorized(context, response, false)) {
        return;
      }

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        return;
      } else {
        String error = "";
        switch (response.statusCode) {
          case 400:
            FocusScope.of(context).requestFocus(_passwordFocusNode);
            var jsonData = json.decode(response.body);
            error = jsonData["error"];
            break;
          default:
            error = "Oops something went wrong";
        }

        setState(() {
          _loading = false;
          _passwordErrorText = ReCase(error).sentenceCase;
        });
      }
    } on SocketException {
      setState(() {
        _loading = false;
        _passwordErrorText = ReCase("Unable to connect").sentenceCase;
      });
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
                            decoration: InputDecoration(
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
