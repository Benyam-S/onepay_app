import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/response.dart';

class RSignUpInitSuccess extends RepositoryResponse {
  final String nonce;

  RSignUpInitSuccess(this.nonce);
}

class RSingUpInitFailure extends RepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  RSingUpInitFailure(this.statusCode, this.errorMap);
}

class RSignUpFinishSuccess extends RepositoryResponse {
  final AccessToken accessToken;

  RSignUpFinishSuccess(this.accessToken);
}

class RSingUpFinishFailure extends RepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  RSingUpFinishFailure(this.statusCode, this.errorMap);
}

class RSignUpFailure extends RepositoryResponse {
  final String error;

  RSignUpFailure([this.error]);
}
