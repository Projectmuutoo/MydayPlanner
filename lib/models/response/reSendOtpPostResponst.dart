// To parse this JSON data, do
//
//     final reSendOtpPostResponst = reSendOtpPostResponstFromJson(jsonString);

import 'dart:convert';

ReSendOtpPostResponst reSendOtpPostResponstFromJson(String str) =>
    ReSendOtpPostResponst.fromJson(json.decode(str));

String reSendOtpPostResponstToJson(ReSendOtpPostResponst data) =>
    json.encode(data.toJson());

class ReSendOtpPostResponst {
  String message;
  String ref;

  ReSendOtpPostResponst({required this.message, required this.ref});

  factory ReSendOtpPostResponst.fromJson(Map<String, dynamic> json) =>
      ReSendOtpPostResponst(message: json["message"], ref: json["ref"]);

  Map<String, dynamic> toJson() => {"message": message, "ref": ref};
}
