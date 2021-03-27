import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onepay_app/authentication/screens/screens.dart';
import 'package:recase/recase.dart';

class Login extends StatefulWidget {
  @override
  _Login createState() => _Login();
}

class _Login extends State<Login> with TickerProviderStateMixin {
  AnimationController _rotateController;
  AnimationController _fadeController1;
  AnimationController _fadeController2;
  AnimationController _slideController;

  Tween<double> _sizeTween;
  Tween<Offset> _slideTween;

  FocusNode _identifierFocusNode;
  FocusNode _passwordFocusNode;
  FocusNode _loginFocusNode;
  FocusNode _signUpFocusNode;

  TextEditingController _identifierController;
  TextEditingController _passwordController;

  bool _errorFlag = false;
  String _errorText = "";
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _initAnimationControllers() {
    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _fadeController1 = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _fadeController2 = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _fadeController1.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        isLoggedIn().then((value) {
          if (value) {
            Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.authorizedRoute, (Route<dynamic> route) => false);
          } else {
            _slideController.forward();
            _fadeController2.forward();
          }
        });
      }
    });
  }

  void _initTween() {
    _slideTween = Tween<Offset>(begin: Offset(0, 0.7), end: Offset(0, -0.2));
    _sizeTween = Tween<double>(begin: 1, end: 0.7);
  }

  void _initTextFieldControllers() {
    _passwordFocusNode = FocusNode();
    _identifierFocusNode = FocusNode();
    _signUpFocusNode = FocusNode();
    _loginFocusNode = FocusNode();

    _identifierController = TextEditingController();
    _passwordController = TextEditingController();
  }

  _onSuccess(AccessTokenGetSuccess state) {
    AuthenticationEvent event = ESetAccessToken(state.accessToken);
    BlocProvider.of<AuthenticationBloc>(context).add(event);
  }

  void _onError(AccessTokenGetFailure state) {
    var error = state.errorMap["error"];
    switch (error) {
      case InvalidPasswordOrIdentifierErrorB:
        FocusScope.of(context).requestFocus(_passwordFocusNode);
        error = InvalidPasswordOrIdentifierError;
        break;
      case TooManyAttemptsErrorB:
        error = TooManyAttemptsError;
        break;
      case FrozenAccountErrorB:
        error = FrozenAccountError;
        break;
      case FrozenAPIClientErrorB:
        error = FrozenAPIClientError;
        break;
    }

    _errorText = ReCase(error).sentenceCase;
    _errorFlag = true;
  }

  void _handleBuilderResponse(BuildContext context, AuthenticationState state) {
    if (state is AccessTokenGetSuccess) {
      _onSuccess(state);
    } else if (state is AccessTokenGetFailure) {
      _onError(state);
    }
  }

  void _handleListenerResponse(
      BuildContext context, AuthenticationState state) {
    if (state is OTPGetSuccess) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LoginVerification(state.nonce),
        ),
      );
    } else if (state is AccessTokenLoaded) {
      print("This is inside login.dart ................... login successful!");
      // Navigator.of(context).pushNamedAndRemoveUntil(
      //     AppRoutes.authorizedRoute, (Route<dynamic> route) => false);
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

  void _login(BuildContext context) async {
    if (BlocProvider.of<AuthenticationBloc>(context).state
        is AccessTokenLoading) {
      return;
    }

    if (_passwordController.text.isEmpty ||
        _identifierController.text.isEmpty) {
      FocusScope.of(context).requestFocus(_identifierFocusNode);
      return;
    }

    // Removing focus from textfields
    FocusScope.of(context).unfocus();
    _errorFlag = false;

    AuthenticationEvent event =
        ELogin(_identifierController.text, _passwordController.text);
    BlocProvider.of<AuthenticationBloc>(context).add(event);
  }

  void _signUpInit(BuildContext context) {
    UserEvent event = ESignUpChangeState(SignUpInitLoaded());
    BlocProvider.of<UserBloc>(context).add(event);

    Navigator.of(context).pushNamed(AppRoutes.singUpRoute);
    FocusScope.of(context).requestFocus(_signUpFocusNode);
  }

  @override
  void initState() {
    super.initState();

    _initAnimationControllers();
    _initTween();
    _initTextFieldControllers();

    Future.delayed(Duration(seconds: 1)).then((value) {
      _rotateController.forward();
      _fadeController1.forward();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _identifierController.dispose();
    _rotateController.dispose();
    _fadeController2.dispose();
    _fadeController1.dispose();
    _slideController.dispose();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    _loginFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryVariant,
      body: Builder(
        builder: (BuildContext context) {
          return SafeArea(
            child: LayoutBuilder(builder:
                (BuildContext context, BoxConstraints viewportConstraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: viewportConstraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Flexible(
                          child: Container(
                            alignment: Alignment.center,
                            child: SlideTransition(
                              position: _slideTween.animate(_slideController),
                              child: OPLogoAW(
                                rotateController: _rotateController,
                                fadeController: _fadeController1,
                                sizeController:
                                    _sizeTween.animate(_slideController),
                                rotate: () {
                                  _rotateController.dispose();
                                  _rotateController = AnimationController(
                                    vsync: this,
                                    duration: Duration(seconds: 1),
                                  );
                                  setState(() {
                                    _rotateController.forward();
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          fit: FlexFit.loose,
                          child: FadeTransition(
                            opacity: _fadeController2,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    BlocConsumer<AuthenticationBloc,
                                            AuthenticationState>(
                                        listener: (context, state) {
                                      if (state != null)
                                        _handleListenerResponse(context, state);
                                    }, builder: (context, state) {
                                      if (state != null)
                                        _handleBuilderResponse(context, state);
                                      return Form(
                                        key: _formKey,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 25, 15, 15),
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: TextFormField(
                                                    focusNode:
                                                        _identifierFocusNode,
                                                    controller:
                                                        _identifierController,
                                                    decoration: InputDecoration(
                                                      floatingLabelBehavior:
                                                          FloatingLabelBehavior
                                                              .always,
                                                      labelText: "Phone number",
                                                    ),
                                                    keyboardType: TextInputType
                                                        .visiblePassword,
                                                    textInputAction:
                                                        TextInputAction.next),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 10,
                                                  bottom: 10,
                                                ),
                                                child: PasswordFormField(
                                                  focusNode: _passwordFocusNode,
                                                  controller:
                                                      _passwordController,
                                                  onFieldSubmitted: (_) =>
                                                      _login(context),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 10, bottom: 15),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Visibility(
                                                      child:
                                                          ErrorText(_errorText),
                                                      visible: _errorFlag,
                                                    ),
                                                    Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: CupertinoButton(
                                                        child: Text(
                                                          "Forgot Password",
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              fontFamily:
                                                                  'Roboto',
                                                              fontSize: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyText2
                                                                  .fontSize),
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: state
                                                                is AccessTokenLoading
                                                            ? null
                                                            : () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pushNamed(
                                                                        AppRoutes
                                                                            .forgotPasswordRoute);
                                                                FocusScope.of(
                                                                        context)
                                                                    .requestFocus(
                                                                        _signUpFocusNode);
                                                              },
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 5),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      fit: FlexFit.loose,
                                                      child: LoadingButton(
                                                        focusNode:
                                                            _loginFocusNode,
                                                        loading: state
                                                            is AccessTokenLoading,
                                                        child: Text(
                                                          "Log In",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            _login(context),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical: 13),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5),
                                                      child: Row(
                                                        textBaseline:
                                                            TextBaseline
                                                                .alphabetic,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .baseline,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                              "Don't have Account? "),
                                                          CupertinoButton(
                                                            child: Text(
                                                              "Sign Up.",
                                                              style: TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .primaryColor,
                                                                  fontFamily:
                                                                      'Roboto',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  fontSize: 15),
                                                            ),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            minSize: 36,
                                                            onPressed: state
                                                                    is AccessTokenLoading
                                                                ? null
                                                                : () {
                                                                    _signUpInit(
                                                                        context);
                                                                  },
                                                          )
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
