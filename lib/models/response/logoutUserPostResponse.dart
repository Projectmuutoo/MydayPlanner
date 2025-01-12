// To parse this JSON data, do
//
//     final logoutUserPostResponse = logoutUserPostResponseFromJson(jsonString);

import 'dart:convert';

LogoutUserPostResponse logoutUserPostResponseFromJson(String str) =>
    LogoutUserPostResponse.fromJson(json.decode(str));

String logoutUserPostResponseToJson(LogoutUserPostResponse data) =>
    json.encode(data.toJson());

class LogoutUserPostResponse {
  bool success;
  String message;

  LogoutUserPostResponse({
    required this.success,
    required this.message,
  });

  factory LogoutUserPostResponse.fromJson(Map<String, dynamic> json) =>
      LogoutUserPostResponse(
        success: json["success"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
      };
}
