import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onepay_app/authentication/bloc/bloc.dart';
import 'package:onepay_app/user/screens/screens.dart';
import 'package:recase/recase.dart';

class SignUpVerify extends StatefulWidget {
  final String nonce;
  final bool visible;
  final bool absorb;
  final UserBloc bloc;

  SignUpVerify(
    this.bloc, {
    this.nonce,
    this.visible,
    this.absorb,
  }) : assert(bloc != null);

  @override
  _SignUpVerify createState() => _SignUpVerify();
}

class _SignUpVerify extends State<SignUpVerify> {
  FocusNode _buttonFocusNode;
  FocusNode _otpFocusNode;
  TextEditingController _otpController;

  String _otpErrorText;
  String _resendText;
  bool _resendWait;

  GlobalKey<FormState> _formKey;

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
      UserEvent event =
          ESignUpChangeState(SignUpVerifyLoaded(widget.nonce, isNew: false));
      widget.bloc.add(event);
    });
  }

  void _onSuccess(OTPVerifySuccess state) {
    UserEvent event = ESignUpChangeState(
        SignUpFinishLoaded(state.nonce, pausedStep: 3, isNew: true));
    widget.bloc.add(event);
  }

  void _onError(OTPVerifyFailure state) {
    var error = state.errorMap["error"];
    _otpErrorText = ReCase(error).sentenceCase;

    UserEvent event =
        ESignUpChangeState(SignUpVerifyLoaded(widget.nonce, isNew: false));
    widget.bloc.add(event);
  }

  void _handleBuilderResponse(BuildContext context, UserState state) {
    if (state is SignUpVerifyLoaded) {
      if (state.isNew ?? false) {
        _otpController.clear();
        _otpErrorText = null;

        // Revoking newness of the state
        widget.bloc.add(
            ESignUpChangeState(SignUpVerifyLoaded(widget.nonce, isNew: false)));
      }
    } else if (state is OTPVerifySuccess) {
      _onSuccess(state);
    } else if (state is OTPVerifyFailure) {
      _onError(state);
    }
  }

  void _handleListenerResponse(BuildContext context, UserState state) {
    if (state is OTPResendSuccess) {
      _resendSuccess(state);
    } else if (state is OTPResendFailure) {
      var error = state.errorMap["error"];
      showServerError(context, error);
    }
  }

  void _signUpVerify() async {
    // Cancelling if loading or resending
    if (widget.bloc.state is SignUpLoading ||
        widget.bloc.state is OTPResending) {
      return;
    }

    var nonce = widget.nonce ?? "";
    var otp = _otpController.text;
    if (otp.isEmpty) {
      FocusScope.of(context).requestFocus(_otpFocusNode);
      return;
    }

    _otpErrorText = null;

    UserEvent event = ESignUpVerify(nonce, otp);
    widget.bloc.add(event);
  }

  void _resend(BuildContext context) async {
    // Cancelling if loading or resending
    if (widget.bloc.state is SignUpLoading ||
        widget.bloc.state is OTPResending) {
      return;
    }

    var nonce = widget.nonce ?? "";
    _otpErrorText = null;
    _otpController.clear();

    UserEvent event = EResendSignUpOTP(nonce);
    widget.bloc.add(event);
  }

  @override
  void initState() {
    super.initState();

    _otpFocusNode = FocusNode();
    _buttonFocusNode = FocusNode();
    _otpController = TextEditingController();
    _formKey = GlobalKey<FormState>();

    _resendText = "Didn't get code, resend.";
    _resendWait = false;
  }

  @override
  Widget build(BuildContext context) {
    var disabled = widget.absorb ?? false;

    return BlocConsumer<UserBloc, UserState>(
      cubit: widget.bloc,
      listener: _handleListenerResponse,
      builder: (context, state) {
        _handleBuilderResponse(context, state);
        return Visibility(
          visible: widget.visible ?? false,
          child: AbsorbPointer(
            absorbing: widget.absorb ?? false,
            child: Form(
              key: _formKey,
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
                    padding: const EdgeInsets.only(top: 5, bottom: 25),
                    child: TextFormField(
                      focusNode: _otpFocusNode,
                      controller: _otpController,
                      enabled: !disabled,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "OTP",
                        errorText: _otpErrorText,
                      ),
                      onChanged: (_) {
                        if (_otpErrorText != null) {
                          setState(() {
                            _otpErrorText = null;
                          });
                        }
                      },
                      onFieldSubmitted: (_) => _signUpVerify(),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                                          color:
                                              Theme.of(context).iconTheme.color)
                                  : Theme.of(context)
                                      .textTheme
                                      .headline3
                                      .copyWith(
                                          color:
                                              Theme.of(context).primaryColor),
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
                        loading: state is SignUpLoading,
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
                        onPressed: _signUpVerify,
                        padding: EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
