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

  IsVerifyUserPutRequest({
    required this.email,
  });

  factory IsVerifyUserPutRequest.fromJson(Map<String, dynamic> json) =>
      IsVerifyUserPutRequest(
        email: json["email"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
      };
}
