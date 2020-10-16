import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:recase/recase.dart';
import 'package:http/http.dart';

class UpdatePhoneVerification extends StatefulWidget {
  final String phoneNumber;
  final String nonce;
  final Function(String) next;
  final Function back;
  final Stream clearStream;

  UpdatePhoneVerification(
      {this.phoneNumber, this.nonce, this.next, this.back, this.clearStream});

  @override
  _UpdatePhoneVerification createState() => _UpdatePhoneVerification();
}

class _UpdatePhoneVerification extends State<UpdatePhoneVerification> {
  FocusNode _buttonFocusNode;
  FocusNode _otpFocusNode;
  TextEditingController _otpController;

  String _otpErrorText;
  bool _loading = false;
  bool _reSending = false;

  Future<void> _onVerifyPhoneSuccess(Response response) async {
    User user = OnePay.of(context).currentUser?.copy() ?? await getLocalUserProfile();
    if (user != null) {
      if (widget.phoneNumber.startsWith("0") &&
          widget.phoneNumber.length == 10) {
        user.phoneNumber = widget.phoneNumber.replaceFirst("0", "+251");
      }else{
        user.phoneNumber = widget.phoneNumber;
      }

      OnePay.of(context).appStateController.add(user);
      setLocalUserProfile(user);
    }

    Navigator.of(context).pop();
    showSuccessDialog(
        context, "You have successfully updated your phone number.");
  }

  void _onVerifyPhoneError(Response response) {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        error = "invalid code used";
        setState(() {
          FocusScope.of(context).requestFocus(_otpFocusNode);
          _otpErrorText = ReCase(error).sentenceCase;
        });
        break;
      default:
        error = SomethingWentWrongError;
        showServerError(context, error);
    }
  }

  Future<void> _makeVerifyPhoneRequest(String nonce, String otp) async {
    var requester = HttpRequester(path: "/oauth/user/profile/phonenumber/verify");
    try {
      var response = await requester.put(context, {
        'nonce': nonce,
        'otp': otp,
      });

      // Stop loading after response received
      setState(() {
        _loading = false;
      });

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onVerifyPhoneSuccess(response);
      } else {
        _onVerifyPhoneError(response);
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

      logout(context);
    } catch (e) {
      setState(() {
        _loading = false;
      });

      showServerError(context, SomethingWentWrongError);
    }
  }

  void _onUpdatePhoneSuccess(Response response) {
    var jsonData = json.decode(response.body);
    widget.next(jsonData["nonce"]);
  }

  Future<void> _makeUpdatePhoneRequest() async {
    HttpRequester requester =
        HttpRequester(path: "/oauth/user/phonenumber/update.json");
    try {
      var response = await requester.post(context, {
        "phone_number": widget.phoneNumber,
      });

      setState(() {
        _reSending = false;
      });

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onUpdatePhoneSuccess(response);
      } else {
        showServerError(context, ReCase("unable to resend code").sentenceCase);
      }
    } on SocketException {
      setState(() {
        _reSending = false;
      });

      showUnableToConnectError(context);
    } on AccessTokenNotFoundException {
      setState(() {
        _reSending = false;
      });

      logout(context);
    } catch (e) {
      setState(() {
        _reSending = false;
      });

      showServerError(context, SomethingWentWrongError);
    }
  }

  void _verifyPhone() async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    var nonce = widget.nonce ?? "";
    var otp = _otpController.text;
    if (otp.isEmpty) {
      FocusScope.of(context).requestFocus(_otpFocusNode);
      return;
    }

    // Removing the final error at the start
    setState(() {
      _loading = true;
      _otpErrorText = null;
    });

    await _makeVerifyPhoneRequest(nonce, otp);
  }

  void _resend() async {
    // Cancelling if resending
    if (_reSending) {
      return;
    }

    setState(() {
      _reSending = true;
      _otpController.clear();
      _otpErrorText = null;
    });

    await _makeUpdatePhoneRequest();
  }

  @override
  void initState() {
    super.initState();

    _buttonFocusNode = FocusNode();
    _otpFocusNode = FocusNode();
    _otpController = TextEditingController();

    widget.clearStream.listen((clear) {
      if (clear) {
        setState(() {
          _otpController.clear();
          _otpErrorText = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              CupertinoButton(
                onPressed: widget.back,
                padding: EdgeInsets.zero,
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "A verification code has been sent to the provided phone number, "
                  "please input the one time code for update to be effective.",
                  style: Theme.of(context).textTheme.headline3,
                ),
              ),
            ],
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
            onFieldSubmitted: (_) => _verifyPhone(),
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
                        .copyWith(color: Theme.of(context).primaryColor),
                  ),
            onPressed: () {
              FocusScope.of(context).requestFocus(_buttonFocusNode);
              _resend();
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
                  SizedBox(width: 3),
                  Icon(
                    Icons.verified_user,
                    color: Colors.white,
                  )
                ],
              ),
              onPressed: () {
                FocusScope.of(context).requestFocus(_buttonFocusNode);
                _verifyPhone();
              },
              padding: EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        )
      ],
    );
  }
}
