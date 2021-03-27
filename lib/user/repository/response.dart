import 'package:onepay_app/models/access.token.dart';

class UserRepositoryResponse {}

class RSignUpInitSuccess extends UserRepositoryResponse {
  final String nonce;

  RSignUpInitSuccess(this.nonce);
}

class RSingUpInitFailure extends UserRepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  RSingUpInitFailure(this.statusCode, this.errorMap);
}

class RSignUpVerifySuccess extends UserRepositoryResponse {
  final String nonce;

  RSignUpVerifySuccess(this.nonce);
}

class RSingUpVerifyFailure extends UserRepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  RSingUpVerifyFailure(this.statusCode, this.errorMap);
}

class RSignUpFinishSuccess extends UserRepositoryResponse {
  final AccessToken accessToken;

  RSignUpFinishSuccess(this.accessToken);
}

class RSingUpFinishFailure extends UserRepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  RSingUpFinishFailure(this.statusCode, this.errorMap);
}

class RSignUpFailure extends UserRepositoryResponse {
  final String error;

  RSignUpFailure([this.error]);
}
