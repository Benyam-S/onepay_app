import 'package:flutter/material.dart';
import 'package:onepay_app/models/linked.account.dart';
import 'package:onepay_app/utils/formatter.dart';
import 'package:onepay_app/widgets/dialog/recharge.dart';

class RechargeLinkedAccountTile extends StatefulWidget {
  final LinkedAccount linkedAccount;
  final Future<void> Function(LinkedAccount) refreshAccountInfo;

  RechargeLinkedAccountTile(this.linkedAccount, this.refreshAccountInfo);

  _RechargeLinkedAccountTile createState() => _RechargeLinkedAccountTile();
}

class _RechargeLinkedAccountTile extends State<RechargeLinkedAccountTile> {
  bool _isRefreshing = false;

  void _showRechargeDialog() {
    showDialog(
      context: context,
      child: RechargeDialog(context, widget.linkedAccount, widget.refreshAccountInfo),
    );
  }

  Future<void> _refreshAccountInfo() async {
    setState(() {
      _isRefreshing = true;
    });

    await widget.refreshAccountInfo(widget.linkedAccount);

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String amount = CurrencyInputFormatter()
        .toCurrency(widget.linkedAccount.amount?.toString());
    if (amount == null) {
      amount = "Undetermined";
    } else {
      amount += " ETB";
    }

    return InkWell(
      onTap: _showRechargeDialog,
      onLongPress: _refreshAccountInfo,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: 50,
              alignment: Alignment.center,
              child: Text(
                widget.linkedAccount.accountProvider.length > 1
                    ? widget.linkedAccount.accountProvider[0]
                    : "",
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).primaryColor)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.linkedAccount.accountProvider,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 5),
                  Row(
                    textBaseline: TextBaseline.alphabetic,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.linkedAccount.accountID),
                      Row(
                        children: [
                          Visibility(
                            visible: !_isRefreshing,
                            child: Text(amount),
                          ),
                          Visibility(
                            visible: _isRefreshing,
                            child: Container(
                              child: CircularProgressIndicator(strokeWidth: 3),
                              height: 20,
                              width: 20,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
