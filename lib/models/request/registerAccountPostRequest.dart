// To parse this JSON data, do
//
//     final registerAccountPostRequest = registerAccountPostRequestFromJson(jsonString);

import 'dart:convert';

RegisterAccountPostRequest registerAccountPostRequestFromJson(String str) =>
    RegisterAccountPostRequest.fromJson(json.decode(str));

String registerAccountPostRequestToJson(RegisterAccountPostRequest data) =>
    json.encode(data.toJson());

class RegisterAccountPostRequest {
  String email;
  String password;
  String name;

  RegisterAccountPostRequest({
    required this.email,
    required this.password,
    required this.name,
  });

  factory RegisterAccountPostRequest.fromJson(Map<String, dynamic> json) =>
      RegisterAccountPostRequest(
        email: json["email"],
        password: json["password"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
    "email": email,
    "password": password,
    "name": name,
  };
}
