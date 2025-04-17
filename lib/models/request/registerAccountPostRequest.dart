// To parse this JSON data, do
//
//     final registerAccountPostRequest = registerAccountPostRequestFromJson(jsonString);

import 'dart:convert';

RegisterAccountPostRequest registerAccountPostRequestFromJson(String str) =>
    RegisterAccountPostRequest.fromJson(json.decode(str));

String registerAccountPostRequestToJson(RegisterAccountPostRequest data) =>
    json.encode(data.toJson());

class RegisterAccountPostRequest {
  String name;
  String email;
  String hashedPassword;
  String profile;

  RegisterAccountPostRequest({
    required this.name,
    required this.email,
    required this.hashedPassword,
    required this.profile,
  });

  factory RegisterAccountPostRequest.fromJson(Map<String, dynamic> json) =>
      RegisterAccountPostRequest(
        name: json["name"],
        email: json["email"],
        hashedPassword: json["hashed_password"],
        profile: json["profile"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "email": email,
        "hashed_password": hashedPassword,
        "profile": profile,
      };
}
