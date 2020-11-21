import 'package:flutter/material.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/history.dart';
import 'package:onepay_app/models/linked.account.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/routes.dart';

void logout(BuildContext context) async {
  try {
    OnePay.of(context).userWallet = null;
    OnePay.of(context).accessToken = null;
    OnePay.of(context).userPreference = null;
    OnePay.of(context).currentUser = null;
    OnePay.of(context).histories = List<History>();
    OnePay.of(context).linkedAccounts = List<LinkedAccount>();
    OnePay.of(context).dataSaverState = null;
    OnePay.of(context).fNotificationState = null;
    OnePay.of(context).bNotificationState = null;

    await setLoggedIn(false);
    await setLocalUserWallet(null);
    await setLocalUserPreference(null);
    await setLocalUserProfile(null);
    await setLocalAccessToken(null);
    await setLocalViewBys(null);
    await setLocalLinkedAccounts(null);
    await setLocalDataSaverState(null);
    await setLocalForegroundNotificationState(null);
    await setLocalBackgroundNotificationState(null);

    // Logging the use out
    Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.logInRoute, (Route<dynamic> route) => false);
  } catch (e) {
    ///TODO: should remove the line below, should only be used for development purpose
    throw (e);
  }
}
