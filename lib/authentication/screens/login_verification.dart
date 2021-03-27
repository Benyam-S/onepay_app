import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onepay_app/authentication/screens/screens.dart';
import 'package:recase/recase.dart';

class LoginVerification extends StatefulWidget {
  final String nonce;

  LoginVerification(this.nonce);

  _LoginVerification createState() => _LoginVerification();
}

class _LoginVerification extends State<LoginVerification> {
  FocusNode _buttonFocusNode;
  FocusNode _otpFocusNode;
  TextEditingController _otpController;

  String _nonce;
  String _otp;
  String _otpErrorText;

  AuthenticationBloc _localBloc;

  Future<void> _onLoginVerifySuccess(OTPVerifySuccess state) async {
    AuthenticationEvent event = ESetAccessToken(state.accessToken);
    BlocProvider.of<AuthenticationBloc>(context).add(event);
  }

  void _onLoginVerifyError(OTPVerifyFailure state) {
    String error = state.errorMap["error"];
    switch (error) {
      case FrozenAPIClientErrorB:
        error = FrozenAPIClientError;
        break;
    }

    _otpErrorText = ReCase(error).sentenceCase;
  }

  void _handleBuilderResponse(BuildContext context, AuthenticationState state) {
    if (state is OTPVerifySuccess) {
      _onLoginVerifySuccess(state);
    } else if (state is OTPVerifyFailure) {
      _onLoginVerifyError(state);
    }
  }

  void _handleListenerResponse(
      BuildContext context, AuthenticationState state) {
    if (state is OTPResendFailure) {
      var error = state.errorMap["error"];
      showServerError(context, error);
    } else if (state is AuthenticationException) {
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

  void _loginVerify(BuildContext context) async {
    // Cancelling if loading or resending
    if (_localBloc.state is OTPVerifying || _localBloc.state is OTPResending) {
      return;
    }

    _nonce = widget.nonce ?? "";
    _otp = _otpController.text;
    if (_otp.isEmpty) {
      FocusScope.of(context).requestFocus(_otpFocusNode);
      return;
    }

    AuthenticationEvent event = EVerifyLoginOTP(_nonce, _otp);
    _localBloc.add(event);
  }

  void _resend(BuildContext context) async {
    // Cancelling if loading or resending
    if (_localBloc.state is OTPVerifying || _localBloc.state is OTPResending) {
      return;
    }

    _nonce = widget.nonce ?? "";
    _otpController.clear();

    AuthenticationEvent event = EResendLoginOTP(_nonce);
    _localBloc.add(event);
  }

  Future<bool> _onWillPop() async {
    return !(_localBloc.state is OTPVerifying);
  }

  void initState() {
    super.initState();

    _buttonFocusNode = FocusNode();
    _otpFocusNode = FocusNode();
    _otpController = TextEditingController();

    AuthenticationRepository authenticationRepo =
        BlocProvider.of<AuthenticationBloc>(context).authenticationRepository;
    _localBloc =
        AuthenticationBloc(authenticationRepository: authenticationRepo);
  }

  @override
  void dispose() {
    super.dispose();

    _otpController.dispose();
    _localBloc.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryVariant,
      body: Builder(builder: (context) {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
                  cubit: _localBloc,
                  listener: _handleListenerResponse,
                  builder: (context, state) {
                    _handleBuilderResponse(context, state);
                    return WillPopScope(
                      onWillPop: _onWillPop,
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
                            padding: const EdgeInsets.only(top: 5, bottom: 15),
                            child: TextFormField(
                              focusNode: _otpFocusNode,
                              controller: _otpController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: "OTP",
                                errorText: state is OTPVerifyFailure
                                    ? _otpErrorText
                                    : null,
                              ),
                              onChanged: (_) {
                                AuthenticationEvent event =
                                    EAuthenticationChangeState(
                                        OTPVerifyLoaded());
                                _localBloc.add(event);
                              },
                              onFieldSubmitted: (_) => _loginVerify(context),
                              keyboardType: TextInputType.visiblePassword,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: CupertinoButton(
                              minSize: 0,
                              padding: EdgeInsets.zero,
                              child: state is OTPResending
                                  ? Container(
                                      margin: const EdgeInsets.only(right: 5),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                      width: 15,
                                      height: 15,
                                    )
                                  : Text(
                                      "Didn't get code, resend.",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline3
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                    ),
                              onPressed: () {
                                FocusScope.of(context)
                                    .requestFocus(_buttonFocusNode);
                                _resend(context);
                              },
                            ),
                          ),
                          SizedBox(height: 15),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: LoadingButton(
                                loading: state is OTPVerifying,
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
                                onPressed: () => _loginVerify(context),
                                padding: EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }),
            ),
          ),
        );
      }),
    );
  }
}
