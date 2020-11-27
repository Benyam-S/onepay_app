part 'history.g.dart';

class History {
  int id;
  String senderID;
  String receiverID;
  DateTime sentAt;
  DateTime receivedAt;
  String method;
  String code;
  double amount;
  bool senderSeen;
  bool receiverSeen;

  History(this.id, this.senderID, this.receiverID, this.sentAt, this.receivedAt,
      this.method, this.code, this.amount, this.senderSeen, this.receiverSeen);

  factory History.fromJson(Map<String, dynamic> json) =>
      _$HistoryFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryToJson(this);
}
