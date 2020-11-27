part 'money.token.g.dart';

class MoneyToken {
  String code;
  String senderID;
  DateTime sentAt;
  double amount;
  DateTime expirationDate;
  String method;

  MoneyToken(this.code, this.senderID, this.sentAt, this.amount,
      this.expirationDate, this.method);

  factory MoneyToken.fromJson(Map<String, dynamic> json) =>
      _$MoneyTokenFromJson(json);

  Map<String, dynamic> toJson() => _$MoneyTokenToJson(this);
}
