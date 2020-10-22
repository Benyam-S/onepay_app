import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/show.dialog.dart';

/// isResponseAuthorized is used for the checking if the request used a valid access token depending on the status response
bool isResponseAuthorized(BuildContext context, http.Response response,
    [Function currentCallback]) {
  switch (response.statusCode) {
    case HttpStatus.unauthorized:
    case HttpStatus.forbidden:
      logout(context);
      return false;
    case HttpStatus.badRequest:
      try {
        var jsonData = json.decode(response.body);
        if (jsonData["error"] ==
            "access token has exceeded it daily expiration time") {
          showDEValidationDialog(context, currentCallback);
          return false;
        }
      } catch (e) {}
  }

  return true;
}
