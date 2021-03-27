import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onepay_app/user/screens/screens.dart';
import 'package:recase/recase.dart';

class SignUpFinish extends StatefulWidget {
  final String nonce;
  final bool visible;
  final Function onWillPop;
  final UserBloc bloc;

  SignUpFinish(this.bloc, {this.nonce, this.visible, this.onWillPop})
      : assert(bloc != null);

  _SignUpFinish createState() => _SignUpFinish();
}

class _SignUpFinish extends State<SignUpFinish> {
  FocusNode _newPasswordFocusNode;
  FocusNode _verifyPasswordFocusNode;
  FocusNode _buttonFocusNode;

  TextEditingController _newPasswordController;
  TextEditingController _verifyPasswordController;

  String nonce;
  String _newPasswordErrorText;
  String _verifyPasswordErrorText;
  String _errorText = "";
  bool _errorFlag = false;

  GlobalKey<FormState> _formKey;

  // autoValidateNewPassword checks for invalid characters only
  String _autoValidateNewPassword(String value) {
    if (value.isEmpty) {
      return null;
    }
    var exp = RegExp(r"^[a-zA-Z0-9\._\-&!?=#]*$");

    if (!exp.hasMatch(value)) {
      return ReCase("invalid characters used in password").sentenceCase;
    }

    return null;
  }

  String _validateNewPassword(String value) {
    if (value.length < 8) {
      return ReCase("password should contain at least 8 characters")
          .sentenceCase;
    }

    var exp = RegExp(r"^[a-zA-Z0-9\._\-&!?=#]{8}[a-zA-Z0-9\._\-&!?=#]*$");

    if (!exp.hasMatch(value)) {
      return ReCase("invalid characters used in password").sentenceCase;
    }

    return null;
  }

  String _validateVerifyPassword() {
    var newPassword = _newPasswordController.text;
    var verifyPassword = _verifyPasswordController.text;

    if (newPassword != verifyPassword) {
      return ReCase("password doesn't match").sentenceCase;
    }

    return null;
  }

  Future<void> _onSuccess(SignUpFinishSuccess state) async {
    UserEvent event = ESignUpChangeState(
        SignUpSuccessLoaded(state.accessToken, pausedStep: 4));
    widget.bloc.add(event);

    // This delay is used to make the use comfortable with registration process
    Future.delayed(Duration(seconds: 4)).then((value) {
      AuthenticationEvent authEvent = ESetAccessToken(state.accessToken);
      BlocProvider.of<AuthenticationBloc>(context).add(authEvent);
    });
  }

  Future<void> _onError(SignUpFinishFailure state) async {
    var error = state.errorMap["error"];
    switch (error) {
      case "password should contain at least 8 characters":
        _newPasswordErrorText = ReCase(error).sentenceCase;
        break;
      case "invalid characters used in password":
        _newPasswordErrorText = ReCase(error).sentenceCase;
        break;
      case "password does not match":
        _verifyPasswordErrorText = ReCase(error).sentenceCase;
        break;
      case "invalid token used":
        _errorText =
            ReCase("the token used is invalid or has expired").sentenceCase;
        _errorFlag = true;
        break;
      default:
        _errorText = ReCase(error).sentenceCase;
        _errorFlag = true;
    }

    UserEvent event =
        ESignUpChangeState(SignUpFinishLoaded(widget.nonce, isNew: false));
    widget.bloc.add(event);
  }

  void _handleBuilderResponse(BuildContext context, UserState state) {
    if (state is SignUpFinishLoaded) {
      if (state.isNew ?? false) {
        _newPasswordController.clear();
        _verifyPasswordController.clear();

        _newPasswordErrorText = null;
        _verifyPasswordErrorText = null;

        _errorText = "";
        _errorFlag = false;

        // Revoking newness of the state
        widget.bloc.add(
            ESignUpChangeState(SignUpFinishLoaded(widget.nonce, isNew: false)));
      }
    } else if (state is SignUpFinishSuccess) {
      _onSuccess(state);
    } else if (state is SignUpFinishFailure) {
      _onError(state);
    }
  }

  void _signUpFinish() async {
    // Cancelling if loading
    if (widget.bloc.state is SignUpLoading) {
      return;
    }

    nonce = widget.nonce ?? this.nonce;
    var newPassword = _newPasswordController.text;
    var verifyPassword = _verifyPasswordController.text;

    var newPasswordError = _validateNewPassword(newPassword);
    var verifyPasswordError = _validateVerifyPassword();

    if (newPasswordError != null) {
      setState(() {
        _newPasswordErrorText = newPasswordError;
      });
    }

    if (verifyPasswordError != null) {
      setState(() {
        _verifyPasswordErrorText = verifyPasswordError;
      });
    }

    if (newPasswordError != null || verifyPasswordError != null) {
      return;
    }

    // Removing the final error at the start
    _newPasswordErrorText = null;
    _verifyPasswordErrorText = null;
    _errorFlag = false;

    // Disabling the back button so the user will wait
    widget.onWillPop(false);

    UserEvent event = ESignUpFinish(newPassword, verifyPassword, nonce);
    widget.bloc.add(event);
  }

  void initState() {
    super.initState();

    _newPasswordFocusNode = FocusNode();
    _verifyPasswordFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();

    _newPasswordController = TextEditingController();
    _verifyPasswordController = TextEditingController();

    _formKey = GlobalKey<FormState>();

    _newPasswordFocusNode.addListener(() {
      if (!_newPasswordFocusNode.hasFocus) {
        var newPassword = _newPasswordController.text;
        if (newPassword != null && newPassword.isNotEmpty) {
          setState(() {
            _newPasswordErrorText = _validateNewPassword(newPassword);
          });
        }
      }
    });

    _verifyPasswordFocusNode.addListener(() {
      if (!_verifyPasswordFocusNode.hasFocus) {
        var verifyPassword = _verifyPasswordController.text;
        if (verifyPassword != null && verifyPassword.isNotEmpty) {
          setState(() {
            _verifyPasswordErrorText = _validateVerifyPassword();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      cubit: widget.bloc,
      builder: (context, state) {
        _handleBuilderResponse(context, state);
        return Visibility(
          visible: widget.visible ?? false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      "Secure your account with robust password, password should be contain at least 8 characters.",
                      style: Theme.of(context).textTheme.headline3,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 20),
                  child: PasswordFormField(
                    focusNode: _newPasswordFocusNode,
                    controller: _newPasswordController,
                    errorText: _newPasswordErrorText,
                    autoValidate: true,
                    validator: _autoValidateNewPassword,
                    onChanged: (_) {
                      // So the page will not be build every time text is written
                      if (_newPasswordErrorText != null) {
                        setState(() {
                          _newPasswordErrorText = null;
                        });
                      }
                    },
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 20),
                  child: TextFormField(
                    focusNode: _verifyPasswordFocusNode,
                    controller: _verifyPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "Verify Password",
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      errorText: _verifyPasswordErrorText,
                    ),
                    onChanged: (_) {
                      // So the page will not be build every time text is written
                      if (_verifyPasswordErrorText != null) {
                        setState(() {
                          _verifyPasswordErrorText = null;
                        });
                      }
                    },
                    onFieldSubmitted: (_) => _signUpFinish(),
                    keyboardType: TextInputType.visiblePassword,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 5),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Visibility(
                          child: ErrorText(_errorText),
                          visible: _errorFlag,
                        ),
                      ),
                    ),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: LoadingButton(
                          loading: state is SignUpLoading,
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          onPressed: () {
                            FocusScope.of(context)
                                .requestFocus(_buttonFocusNode);
                            _signUpFinish();
                          },
                          padding: EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
