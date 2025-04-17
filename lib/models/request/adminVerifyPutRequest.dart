// To parse this JSON data, do
//
//     final adminVerifyPutRequest = adminVerifyPutRequestFromJson(jsonString);

import 'dart:convert';

AdminVerifyPutRequest adminVerifyPutRequestFromJson(String str) =>
    AdminVerifyPutRequest.fromJson(json.decode(str));

String adminVerifyPutRequestToJson(AdminVerifyPutRequest data) =>
    json.encode(data.toJson());

class AdminVerifyPutRequest {
  String email;

  AdminVerifyPutRequest({
    required this.email,
  });

  factory AdminVerifyPutRequest.fromJson(Map<String, dynamic> json) =>
      AdminVerifyPutRequest(
        email: json["email"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
      };
}
