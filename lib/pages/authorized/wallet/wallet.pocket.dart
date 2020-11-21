import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/wallet.dart';
import 'package:onepay_app/utils/currency.formatter.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/show.snackbar.dart';

// Use instead of numbers or booleans
enum AmountState {
  unLoaded,
  loaded,
}

// Use instead of numbers or booleans
enum Origin {
  refresh,
  initAmount,
}

class WalletPocket extends StatefulWidget {
  final Color textColor;
  final Color backgroundColor;
  final Color iconColor;
  final bool isCustom;

  WalletPocket(
      {this.textColor, this.backgroundColor, this.iconColor, this.isCustom});

  _WalletPocket createState() => _WalletPocket();
}

class _WalletPocket extends State<WalletPocket>
    with SingleTickerProviderStateMixin {
  AnimationController _rotationController;
  String _amount = "0.00";
  AmountState _amountState = AmountState.unLoaded;
  bool _refreshing = false;

  void _onSuccess(Response response) {
    var jsonData = json.decode(response.body);
    var wallet = Wallet.fromJson(jsonData);

    // Since we are the wallet view we have to set the seen flag to true
    wallet.seen = true;

    setState(() {
      _amount = CurrencyInputFormatter.toCurrency(wallet.amount.toString());
    });

    // Add current user to the stream and shared preference
    OnePay.of(context).appStateController.add(wallet);
    setLocalUserWallet(wallet);
  }

  void _handleResponse(Response response, Origin origin) {
    if (!mounted) return;

    if (response.statusCode == HttpStatus.ok) {
      _onSuccess(response);
    } else {
      if (origin == Origin.refresh) {
        showInternalError(context, "Unable to refresh wallet");
      }
    }
  }

  Future<void> _makeRequest(Origin origin) async {
    var requester = HttpRequester(path: "/oauth/user/wallet.json");

    try {
      Response response = await requester.get(context);

      _handleResponse(response, origin);
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {
      if (origin == Origin.refresh) {
        if (mounted) showInternalError(context, "Unable to refresh wallet");
      }
    }
  }

  void _startIconRotation() {
    _rotationController.repeat();
  }

  void _stopIconRotation() {
    _rotationController.reset();
  }

  Future<void> _refresh() async {
    if (_refreshing) {
      return;
    }

    _refreshing = true;
    _startIconRotation();

    await _makeRequest(Origin.refresh);

    // Since we can navigate after starting animation
    if (!mounted) return;

    _stopIconRotation();
    _refreshing = false;
  }

  Future<void> _initAmount() async {
    if (_amountState != AmountState.unLoaded) {
      return;
    }

    _amountState = AmountState.loaded;

    double amount = OnePay.of(context).userWallet?.amount ??
        (await getLocalUserWallet())?.amount;

    setState(() {
      _amount = CurrencyInputFormatter.toCurrency(amount.toString());
    });

    await _makeRequest(Origin.initAmount);
  }

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _initAmount();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: widget.backgroundColor ??
              Theme.of(context).colorScheme.primaryVariant),
      child: widget.isCustom ?? false
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CustomIcons.onepay_logo_filled,
                      color: widget.iconColor ?? Theme.of(context).primaryColor,
                      size: 80,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder(
                          stream: OnePay.of(context).walletStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              double amount = (snapshot.data as Wallet)?.amount;
                              if (amount != null) {
                                _amount = CurrencyInputFormatter.toCurrency(
                                    amount.toString());
                              }
                            }
                            return Text(
                              "ETB $_amount",
                              style: TextStyle(
                                  color: widget.textColor ?? Colors.white,
                                  fontSize: 25,
                                  fontFamily: 'Roboto'),
                              maxLines: 2,
                            );
                          },
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Deposited from linked accounts",
                          style: TextStyle(
                              color: widget.textColor ?? Colors.white,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                RotationTransition(
                  turns: _rotationController,
                  child: GestureDetector(
                    onTap: _refresh,
                    child: Icon(
                      Icons.refresh,
                      size: 26,
                      color: widget.textColor ?? Colors.white,
                    ),
                  ),
                )
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder(
                  stream: OnePay.of(context).walletStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      double amount = (snapshot.data as Wallet)?.amount;
                      if (amount != null) {
                        _amount = CurrencyInputFormatter.toCurrency(
                            amount.toString());
                      }
                    }
                    return Text(
                      "ETB $_amount",
                      style: TextStyle(
                          color: widget.textColor ?? Colors.white,
                          fontSize: 30,
                          fontFamily: 'Roboto'),
                    );
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Deposited",
                  style: TextStyle(
                      color: widget.textColor ?? Colors.white, fontSize: 20),
                ),
                SizedBox(
                  height: 10,
                ),
                RotationTransition(
                  turns: _rotationController,
                  child: GestureDetector(
                    onTap: _refresh,
                    child: Icon(
                      Icons.refresh,
                      size: 26,
                      color: widget.textColor ?? Colors.white,
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
