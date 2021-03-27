import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onepay_app/user/bloc/bloc.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;

  UserBloc({this.userRepository})
      : assert(userRepository != null),
        super(SignUpInitLoaded());

  @override
  Stream<UserState> mapEventToState(UserEvent event) async* {
    if (event is ESignUpInit) {
      yield SignUpLoading();

      try {
        UserRepositoryResponse response = await userRepository.signUpInit(
            event.firstName, event.lastName, event.email, event.phoneNumber);
        yield _handleResponse(response);
        return;
      } catch (e) {
        yield SignUpException(e);
        return;
      }
    } else if (event is ESignUpVerify) {
      yield SignUpLoading();

      try {
        UserRepositoryResponse response =
            await userRepository.signUpVerify(event.nonce, event.otp);
        yield _handleResponse(response);
        return;
      } catch (e) {
        yield SignUpException(e);
        return;
      }
    } else if (event is ESignUpFinish) {
      yield SignUpLoading();

      try {
        UserRepositoryResponse response = await userRepository.signUpFinish(
            event.newPassword, event.verifyPassword, event.nonce);
        yield _handleResponse(response);
        return;
      } catch (e) {
        yield SignUpException(e);
        return;
      }
    } else if (event is ESignUpChangeState) {
      yield event.state;
      return;
    }
  }

  UserState _handleResponse(UserRepositoryResponse response) {
    UserState state;

    if (response is RSignUpInitSuccess) {
      state = SignUpInitSuccess(response.nonce);
    } else if (response is RSingUpInitFailure) {
      state = SignUpInitFailure(response.errorMap);
    } else if (response is RSignUpVerifySuccess) {
      state = SignUpVerifySuccess(response.nonce);
    } else if (response is RSingUpVerifyFailure) {
      state = SignUpVerifyFailure(response.errorMap);
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
