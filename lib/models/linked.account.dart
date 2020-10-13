class LinkedAccount {
  String id;
  String userID;
  String accountProviderID;
  String accountProviderName;
  String accountID;
  double amount;

  LinkedAccount(
      this.id, this.userID, this.accountProviderID, this.accountProviderName, this.accountID, this.amount);

  factory LinkedAccount.fromJson(Map<String, dynamic> json) {
    return LinkedAccount(
      json["ID"] as String,
      json["UserID"] as String,
      json["AccountProviderID"] as String,
      json["AccountProviderName"] as String,
      json["AccountID"] as String,
      (json['Amount'] as num)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "ID": id,
      "UserID": userID,
      "AccountProviderID": accountProviderID,
      "AccountProviderName": accountProviderName,
      "AccountID": accountID,
      "Amount": amount,
    };
  }

  void copyWith(LinkedAccount linkedAccount) {
    this.id = linkedAccount.id;
    this.userID = linkedAccount.userID;
    this.accountProviderID = linkedAccount.accountProviderID;
    this.accountProviderName = linkedAccount.accountProviderName;
    this.accountID = linkedAccount.accountID;
    this.amount = linkedAccount.amount;
  }
}
