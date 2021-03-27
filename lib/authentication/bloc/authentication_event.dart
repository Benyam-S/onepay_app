import 'package:onepay_app/authentication/bloc/authentication_state.dart';
import 'package:onepay_app/models/access.token.dart';

class AuthenticationEvent {}

class ELogin extends AuthenticationEvent {
  final String identifier;
  final String password;

  ELogin(this.identifier, this.password);
}

class EVerifyLoginOTP extends AuthenticationEvent {
  final String nonce;
  final String otp;

  EVerifyLoginOTP(this.nonce, this.otp);
}

class EResendLoginOTP extends AuthenticationEvent {
  final String nonce;

  EResendLoginOTP(this.nonce);
}

class EResetPassword extends AuthenticationEvent {
  final String method;
  final String identifier;

  EResetPassword(this.method, this.identifier);
}

class ESetAccessToken extends AuthenticationEvent {
  final AccessToken accessToken;
  final bool isLoggedIn;

  ESetAccessToken(this.accessToken, {this.isLoggedIn});
}

class EAuthenticationChangeState extends AuthenticationEvent {
  final AuthenticationState state;

  EAuthenticationChangeState(this.state) : assert(state != null);
}
