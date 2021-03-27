import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/user/data_provider/user_data.dart';
import 'package:onepay_app/user/repository/response.dart';

class UserRepository {
  final UserDataProvider dataProvider;

  UserRepository({this.dataProvider}) : assert(dataProvider != null);

  Future<UserRepositoryResponse> signUpInit(String firstName, String lastName,
      String email, String phoneNumber) async {
    http.Response response =
        await dataProvider.signUpInit(firstName, lastName, email, phoneNumber);

    switch (response.statusCode) {
      case HttpStatus.ok:
        Map<String, dynamic> jsonData = json.decode(response.body);
        print("This print statement is inside user_repository.dart =====> " +
            jsonData["messageID"]);
        return RSignUpInitSuccess(jsonData["nonce"]);
      case HttpStatus.badRequest:
        Map<String, dynamic> jsonData = json.decode(response.body);
        return RSingUpInitFailure(response.statusCode, jsonData);
      case HttpStatus.internalServerError:
        return RSignUpFailure(FailedOperationError);
      default:
        return RSignUpFailure(SomethingWentWrongError);
    }
  }

  Future<UserRepositoryResponse> signUpVerify(String otp, String nonce) async {
    http.Response response = await dataProvider.signUpVerify(otp, nonce);

    switch (response.statusCode) {
      case HttpStatus.ok:
        Map<String, dynamic> jsonData = json.decode(response.body);
        return RSignUpVerifySuccess(jsonData["nonce"]);
      case HttpStatus.badRequest:
        return RSingUpVerifyFailure(
            response.statusCode, {"error": "invalid code used"});
      default:
        return RSignUpFailure(SomethingWentWrongError);
    }
  }

  Future<UserRepositoryResponse> signUpFinish(
      String newPassword, String verifyPassword, String nonce) async {
    http.Response response =
        await dataProvider.signUpFinish(newPassword, verifyPassword, nonce);

    switch (response.statusCode) {
      case HttpStatus.ok:
        var jsonData = json.decode(response.body);
        var accessToken = AccessToken.fromJson(jsonData);
        return RSignUpFinishSuccess(accessToken);
      case HttpStatus.badRequest:
        Map<String, dynamic> jsonData = json.decode(response.body);
        return RSingUpFinishFailure(
            response.statusCode, {"error": jsonData["error"]});
      case HttpStatus.internalServerError:
        return RSignUpFailure(FailedOperationError);
      default:
        return RSignUpFailure(SomethingWentWrongError);
    }
  }
}
