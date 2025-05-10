// To parse this JSON data, do
//
//     final registerAccountPostResponse = registerAccountPostResponseFromJson(jsonString);

import 'dart:convert';

RegisterAccountPostResponse registerAccountPostResponseFromJson(String str) =>
    RegisterAccountPostResponse.fromJson(json.decode(str));

String registerAccountPostResponseToJson(RegisterAccountPostResponse data) =>
    json.encode(data.toJson());

class RegisterAccountPostResponse {
  String message;
  User user;

  RegisterAccountPostResponse({required this.message, required this.user});

  factory RegisterAccountPostResponse.fromJson(Map<String, dynamic> json) =>
      RegisterAccountPostResponse(
        message: json["message"],
        user: User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {"message": message, "user": user.toJson()};
}

class User {
  String email;
  String name;
  int userId;

  User({required this.email, required this.name, required this.userId});

  factory User.fromJson(Map<String, dynamic> json) =>
      User(email: json["email"], name: json["name"], userId: json["userId"]);

  Map<String, dynamic> toJson() => {
    "email": email,
    "name": name,
    "userId": userId,
  };
}
