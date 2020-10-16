import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:recase/recase.dart';

class UpdateEmail extends StatefulWidget {
  _UpdateEmail createState() => _UpdateEmail();
}

class _UpdateEmail extends State<UpdateEmail> {
  FocusNode _emailFocusNode;
  FocusNode _buttonFocusNode;

  TextEditingController _emailController;

  User _user;
  String _email = "";
  String _emailErrorText;
  bool _loading = false;
  bool _verificationDialog = false;

  String _validateEmail(String value) {
    if (value.isEmpty) {
      return ReCase(EmptyEntryError).sentenceCase;
    }

    var exp = RegExp(
        r'^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

    if (!exp.hasMatch(value)) {
      return ReCase(InvalidEmailAddressError).sentenceCase;
    }

    return null;
  }

  Future<void> _onSuccess(BuildContext context, Response response) async {
    setState(() {
      _verificationDialog = true;
    });
  }

  void _onError(BuildContext context, Response response) {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        var jsonData = json.decode(response.body);
        error = jsonData["error"];
        if (error == EmailAlreadyExistsErrorB) {
          error = EmailAlreadyExistsError;
        }
        setState(() {
          _emailErrorText = ReCase(error).sentenceCase;
        });
        FocusScope.of(context).requestFocus(_emailFocusNode);
        return;
      case HttpStatus.internalServerError:
        error = FailedOperationError;
        break;
      default:
        error = SomethingWentWrongError;
    }

    showServerError(context, error);
  }

  Future<void> _makeRequest(BuildContext context) async {
    var requester = HttpRequester(path: "/oauth/user/profile/email.json");
    try {
      var response = await requester.put(context, {
        'email': _email,
      });

      setState(() {
        _loading = false;
      });

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onSuccess(context, response);
      } else {
        _onError(context, response);
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

  void _updateEmail(BuildContext context) async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    _email = _emailController.text;

    // Checking similarity with the previous email address
    if (_email == _user?.email) {
      return;
    }

    var emailError = _validateEmail(_email);

    if (emailError != null) {
      setState(() {
        _emailErrorText = emailError;
      });
      FocusScope.of(context).requestFocus(_emailFocusNode);
      return;
    }

    setState(() {
      _loading = true;
      _emailErrorText = null;
    });

    await _makeRequest(context);
  }

  void _initUserProfile() async {
    _user = OnePay.of(context).currentUser ?? await getLocalUserProfile();
    if (_user != null) {
      _emailController.text = _user.email;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    _emailFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();

    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _initUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contact Info"),
      ),
      body: Builder(builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: _verificationDialog
              ? Column(
                  children: [
                    SizedBox(height: 50),
                    Icon(
                      CustomIcons.phone_mail,
                      size: 80,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "A verification link has been sent to $_email. "
                      "The update will be effective after verification.",
                      style: TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Text(
                        "Update your email address, "
                        "changing your email address requires verification.",
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          isDense: true,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: "Email",
                          errorText: _emailErrorText,
                        ),
                        onChanged: (_) => this.setState(() {
                          _emailErrorText = null;
                        }),
                        onFieldSubmitted: (_) => _updateEmail(context),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 25,
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
                                    "Update",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.email,
                                    color: Colors.white,
                                  )
                                ],
                              ),
                              onPressed: () {
                                FocusScope.of(context)
                                    .requestFocus(_buttonFocusNode);
                                _updateEmail(context);
                              },
                              padding: EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
        );
      }),
    );
  }
}
