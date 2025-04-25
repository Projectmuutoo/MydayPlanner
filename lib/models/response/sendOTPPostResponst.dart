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
  String ref;

  SendOtpPostResponst({
    required this.message,
    required this.ref,
  });

  factory SendOtpPostResponst.fromJson(Map<String, dynamic> json) =>
      SendOtpPostResponst(
        message: json["message"],
        ref: json["ref"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "ref": ref,
      };
}
