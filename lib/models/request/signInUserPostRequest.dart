// To parse this JSON data, do
//
//     final signInUserPostRequest = signInUserPostRequestFromJson(jsonString);

import 'dart:convert';

SignInUserPostRequest signInUserPostRequestFromJson(String str) =>
    SignInUserPostRequest.fromJson(json.decode(str));

String signInUserPostRequestToJson(SignInUserPostRequest data) =>
    json.encode(data.toJson());

class SignInUserPostRequest {
  String email;
  String hashedPassword;

  SignInUserPostRequest({
    required this.email,
    required this.hashedPassword,
  });

  factory SignInUserPostRequest.fromJson(Map<String, dynamic> json) =>
      SignInUserPostRequest(
        email: json["email"],
        hashedPassword: json["hashed_password"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "hashed_password": hashedPassword,
      };
}
