import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/pages/authorized/settings/profile/update.phone.verification.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:recase/recase.dart';

class UpdatePhoneNumber extends StatefulWidget {
  _UpdatePhoneNumber createState() => _UpdatePhoneNumber();
}

class _UpdatePhoneNumber extends State<UpdatePhoneNumber> {
  FocusNode _phoneFocusNode;
  FocusNode _buttonFocusNode;

  TextEditingController _phoneController;

  User _user;
  String _phoneNumber;
  String _nonce;
  String _phoneNumberErrorText;
  String _phoneNumberHint = "";
  String _areaCode = '+251';
  String _countryCode = "ET";
  bool _loading = false;
  bool _verificationDialog = false;

  void _back() {
    setState(() {
      _verificationDialog = false;
    });
  }

  void _next(String nonce) {
    this._nonce = nonce;
    setState(() {
      _verificationDialog = true;
    });
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

  String _withCountryCode(String phoneNumber) {
    return phoneNumber + "[" + _countryCode + "]";
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

  Future<void> _onSuccess(BuildContext context, Response response) async {
    print(response.body);
    var jsonData = json.decode(response.body);
    _next(jsonData["nonce"]);
  }

  void _onError(BuildContext context, Response response) {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        var jsonData = json.decode(response.body);
        error = jsonData["error"];
        if (error == PhoneNumberAlreadyExistsErrorB) {
          error = PhoneNumberAlreadyExistsError;
        }
        setState(() {
          _phoneNumberErrorText = ReCase(error).sentenceCase;
        });
        FocusScope.of(context).requestFocus(_phoneFocusNode);
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
    var requester = HttpRequester(path: "/oauth/user/profile/phonenumber.json");
    try {
      var response = await requester.put(context, {
        'phone_number': _phoneNumber,
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

  void _updatePhone(BuildContext context) async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    _phoneNumber = _phoneController.text;
    if (_phoneNumber.isEmpty) {
      FocusScope.of(context).requestFocus(_phoneFocusNode);
      return;
    }

    // Checking similarity with the previous phone number
    _phoneNumber = await _transformPhoneNumber(_phoneNumber);
    if (_user?.onlyPhoneNumber == _phoneNumber) {
      return;
    }

    var phoneNumberError = await _validatePhoneNumber(_phoneNumber);
    if (phoneNumberError != null) {
      FocusScope.of(context).requestFocus(_phoneFocusNode);
      setState(() {
        _phoneNumberErrorText = phoneNumberError;
      });
      return;
    }

    setState(() {
      _loading = true;
      _phoneNumberErrorText = null;
    });

    _phoneNumber = _withCountryCode(_phoneNumber);
    await _makeRequest(context);
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

  void _initUserProfile() async {
    _user = OnePay.of(context).currentUser ?? await getLocalUserProfile();
    if (_user != null) {
      try {
        Future<Map<String, dynamic>> fParsed =
            FlutterLibphonenumber().parse(_user.onlyPhoneNumber);
        fParsed.then((parsed) {
          if (mounted) {
            setState(() {
              _areaCode = "+" + (parsed["country_code"]).toString();
              if (_user.countryCode != "") {
                _countryCode = _user.countryCode;
              } else {
                _countryCode = CountryManager()
                    .countries
                    .firstWhere(
                        (element) =>
                            element.phoneCode ==
                            _areaCode.replaceAll(RegExp(r'[^\d]+'), ''),
                        orElse: () => null)
                    ?.countryCode;
              }
              String formatted =
                  _formatTextController(parsed["national_number"]);
              _phoneNumberHint = _getPhoneNumberHint();
              _phoneController.text = formatted;
              _phoneController.selection =
                  TextSelection.collapsed(offset: formatted.length);
            });
          }
        });
      } catch (e) {}
    }
  }

  @override
  void initState() {
    super.initState();

    _phoneFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();

    _phoneController = TextEditingController();

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        setState(() {
          _phoneNumberHint = _getPhoneNumberHint();
        });
      } else {
        setState(() {
          _phoneNumberHint = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _verificationDialog
                ? UpdatePhoneVerification(
                    phoneNumber: _phoneNumber,
                    nonce: _nonce,
                    next: _next,
                    back: _back)
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          "Update your phone number, "
                          "changing your phone number requires verification.",
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            decoration: InputDecoration(
                              prefixIcon: CountryCodePicker(
                                textStyle: TextStyle(fontSize: 11),
                                initialSelection: _countryCode,
                                favorite: ['+251'],
                                onChanged: (CountryCode countryCode) {
                                  _countryCode = countryCode.code;
                                  _areaCode = countryCode.dialCode;
                                  _phoneController.text = _formatTextController(
                                      _phoneController.text);
                                  setState(() {
                                    _phoneNumberHint = _getPhoneNumberHint();
                                  });
                                },
                                alignLeft: false,
                              ),
                              border: const OutlineInputBorder(),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              labelText: "Phone number",
                              hintText: _phoneNumberHint,
                              errorText: _phoneNumberErrorText,
                              errorMaxLines: 2,
                            ),
                            enableInteractiveSelection: false,
                            inputFormatters: [
                              LibPhonenumberTextFormatter(
                                phoneNumberType: PhoneNumberType.mobile,
                                phoneNumberFormat: PhoneNumberFormat.national,
                                overrideSkipCountryCode: _countryCode,
                              ),
                            ],
                            keyboardType: TextInputType.phone,
                            onChanged: (_) => this.setState(() {
                                  _phoneNumberErrorText = null;
                                }),
                            onFieldSubmitted: (_) => _updatePhone(context)),
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
                                      "Continue",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    )
                                  ],
                                ),
                                onPressed: () {
                                  FocusScope.of(context)
                                      .requestFocus(_buttonFocusNode);
                                  _updatePhone(context);
                                },
                                padding: EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
          ),
        );
      }),
    );
  }
}
