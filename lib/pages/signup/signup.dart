import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/pages/signup/signup.Init.dart';
import 'package:onepay_app/pages/signup/signup.finish.dart';
import 'package:onepay_app/pages/signup/signup.verify.dart';
import 'package:onepay_app/pages/signup/singup.success.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/widgets/basic/steps.dart';

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

  StreamController<String> _verifyNonceController;
  StreamController<String> _passwordNonceController;

  StreamController<bool> _verifyIsNewController;
  StreamController<bool> _passwordIsNewController;

  List<Widget> _listOfStepWidget;

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

  void _initStreams() {
    _verifyNonceController = StreamController();
    _passwordNonceController = StreamController();
    _verifyIsNewController = StreamController();
    _passwordIsNewController = StreamController();

    _verifyNonceController.stream.listen((String nonce) {
      _verifyNonce = nonce;
      _changeStep(2);
    });

    _passwordNonceController.stream.listen((String nonce) {
      _passwordNonce = nonce;
      _changeStep(3);
    });
  }

  void _switchStep(int step) {
    if (this._pausedStep < step) {
      return;
    }

    _listOfStepWidget = [
      SignUpInit(
        nonceController: _verifyNonceController,
      ),
      SignUpVerify(
        nonceController: _passwordNonceController,
      ),
      SignUpFinish(),
      SignUpCompleted(
        controller: _shakeController,
      ),
    ];

    // Changing size of previous step
    switch (this._currentStep) {
      case 1:
        setState(() {
          _step1Controller.reverse();
          _step1Controller.dispose();
          _step1Controller = AnimationController(
            vsync: this,
            duration: Duration(microseconds: 700),
          );
        });
        break;

      case 2:
        setState(() {
          _step2Controller.reverse();
          _step2Controller.dispose();
          _step2Controller = AnimationController(
            vsync: this,
            duration: Duration(microseconds: 700),
          );
        });
        break;

      case 3:
        setState(() {
          _step3Controller.reverse();
          _step3Controller.dispose();
          _step3Controller = AnimationController(
            vsync: this,
            duration: Duration(microseconds: 700),
          );
        });
        break;
    }

    switch (step) {
      case 1:
        _progressValue = 0;
        _step1Controller.forward();
        _listOfStepWidget[0] = SignUpInit(
          visible: true,
          nonceController: _verifyNonceController,
        );
        break;

      case 2:
        _progressValue = 0.5;
        _step2Controller.forward();
        _listOfStepWidget[1] = SignUpVerify(
          visible: true,
          absorb: _pausedStep > step ? true : false,
          nonce: _verifyNonce,
          nonceController: _passwordNonceController,
        );
        break;

      case 3:
        _progressValue = 1;
        _step3Controller.forward();
        _listOfStepWidget[2] = SignUpFinish(
          visible: true,
          nonce: _passwordNonce,
          changeStep: _changeStep,
          disable: _disableBackButton,
        );
        break;
    }

    // Called just for rendering the screen
    setState(() {
      this._currentStep = step;
    });
  }

  void _changeStep(int step) {
    _listOfStepWidget = [
      SignUpInit(
        nonceController: _verifyNonceController,
      ),
      SignUpVerify(
        nonceController: _passwordNonceController,
      ),
      SignUpFinish(),
      SignUpCompleted(
        controller: _shakeController,
      ),
    ];

    // Changing size of previous step
    switch (this._currentStep) {
      case 1:
        setState(() {
          _step1Controller.reverse();
          _step1Controller.dispose();
          _step1Controller = AnimationController(
            vsync: this,
            duration: Duration(microseconds: 700),
          );
        });
        break;

      case 2:
        setState(() {
          _step2Controller.reverse();
          _step2Controller.dispose();
          _step2Controller = AnimationController(
            vsync: this,
            duration: Duration(microseconds: 700),
          );
        });
        break;

      case 3:
        setState(() {
          _step3Controller.reverse();
          _step3Controller.dispose();
          _step3Controller = AnimationController(
            vsync: this,
            duration: Duration(microseconds: 700),
          );
        });
        break;
    }

    switch (step) {
      case 1:
        _pausedStep = 1;
        _progressValue = 0;
        _step1Controller.forward();
        _listOfStepWidget[0] = SignUpInit(
          visible: true,
          nonceController: _verifyNonceController,
        );
        break;

      case 2:
        _pausedStep = 2;
        _progressValue = 0.5;
        _step2Controller.forward();
        _listOfStepWidget[1] = SignUpVerify(
          visible: true,
          nonce: _verifyNonce,
          isNewStream: _verifyIsNewController.stream,
          nonceController: _passwordNonceController,
        );

        // Making is new
        _verifyIsNewController.add(true);

        break;

      case 3:
        _pausedStep = 3;
        _progressValue = 1;
        _step3Controller.forward();
        _listOfStepWidget[2] = SignUpFinish(
          visible: true,
          nonce: _passwordNonce,
          changeStep: _changeStep,
          isNewStream: _passwordIsNewController.stream,
          disable: _disableBackButton,
        );

        // Making is new
        _passwordIsNewController.add(true);
        break;

      case 4:
        _pausedStep = 4;
        _progressValue = 1;
        _shakeController.forward();
        _listOfStepWidget[3] = SignUpCompleted(
          controller: _shakeController,
          visible: true,
        );
        break;
    }

    setState(() {
      this._currentStep = step;
    });
  }

  Future<bool> _onWillPop() async {
    return _willPopValue;
  }

  void _disableBackButton() {
    print("Will pop value changed");
    _willPopValue = false;
  }

  @override
  void initState() {
    super.initState();

    _initAnimationControllers();
    _initStreams();

    _listOfStepWidget = [
      SignUpInit(
        visible: true,
        nonceController: _verifyNonceController,
      ),
      SignUpVerify(
        isNewStream: _verifyIsNewController.stream,
        nonceController: _passwordNonceController,
      ),
      SignUpFinish(
        isNewStream: _passwordIsNewController.stream,
        disable: _disableBackButton,
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
    _verifyIsNewController.close();
    _passwordIsNewController.close();
    _verifyNonceController.close();
    _passwordNonceController.close();
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
                child: Container(
                  margin: EdgeInsets.only(top: 25),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 25, 15, 15),
                          child: Column(children: [
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Text(
                                    "Create Your OnePay Account",
                                    style:
                                        Theme.of(context).textTheme.headline5,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 25),
                                  child: Container(
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        LinearProgressIndicator(
                                          value: _progressValue,
                                          minHeight: 2,
                                          backgroundColor:
                                              Color.fromRGBO(216, 219, 224, 1),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
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
                                                      : CustomIcons.number_1,
                                                  sizeController:
                                                      _step1Controller,
                                                  iconColor: _currentStep == 1
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .secondary
                                                      : Theme.of(context)
                                                          .accentColor,
                                                ),
                                                onPressed: _pausedStep >= 1 &&
                                                        _pausedStep < 4
                                                    ? () => _switchStep(1)
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
                                                      : CustomIcons.number_2,
                                                  sizeController:
                                                      _step2Controller,
                                                  iconColor: _currentStep == 2
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .secondary
                                                      : _pausedStep == 2
                                                          ? Color.fromRGBO(
                                                              4, 148, 255, 0.4)
                                                          : _currentStep > 2
                                                              ? Theme.of(
                                                                      context)
                                                                  .accentColor
                                                              : Color.fromRGBO(
                                                                  216,
                                                                  219,
                                                                  224,
                                                                  1),
                                                ),
                                                onPressed: _pausedStep >= 2 &&
                                                        _pausedStep < 4
                                                    ? () => _switchStep(2)
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
                                                      : CustomIcons.number_3,
                                                  sizeController:
                                                      _step3Controller,
                                                  iconColor: _currentStep == 3
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .secondary
                                                      : _pausedStep == 3
                                                          ? Color.fromRGBO(
                                                              4, 148, 255, 0.4)
                                                          : _currentStep > 3
                                                              ? Theme.of(
                                                                      context)
                                                                  .accentColor
                                                              : Color.fromRGBO(
                                                                  216,
                                                                  219,
                                                                  224,
                                                                  1),
                                                ),
                                                onPressed: _pausedStep >= 3 &&
                                                        _pausedStep < 4
                                                    ? () => _switchStep(3)
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
