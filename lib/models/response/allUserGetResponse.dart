// To parse this JSON data, do
//
//     final allUserGetResponse = allUserGetResponseFromJson(jsonString);

import 'dart:convert';

List<AllUserGetResponse> allUserGetResponseFromJson(String str) =>
    List<AllUserGetResponse>.from(
        json.decode(str).map((x) => AllUserGetResponse.fromJson(x)));

String allUserGetResponseToJson(List<AllUserGetResponse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AllUserGetResponse {
  int userId;
  String name;
  String email;
  String hashedPassword;
  String profile;
  String role;
  String isVerify;
  String isActive;
  String createdAt;

  AllUserGetResponse({
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

  factory AllUserGetResponse.fromJson(Map<String, dynamic> json) =>
      AllUserGetResponse(
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
