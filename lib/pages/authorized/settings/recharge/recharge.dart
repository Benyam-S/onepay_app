import 'package:flutter/material.dart';
import 'package:onepay_app/pages/authorized/settings/recharge/recharge.accounts.dart';
import 'package:onepay_app/pages/authorized/wallet/wallet.pocket.dart';

class Recharge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Recharge")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: WalletPocket(
              textColor: Theme.of(context).iconTheme.color,
              backgroundColor: Colors.transparent,
              isCustom: true,
            ),
          ),
          Expanded(
            flex: 2,
            child: RechargeLinkedAccounts(),
          ),
        ],
      ),
    );
  }
}
