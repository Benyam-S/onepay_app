import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.dialog.dart';

class HttpRequester {
  String baseURI = "http://192.168.1.3:8080/api/v1";
  String requestURL = "";

  HttpRequester({@required String path}) {
    if (path.startsWith("/")) {
      requestURL = Uri.encodeFull(baseURI + path);
    } else {
      requestURL = Uri.encodeFull(baseURI + "/" + path);
    }
  }

  Future<http.Response> get(BuildContext context) async {
    AccessToken accessToken =
        OnePay.of(context).accessToken ?? await getLocalAccessToken();

    if (accessToken == null) {
      throw AccessTokenNotFoundException();
    }

    String basicAuth = 'Basic ' +
        base64Encode(
            utf8.encode('${accessToken.apiKey}:${accessToken.accessToken}'));
    return await http.get(requestURL, headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'authorization': basicAuth,
    });
  }

  Future<http.Response> post(
      BuildContext context, Map<String, dynamic> body) async {
    AccessToken accessToken =
        OnePay.of(context).accessToken ?? await getLocalAccessToken();

    if (accessToken == null) {
      throw AccessTokenNotFoundException();
    }

    String basicAuth = 'Basic ' +
        base64Encode(
            utf8.encode('${accessToken.apiKey}:${accessToken.accessToken}'));
    return await http.post(
      requestURL,
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'authorization': basicAuth,
      },
      body: body,
    );
  }

  Future<http.Response> put(
      BuildContext context, Map<String, dynamic> body) async {
    AccessToken accessToken =
        OnePay.of(context).accessToken ?? await getLocalAccessToken();

    if (accessToken == null) {
      throw AccessTokenNotFoundException();
    }

    String basicAuth = 'Basic ' +
        base64Encode(
            utf8.encode('${accessToken.apiKey}:${accessToken.accessToken}'));
    return await http.put(
      requestURL,
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'authorization': basicAuth,
      },
      body: body,
    );
  }

  /// isAuthorized is used for the checking if the request used a valid access token depending on the status response
  bool isAuthorized(
      BuildContext context, http.Response response, bool showDialog,
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
        if (showDialog) {
          var jsonData = json.decode(response.body);
          if (jsonData["error"] ==
              "access token has exceeded it daily expiration time") {
            showDEValidationDialog(context, currentCallback);
            return false;
          }
        }
    }

    return true;
  }
}
