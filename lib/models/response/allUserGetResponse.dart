// To parse this JSON data, do
//
//     final allUserGetResponse = allUserGetResponseFromJson(jsonString);

import 'dart:convert';

AllUserGetResponse allUserGetResponseFromJson(String str) =>
    AllUserGetResponse.fromJson(json.decode(str));

String allUserGetResponseToJson(AllUserGetResponse data) =>
    json.encode(data.toJson());

class AllUserGetResponse {
  bool success;
  List<User> users;

  AllUserGetResponse({
    required this.success,
    required this.users,
  });

  factory AllUserGetResponse.fromJson(Map<String, dynamic> json) =>
      AllUserGetResponse(
        success: json["success"],
        users: List<User>.from(json["users"].map((x) => User.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "users": List<dynamic>.from(users.map((x) => x.toJson())),
      };
}

class User {
  int userId;
  String name;
  String email;
  String hashedPassword;
  String profile;
  String role;
  String isActive;
  int isVerify;
  DateTime createAt;

  User({
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

  factory User.fromJson(Map<String, dynamic> json) => User(
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
