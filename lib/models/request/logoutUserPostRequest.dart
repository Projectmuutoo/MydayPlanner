// To parse this JSON data, do
//
//     final logoutUserPostRequest = logoutUserPostRequestFromJson(jsonString);

import 'dart:convert';

LogoutUserPostRequest logoutUserPostRequestFromJson(String str) =>
    LogoutUserPostRequest.fromJson(json.decode(str));

String logoutUserPostRequestToJson(LogoutUserPostRequest data) =>
    json.encode(data.toJson());

class LogoutUserPostRequest {
  String email;

  LogoutUserPostRequest({
    required this.email,
  });

  factory LogoutUserPostRequest.fromJson(Map<String, dynamic> json) =>
      LogoutUserPostRequest(
        email: json["email"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
      };
}
