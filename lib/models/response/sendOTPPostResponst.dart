// To parse this JSON data, do
//
//     final sendOtpPostResponst = sendOtpPostResponstFromJson(jsonString);

import 'dart:convert';

SendOtpPostResponst sendOtpPostResponstFromJson(String str) =>
    SendOtpPostResponst.fromJson(json.decode(str));

String sendOtpPostResponstToJson(SendOtpPostResponst data) =>
    json.encode(data.toJson());

class SendOtpPostResponst {
  String message;
  String otp;
  String ref;

  SendOtpPostResponst({
    required this.message,
    required this.otp,
    required this.ref,
  });

  factory SendOtpPostResponst.fromJson(Map<String, dynamic> json) =>
      SendOtpPostResponst(
        message: json["message"],
        otp: json["OTP"],
        ref: json["REF"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "OTP": otp,
        "REF": ref,
      };
}
