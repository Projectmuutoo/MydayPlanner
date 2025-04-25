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
  String status;

  RegisterAccountPostResponse({
    required this.message,
    required this.status,
  });

  factory RegisterAccountPostResponse.fromJson(Map<String, dynamic> json) =>
      RegisterAccountPostResponse(
        message: json["message"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "status": status,
      };
}
