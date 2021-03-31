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

  String _otpErrorText;
  String _resendText;
  bool _resendWait;

  AuthenticationBloc _localBloc;

  String _timer(int value) {
    var prefix = "Resend in ";
    if (value == 60) {
      return prefix + "01 : 00";
    } else if (value > 9) {
      return prefix + "00 : " + value.toString();
    } else if (value >= 0) {
      return prefix + "00 : 0" + value.toString();
    }

    return "Didn't get code, resend.";
  }

  void _resendSuccess(OTPResendSuccess state) {
    int i = 60;
    Future.doWhile(() async {
      if (i < 0) {
        return false;
      }

      setState(() {
        _resendWait = true;
        _resendText = _timer(i);
      });

      await Future.delayed(Duration(seconds: 1));
      i--;
      return true;
    }).then((value) {
      _resendText = "Didn't get code, resend.";
      _resendWait = false;
      AuthenticationEvent event = EAuthenticationChangeState(OTPVerifyLoaded());
      _localBloc.add(event);
    });
  }

  void _onLoginVerifySuccess(OTPVerifySuccess state) {
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

    AuthenticationEvent event = EAuthenticationChangeState(OTPVerifyLoaded());
    _localBloc.add(event);
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
    if (state is OTPResendSuccess) {
      _resendSuccess(state);
    } else if (state is OTPResendFailure) {
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

    var nonce = widget.nonce ?? "";
    var otp = _otpController.text;
    if (otp.isEmpty) {
      FocusScope.of(context).requestFocus(_otpFocusNode);
      return;
    }

    _otpErrorText = null;

    AuthenticationEvent event = EVerifyLoginOTP(nonce, otp);
    _localBloc.add(event);
  }

  void _resend(BuildContext context) async {
    // Cancelling if loading or resending
    if (_localBloc.state is OTPVerifying || _localBloc.state is OTPResending) {
      return;
    }

    var nonce = widget.nonce ?? "";
    _otpErrorText = null;
    _otpController.clear();

    AuthenticationEvent event = EResendLoginOTP(nonce);
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

    _resendText = "Didn't get code, resend.";
    _resendWait = false;

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
                                  errorText: _otpErrorText),
                              onChanged: (_) {
                                if (_otpErrorText != null) {
                                  setState(() {
                                    _otpErrorText = null;
                                  });
                                }
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
                                      _resendText,
                                      style: _resendWait
                                          ? Theme.of(context)
                                              .textTheme
                                              .headline6
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .iconTheme
                                                      .color)
                                          : Theme.of(context)
                                              .textTheme
                                              .headline3
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                    ),
                              onPressed: state is OTPResendSuccess
                                  ? null
                                  : () {
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
