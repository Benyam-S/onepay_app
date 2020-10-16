import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
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
  StreamController _streamController;
  Stream _clearStream;

  User _user;
  String _phoneNumber;
  String _nonce;
  String _phoneNumberErrorText;
  String _phoneNumberHint = "9 * * * * * * * *";
  String _areaCode = '+251';
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
      _phoneNumber = _transformPhoneNumber(_phoneNumber);
      _verificationDialog = true;
    });

    //  This will clear the the second dialog
    _streamController.add(true);
  }

  String _validatePhoneNumber(String value) {
    if (value.isEmpty) {
      return ReCase(EmptyEntryError).sentenceCase;
    }

    // Means it is local phone number
    if (value.startsWith("0") && value.length == 10) {
      value = value;
    } else {
      value = _areaCode + value;
    }

    var exp = RegExp(r'^(\+\d{11,12})$|(0\d{9})$');

    if (!exp.hasMatch(value)) {
      return ReCase(InvalidPhoneNumberError).sentenceCase;
    }

    return null;
  }

  String _transformPhoneNumber(String phoneNumber) {
    // Means local phone number
    if (phoneNumber.startsWith("0") &&
        phoneNumber.length == 10 &&
        _areaCode == "+251") {
      phoneNumber = phoneNumber;
    } else {
      phoneNumber = _areaCode + phoneNumber;
    }

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
        'phone_number': _transformPhoneNumber(_phoneNumber),
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
    var phoneNumberError = _validatePhoneNumber(_phoneNumber);

    // Checking similarity with the previous phone number
    if (_phoneNumber.startsWith("0") &&
        _phoneNumber.length == 10 &&
        _areaCode == "+251") {
      String phoneNumber = _phoneNumber.replaceFirst("0", "+251");
      if (_user?.phoneNumber == phoneNumber) {
        return;
      }
    } else {
      if (_user?.phoneNumber == _transformPhoneNumber(_phoneNumber)) {
        return;
      }
    }

    if (phoneNumberError != null) {
      setState(() {
        _phoneNumberErrorText = phoneNumberError;
      });

      return;
    }

    setState(() {
      _loading = true;
      _phoneNumberErrorText = null;
    });

    await _makeRequest(context);
  }

  void _initUserProfile() async {
    _user = OnePay.of(context).currentUser ?? await getLocalUserProfile();
    if (_user != null) {
      if (_user.phoneNumber.length > 9 && _user.phoneNumber.startsWith("+")) {
        _phoneController.text = _user.phoneNumber
            .substring(_user.phoneNumber.length - 9, _user.phoneNumber.length);
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _phoneFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();

    _phoneController = TextEditingController();

    _streamController = StreamController.broadcast();
    _clearStream = _streamController.stream.where((event) => event is bool);
  }

  @override
  void dispose() {
    _streamController.close();
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
                    back: _back,
                    clearStream: _clearStream)
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
                                initialSelection: _areaCode,
                                favorite: ['+251'],
                                onChanged: (CountryCode countryCode) =>
                                    _areaCode = countryCode.dialCode,
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
