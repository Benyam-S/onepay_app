import 'package:flutter/material.dart';

part 'currency.rate.g.dart';

class CurrencyRate {
  String fromSymbol;
  String fromName;
  String toSymbol;
  String toName;
  double currentValue;
  List<double> values;
  List<DateTime> dates;
  Color color;

  CurrencyRate(this.fromSymbol, this.fromName, this.toSymbol, this.toName,
      this.currentValue, this.values, this.dates);

  factory CurrencyRate.fromJson(Map<String, dynamic> json) =>
      _$CurrencyRateFromJson(json);

  Map<String, dynamic> toJson() => _$CurrencyRateToJson(this);
}
