import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/button/loading.dart';
import 'package:recase/recase.dart';

class UpdateBasicInfo extends StatefulWidget {
  _UpdateBasicInfo createState() => _UpdateBasicInfo();
}

class _UpdateBasicInfo extends State<UpdateBasicInfo> {
  FocusNode _firstNameFocusNode;
  FocusNode _lastNameFocusNode;
  FocusNode _buttonFocusNode;

  TextEditingController _firstNameController;
  TextEditingController _lastNameController;

  User _user;
  String _firstName;
  String _lastName;
  String _firstNameErrorText;
  String _lastNameErrorText;
  bool _loading = false;

  String _autoValidateFirstName(String value) {
    if (value.isEmpty) {
      return null;
    }
    return _validateFirstName(value);
  }

  String _validateFirstName(String value) {
    if (value.isEmpty) {
      return ReCase(EmptyEntryError).sentenceCase;
    }

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

  Future<void> _onSuccess(BuildContext context, Response response) async {
    User user = OnePay.of(context).currentUser?.copy() ?? await getLocalUserProfile();
    if (user != null) {
      user.firstName = _firstName;
      user.lastName = _lastName;

      OnePay.of(context).appStateController.add(user);
      setLocalUserProfile(user);
    }

    Navigator.of(context).pop();
    showSuccessDialog(context,
        "You have successfully updated your profile's basic information.");
  }

  void _onError(BuildContext context, Response response) {
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

  Future<void> _makeRequest(BuildContext context) async {
    var requester = HttpRequester(path: "/oauth/user/profile.json");
    try {
      var response = await requester.put(context, {
        'first_name': _firstName,
        'last_name': _lastName,
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

  void _updateBasicInfo(BuildContext context) async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    _firstName = _firstNameController.text;
    _lastName = _lastNameController.text;

    var firstNameError = _validateFirstName(_firstName);
    var lastNameError = _validateLastName(_lastName);

    // Checking similarities with previous basic information
    if (_user?.firstName?.sentenceCase == _firstName &&
        _user?.lastName?.sentenceCase == _lastName) {
      return;
    }

    if (firstNameError != null) {
      setState(() {
        _firstNameErrorText = firstNameError;
      });
    }

    if (lastNameError != null) {
      setState(() {
        _lastNameErrorText = lastNameError;
      });
    }

    if (firstNameError != null || lastNameError != null) {
      return;
    }

    setState(() {
      _loading = true;
      _firstNameErrorText = null;
      _lastNameErrorText = null;
    });

    await _makeRequest(context);
  }

  void _initUserProfile() async {
    _user = OnePay.of(context).currentUser ?? await getLocalUserProfile();
    if (_user != null) {
      _firstNameController.text = _user.firstName.sentenceCase;
      _lastNameController.text = _user.lastName.sentenceCase;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    _firstNameFocusNode = FocusNode();
    _lastNameFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();

    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();

    _firstNameFocusNode.addListener(() {
      if (!_firstNameFocusNode.hasFocus) {
        var firstName = _firstNameController.text;
        if (firstName != null) {
          setState(() {
            _firstNameErrorText = _validateFirstName(firstName);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
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
        title: Text("Basic Info"),
      ),
      body: Builder(builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Text(
                    "Update basic account information, "
                    "use formal and appropriate data as it can be used to identify your account.",
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                SizedBox(height: 20),
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
                    onFieldSubmitted: (_) => _updateBasicInfo(context),
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.name,
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
                                Icons.account_circle,
                                color: Colors.white,
                              )
                            ],
                          ),
                          onPressed: () {
                            FocusScope.of(context)
                                .requestFocus(_buttonFocusNode);
                            _updateBasicInfo(context);
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
