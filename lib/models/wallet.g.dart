// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wallet _$WalletFromJson(Map<String, dynamic> json) {
  return Wallet(
      json['UserID'] as String,
      (json['Amount'] as num)?.toDouble(),
      json['Seen'] as bool,
      json['UpdatedAt'] == null
          ? null
          : DateTime.parse(json['UpdatedAt'] as String));
}

Map<String, dynamic> _$WalletToJson(Wallet instance) => <String, dynamic>{
      'UserID': instance.userID,
      'Amount': instance.amount,
      'Seen': instance.seen,
      'UpdatedAt': instance.updatedAt?.toIso8601String()
    };
