import 'package:onepay_app/user/bloc/bloc.dart';

class UserEvent {}

class ESignUpInit extends UserEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;

  ESignUpInit(this.firstName, this.lastName, this.email, this.phoneNumber);
}

class ESignUpVerify extends UserEvent {
  final String nonce;
  final String otp;

  ESignUpVerify(this.nonce, this.otp);
}

class ESignUpFinish extends UserEvent {
  final String newPassword;
  final String verifyPassword;
  final String nonce;

  ESignUpFinish(this.newPassword, this.verifyPassword, this.nonce);
}

class ESignUpChangeState extends UserEvent {
  final UserState state;

  ESignUpChangeState(this.state) : assert(state != null);
}
