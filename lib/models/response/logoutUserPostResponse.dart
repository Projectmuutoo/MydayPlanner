// To parse this JSON data, do
//
//     final logoutUserPostResponse = logoutUserPostResponseFromJson(jsonString);

import 'dart:convert';

LogoutUserPostResponse logoutUserPostResponseFromJson(String str) =>
    LogoutUserPostResponse.fromJson(json.decode(str));

String logoutUserPostResponseToJson(LogoutUserPostResponse data) =>
    json.encode(data.toJson());

class LogoutUserPostResponse {
  String email;
  String message;

  LogoutUserPostResponse({
    required this.email,
    required this.message,
  });

  factory LogoutUserPostResponse.fromJson(Map<String, dynamic> json) =>
      LogoutUserPostResponse(
        email: json["email"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "message": message,
      };
}
