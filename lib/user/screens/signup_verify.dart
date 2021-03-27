import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  FocusNode _otpFocusNode;
  TextEditingController _otpController;

  String _otpErrorText;

  GlobalKey<FormState> _formKey;

  void _onSuccess(SignUpVerifySuccess state) {
    UserEvent event = ESignUpChangeState(
        SignUpFinishLoaded(state.nonce, pausedStep: 3, isNew: true));
    widget.bloc.add(event);
  }

  void _onError(SignUpVerifyFailure state) {
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
    } else if (state is SignUpVerifySuccess) {
      _onSuccess(state);
    } else if (state is SignUpVerifyFailure) {
      _onError(state);
    }
  }

  void _signUpVerify() async {
    // Cancelling if loading
    if (widget.bloc.state is SignUpLoading) {
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

  @override
  void initState() {
    super.initState();

    _otpFocusNode = FocusNode();
    _otpController = TextEditingController();
    _formKey = GlobalKey<FormState>();
  }

  @override
  Widget build(BuildContext context) {
    var disabled = widget.absorb ?? false;

    return BlocBuilder<UserBloc, UserState>(
      cubit: widget.bloc,
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
