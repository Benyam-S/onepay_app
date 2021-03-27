import 'package:onepay_app/authentication/bloc/bloc.dart';

abstract class AuthenticationRepositoryResponse {
  const AuthenticationRepositoryResponse();
}

class ROTPGetSuccess extends AuthenticationRepositoryResponse {
  final String nonce;

  ROTPGetSuccess(this.nonce) : assert(nonce != null);
}

class ROTPVerifySuccess extends AuthenticationRepositoryResponse {
  final AccessToken accessToken;

  ROTPVerifySuccess(this.accessToken) : assert(accessToken != null);
}

class ROTPVerifyFailure extends AuthenticationRepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  ROTPVerifyFailure([this.statusCode, this.errorMap]);
}

class ROTPResendSuccess extends AuthenticationRepositoryResponse {}

class ROTPResendFailure extends AuthenticationRepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  ROTPResendFailure([this.statusCode, this.errorMap]);
}

class RPasswordResetSuccess extends AuthenticationRepositoryResponse {}

class RPasswordRestFailure extends AuthenticationRepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  RPasswordRestFailure([this.statusCode, this.errorMap]);
}

class RAccessTokenGetSuccess extends AuthenticationRepositoryResponse {
  final AccessToken accessToken;

  RAccessTokenGetSuccess(this.accessToken) : assert(accessToken != null);
}

class RAccessTokenGetFailure extends AuthenticationRepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  RAccessTokenGetFailure([this.statusCode, this.errorMap]);
}

class RAuthenticationFailure extends AuthenticationRepositoryResponse {
  final String error;

  RAuthenticationFailure([this.error]);
}
