// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
      json['UserID'] as String,
      json['FirstName'] as String,
      json['LastName'] as String,
      json['Email'] as String,
      json['PhoneNumber'] as String,
      json['ProfilePic'] as String,
      json['CreatedAt'] == null
          ? null
          : DateTime.parse(json['CreatedAt'] as String),
      json['UpdatedAt'] == null
          ? null
          : DateTime.parse(json['UpdatedAt'] as String));
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'UserID': instance.userID,
      'FirstName': instance.firstName,
      'LastName': instance.lastName,
      'Email': instance.email,
      'PhoneNumber': instance.phoneNumber,
      'ProfilePic': instance.profilePic,
      'CreatedAt': instance.createdAt?.toIso8601String(),
      'UpdatedAt': instance.updatedAt?.toIso8601String()
    };
