import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:country_code_picker/country_code.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;

class SignUpInit extends StatefulWidget {
  final bool visible;
  final StreamController<String> nonceController;

  SignUpInit({this.visible, @required this.nonceController});

  _SignUpInit createState() => _SignUpInit();
}

class _SignUpInit extends State<SignUpInit> {
  FocusNode _firstNameFocusNode;
  FocusNode _lastNameFocusNode;
  FocusNode _emailFocusNode;
  FocusNode _phoneFocusNode;
  FocusNode _buttonFocusNode;

  TextEditingController _firstNameController;
  TextEditingController _lastNameController;
  TextEditingController _emailController;
  TextEditingController _phoneController;

  String _firstNameErrorText;
  String _lastNameErrorText;
  String _emailErrorText;
  String _phoneNumberErrorText;
  String _phoneNumberHint = "9 * * * * * * * *";
  String _areaCode = '+251';
  bool _loading = false;

  GlobalKey<FormState> _formKey;

  String _autoValidateFirstName(String value) {
    if (value.isEmpty) {
      return null;
    }
    return _validateFirstName(value);
  }

  String _validateFirstName(String value) {
    var exp1 = RegExp(r"^[a-zA-Z]\w*$");
    var exp2 = RegExp(r"^[a-zA-Z]");

    if (!exp2.hasMatch(value)) {
      return ReCase("name should only start with a letter").sentenceCase;
    }

    if (!exp1.hasMatch(value)) {
      return ReCase("first name should only contain alpha numerical values")
          .sentenceCase;
    }

    return null;
  }

  String _autoValidateLastName(String value) {
    if (value.isEmpty) {
      return null;
    }

    return _validateLastName(value);
  }

  String _validateLastName(String value) {
    var exp = RegExp(r"^\w*$");

    if (!exp.hasMatch(value)) {
      return ReCase("last name should only contain alpha numerical values")
          .sentenceCase;
    }

    return null;
  }

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
    // Meaning local phone number
    if (phoneNumber.startsWith("0") &&
        phoneNumber.length == 10 &&
        _areaCode == "+251") {
      phoneNumber = phoneNumber;
    } else {
      phoneNumber = _areaCode + phoneNumber;
    }

    return phoneNumber;
  }

  void _onSuccess(http.Response response) {
    var jsonData = json.decode(response.body);
    var nonce = jsonData["nonce"];
    widget.nonceController.add(nonce);

    print(nonce);
    print(jsonData["messageID"]);
  }

  void _onError(http.Response response) {
    String error = "";
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        var jsonData = json.decode(response.body);
        jsonData.forEach((key, value) {
          error = jsonData[key];
          switch (key) {
            case "first_name":
              setState(() {
                _firstNameErrorText = ReCase(error).sentenceCase;
              });
              break;
            case "last_name":
              setState(() {
                _lastNameErrorText = ReCase(error).sentenceCase;
              });
              break;
            case "email":
              if (error == EmailAlreadyExistsErrorB) {
                error = EmailAlreadyExistsError;
              }
              setState(() {
                _emailErrorText = ReCase(error).sentenceCase;
              });
              break;
            case "phone_number":
              if (error == PhoneNumberAlreadyExistsErrorB) {
                error = PhoneNumberAlreadyExistsError;
              }
              setState(() {
                _phoneNumberErrorText = ReCase(error).sentenceCase;
              });
              break;
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
      _onSuccess(response);
    } else {
      _onError(response);
    }
  }

  Future<void> _makeRequest(String firstName, String lastName, String email,
      String phoneNumber) async {
    var requester = HttpRequester(path: "/oauth/user/register/init");
    try {
      var response =
          await http.post(requester.requestURL, headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      }, body: <String, String>{
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': _transformPhoneNumber(phoneNumber),
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

  void _signUpInit() async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    var firstName = _firstNameController.text;
    var lastName = _lastNameController.text;
    var email = _emailController.text;
    var phoneNumber = _phoneController.text;

    var firstNameError = _validateFirstName(firstName);
    var lastNameError = _validateLastName(lastName);
    var emailError = _validateEmail(email);
    var phoneNumberError = _validatePhoneNumber(phoneNumber);

    if (firstName.isEmpty) {
      setState(() {
        _firstNameErrorText = ReCase(EmptyEntryError).sentenceCase;
      });
    } else if (firstNameError != null) {
      setState(() {
        _firstNameErrorText = firstNameError;
      });
    }

    if (lastNameError != null) {
      setState(() {
        _lastNameErrorText = lastNameError;
      });
    }

    if (emailError != null) {
      setState(() {
        _emailErrorText = emailError;
      });
    }

    if (phoneNumberError != null) {
      setState(() {
        _phoneNumberErrorText = phoneNumberError;
      });
    }

    if (firstNameError != null ||
        lastNameError != null ||
        emailError != null ||
        phoneNumberError != null) {
      return;
    }

    // Removing the final error at the start
    setState(() {
      _loading = true;
      _firstNameErrorText = null;
      _lastNameErrorText = null;
      _emailErrorText = null;
      _phoneNumberErrorText = null;
    });

    await _makeRequest(firstName, lastName, email, phoneNumber);
  }

  @override
  void initState() {
    super.initState();

    _firstNameFocusNode = FocusNode();
    _lastNameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();

    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        var email = _emailController.text;
        if (email != null && email.isNotEmpty) {
          setState(() {
            _emailErrorText = _validateEmail(email);
          });
        }
      }
    });

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        var phoneNumber = _phoneController.text;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          setState(() {
            _phoneNumberErrorText = _validatePhoneNumber(phoneNumber);
          });
        }
        setState(() {
          _phoneNumberHint = "9 * * * * * * * *";
        });
      } else {
        setState(() {
          _phoneNumberHint = null;
        });
      }
    });

    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.visible ?? false,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextFormField(
                controller: _firstNameController,
                focusNode: _firstNameFocusNode,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelText: "First Name",
                  errorText: _firstNameErrorText,
                ),
                autovalidate: true,
                validator: _autoValidateFirstName,
                onChanged: (_) => this.setState(() {
                  _firstNameErrorText = null;
                }),
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: TextFormField(
                controller: _lastNameController,
                focusNode: _lastNameFocusNode,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Last Name",
                  errorText: _lastNameErrorText,
                  isDense: true,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                autovalidate: true,
                validator: _autoValidateLastName,
                onChanged: (_) => this.setState(() {
                  _lastNameErrorText = null;
                }),
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(
                  "Contact Information",
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
            ),
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
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
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
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: "Phone number",
                    hintText: _phoneNumberHint,
                    errorText: _phoneNumberErrorText,
                    errorMaxLines: 2,
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => this.setState(() {
                        _phoneNumberErrorText = null;
                      }),
                  onFieldSubmitted: (_) => _signUpInit()),
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
                      focusNode: _buttonFocusNode,
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
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          )
                        ],
                      ),
                      onPressed: () {
                        FocusScope.of(context).requestFocus(_buttonFocusNode);
                        _signUpInit();
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
  }
}
