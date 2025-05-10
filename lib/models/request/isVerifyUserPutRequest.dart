// To parse this JSON data, do
//
//     final isVerifyUserPutRequest = isVerifyUserPutRequestFromJson(jsonString);

import 'dart:convert';

IsVerifyUserPutRequest isVerifyUserPutRequestFromJson(String str) =>
    IsVerifyUserPutRequest.fromJson(json.decode(str));

String isVerifyUserPutRequestToJson(IsVerifyUserPutRequest data) =>
    json.encode(data.toJson());

class IsVerifyUserPutRequest {
  String email;
  String ref;
  String otp;
  String record;

  IsVerifyUserPutRequest({
    required this.email,
    required this.ref,
    required this.otp,
    required this.record,
  });

  factory IsVerifyUserPutRequest.fromJson(Map<String, dynamic> json) =>
      IsVerifyUserPutRequest(
        email: json["email"],
        ref: json["ref"],
        otp: json["otp"],
        record: json["record"],
      );

  Map<String, dynamic> toJson() => {
    "email": email,
    "ref": ref,
    "otp": otp,
    "record": record,
  };
}
