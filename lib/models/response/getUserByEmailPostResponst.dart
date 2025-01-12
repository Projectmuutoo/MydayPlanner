// To parse this JSON data, do
//
//     final getUserByEmailPostResponst = getUserByEmailPostResponstFromJson(jsonString);

import 'dart:convert';

GetUserByEmailPostResponst getUserByEmailPostResponstFromJson(String str) =>
    GetUserByEmailPostResponst.fromJson(json.decode(str));

String getUserByEmailPostResponstToJson(GetUserByEmailPostResponst data) =>
    json.encode(data.toJson());

class GetUserByEmailPostResponst {
  int userId;
  String name;
  String email;
  String hashedPassword;
  String profile;
  String role;
  String isActive;
  int isVerify;
  DateTime createAt;

  GetUserByEmailPostResponst({
    required this.userId,
    required this.name,
    required this.email,
    required this.hashedPassword,
    required this.profile,
    required this.role,
    required this.isActive,
    required this.isVerify,
    required this.createAt,
  });

  factory GetUserByEmailPostResponst.fromJson(Map<String, dynamic> json) =>
      GetUserByEmailPostResponst(
        userId: json["user_id"],
        name: json["name"],
        email: json["email"],
        hashedPassword: json["hashed_password"],
        profile: json["profile"],
        role: json["role"],
        isActive: json["is_active"],
        isVerify: json["is_verify"],
        createAt: DateTime.parse(json["create_at"]),
      );

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "name": name,
        "email": email,
        "hashed_password": hashedPassword,
        "profile": profile,
        "role": role,
        "is_active": isActive,
        "is_verify": isVerify,
        "create_at": createAt.toIso8601String(),
      };
}
