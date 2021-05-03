import 'package:onepay_app/models/response.dart';

class RAuthorizedFailure extends RepositoryResponse {
  final String error;

  RAuthorizedFailure([this.error]);
}
