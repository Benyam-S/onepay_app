import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onepay_app/authentication/bloc/bloc.dart';
import 'package:onepay_app/authentication/data_provider/authentication_data.dart';
import 'package:onepay_app/authentication/repository/response.dart';
import 'package:onepay_app/models/response.dart';

class AuthenticationRepository {
  final AuthenticationDataProvider dataProvider;

  AuthenticationRepository({@required this.dataProvider})
      : assert(dataProvider != null);

  Future<RepositoryResponse> getAccessTokenOverNetwork(
      String identifier, String password) async {
    http.Response response =
        await dataProvider.getAccessTokenFromNetwork(identifier, password);

    switch (response.statusCode) {
      case HttpStatus.ok:
        Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData["type"] == "Bearer") {
          return RAccessTokenGetSuccess(AccessToken.fromJson(jsonData));
        } else if (jsonData["type"] == "OTP") {
          print(
              "This print statement is inside authentication_repository.dart =====> " +
                  jsonData["messageID"]);
          return ROTPGetSuccess(jsonData["nonce"]);
        }

        return RAuthenticationFailure(SomethingWentWrongError);
      case HttpStatus.badRequest:
        Map<String, dynamic> jsonData = json.decode(response.body);
        return RAccessTokenGetFailure(response.statusCode, jsonData);
      case HttpStatus.forbidden:
        return RAccessTokenGetFailure(
            response.statusCode, {"error": response.body});
      case HttpStatus.internalServerError:
        return RAuthenticationFailure(FailedOperationError);
      default:
        return RAuthenticationFailure(SomethingWentWrongError);
    }
  }

  void setAccessToken(AccessToken accessToken, {bool isLoggedIn}) {
    dataProvider.setLocalAccessToken(accessToken);
    dataProvider.setLoggedIn(isLoggedIn);
  }

  Future<RepositoryResponse> verifyLoginOTP(String nonce, String otp) async {
    http.Response response = await dataProvider.verifyLoginOTP(nonce, otp);

    switch (response.statusCode) {
      case HttpStatus.ok:
        var jsonData = json.decode(response.body);
        return ROTPVerifySuccess(accessToken: AccessToken.fromJson(jsonData));
      case HttpStatus.badRequest:
        return ROTPVerifyFailure(
            response.statusCode, {"error": "invalid code used"});
      case HttpStatus.forbidden:
        return ROTPVerifyFailure(response.statusCode, {"error": response.body});
      case HttpStatus.internalServerError:
        return RAuthenticationFailure(FailedOperationError);
      default:
        return RAuthenticationFailure(SomethingWentWrongError);
    }
  }

  Future<RepositoryResponse> resendOTP(String nonce) async {
    http.Response response = await dataProvider.resendOTP(nonce);

    switch (response.statusCode) {
      case HttpStatus.ok:
        return ROTPResendSuccess();
      case HttpStatus.badRequest:
        return ROTPResendFailure(
            response.statusCode, {"error": "unable to resend code"});
      default:
        return RAuthenticationFailure(SomethingWentWrongError);
    }
  }

  Future<RepositoryResponse> requestPasswordRest(
      String method, String identifier) async {
    http.Response response =
        await dataProvider.requestPasswordReset(method, identifier);

    switch (response.statusCode) {
      case HttpStatus.ok:
        return RPasswordResetSuccess();
      case HttpStatus.badRequest:
        var jsonData = json.decode(response.body);
        return RPasswordRestFailure(
            response.statusCode, {"error": jsonData["error"]});
      case HttpStatus.internalServerError:
        return RAuthenticationFailure(FailedOperationError);
      default:
        return RAuthenticationFailure(SomethingWentWrongError);
    }
  }
}
