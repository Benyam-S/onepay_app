import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onepay_app/utils/request.maker.dart';

class HomeDataProvider {
  Future<http.Response> getCurrencyRate(BuildContext context) async {
    var requester = HttpRequester(path: "/oauth/currency/rates/ETB.json");
    var response = await requester.get(context);
    return response;
  }
}
