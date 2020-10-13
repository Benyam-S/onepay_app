class AccountInfo {
  String accountID;
  String accountProviderID;
  double amount;

  AccountInfo(this.accountID, this.accountProviderID, this.amount);

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      json["AccountID"] as String,
      json["AccountProviderID"] as String,
      (json['Amount'] as num)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "AccountID": accountID,
      "AccountProviderID": accountProviderID,
      "Amount": amount,
    };
  }
}
