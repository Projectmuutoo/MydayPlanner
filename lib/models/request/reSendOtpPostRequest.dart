// To parse this JSON data, do
//
//     final reSendOtpPostRequest = reSendOtpPostRequestFromJson(jsonString);

import 'dart:convert';

ReSendOtpPostRequest reSendOtpPostRequestFromJson(String str) =>
    ReSendOtpPostRequest.fromJson(json.decode(str));

String reSendOtpPostRequestToJson(ReSendOtpPostRequest data) =>
    json.encode(data.toJson());

class ReSendOtpPostRequest {
  String email;
  String record;

  ReSendOtpPostRequest({required this.email, required this.record});

  factory ReSendOtpPostRequest.fromJson(Map<String, dynamic> json) =>
      ReSendOtpPostRequest(email: json["email"], record: json["record"]);

  Map<String, dynamic> toJson() => {"email": email, "record": record};
}
