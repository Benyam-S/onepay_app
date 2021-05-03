import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onepay_app/authorized/bloc/common/common_event.dart';
import 'package:onepay_app/authorized/bloc/common/common_state.dart';
import 'package:onepay_app/authorized/bloc/home/bloc.dart';
import 'package:onepay_app/authorized/bloc/home/home_event.dart';
import 'package:onepay_app/authorized/repository/home_response.dart';

class HomeBloc extends Bloc<AuthorizedEvent, AuthorizedState> {
  final HomeRepository homeRepository;

  HomeBloc({@required this.homeRepository})
      : assert(homeRepository != null),
        super(null);

  @override
  Stream<AuthorizedState> mapEventToState(AuthorizedEvent event) async* {
    // +++++++++++++++++++++++++++++++++++++++++ EGetCurrencyRates +++++++++++++++++++++++++++++++++++++++++
    if (event is EGetCurrencyRates) {
      yield HomeLoading();

      try {
        RepositoryResponse response =
            await homeRepository.getCurrencyRate(event.context);
        yield _handleResponse(response);
      } catch (e) {
        yield AuthorizedException(e);
      }
    }
  }

  AuthorizedState _handleResponse(RepositoryResponse response) {
    AuthorizedState state;
    if (response is RCurrencyRateGetSuccess) {
      state = CurrencyRateGetSuccess(response.currencyRates);
    } else if (response is RCurrencyRateGetFailure) {
      state = CurrencyRateGetFailure(response.errorMap);
    } else {
      state = AuthorizedOperationFailure();
    }

    return state;
  }
}
