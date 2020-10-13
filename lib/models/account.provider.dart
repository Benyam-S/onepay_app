class AccountProvider {
  String id;
  String name;
  DateTime createdAt;

  AccountProvider(this.id, this.name, this.createdAt);

  factory AccountProvider.fromJson(Map<String, dynamic> json) {
    return AccountProvider(
        json["ID"] as String,
        json["Name"] as String,
        json['CreatedAt'] == null
            ? null
            : DateTime.parse(json['CreatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "ID": id,
      "Name": name,
      "CreatedAt": createdAt?.toIso8601String(),
    };
  }
}
