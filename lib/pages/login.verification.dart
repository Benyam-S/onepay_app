import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:http/http.dart' as http;
import 'package:recase/recase.dart';

class LoginVerification extends StatefulWidget {
  final String nonce;

  LoginVerification(this.nonce);

  _LoginVerification createState() => _LoginVerification();
}

class _LoginVerification extends State<LoginVerification> {
  FocusNode _buttonFocusNode;
  FocusNode _otpFocusNode;
  TextEditingController _otpController;

  String _nonce;
  String _otp;
  String _otpErrorText;
  bool _loading = false;
  bool _reSending = false;

  Future<void> _onLoginVerifySuccess(
      BuildContext context, http.Response response) async {
    var jsonData = json.decode(response.body);
    var accessToken = AccessToken.fromJson(jsonData);

    OnePay.of(context).appStateController.add(accessToken);

    // Saving data to shared preferences
    await setLocalAccessToken(accessToken);
    await setLoggedIn(true);

    Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.homeRoute, (Route<dynamic> route) => false);
  }

  void _onLoginVerifyError(BuildContext context, http.Response response) {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        error = "invalid code used";
        setState(() {
          _otpErrorText = ReCase(error).sentenceCase;
        });
        break;
      default:
        error = SomethingWentWrongError;
        showServerError(context, error);
    }
  }

  void _onResendError(BuildContext context, http.Response response) {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        error = "unable to resend code";
        break;
      default:
        error = SomethingWentWrongError;
    }

    showServerError(context, error);
  }

  Future<void> _handleResponse(
      BuildContext context,
      Future<http.Response> Function() requester,
      Function(BuildContext context, http.Response response) onSuccess,
      Function(BuildContext context, http.Response response) onError) async {
    try {
      var response = await requester();

      if (response.statusCode == HttpStatus.ok) {
        if (onSuccess != null) await onSuccess(context, response);
      } else {
        onError(context, response);
      }
    } on SocketException {
      showUnableToConnectError(context);
    } catch (e) {
      showServerError(context, SomethingWentWrongError);
    }
  }

  Future<http.Response> _makeLoginVerifyRequest() async {
    var requester = HttpRequester(path: "/oauth/login/app/verify.json");

    return http.post(requester.requestURL, headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: <String, String>{
      'nonce': _nonce,
      'otp': _otp,
    });
  }

  Future<http.Response> _makeResendRequest() async {
    var requester = HttpRequester(path: "/oauth/resend");

    return http.post(requester.requestURL, headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: <String, String>{
      'message_id': MessageIDPrefix + _nonce,
    });
  }

  void _loginVerify(BuildContext context) async {
    // Cancelling if loading
    if (_loading || _reSending) {
      return;
    }

    _nonce = widget.nonce ?? "";
    _otp = _otpController.text;
    if (_otp.isEmpty) {
      FocusScope.of(context).requestFocus(_otpFocusNode);
      return;
    }

    // Removing the final error at the start
    setState(() {
      _loading = true;
      _otpErrorText = null;
    });

    await _handleResponse(context, _makeLoginVerifyRequest,
        _onLoginVerifySuccess, _onLoginVerifyError);

    // Stop loading after response received
    setState(() {
      _loading = false;
    });
  }

  void _resend(BuildContext context) async {
    // Cancelling if resending
    if (_loading || _reSending) {
      return;
    }

    _nonce = widget.nonce ?? "";

    setState(() {
      _reSending = true;
      _otpController.clear();
      _otpErrorText = null;
    });

    await _handleResponse(context, _makeResendRequest, null, _onResendError);

    setState(() {
      _reSending = false;
    });
  }

  void initState() {
    super.initState();

    _buttonFocusNode = FocusNode();
    _otpFocusNode = FocusNode();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();

    _otpController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryVariant,
      body: Builder(builder: (context) {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: Text(
                      "A verification code has been sent to your phone, please input the one time code to proceed.",
                      style: Theme.of(context).textTheme.headline3,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 15),
                    child: TextFormField(
                      focusNode: _otpFocusNode,
                      controller: _otpController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "OTP",
                        errorText: _otpErrorText,
                      ),
                      onChanged: (_) => this.setState(() {
                        _otpErrorText = null;
                      }),
                      onFieldSubmitted: (_) => _loginVerify(context),
                      keyboardType: TextInputType.visiblePassword,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CupertinoButton(
                      minSize: 0,
                      padding: EdgeInsets.zero,
                      child: _reSending
                          ? Container(
                              margin: const EdgeInsets.only(right: 5),
                              child: CircularProgressIndicator(strokeWidth: 2),
                              width: 15,
                              height: 15,
                            )
                          : Text(
                              "Didn't get code, resend.",
                              style: Theme.of(context)
                                  .textTheme
                                  .headline3
                                  .copyWith(
                                      color: Theme.of(context).primaryColor),
                            ),
                      onPressed: () {
                        FocusScope.of(context).requestFocus(_buttonFocusNode);
                        _resend(context);
                      },
                    ),
                  ),
                  SizedBox(height: 15),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: LoadingButton(
                        loading: _loading,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Verify",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            Icon(
                              Icons.verified_user,
                              color: Colors.white,
                            )
                          ],
                        ),
                        onPressed: () => _loginVerify(context),
                        padding: EdgeInsets.symmetric(vertical: 13),
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
  }
}
