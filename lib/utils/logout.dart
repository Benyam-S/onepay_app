import 'package:flutter/material.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/routes.dart';

void logout(BuildContext context) async{

  await setLoggedIn(false);
  await setLocalUserWallet(null);
  await setLocalUserProfile(null);
  await setLocalAccessToken(null);

  // Logging the use out
  Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.logInRoute, (Route<dynamic> route) => false);
}