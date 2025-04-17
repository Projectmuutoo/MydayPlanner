// To parse this JSON data, do
//
//     final signInUserPostResponst = signInUserPostResponstFromJson(jsonString);

import 'dart:convert';

SignInUserPostResponst signInUserPostResponstFromJson(String str) =>
    SignInUserPostResponst.fromJson(json.decode(str));

String signInUserPostResponstToJson(SignInUserPostResponst data) =>
    json.encode(data.toJson());

class SignInUserPostResponst {
  bool success;
  String message;
  String role;

  SignInUserPostResponst({
    required this.success,
    required this.message,
    required this.role,
  });

  factory SignInUserPostResponst.fromJson(Map<String, dynamic> json) =>
      SignInUserPostResponst(
        success: json["success"],
        message: json["message"],
        role: json["role"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "role": role,
      };
}
