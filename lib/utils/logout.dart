import 'package:flutter/material.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/history.dart';
import 'package:onepay_app/models/linked.account.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/routes.dart';

void logout(BuildContext context) async{

  await setLoggedIn(false);
  await setLocalUserWallet(null);
  await setLocalUserProfile(null);
  await setLocalAccessToken(null);
  await setLocalViewBys(null);
  await setLocalLinkedAccounts(null);

  OnePay.of(context).userWallet = null;
  OnePay.of(context).accessToken = null;
  OnePay.of(context).currentUser = null;
  OnePay.of(context).histories = List<History>();
  OnePay.of(context).linkedAccounts = List<LinkedAccount>();

  // Logging the use out
  Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.logInRoute, (Route<dynamic> route) => false);
}