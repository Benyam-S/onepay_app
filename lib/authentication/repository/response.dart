import 'package:onepay_app/authentication/bloc/bloc.dart';
import 'package:onepay_app/models/response.dart';

class ROTPGetSuccess extends RepositoryResponse {
  final String nonce;

  ROTPGetSuccess(this.nonce) : assert(nonce != null);
}

class ROTPVerifySuccess extends RepositoryResponse {
  final AccessToken accessToken;
  final String nonce;

  ROTPVerifySuccess({this.accessToken, this.nonce});
}

class ROTPVerifyFailure extends RepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  ROTPVerifyFailure([this.statusCode, this.errorMap]);
}

class ROTPResendSuccess extends RepositoryResponse {}

class ROTPResendFailure extends RepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  ROTPResendFailure([this.statusCode, this.errorMap]);
}

class RPasswordResetSuccess extends RepositoryResponse {}

class RPasswordRestFailure extends RepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  RPasswordRestFailure([this.statusCode, this.errorMap]);
}

class RAccessTokenGetSuccess extends RepositoryResponse {
  final AccessToken accessToken;

  RAccessTokenGetSuccess(this.accessToken) : assert(accessToken != null);
}

class RAccessTokenGetFailure extends RepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  RAccessTokenGetFailure([this.statusCode, this.errorMap]);
}

class RAuthenticationFailure extends RepositoryResponse {
  final String error;

  RAuthenticationFailure([this.error]);
}
