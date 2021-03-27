import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:onepay_app/authentication/screens/screens.dart';
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
  String _phoneNumberHint = "*  *  *   *  *  *   *  *  *  *";
  String _areaCode = '+251';
  String _countryCode = "ET";

  String _currentType = "email";

  AuthenticationBloc _localBloc;

  void _switchType() {
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

  String _validateEmail(String value) {
    var exp = RegExp(
        r'^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

    if (!exp.hasMatch(value)) {
      return ReCase("invalid email address used").sentenceCase;
    }

    return null;
  }

  Future<String> _validatePhoneNumber(String value) async {
    if (value.isEmpty) {
      return ReCase(EmptyEntryError).sentenceCase;
    }

    try {
      // Validating phone number
      await FlutterLibphonenumber().parse(await _transformPhoneNumber(value));
    } catch (e) {
      return ReCase(InvalidPhoneNumberError).sentenceCase;
    }

    return null;
  }

  Future<String> _transformPhoneNumber(String phoneNumber) async {
    try {
      Map<String, dynamic> parsed =
          await FlutterLibphonenumber().parse(_areaCode + phoneNumber);
      phoneNumber = _areaCode + parsed["national_number"];
      return phoneNumber;
    } catch (e) {}

    return phoneNumber;
  }

  void _onError(PasswordResetFailure state) {
    if (state.errorMap["error"] == InvalidIdentifierErrorB) {
      if (_currentType == "email") {
        _emailErrorText =
            ReCase("Unable to find user registered with this email address")
                .sentenceCase;
      } else if (_currentType == "phone") {
        _phoneNumberErrorText =
            ReCase("Unable to find user registered with this phone number")
                .sentenceCase;
      }

      _localBloc.add(EAuthenticationChangeState(PasswordResetLoaded()));
      return;
    }

    if (_currentType == "email") {
      _emailErrorText =
          ReCase("unable to send email to the provided address").sentenceCase;
    } else if (_currentType == "phone") {
      _phoneNumberErrorText =
          ReCase("unable to send message to the provided phone number")
              .sentenceCase;
    }

    _localBloc.add(EAuthenticationChangeState(PasswordResetLoaded()));
  }

  void _handleBuilderResponse(BuildContext context, AuthenticationState state) {
    if (state is PasswordResetFailure) {
      _onError(state);
    }
  }

  void _handleListenerResponse(
      BuildContext context, AuthenticationState state) {
    if (state is AuthenticationException) {
      var exp = state.e;
      if (exp is SocketException) {
        showUnableToConnectError(context);
        return;
      } else if (exp is AppException) {
        showServerError(context, exp.e);
        return;
      }

      showServerError(context, SomethingWentWrongError);
    } else if (state is AuthenticationOperationFailure) {
      showServerError(context, SomethingWentWrongError);
    }
  }

  void _send(BuildContext context) async {
    // Cancelling if loading
    if (_localBloc.state is PasswordResetting) {
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
      var emailError = _validateEmail(identifier);
      if (emailError != null) {
        setState(() {
          _emailErrorText = emailError;
        });
        return;
      }
    } else if (_currentType == "phone") {
      var phoneNumberError = await _validatePhoneNumber(identifier);
      if (phoneNumberError != null) {
        setState(() {
          _phoneNumberErrorText = phoneNumberError;
        });
        return;
      }
    }

    // Removing the final error at the start
    _emailErrorText = null;
    _phoneNumberErrorText = null;

    var method = _currentType == "phone" ? "phone_number" : "email";
    identifier = _currentType == "phone"
        ? await _transformPhoneNumber(identifier)
        : identifier;

    AuthenticationEvent event = EResetPassword(method, identifier);
    _localBloc.add(event);
  }

  String _getPhoneNumberHint() {
    var selectedCountry = CountryManager().countries.firstWhere(
        (element) =>
            element.phoneCode == _areaCode.replaceAll(RegExp(r'[^\d]+'), ''),
        orElse: () => null);

    String hint = selectedCountry?.exampleNumberMobileNational ??
        " *  *  *  *  *  *  *  *  *";
    hint = hint
        .replaceAll(RegExp(r'[\d]'), " * ")
        .replaceAll(RegExp(r'[\-\(\)]'), "");
    return hint;
  }

  String _formatTextController(String phoneNumber) {
    if (phoneNumber.isEmpty) return "";

    String formatted = LibPhonenumberTextFormatter(
      phoneNumberType: PhoneNumberType.mobile,
      phoneNumberFormat: PhoneNumberFormat.national,
      overrideSkipCountryCode: _countryCode,
    )
        .formatEditUpdate(
            TextEditingValue.empty, TextEditingValue(text: phoneNumber))
        .text;
    return formatted.trim();
  }

  @override
  void initState() {
    super.initState();

    FlutterLibphonenumber().init();

    _emailFocusNode = FocusNode();
    _phoneNumberFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();

    _emailController = TextEditingController();
    _phoneNumberController = TextEditingController();

    AuthenticationRepository authenticationRepo =
        BlocProvider.of<AuthenticationBloc>(context).authenticationRepository;
    _localBloc =
        AuthenticationBloc(authenticationRepository: authenticationRepo);

    _phoneNumberFocusNode.addListener(() {
      if (_phoneNumberFocusNode.hasFocus) {
        setState(() {
          _phoneNumberHint = null;
        });
      } else {
        setState(() {
          _phoneNumberHint = _getPhoneNumberHint();
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    _emailController.dispose();
    _phoneNumberController.dispose();
    _localBloc.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reset"),
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryVariant,
      body: Builder(builder: (BuildContext context) {
        return SafeArea(
          child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
              cubit: _localBloc,
              listener: _handleListenerResponse,
              builder: (context, state) {
                _handleBuilderResponse(context, state);
                return Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                    child: state is PasswordResetSuccess
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 10),
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
                                                    FloatingLabelBehavior
                                                        .always,
                                              ),
                                              onChanged: (_) =>
                                                  this.setState(() {
                                                _emailErrorText = null;
                                              }),
                                              onFieldSubmitted: (_) =>
                                                  _send(context),
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
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontFamily: 'Roboto',
                                                    fontSize: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2
                                                        .fontSize),
                                              ),
                                              padding: EdgeInsets.zero,
                                              onPressed:
                                                  state is PasswordResetting
                                                      ? null
                                                      : () => _switchType(),
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
                                              controller:
                                                  _phoneNumberController,
                                              decoration: InputDecoration(
                                                prefixIcon: CountryCodePicker(
                                                  textStyle:
                                                      TextStyle(fontSize: 11),
                                                  initialSelection:
                                                      _countryCode,
                                                  favorite: ['+251'],
                                                  onChanged: (CountryCode
                                                      countryCode) {
                                                    _countryCode =
                                                        countryCode.code;
                                                    _areaCode =
                                                        countryCode.dialCode;
                                                    _phoneNumberController
                                                            .text =
                                                        _formatTextController(
                                                            _phoneNumberController
                                                                .text);
                                                    setState(() {
                                                      _phoneNumberHint =
                                                          _getPhoneNumberHint();
                                                    });
                                                  },
                                                ),
                                                // isDense: true,
                                                border:
                                                    const OutlineInputBorder(),
                                                floatingLabelBehavior:
                                                    FloatingLabelBehavior
                                                        .always,
                                                labelText: "Phone number",
                                                errorText:
                                                    _phoneNumberErrorText,
                                                errorMaxLines: 2,
                                                hintText: _phoneNumberHint,
                                              ),
                                              enableInteractiveSelection: false,
                                              inputFormatters: [
                                                LibPhonenumberTextFormatter(
                                                  phoneNumberType:
                                                      PhoneNumberType.mobile,
                                                  phoneNumberFormat:
                                                      PhoneNumberFormat
                                                          .national,
                                                  overrideSkipCountryCode:
                                                      _countryCode,
                                                ),
                                              ],
                                              onChanged: (_) =>
                                                  this.setState(() {
                                                _phoneNumberErrorText = null;
                                              }),
                                              onFieldSubmitted: (_) =>
                                                  _send(context),
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
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontFamily: 'Roboto',
                                                    fontSize: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2
                                                        .fontSize),
                                              ),
                                              padding: EdgeInsets.zero,
                                              onPressed:
                                                  state is PasswordResetting
                                                      ? null
                                                      : () => _switchType(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, bottom: 15),
                                      child: LoadingButton(
                                        loading: state is PasswordResetting,
                                        child: Text(
                                          "Send",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        onPressed: () => _send(context),
                                        padding:
                                            EdgeInsets.symmetric(vertical: 13),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                  ),
                );
              }),
        );
      }),
    );
  }
}
