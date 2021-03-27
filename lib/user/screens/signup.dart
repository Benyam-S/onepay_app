import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onepay_app/user/screens/screens.dart';

class SignUp extends StatefulWidget {
  _SignUp createState() => _SignUp();
}

class _SignUp extends State<SignUp> with TickerProviderStateMixin {
  AnimationController _slideController;
  AnimationController _step1Controller;
  AnimationController _step2Controller;
  AnimationController _step3Controller;
  AnimationController _shakeController;

  int _currentStep = 1;
  int _pausedStep = 1;
  Tween<Offset> _slideTween;
  double _progressValue = 0;
  String _verifyNonce;
  String _passwordNonce;
  bool _willPopValue = true;

  List<Widget> _listOfStepWidget;

  UserBloc _localBloc;

  void _initAnimationControllers() {
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _step1Controller = AnimationController(
      vsync: this,
      duration: Duration(microseconds: 700),
    );

    _step2Controller = AnimationController(
      vsync: this,
      duration: Duration(microseconds: 700),
    );

    _step3Controller = AnimationController(
      vsync: this,
      duration: Duration(microseconds: 700),
    );

    _shakeController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    _slideTween = Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0));

    _slideController.forward();
    _step1Controller.forward();
  }

  void _initChangeStep(BuildContext context, int step) {
    if (this._pausedStep < step) {
      return;
    }

    switch (step) {
      case 1:
        UserEvent event = ESignUpChangeState(SignUpInitLoaded());
        _localBloc.add(event);
        break;
      case 2:
        UserEvent event = ESignUpChangeState(SignUpVerifyLoaded(_verifyNonce));
        _localBloc.add(event);
        break;
      case 3:
        UserEvent event =
            ESignUpChangeState(SignUpFinishLoaded(_passwordNonce));
        _localBloc.add(event);
        break;
    }
  }

  void _changeStep(int step) {
    _listOfStepWidget = [
      SignUpInit(_localBloc),
      SignUpVerify(_localBloc),
      SignUpFinish(_localBloc),
      SignUpCompleted(
        controller: _shakeController,
      ),
    ];

    // Changing size of previous step
    switch (this._currentStep) {
      case 1:
        _step1Controller.reverse();
        _step1Controller.dispose();
        _step1Controller = AnimationController(
          vsync: this,
          duration: Duration(microseconds: 700),
        );
        break;

      case 2:
        _step2Controller.reverse();
        _step2Controller.dispose();
        _step2Controller = AnimationController(
          vsync: this,
          duration: Duration(microseconds: 700),
        );
        break;

      case 3:
        _step3Controller.reverse();
        _step3Controller.dispose();
        _step3Controller = AnimationController(
          vsync: this,
          duration: Duration(microseconds: 700),
        );
        break;
    }

    switch (step) {
      case 1:
        _progressValue = 0;
        _step1Controller.forward();
        _listOfStepWidget[0] = SignUpInit(_localBloc, visible: true);
        break;

      case 2:
        _progressValue = 0.5;
        _step2Controller.forward();
        _listOfStepWidget[1] = SignUpVerify(
          _localBloc,
          visible: true,
          absorb: _pausedStep > step ? true : false,
          nonce: _verifyNonce,
        );
        break;

      case 3:
        _progressValue = 1;
        _step3Controller.forward();
        _listOfStepWidget[2] = SignUpFinish(
          _localBloc,
          visible: true,
          nonce: _passwordNonce,
          onWillPop: _changeOnWillPop,
        );
        break;

      case 4:
        _progressValue = 1;
        _shakeController.forward();
        _listOfStepWidget[3] = SignUpCompleted(
          controller: _shakeController,
          visible: true,
        );
        break;
    }

    this._currentStep = step;
  }

  Future<bool> _onWillPop() async {
    return _willPopValue;
  }

  void _changeOnWillPop(bool value) {
    _willPopValue = value;
  }

  void _handleBuilderResponse(BuildContext context, UserState state) {
    if (state is SignUpInitLoaded) {
      _pausedStep = state.pausedStep ?? _pausedStep;
      _changeStep(1);
    } else if (state is SignUpVerifyLoaded) {
      _pausedStep = state.pausedStep ?? _pausedStep;
      _verifyNonce = state.nonce;
      _changeStep(2);
    } else if (state is SignUpFinishLoaded) {
      _pausedStep = state.pausedStep ?? _pausedStep;
      _passwordNonce = state.nonce;
      _changeStep(3);
    } else if (state is SignUpSuccessLoaded) {
      _pausedStep = state.pausedStep ?? _pausedStep;
      _changeStep(4);
    }
  }

  void _handleListenerResponse(BuildContext context, UserState state) {
    // Re enabling on will pop
    if (!(state is SignUpLoading) &&
        !(state is SignUpFinishSuccess) &&
        !(state is SignUpSuccessLoaded)) {
      _changeOnWillPop(true);
    }

    if (state is SignUpException) {
      var exp = state.e;
      if (exp is SocketException) {
        showUnableToConnectError(context);
        return;
      } else if (exp is AppException) {
        showServerError(context, exp.e);
        return;
      }

      showServerError(context, SomethingWentWrongError);
    } else if (state is SignUpOperationFailure) {
      showServerError(context, SomethingWentWrongError);
    }
  }

  @override
  void initState() {
    super.initState();

    _initAnimationControllers();

    UserRepository userRepo = BlocProvider.of<UserBloc>(context).userRepository;
    _localBloc = UserBloc(userRepository: userRepo);

    _listOfStepWidget = [
      SignUpInit(_localBloc, visible: true),
      SignUpVerify(_localBloc),
      SignUpFinish(
        _localBloc,
        onWillPop: _changeOnWillPop,
      ),
      SignUpCompleted(
        controller: _shakeController,
      )
    ];
  }

  @override
  void dispose() {
    _slideController.dispose();
    _step1Controller.dispose();
    _step2Controller.dispose();
    _step3Controller.dispose();
    _shakeController.dispose();
    _localBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Sign Up"),
          elevation: 0,
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryVariant,
        body: SafeArea(
          child: SingleChildScrollView(
            child: SlideTransition(
              position: _slideTween.animate(_slideController),
              child: FadeTransition(
                opacity: _slideController,
                child: BlocConsumer<UserBloc, UserState>(
                  cubit: _localBloc,
                  listener: _handleListenerResponse,
                  builder: (context, state) {
                    _handleBuilderResponse(context, state);
                    return Container(
                      margin: EdgeInsets.only(top: 25),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(15, 25, 15, 15),
                              child: Column(children: [
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Text(
                                        "Create Your OnePay Account",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5,
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 25),
                                      child: Container(
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            LinearProgressIndicator(
                                              value: _progressValue,
                                              minHeight: 2,
                                              backgroundColor: Color.fromRGBO(
                                                  216, 219, 224, 1),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                ButtonTheme(
                                                  minWidth: 0,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 0),
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  child: FlatButton(
                                                    child: StepIcon(
                                                      iconData: _currentStep > 1
                                                          ? CustomIcons.checked
                                                          : CustomIcons
                                                              .number_1,
                                                      sizeController:
                                                          _step1Controller,
                                                      iconColor: _currentStep ==
                                                              1
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                          : Theme.of(context)
                                                              .accentColor,
                                                    ),
                                                    onPressed: _pausedStep >=
                                                                1 &&
                                                            _pausedStep < 4 &&
                                                            !(state
                                                                is SignUpLoading)
                                                        ? () => _initChangeStep(
                                                            context, 1)
                                                        : null,
                                                  ),
                                                ),
                                                ButtonTheme(
                                                  minWidth: 0,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 0),
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  child: FlatButton(
                                                    child: StepIcon(
                                                      iconData: _currentStep > 2
                                                          ? CustomIcons.checked
                                                          : CustomIcons
                                                              .number_2,
                                                      sizeController:
                                                          _step2Controller,
                                                      iconColor: _currentStep ==
                                                              2
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                          : _pausedStep == 2
                                                              ? Color.fromRGBO(
                                                                  4,
                                                                  148,
                                                                  255,
                                                                  0.4)
                                                              : _currentStep > 2
                                                                  ? Theme.of(
                                                                          context)
                                                                      .accentColor
                                                                  : Color
                                                                      .fromRGBO(
                                                                          216,
                                                                          219,
                                                                          224,
                                                                          1),
                                                    ),
                                                    onPressed: _pausedStep >=
                                                                2 &&
                                                            _pausedStep < 4 &&
                                                            !(state
                                                                is SignUpLoading)
                                                        ? () => _initChangeStep(
                                                            context, 2)
                                                        : null,
                                                  ),
                                                ),
                                                ButtonTheme(
                                                  minWidth: 0,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 0),
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  child: FlatButton(
                                                    child: StepIcon(
                                                      iconData: _currentStep > 3
                                                          ? CustomIcons.checked
                                                          : CustomIcons
                                                              .number_3,
                                                      sizeController:
                                                          _step3Controller,
                                                      iconColor: _currentStep ==
                                                              3
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                          : _pausedStep == 3
                                                              ? Color.fromRGBO(
                                                                  4,
                                                                  148,
                                                                  255,
                                                                  0.4)
                                                              : _currentStep > 3
                                                                  ? Theme.of(
                                                                          context)
                                                                      .accentColor
                                                                  : Color
                                                                      .fromRGBO(
                                                                          216,
                                                                          219,
                                                                          224,
                                                                          1),
                                                    ),
                                                    onPressed: _pausedStep >=
                                                                3 &&
                                                            _pausedStep < 4 &&
                                                            !(state
                                                                is SignUpLoading)
                                                        ? () => _initChangeStep(
                                                            context, 3)
                                                        : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: _listOfStepWidget,
                                )
                              ]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
