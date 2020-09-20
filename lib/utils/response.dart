import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.dialog.dart';

/// isResponseAuthorized is used for the checking if the request used a valid access token depending on the status response
bool isResponseAuthorized(BuildContext context, http.Response response,
    [Function currentCallback]) {
  switch (response.statusCode) {
    case HttpStatus.unauthorized:
    case HttpStatus.forbidden:
      setLoggedIn(false);
      setLocalAccessToken(null);

      // Logging the use out
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.logInRoute, (Route<dynamic> route) => false);
      return false;
    case HttpStatus.badRequest:
      var jsonData = json.decode(response.body);
      if (jsonData["error"] ==
          "access token has exceeded it daily expiration time") {
        showDEValidationDialog(context, currentCallback);
        return false;
      }
  }

  return true;
}
