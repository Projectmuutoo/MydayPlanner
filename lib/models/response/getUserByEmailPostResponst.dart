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
  String isVerify;
  String isActive;
  String createdAt;

  GetUserByEmailPostResponst({
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

  factory GetUserByEmailPostResponst.fromJson(Map<String, dynamic> json) =>
      GetUserByEmailPostResponst(
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
