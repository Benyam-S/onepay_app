import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onepay_app/authentication/bloc/authentication_state.dart';
import 'package:onepay_app/models/response.dart';
import 'package:onepay_app/user/bloc/bloc.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;
  final AuthenticationRepository authenticationRepository;

  UserBloc({this.userRepository, this.authenticationRepository})
      : assert(userRepository != null && authenticationRepository != null),
        super(SignUpInitLoaded());

  @override
  Stream<UserState> mapEventToState(UserEvent event) async* {
    // +++++++++++++++++++++++++++++++++++++++++ ESignUpInit +++++++++++++++++++++++++++++++++++++++++
    if (event is ESignUpInit) {
      yield SignUpLoading();

      try {
        RepositoryResponse response = await userRepository.signUpInit(
            event.firstName, event.lastName, event.email, event.phoneNumber);
        yield _handleResponse(response);
        return;
      } catch (e) {
        yield SignUpException(e);
        return;
      }
    }

    // +++++++++++++++++++++++++++++++++++++++++ ESignUpVerify +++++++++++++++++++++++++++++++++++++++++
    else if (event is ESignUpVerify) {
      yield SignUpLoading();

      try {
        RepositoryResponse response =
            await userRepository.signUpVerify(event.nonce, event.otp);
        yield _handleResponse(response);
        return;
      } catch (e) {
        yield SignUpException(e);
        return;
      }
    }

    // +++++++++++++++++++++++++++++++++++++++++ EResendLoginOTP +++++++++++++++++++++++++++++++++++++++++
    else if (event is EResendSignUpOTP) {
      yield OTPResending();

      try {
        RepositoryResponse response =
            await authenticationRepository.resendOTP(event.nonce);
        yield _handleResponse(response);
      } catch (e) {
        yield SignUpException(e);
      }
    }

    // +++++++++++++++++++++++++++++++++++++++++ ESignUpFinish +++++++++++++++++++++++++++++++++++++++++
    else if (event is ESignUpFinish) {
      yield SignUpLoading();

      try {
        RepositoryResponse response = await userRepository.signUpFinish(
            event.newPassword, event.verifyPassword, event.nonce);
        yield _handleResponse(response);
        return;
      } catch (e) {
        yield SignUpException(e);
        return;
      }
    }

    // +++++++++++++++++++++++++++++++++++++++++ ESignUpChangeState +++++++++++++++++++++++++++++++++++++++++
    else if (event is ESignUpChangeState) {
      yield event.state;
      return;
    }
  }

  UserState _handleResponse(RepositoryResponse response) {
    UserState state;

    if (response is RSignUpInitSuccess) {
      state = SignUpInitSuccess(response.nonce);
    } else if (response is RSingUpInitFailure) {
      state = SignUpInitFailure(response.errorMap);
    } else if (response is ROTPVerifySuccess) {
      state = OTPVerifySuccess(nonce: response.nonce);
    } else if (response is ROTPVerifyFailure) {
      state = OTPVerifyFailure(response.errorMap);
    } else if (response is ROTPResendSuccess) {
      state = OTPResendSuccess();
    } else if (response is ROTPResendFailure) {
      state = OTPResendFailure(response.errorMap);
    } else if (response is RSignUpFinishSuccess) {
      state = SignUpFinishSuccess(response.accessToken);
    } else if (response is RSingUpFinishFailure) {
      state = SignUpFinishFailure(response.errorMap);
    } else if (response is RSignUpFailure) {
      state = SignUpException(AppException(response.error));
    } else {
      state = SignUpOperationFailure();
    }

    return state;
  }
}
