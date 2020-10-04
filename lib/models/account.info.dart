class AccountInfo {
  String accountID;
  String accountProvider;
  double amount;

  AccountInfo(this.accountID, this.accountProvider, this.amount);

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      json["AccountID"] as String,
      json["AccountProvider"] as String,
      (json['Amount'] as num)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "AccountID": accountID,
      "AccountProvider": accountProvider,
      "Amount": amount,
    };
  }
}
