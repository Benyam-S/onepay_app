import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/pages/authorized/settings/withdraw/withdraw.accounts.dart';
import 'package:onepay_app/pages/authorized/wallet/wallet.pocket.dart';

class Withdraw extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Withdraw"),
        elevation: 0,
        // backgroundColor: Theme.of(context).colorScheme.primaryVariant,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.primaryVariant,
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin:
                    EdgeInsets.only(top: MediaQuery.of(context).size.height / 15),
                child: WalletPocket(
                  textColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.primaryVariant,
                  iconColor: Colors.white,
                  isCustom: true,
                ),
              ),
              SizedBox(height: 35),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: WithdrawLinkedAccounts(),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
