import 'package:onepay_app/authentication/bloc/bloc.dart';

class AuthenticationState {
  const AuthenticationState();
}

class AccessTokenLoading extends AuthenticationState {}

class AccessTokenLoaded extends AuthenticationState {
  final AccessToken accessToken;

  AccessTokenLoaded(this.accessToken);
}

class OTPGetSuccess extends AuthenticationState {
  final String nonce;

  OTPGetSuccess(this.nonce);
}

class OTPVerifying extends AuthenticationState {}

class OTPVerifyLoaded extends AuthenticationState {}

class OTPVerifySuccess extends AuthenticationState {
  final AccessToken accessToken;

  OTPVerifySuccess(this.accessToken);
}

class OTPVerifyFailure extends AuthenticationState {
  final Map<String, dynamic> errorMap;

  OTPVerifyFailure([this.errorMap]);
}

class OTPResending extends AuthenticationState {}

class OTPResendSuccess extends AuthenticationState {}

class OTPResendFailure extends AuthenticationState {
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
