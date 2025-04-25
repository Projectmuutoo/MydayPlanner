// To parse this JSON data, do
//
//     final signInUserPostResponst = signInUserPostResponstFromJson(jsonString);

import 'dart:convert';

SignInUserPostResponst signInUserPostResponstFromJson(String str) =>
    SignInUserPostResponst.fromJson(json.decode(str));

String signInUserPostResponstToJson(SignInUserPostResponst data) =>
    json.encode(data.toJson());

class SignInUserPostResponst {
  String email;
  String message;
  String role;

  SignInUserPostResponst({
    required this.email,
    required this.message,
    required this.role,
  });

  factory SignInUserPostResponst.fromJson(Map<String, dynamic> json) =>
      SignInUserPostResponst(
        email: json["email"],
        message: json["message"],
        role: json["role"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "message": message,
        "role": role,
      };
}
