import 'package:json_annotation/json_annotation.dart';

part 'wallet.g.dart';

@JsonSerializable()
class Wallet {
  String userID;
  double amount;
  bool seen;
  DateTime updatedAt;

  Wallet(this.userID, this.amount, this.seen, this.updatedAt);

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

  Map<String, dynamic> toJson() => _$WalletToJson(this);
}