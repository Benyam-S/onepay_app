import 'package:onepay_app/models/access.token.dart';

class UserState {}

class SignUpLoading extends UserState {}

class SignUpInitLoaded extends UserState {
  final int pausedStep;

  SignUpInitLoaded({this.pausedStep});
}

class SignUpInitSuccess extends UserState {
  final String nonce;

  SignUpInitSuccess(this.nonce);
}

class SignUpInitFailure extends UserState {
  final Map<String, dynamic> errorMap;

  SignUpInitFailure([this.errorMap]);
}

class SignUpOperationFailure extends UserState {}

class SignUpVerifyLoaded extends UserState {
  final String nonce;
  final int pausedStep;
  final bool isNew;

  SignUpVerifyLoaded(this.nonce, {this.pausedStep, this.isNew});
}

class SignUpVerifySuccess extends UserState {
  final String nonce;

  SignUpVerifySuccess(this.nonce);
}

class SignUpVerifyFailure extends UserState {
  final Map<String, dynamic> errorMap;

  SignUpVerifyFailure([this.errorMap]);
}

class SignUpFinishLoaded extends UserState {
  final String nonce;
  final int pausedStep;
  final bool isNew;

  SignUpFinishLoaded(this.nonce, {this.pausedStep, this.isNew});
}

class SignUpFinishSuccess extends UserState {
  final AccessToken accessToken;

  SignUpFinishSuccess(this.accessToken);
}

class SignUpFinishFailure extends UserState {
  final Map<String, dynamic> errorMap;

  SignUpFinishFailure([this.errorMap]);
}

class SignUpSuccessLoaded extends UserState {
  final AccessToken accessToken;
  final int pausedStep;

  SignUpSuccessLoaded(this.accessToken, {this.pausedStep});
}

class SignUpException extends UserState {
  final e;

  SignUpException([this.e]);
}
