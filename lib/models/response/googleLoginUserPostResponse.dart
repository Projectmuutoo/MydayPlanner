// To parse this JSON data, do
//
//     final googleLoginUserPostResponse = googleLoginUserPostResponseFromJson(jsonString);

import 'dart:convert';

GoogleLoginUserPostResponse googleLoginUserPostResponseFromJson(String str) =>
    GoogleLoginUserPostResponse.fromJson(json.decode(str));

String googleLoginUserPostResponseToJson(GoogleLoginUserPostResponse data) =>
    json.encode(data.toJson());

class GoogleLoginUserPostResponse {
  String message;
  String status;
  User user;

  GoogleLoginUserPostResponse({
    required this.message,
    required this.status,
    required this.user,
  });

  factory GoogleLoginUserPostResponse.fromJson(Map<String, dynamic> json) =>
      GoogleLoginUserPostResponse(
        message: json["message"],
        status: json["status"],
        user: User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "status": status,
        "user": user.toJson(),
      };
}

class User {
  String email;
  int id;
  String name;

  User({
    required this.email,
    required this.id,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        email: json["email"],
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "id": id,
        "name": name,
      };
}
