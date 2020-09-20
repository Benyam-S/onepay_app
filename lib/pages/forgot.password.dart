import 'dart:convert';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:http/http.dart' as http;
import 'package:recase/recase.dart';

class ForgotPassword extends StatefulWidget {
  _ForgotPassword createState() => _ForgotPassword();
}

class _ForgotPassword extends State<ForgotPassword> {
  FocusNode _emailFocusNode;
  FocusNode _phoneNumberFocusNode;
  FocusNode _buttonFocusNode;

  TextEditingController _emailController;
  TextEditingController _phoneNumberController;

  String _emailErrorText;
  String _phoneNumberErrorText;
  String _areaCode = '+251';

  bool _loading = false;
  String _currentType = "email";
  bool _success = false;
  String _phoneNumberHint = "9 * * * * * * * *";

  @override
  void initState() {
    super.initState();

    _emailFocusNode = FocusNode();
    _phoneNumberFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();

    _emailController = TextEditingController();
    _phoneNumberController = TextEditingController();

    _phoneNumberFocusNode.addListener(() {
      if (_phoneNumberFocusNode.hasFocus) {
        setState(() {
          _phoneNumberHint = null;
        });
      } else {
        setState(() {
          _phoneNumberHint = "9 * * * * * * * *";
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    _emailController.dispose();
    _phoneNumberController.dispose();
  }

  void switchType() {
    // Removing focus
    FocusScope.of(context).requestFocus(_buttonFocusNode);

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

  void _onError(http.Response response) {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        var jsonData = json.decode(response.body);
        error = jsonData["error"];
        if (error == InvalidIdentifierErrorB) {
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
        }

        setState(() {
          if (_currentType == "email") {
            _emailErrorText =
                ReCase("unable to send email to the provided address")
                    .sentenceCase;
          } else if (_currentType == "phone") {
            _phoneNumberErrorText =
                ReCase("unable to send message to the provided phone number")
                    .sentenceCase;
          }
        });
        return;

      case HttpStatus.internalServerError:
        error = FailedOperationError;
        break;
      default:
        error = SomethingWentWrongError;
    }

    showServerError(context, error);
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode == HttpStatus.ok) {
      setState(() {
        _success = true;
      });
    } else {
      _onError(response);
    }
  }

  Future<void> _makeRequest(String identifier) async {
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

      _handleResponse(response);
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

  void _send(BuildContext context) async {
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
      _emailErrorText = null;
      _phoneNumberErrorText = null;
    });

    await _makeRequest(identifier);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reset"),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryVariant,
      body: Builder(builder: (BuildContext context) {
        return SafeArea(
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline3,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, bottom: 5),
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
                                        onFieldSubmitted: (_) => _send(context),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: CupertinoButton(
                                        child: Text(
                                          "Can't access email address?",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontWeight: FontWeight.normal,
                                              fontFamily: 'Roboto',
                                              fontSize: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2
                                                  .fontSize),
                                        ),
                                        padding: EdgeInsets.zero,
                                        onPressed: _loading
                                            ? null
                                            : () => switchType(),
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
                                          top: 5, bottom: 5),
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
                                          hintText: _phoneNumberHint,
                                        ),
                                        onChanged: (_) => this.setState(() {
                                          _phoneNumberErrorText = null;
                                        }),
                                        onFieldSubmitted: (_) => _send(context),
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: CupertinoButton(
                                        child: Text(
                                          "Can't access phone number?",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontWeight: FontWeight.normal,
                                              fontFamily: 'Roboto',
                                              fontSize: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2
                                                  .fontSize),
                                        ),
                                        padding: EdgeInsets.zero,
                                        onPressed: _loading
                                            ? null
                                            : () => switchType(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 5, bottom: 15),
                                child: LoadingButton(
                                  loading: _loading,
                                  child: Text(
                                    "Send",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  onPressed: () => _send(context),
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
        );
      }),
    );
  }
}
