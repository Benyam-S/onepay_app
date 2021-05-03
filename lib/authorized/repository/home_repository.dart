import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onepay_app/authorized/repository/repository.dart';

class HomeRepository {
  final HomeDataProvider dataProvider;

  HomeRepository({@required this.dataProvider}) : assert(dataProvider != null);

  Future<RepositoryResponse> getCurrencyRate(BuildContext context) async {
    http.Response response = await dataProvider.getCurrencyRate(context);

    switch (response.statusCode) {
      case HttpStatus.ok:
        List<dynamic> jsonData = json.decode(response.body);
        final List<CurrencyRate> currencyRates = List<CurrencyRate>();
        jsonData.forEach((element) {
          CurrencyRate currencyRate = CurrencyRate.fromJson(element);
          currencyRates.add(currencyRate);
        });

        return RCurrencyRateGetSuccess(currencyRates);
      case HttpStatus.badRequest:
        return RCurrencyRateGetFailure(
            response.statusCode, {"error": response.body});
      case HttpStatus.internalServerError:
        return RAuthorizedFailure(FailedOperationError);
      default:
        return RAuthorizedFailure(SomethingWentWrongError);
    }
  }
}
