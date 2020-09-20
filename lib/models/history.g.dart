// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

History _$HistoryFromJson(Map<String, dynamic> json) {
  return History(
      json['ID'] as String,
      json['SenderID'] as String,
      json['ReceiverID'] as String,
      json['SentAt'] == null ? null : DateTime.parse(json['SentAt'] as String),
      json['ReceivedAt'] == null
          ? null
          : DateTime.parse(json['ReceivedAt'] as String),
      json['Method'] as String,
      json['Code'] as String,
      (json['Amount'] as num)?.toDouble(),
      json['SenderSeen'] as bool,
      json['ReceiverSeen'] as bool);
}

Map<String, dynamic> _$HistoryToJson(History instance) => <String, dynamic>{
      'ID': instance.id,
      'SenderID': instance.senderID,
      'ReceiverID': instance.receiverID,
      'SentAt': instance.sentAt?.toIso8601String(),
      'ReceivedAt': instance.receivedAt?.toIso8601String(),
      'Method': instance.method,
      'Code': instance.code,
      'Amount': instance.amount,
      'SenderSeen': instance.senderSeen,
      'ReceiverSeen': instance.receiverSeen
    };
