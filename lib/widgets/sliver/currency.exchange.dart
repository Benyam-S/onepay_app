import 'dart:math';

import 'package:flutter/material.dart';
import 'package:onepay_app/models/wallet.dart';
import 'package:onepay_app/utils/currency.formatter.dart';
import 'package:onepay_app/utils/routes.dart';

class CurrencyExchangeAppBar extends SliverPersistentHeaderDelegate {
  final Wallet wallet;
  double _appBarHeight = AppBar().preferredSize.height;
  double _titleFontSize = 25;
  double _descFontSize = 15;
  double _iconSize = 30;

  CurrencyExchangeAppBar({this.wallet});

  double _getTitleSize(double offSet) {
    return (1.0 - max(0.0, (offSet - minExtent)) / (maxExtent - minExtent)) *
        _titleFontSize;
  }

  double _getDescSize(double offSet) {
    return (1.0 - max(0.0, (offSet - minExtent)) / (maxExtent - minExtent)) *
        _descFontSize;
  }

  double _getIconSize(double offSet) {
    if (offSet > 60) return 0;
    return (1.0 - max(0.0, (offSet - minExtent)) / (maxExtent - minExtent)) *
        _iconSize;
  }

  double _getIconsOpacity(double offSet) {
    if (offSet > 60) return 0;
    return 1.0 - max(0.0, offSet * 2) / maxExtent;
  }

  double _getContainerOpacity(double offSet) {
    if (offSet > 150) return 0;
    return 1.0 - max(0.0, offSet) / maxExtent;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    String amount =
        CurrencyInputFormatter.toCurrency(wallet?.amount?.toString()) ?? "0.00";

    return Container(
      color: Theme.of(context).colorScheme.primaryVariant,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              title: shrinkOffset > 150
                  ? Row(
                      children: [
                        Icon(Icons.home_work),
                        SizedBox(
                          width: 5,
                        ),
                        Text("OnePay"),
                      ],
                    )
                  : null,
              elevation: 0,
            ),
          ),
          Center(
            child: Opacity(
              opacity: _getContainerOpacity(shrinkOffset),
              child: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "ETB $amount",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: _getTitleSize(shrinkOffset),
                          fontFamily: 'Roboto'),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Your Balance",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getDescSize(shrinkOffset),
                        fontFamily: 'Roboto',
                      ),
                    ),
                    SizedBox(height: _getIconSize(shrinkOffset) == 0 ? 0 : 30),
                    Opacity(
                      opacity: _getIconsOpacity(shrinkOffset),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FlatButton(
                            padding: EdgeInsets.all(
                                _getIconSize(shrinkOffset) == 0 ? 0 : 5),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            minWidth: 0,
                            height: 0,
                            child: Icon(
                              Icons.account_balance,
                              color: Colors.white,
                              size: _getIconSize(shrinkOffset),
                            ),
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRoutes.moneyVault),
                          ),
                          SizedBox(width: 15),
                          FlatButton(
                            padding: EdgeInsets.all(
                                _getIconSize(shrinkOffset) == 0 ? 0 : 5),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            minWidth: 0,
                            height: 0,
                            child: Icon(
                              Icons.account_circle,
                              color: Colors.white,
                              size: _getIconSize(shrinkOffset),
                            ),
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRoutes.profile),
                          ),
                          SizedBox(width: 15),
                          FlatButton(
                            padding: EdgeInsets.all(
                                _getIconSize(shrinkOffset) == 0 ? 0 : 5),
                            minWidth: 0,
                            height: 0,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            child: Icon(
                              Icons.credit_card,
                              color: Colors.white,
                              size: _getIconSize(shrinkOffset),
                            ),
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRoutes.accounts),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 230;

  @override
  double get minExtent => _appBarHeight;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
