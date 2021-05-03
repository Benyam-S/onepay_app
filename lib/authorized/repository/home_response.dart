import 'package:onepay_app/models/currency.rate.dart';
import 'package:onepay_app/models/response.dart';

class RCurrencyRateGetSuccess extends RepositoryResponse {
  final List<CurrencyRate> currencyRates;

  RCurrencyRateGetSuccess(this.currencyRates);
}

class RCurrencyRateGetFailure extends RepositoryResponse {
  final int statusCode;
  final Map<String, dynamic> errorMap;

  RCurrencyRateGetFailure([this.statusCode, this.errorMap]);
}
