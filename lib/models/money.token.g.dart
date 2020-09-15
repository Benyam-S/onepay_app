// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money.token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoneyToken _$MoneyTokenFromJson(Map<String, dynamic> json) {
  return MoneyToken(
      json['Code'] as String,
      json['SenderID'] as String,
      json['SentAt'] == null ? null : DateTime.parse(json['SentAt'] as String),
      (json['Amount'] as num)?.toDouble(),
      json['ExpirationDate'] == null
          ? null
          : DateTime.parse(json['ExpirationDate'] as String),
      json['Method'] as String);
}

Map<String, dynamic> _$MoneyTokenToJson(MoneyToken instance) =>
    <String, dynamic>{
      'Code': instance.code,
      'SenderID': instance.senderID,
      'SentAt': instance.sentAt?.toIso8601String(),
      'Amount': instance.amount,
      'ExpirationDate': instance.expirationDate?.toIso8601String(),
      'Method': instance.method
    };
