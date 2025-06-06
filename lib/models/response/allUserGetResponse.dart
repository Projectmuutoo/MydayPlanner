// To parse this JSON data, do
//
//     final allUserGetResponse = allUserGetResponseFromJson(jsonString);

import 'dart:convert';

List<AllUserGetResponse> allUserGetResponseFromJson(String str) =>
    List<AllUserGetResponse>.from(
      json.decode(str).map((x) => AllUserGetResponse.fromJson(x)),
    );

String allUserGetResponseToJson(List<AllUserGetResponse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AllUserGetResponse {
  String createAt;
  String email;
  String isActive;
  int isVerify;
  String name;
  String profile;
  String role;
  int userId;

  AllUserGetResponse({
    required this.createAt,
    required this.email,
    required this.isActive,
    required this.isVerify,
    required this.name,
    required this.profile,
    required this.role,
    required this.userId,
  });

  factory AllUserGetResponse.fromJson(Map<String, dynamic> json) =>
      AllUserGetResponse(
        createAt: json["create_at"],
        email: json["email"],
        isActive: json["is_active"],
        isVerify: json["is_verify"],
        name: json["name"],
        profile: json["profile"],
        role: json["role"],
        userId: json["user_id"],
      );

  Map<String, dynamic> toJson() => {
    "create_at": createAt,
    "email": email,
    "is_active": isActive,
    "is_verify": isVerify,
    "name": name,
    "profile": profile,
    "role": role,
    "user_id": userId,
  };
}
