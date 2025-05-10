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
  String reference;
  String record;

  SendOtpPostRequest({
    required this.email,
    required this.reference,
    required this.record,
  });

  factory SendOtpPostRequest.fromJson(Map<String, dynamic> json) =>
      SendOtpPostRequest(
        email: json["email"],
        reference: json["reference"],
        record: json["record"],
      );

  Map<String, dynamic> toJson() => {
    "email": email,
    "reference": reference,
    "record": record,
  };
}
