// To parse this JSON data, do
//
//     final googleLoginUserPostResponse = googleLoginUserPostResponseFromJson(jsonString);

import 'dart:convert';

GoogleLoginUserPostResponse googleLoginUserPostResponseFromJson(String str) =>
    GoogleLoginUserPostResponse.fromJson(json.decode(str));

String googleLoginUserPostResponseToJson(GoogleLoginUserPostResponse data) =>
    json.encode(data.toJson());

class GoogleLoginUserPostResponse {
  bool success;
  String message;
  String role;

  GoogleLoginUserPostResponse({
    required this.success,
    required this.message,
    required this.role,
  });

  factory GoogleLoginUserPostResponse.fromJson(Map<String, dynamic> json) =>
      GoogleLoginUserPostResponse(
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
