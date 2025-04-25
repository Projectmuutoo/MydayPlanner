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

  RegisterAccountPostRequest({
    required this.name,
    required this.email,
    required this.hashedPassword,
  });

  factory RegisterAccountPostRequest.fromJson(Map<String, dynamic> json) =>
      RegisterAccountPostRequest(
        name: json["name"],
        email: json["email"],
        hashedPassword: json["hashed_password"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "email": email,
        "hashed_password": hashedPassword,
      };
}
