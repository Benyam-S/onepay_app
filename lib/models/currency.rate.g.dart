// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency.rate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrencyRate _$CurrencyRateFromJson(Map<String, dynamic> json) {
  return CurrencyRate(
      json['FromSymbol'] as String,
      json['FromName'] as String,
      json['ToSymbol'] as String,
      json['ToName'] as String,
      (json['CurrentValue'] as num)?.toDouble(),
      (json['Values'] as List)?.map((e) => (e as num)?.toDouble())?.toList(),
      (json['Dates'] as List)
          ?.map((e) => e == null ? null : DateTime.parse(e as String))
          ?.toList());
}

Map<String, dynamic> _$CurrencyRateToJson(CurrencyRate instance) =>
    <String, dynamic>{
      'FromSymbol': instance.fromSymbol,
      'FromName': instance.fromName,
      'ToSymbol': instance.toSymbol,
      'ToName': instance.toName,
      'CurrentValue': instance.currentValue,
      'Values': instance.values,
      'Dates': instance.dates?.map((e) => e?.toIso8601String())?.toList()
    };
