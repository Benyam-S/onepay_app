import 'package:onepay_app/models/constants.dart';

class Session {
  String id;
  String deviceInfo;
  String ipAddress;
  String type;
  DateTime createdAt;
  DateTime updatedAt;

  Session(this.id, this.deviceInfo, this.ipAddress, this.type, this.createdAt,
      this.updatedAt);

  String get applicationName {
    if (type == APIClientTypeExternalB) {
      return deviceInfo;
    } else if (type == ClientTypeWebB) {
      return "OnePay Web";
    }

    var reg = RegExp(r"^.*\(");
    bool containApplicationName = reg.hasMatch(this.deviceInfo);
    if (containApplicationName) {
      String name = reg.stringMatch(this.deviceInfo);
      name = name.replaceAll(RegExp(r"[\(\);]"), " ").trim();
      return name;
    }

    return deviceInfo;
  }

  String get targetDevice {
    if (type == APIClientTypeExternalB) {
      return "Third Party Session";
    } else if (type == ClientTypeWebB) {
      return deviceInfo;
    }

    var reg = RegExp(r"\(.*\)$");
    bool containUserAgent = reg.hasMatch(this.deviceInfo);
    if (containUserAgent) {
      String device = reg.stringMatch(this.deviceInfo);
      device = device.replaceAll(RegExp(r"[\)\(;]"), " ").trim();
      return device;
    }

    return deviceInfo;
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      json["ID"] as String,
      json["DeviceInfo"] as String,
      json["IPAddress"] as String,
      json["Type"] as String,
      json['CreatedAt'] == null
          ? null
          : DateTime.parse(json['CreatedAt'] as String),
      json['UpdatedAt'] == null
          ? null
          : DateTime.parse(json['UpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "ID": id,
      "DeviceInfo": deviceInfo,
      "IPAddress": ipAddress,
      "Type": type,
      "CreatedAt": createdAt?.toIso8601String(),
      "UpdatedAt": updatedAt?.toIso8601String(),
    };
  }
}
