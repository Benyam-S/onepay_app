import 'package:onepay_app/authentication/bloc/bloc.dart';
import 'package:onepay_app/user/bloc/bloc.dart';

class AuthenticationState {}

class AccessTokenLoading extends AuthenticationState {}

class AccessTokenLoaded extends AuthenticationState {
  final AccessToken accessToken;

  AccessTokenLoaded(this.accessToken);
}

class OTPGetSuccess extends AuthenticationState {
  final String nonce;

  OTPGetSuccess(this.nonce);
}

class OTPVerifying implements AuthenticationState, UserState {}

class OTPVerifyLoaded implements AuthenticationState, UserState {}

class OTPVerifySuccess implements AuthenticationState, UserState {
  final AccessToken accessToken;
  final String nonce;

  OTPVerifySuccess({this.accessToken, this.nonce});
}

class OTPVerifyFailure implements AuthenticationState, UserState {
  final Map<String, dynamic> errorMap;

  OTPVerifyFailure([this.errorMap]);
}

class OTPResending implements AuthenticationState, UserState {}

class OTPResendSuccess implements AuthenticationState, UserState {}

class OTPResendFailure implements AuthenticationState, UserState {
  final Map<String, dynamic> errorMap;

  OTPResendFailure([this.errorMap]);
}

class PasswordResetLoaded extends AuthenticationState {}

class PasswordResetting extends AuthenticationState {}

class PasswordResetSuccess extends AuthenticationState {}

class PasswordResetFailure extends AuthenticationState {
  final Map<String, dynamic> errorMap;

  PasswordResetFailure([this.errorMap]);
}

class AccessTokenGetSuccess extends AuthenticationState {
  final AccessToken accessToken;

  AccessTokenGetSuccess(this.accessToken);
}

class AccessTokenGetFailure extends AuthenticationState {
  final Map<String, dynamic> errorMap;

  AccessTokenGetFailure([this.errorMap]);
}

class AuthenticationException extends AuthenticationState {
  final e;

  AuthenticationException([this.e]);
}

class AuthenticationOperationFailure extends AuthenticationState {}
