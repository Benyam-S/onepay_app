part 'wallet.g.dart';

class Wallet {
  String userID;
  double amount;
  bool seen;
  DateTime updatedAt;

  Wallet(this.userID, this.amount, this.seen, this.updatedAt);

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

  Map<String, dynamic> toJson() => _$WalletToJson(this);
}
