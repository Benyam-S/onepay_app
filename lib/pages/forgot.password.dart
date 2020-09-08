import 'dart:convert';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/custom_icons_icons.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:onepay_app/widgets/text/error.dart';
import 'package:http/http.dart' as http;
import 'package:recase/recase.dart';

class ForgotPassword extends StatefulWidget {
  _ForgotPassword createState() => _ForgotPassword();
}

class _ForgotPassword extends State<ForgotPassword> {
  FocusNode _emailFocusNode;
  FocusNode _phoneNumberFocusNode;

  TextEditingController _emailController;
  TextEditingController _phoneNumberController;

  String _emailErrorText;
  String _phoneNumberErrorText;
  String _areaCode = '+251';
  String _errorText = "";
  bool _errorFlag = false;

  bool _loading = false;
  String _currentType = "email";
  bool _success = false;

  @override
  void initState() {
    super.initState();

    _emailFocusNode = FocusNode();
    _phoneNumberFocusNode = FocusNode();

    _emailController = TextEditingController();
    _phoneNumberController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();

    _emailController.dispose();
    _phoneNumberController.dispose();
  }

  void switchType() {
    _errorFlag = false;

    if (_currentType == "email") {
      setState(() {
        _currentType = "phone";
      });
    } else if (_currentType == "phone") {
      setState(() {
        _currentType = "email";
      });
    }
  }

  String validateEmail(String value) {
    var exp = RegExp(
        r'^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

    if (!exp.hasMatch(value)) {
      return ReCase("invalid email address used").sentenceCase;
    }

    return null;
  }

  String validatePhoneNumber(String value) {
    // Means it is local phone number
    if (value.startsWith("0") && value.length == 10) {
      value = value;
    } else {
      value = _areaCode + value;
    }

    var exp = RegExp(r'^(\+\d{11,12})$|(0\d{9})$');

    if (!exp.hasMatch(value)) {
      return ReCase("invalid phone number used").sentenceCase;
    }

    return null;
  }

  String transformPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith("0") && phoneNumber.length == 10) {
      phoneNumber = phoneNumber;
    } else {
      phoneNumber = _areaCode + phoneNumber;
    }

    return phoneNumber;
  }

  Future<void> send() async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    var identifier = "";
    if (_currentType == "email") {
      identifier = _emailController.text;
    } else if (_currentType == "phone") {
      identifier = _phoneNumberController.text;
    }

    if (identifier.isEmpty) {
      if (_currentType == "email") {
        FocusScope.of(context).requestFocus(_emailFocusNode);
        return;
      } else if (_currentType == "phone") {
        FocusScope.of(context).requestFocus(_phoneNumberFocusNode);
        return;
      }
    }

    if (_currentType == "email") {
      var emailError = validateEmail(identifier);
      if (emailError != null) {
        setState(() {
          _emailErrorText = emailError;
        });
        return;
      }
    } else if (_currentType == "phone") {
      var phoneNumberError = validatePhoneNumber(identifier);
      if (phoneNumberError != null) {
        setState(() {
          _phoneNumberErrorText = phoneNumberError;
        });
        return;
      }
    }

    // Removing the final error at the start
    setState(() {
      _loading = true;
      _errorFlag = false;
      _errorText = "";
      _emailErrorText = null;
      _phoneNumberErrorText = null;
    });

    var requester = HttpRequester(path: "/user/password/rest/init.json");
    try {
      var response =
          await http.post(requester.requestURL, headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      }, body: <String, String>{
        'method': _currentType == "phone" ? "phone_number" : "email",
        'identifier': _currentType == "phone"
            ? transformPhoneNumber(identifier)
            : identifier,
      });

      // Stop loading after response received
      setState(() {
        _loading = false;
      });

      if (response.statusCode == 200) {
        setState(() {
          _success = true;
        });
        return;
      } else {
        String error = "";
        switch (response.statusCode) {
          case 400:
            var jsonData = json.decode(response.body);
            if (jsonData["error"] == "invalid identifier used") {
              setState(() {
                if (_currentType == "email") {
                  _emailErrorText = ReCase(
                          "Unable to find user registered with this email address")
                      .sentenceCase;
                } else if (_currentType == "phone") {
                  _phoneNumberErrorText = ReCase(
                          "Unable to find user registered with this phone number")
                      .sentenceCase;
                }
              });
              return;
            } else {
              error = jsonData["error"];
            }
            break;
          case 500:
            error = "Unable to perform operation";
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryVariant,
        title: Text("Reset"),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryVariant,
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: _success
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Icon(
                            _currentType == "email"
                                ? CustomIcons.mail_secured
                                : CustomIcons.phone_mail_secured,
                            color: Colors.black,
                            size: 100,
                          ),
                        ),
                        Text(
                          "We have sent a rest link to your ${_currentType == "email" ? "email address" : "phone number"}. "
                          "use the link to reset your password, please don't share the reset link with any one!",
                        ),
                      ],
                    ),
                  )
                : Form(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Visibility(
                            visible: _currentType == "email",
                            child: Container(
                              margin: EdgeInsets.only(bottom: 15),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 15, bottom: 15),
                                    child: Text(
                                      "For resetting your password insert your account's email address, "
                                      "a rest link will be sent to you.",
                                      style:
                                          Theme.of(context).textTheme.headline3,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 5, bottom: 10),
                                    child: TextFormField(
                                      style: TextStyle(fontSize: 13),
                                      focusNode: _emailFocusNode,
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText: "Email",
                                        errorText: _emailErrorText,
                                        errorMaxLines: 2,
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
                                      ),
                                      onChanged: (_) => this.setState(() {
                                        _emailErrorText = null;
                                      }),
                                      onFieldSubmitted: (_) => send(),
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FlatButton(
                                      child: Text(
                                        "Can't access email address?",
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.normal,
                                            fontSize: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .fontSize),
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.zero,
                                      onPressed:
                                          _loading ? null : () => switchType(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: _currentType == "phone",
                            child: Container(
                              margin: EdgeInsets.only(bottom: 15),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 15, bottom: 15),
                                    child: Text(
                                        "For resetting your password insert your account's phone number, "
                                        "a rest link will be sent to you.",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline3),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 5, bottom: 10),
                                    child: TextFormField(
                                      style: TextStyle(fontSize: 13),
                                      focusNode: _phoneNumberFocusNode,
                                      controller: _phoneNumberController,
                                      decoration: InputDecoration(
                                        prefixIcon: CountryCodePicker(
                                          textStyle: TextStyle(fontSize: 11),
                                          initialSelection: '+251',
                                          favorite: ['+251'],
                                          onChanged:
                                              (CountryCode countryCode) =>
                                                  _areaCode =
                                                      countryCode.dialCode,
                                          alignLeft: false,
                                        ),
                                        // isDense: true,
                                        border: const OutlineInputBorder(),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
                                        labelText: "Phone number",
                                        errorText: _phoneNumberErrorText,
                                        errorMaxLines: 2,
                                        hintText: "9 * * * * * * * *",
                                      ),
                                      onChanged: (_) => this.setState(() {
                                        _phoneNumberErrorText = null;
                                      }),
                                      onFieldSubmitted: (_) => send(),
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FlatButton(
                                      child: Text(
                                        "Can't access phone number?",
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.normal,
                                            fontSize: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .fontSize),
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.zero,
                                      onPressed:
                                          _loading ? null : () => switchType(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: _errorFlag,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ErrorText(_errorText),
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
                                  "Send",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                onPressed: send,
                                padding: EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
