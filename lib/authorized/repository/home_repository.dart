import 'package:flutter/material.dart';

class AuthenticationRepository {
  final AuthenticationDataProvider dataProvider;

  AuthenticationRepository({@required this.dataProvider})
      : assert(dataProvider != null);
}
