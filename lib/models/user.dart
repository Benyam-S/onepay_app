import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
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
}
