class UserPreference {
  String userID;
  bool twoStepVerification;

  UserPreference(this.userID, this.twoStepVerification);

  UserPreference.fromJson(Map<String, dynamic> json)
      : userID = json['UserID'] as String,
        twoStepVerification = json['TwoStepVerification'] as bool;

  Map<String, dynamic> toJson() =>
      {'UserID': userID, 'TwoStepVerification': twoStepVerification};
}
