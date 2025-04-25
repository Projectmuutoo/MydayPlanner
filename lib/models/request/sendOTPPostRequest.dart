// To parse this JSON data, do
//
//     final sendOtpPostRequest = sendOtpPostRequestFromJson(jsonString);

import 'dart:convert';

SendOtpPostRequest sendOtpPostRequestFromJson(String str) =>
    SendOtpPostRequest.fromJson(json.decode(str));

String sendOtpPostRequestToJson(SendOtpPostRequest data) =>
    json.encode(data.toJson());

class SendOtpPostRequest {
  String email;

  SendOtpPostRequest({
    required this.email,
  });

  factory SendOtpPostRequest.fromJson(Map<String, dynamic> json) =>
      SendOtpPostRequest(
        email: json["email"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
      };
}
