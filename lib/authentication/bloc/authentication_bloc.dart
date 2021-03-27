import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onepay_app/authentication/bloc/bloc.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationRepository authenticationRepository;

  AuthenticationBloc({@required this.authenticationRepository})
      : assert(authenticationRepository != null),
        super(null);

  @override
  Stream<AuthenticationState> mapEventToState(
      AuthenticationEvent event) async* {
    // +++++++++++++++++++++++++++++++++++++++++ ELogin +++++++++++++++++++++++++++++++++++++++++
    if (event is ELogin) {
      yield AccessTokenLoading();

      try {
        AuthenticationRepositoryResponse response =
            await authenticationRepository.getAccessTokenOverNetwork(
                event.identifier, event.password);
        yield _handleResponse(response);
      } catch (e) {
        yield AuthenticationException(e);
      }
    }

    // +++++++++++++++++++++++++++++++++++++++++ ESetAccessToken +++++++++++++++++++++++++++++++++++++++++
    else if (event is ESetAccessToken) {
      authenticationRepository.setAccessToken(event.accessToken,
          isLoggedIn: event.isLoggedIn);

      yield AccessTokenLoaded(event.accessToken);
    }

    // +++++++++++++++++++++++++++++++++++++++++ EVerifyLoginOTP +++++++++++++++++++++++++++++++++++++++++
    else if (event is EVerifyLoginOTP) {
      yield OTPVerifying();

      try {
        AuthenticationRepositoryResponse response =
            await authenticationRepository.verifyLoginOTP(
                event.nonce, event.otp);
        yield _handleResponse(response);
      } catch (e) {
        yield AuthenticationException(e);
      }
    }

    // +++++++++++++++++++++++++++++++++++++++++ EResendLoginOTP +++++++++++++++++++++++++++++++++++++++++
    else if (event is EResendLoginOTP) {
      yield OTPResending();

      try {
        AuthenticationRepositoryResponse response =
            await authenticationRepository.resendLoginOTP(event.nonce);
        yield _handleResponse(response);
      } catch (e) {
        yield AuthenticationException(e);
      }
    }

    // +++++++++++++++++++++++++++++++++++++++++ EResetPassword +++++++++++++++++++++++++++++++++++++++++
    else if (event is EResetPassword) {
      yield PasswordResetting();

      try {
        AuthenticationRepositoryResponse response =
            await authenticationRepository.requestPasswordRest(
                event.method, event.identifier);
        yield _handleResponse(response);
      } catch (e) {
        yield AuthenticationException(e);
      }
    }

    // +++++++++++++++++++++++++++++++++++++++++ ESetAccessToken +++++++++++++++++++++++++++++++++++++++++
    else if (event is ESetAccessToken) {
      authenticationRepository.setAccessToken(event.accessToken,
          isLoggedIn: event.isLoggedIn);

      yield AccessTokenLoaded(event.accessToken);
    }

    // +++++++++++++++++++++++++++++++++++++++++ EAuthenticationChangeState +++++++++++++++++++++++++++++++++++++++++
    else if (event is EAuthenticationChangeState) {
      yield event.state;
      return;
    }
  }

  AuthenticationState _handleResponse(
      AuthenticationRepositoryResponse response) {
    AuthenticationState state;

    if (response is ROTPGetSuccess) {
      state = OTPGetSuccess(response.nonce);
    } else if (response is ROTPVerifySuccess) {
      state = OTPVerifySuccess(response.accessToken);
    } else if (response is ROTPVerifyFailure) {
      state = OTPVerifyFailure(response.errorMap);
    } else if (response is ROTPResendSuccess) {
      state = OTPResendSuccess();
    } else if (response is ROTPResendFailure) {
      state = OTPResendFailure(response.errorMap);
    } else if (response is RPasswordResetSuccess) {
      state = PasswordResetSuccess();
    } else if (response is RPasswordRestFailure) {
      state = PasswordResetFailure(response.errorMap);
    } else if (response is RAccessTokenGetSuccess) {
      state = AccessTokenGetSuccess(response.accessToken);
    } else if (response is RAccessTokenGetFailure) {
      state = AccessTokenGetFailure(response.errorMap);
    } else if (response is RAuthenticationFailure) {
      state = AuthenticationException(AppException(response.error));
    } else {
      state = AuthenticationOperationFailure();
    }

    return state;
  }
}
