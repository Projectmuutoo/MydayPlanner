// To parse this JSON data, do
//
//     final dataProfileGetResponst = dataProfileGetResponstFromJson(jsonString);

import 'dart:convert';

DataProfileGetResponst dataProfileGetResponstFromJson(String str) =>
    DataProfileGetResponst.fromJson(json.decode(str));

String dataProfileGetResponstToJson(DataProfileGetResponst data) =>
    json.encode(data.toJson());

class DataProfileGetResponst {
  User user;

  DataProfileGetResponst({required this.user});

  factory DataProfileGetResponst.fromJson(Map<String, dynamic> json) =>
      DataProfileGetResponst(user: User.fromJson(json["user"]));

  Map<String, dynamic> toJson() => {"user": user.toJson()};
}

class User {
  int userId;
  String name;
  String email;
  String hashedPassword;
  String profile;
  String role;
  String isVerify;
  String isActive;
  String createdAt;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.hashedPassword,
    required this.profile,
    required this.role,
    required this.isVerify,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json["UserID"],
    name: json["Name"],
    email: json["Email"],
    hashedPassword: json["HashedPassword"],
    profile: json["Profile"],
    role: json["Role"],
    isVerify: json["IsVerify"],
    isActive: json["IsActive"],
    createdAt: json["CreatedAt"],
  );

  Map<String, dynamic> toJson() => {
    "UserID": userId,
    "Name": name,
    "Email": email,
    "HashedPassword": hashedPassword,
    "Profile": profile,
    "Role": role,
    "IsVerify": isVerify,
    "IsActive": isActive,
    "CreatedAt": createdAt,
  };
}
