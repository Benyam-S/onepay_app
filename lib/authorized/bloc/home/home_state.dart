import 'package:onepay_app/authorized/bloc/common/common_state.dart';
import 'package:onepay_app/authorized/repository/repository.dart';

class HomeLoading extends AuthorizedState {}

class HomeLoaded extends AuthorizedState {
  final List<CurrencyRate> currencyRates;

  HomeLoaded(this.currencyRates);
}

class CurrencyRateGetSuccess extends AuthorizedState {
  final List<CurrencyRate> currencyRates;

  CurrencyRateGetSuccess(this.currencyRates);
}

class CurrencyRateGetFailure extends AuthorizedState {
  final Map<String, dynamic> errorMap;

  CurrencyRateGetFailure([this.errorMap]);
}
