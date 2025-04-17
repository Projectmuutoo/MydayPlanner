// To parse this JSON data, do
//
//     final sendOtpPostRequest = sendOtpPostRequestFromJson(jsonString);

import 'dart:convert';

SendOtpPostRequest sendOtpPostRequestFromJson(String str) =>
    SendOtpPostRequest.fromJson(json.decode(str));

String sendOtpPostRequestToJson(SendOtpPostRequest data) =>
    json.encode(data.toJson());

class SendOtpPostRequest {
  String recipient;

  SendOtpPostRequest({
    required this.recipient,
  });

  factory SendOtpPostRequest.fromJson(Map<String, dynamic> json) =>
      SendOtpPostRequest(
        recipient: json["recipient"],
      );

  Map<String, dynamic> toJson() => {
        "recipient": recipient,
      };
}
