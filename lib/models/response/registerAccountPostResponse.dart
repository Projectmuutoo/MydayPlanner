// To parse this JSON data, do
//
//     final registerAccountPostResponse = registerAccountPostResponseFromJson(jsonString);

import 'dart:convert';

RegisterAccountPostResponse registerAccountPostResponseFromJson(String str) =>
    RegisterAccountPostResponse.fromJson(json.decode(str));

String registerAccountPostResponseToJson(RegisterAccountPostResponse data) =>
    json.encode(data.toJson());

class RegisterAccountPostResponse {
  String message;
  int userId;

  RegisterAccountPostResponse({
    required this.message,
    required this.userId,
  });

  factory RegisterAccountPostResponse.fromJson(Map<String, dynamic> json) =>
      RegisterAccountPostResponse(
        message: json["message"],
        userId: json["user_id"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "user_id": userId,
      };
}
