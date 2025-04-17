// To parse this JSON data, do
//
//     final resetPasswordPutRequest = resetPasswordPutRequestFromJson(jsonString);

import 'dart:convert';

ResetPasswordPutRequest resetPasswordPutRequestFromJson(String str) =>
    ResetPasswordPutRequest.fromJson(json.decode(str));

String resetPasswordPutRequestToJson(ResetPasswordPutRequest data) =>
    json.encode(data.toJson());

class ResetPasswordPutRequest {
  String email;
  String hashedPassword;

  ResetPasswordPutRequest({
    required this.email,
    required this.hashedPassword,
  });

  factory ResetPasswordPutRequest.fromJson(Map<String, dynamic> json) =>
      ResetPasswordPutRequest(
        email: json["email"],
        hashedPassword: json["hashed_password"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "hashed_password": hashedPassword,
      };
}
