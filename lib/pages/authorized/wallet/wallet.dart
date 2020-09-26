import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onepay_app/pages/authorized/wallet/wallet.history.dart';
import 'package:onepay_app/pages/authorized/wallet/wallet.pocket.dart';

class WalletView extends StatefulWidget{

  final StreamController<bool> _unseenStreamController;

  WalletView(this._unseenStreamController);

  @override
  _WalletView createState()=> _WalletView();
}

class _WalletView extends State<WalletView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: 1,
          fit: FlexFit.tight,
          child: WalletPocket(),
        ),
        Expanded(
          flex: 2,
          // fit: FlexFit.tight,
          child: WalletHistory(widget._unseenStreamController),
        ),
      ],
    );
  }

}