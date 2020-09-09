import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.dialog.dart';

class HttpRequester {
  String baseURI = "http://192.168.1.7:8080/api/v1";
  String requestURL = "";

  HttpRequester({@required String path}) {
    if (path.startsWith("/")) {
      requestURL = Uri.encodeFull(baseURI + path);
    } else {
      requestURL = Uri.encodeFull(baseURI + "/" + path);
    }
  }

  /// isAuthorized is used for the checking if the request used a valid access token depending on the status response
  bool isAuthorized(
      BuildContext context, http.Response response, bool showDialog) {
    switch (response.statusCode) {
      case 403:
      case 401:
        setLoggedIn(false);
        setLocalAccessToken(null);

        // Logging the use out
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.logInRoute, (Route<dynamic> route) => false);
        return false;
      case 400:
        if (showDialog) {
          var jsonData = json.decode(response.body);
          if (jsonData["error"] ==
              "access token has exceeded it daily expiration time") {
            showDEValidationDialog(context);
          }
        }
    }

    return true;
  }
}
