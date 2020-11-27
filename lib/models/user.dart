part 'user.g.dart';

class User {
  String userID;
  String firstName;
  String lastName;
  String email;
  String phoneNumber;
  String profilePic;
  DateTime createdAt;
  DateTime updatedAt;

  User(this.userID, this.firstName, this.lastName, this.email, this.phoneNumber,
      this.profilePic, this.createdAt, this.updatedAt);

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copy() {
    return User(this.userID, this.firstName, this.lastName, this.email,
        this.phoneNumber, this.profilePic, this.createdAt, this.updatedAt);
  }

  String get onlyPhoneNumber => phoneNumber.replaceAll(RegExp(r"[^+0-9]+"), "");

  String get countryCode {
    var reg = RegExp(r"\[[a-zA-Z]{2}]$");
    bool containCountryCode = reg.hasMatch(this.phoneNumber);
    if (containCountryCode) {
      String countryCode = reg.stringMatch(this.phoneNumber);
      countryCode = countryCode.replaceAll(RegExp(r"[\[\]]"), "").toUpperCase();
      return countryCode;
    }

    return "";
  }
}
