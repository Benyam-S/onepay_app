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
      ),
      body: SingleChildScrollView(
        child: Stack(
          overflow: Overflow.visible,
          children: [
            Container(
              height: (MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  AppBar().preferredSize.height),
            ),
            Container(
              height: MediaQuery.of(context).size.height / 2.5,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryVariant),
            ),
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
            Positioned(
              top: MediaQuery.of(context).size.height / 3.7,
              right: 0,
              left: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Please select the preferred linked account to withdraw an amount you entered.",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    SizedBox(height: 10),
                    WithdrawLinkedAccounts(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
