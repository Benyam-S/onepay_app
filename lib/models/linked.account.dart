class LinkedAccount {
  String id;
  String userID;
  String accountProvider;
  String accountID;
  double amount;

  LinkedAccount(
      this.id, this.userID, this.accountProvider, this.accountID, this.amount);

  factory LinkedAccount.fromJson(Map<String, dynamic> json) {
    return LinkedAccount(
      json["ID"] as String,
      json["UserID"] as String,
      json["AccountProvider"] as String,
      json["AccountID"] as String,
      (json['Amount'] as num)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "ID": id,
      "UserID": userID,
      "AccountProvider": accountProvider,
      "AccountID": accountID,
      "Amount": amount,
    };
  }
}
