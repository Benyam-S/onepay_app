class AuthorizedState {}

class AuthorizedException extends AuthorizedState {
  final e;

  AuthorizedException([this.e]);
}

class AuthorizedOperationFailure extends AuthorizedState {}
