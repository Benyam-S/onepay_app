import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;

class SignUpVerify extends StatefulWidget {
  final String nonce;
  final bool visible;
  final bool absorb;
  final StreamController<String> nonceController;
  final Stream<bool> isNewStream;

  SignUpVerify({
    this.nonce,
    this.visible,
    this.absorb,
    @required this.nonceController,
    this.isNewStream,
  });

  @override
  _SignUpVerify createState() => _SignUpVerify();
}

class _SignUpVerify extends State<SignUpVerify> {
  FocusNode _otpFocusNode;
  TextEditingController _otpController;

  String _otpErrorText;
  bool _loading = false;

  GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();

    _otpFocusNode = FocusNode();
    _otpController = TextEditingController();
    _formKey = GlobalKey<FormState>();

    widget.isNewStream?.listen((event) {
      if (event) {
        setState(() {
          _otpController.clear();
          _otpErrorText = null;
          _loading = false;
        });
      }
    });
  }

  void signUpVerify() async {
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
    });

    var requester = HttpRequester(path: "/oauth/user/register/verify");
    try {
      var response =
          await http.post(requester.requestURL, headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      }, body: <String, String>{
        'nonce': nonce,
        'otp': otp,
      });

      // Stop loading after response received
      setState(() {
        _loading = false;
      });

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        var nonce = jsonData["nonce"];
        widget.nonceController.add(nonce);
      } else {
        String error = "";
        switch (response.statusCode) {
          case 400:
            error = "invalid code used";
            break;
          default:
            error = "Oops something went wrong";
        }

        setState(() {
          _otpErrorText = ReCase(error).sentenceCase;
        });
      }
    } on SocketException {
      setState(() {
        _loading = false;
        _otpErrorText = ReCase("Unable to connect").sentenceCase;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var disabled = widget.absorb ?? false;

    return Visibility(
      visible: widget.visible ?? false,
      child: AbsorbPointer(
        absorbing: widget.absorb ?? false,
        child: Form(
          key: _formKey,
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
                padding: const EdgeInsets.only(top: 5, bottom: 25),
                child: TextFormField(
                  focusNode: _otpFocusNode,
                  controller: _otpController,
                  enabled: !disabled,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: "OTP",
                    labelStyle:
                        TextStyle(color: Theme.of(context).primaryColor),
                    errorText: _otpErrorText,
                    errorStyle: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.overline.fontSize),
                  ),
                  onChanged: (_) => this.setState(() {
                    _otpErrorText = null;
                  }),
                  onFieldSubmitted: (_) => signUpVerify(),
                  keyboardType: TextInputType.visiblePassword,
                ),
              ),
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
                    onPressed: signUpVerify,
                    padding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
