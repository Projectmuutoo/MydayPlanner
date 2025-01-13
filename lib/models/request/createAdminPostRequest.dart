// To parse this JSON data, do
//
//     final createAdminPostRequest = createAdminPostRequestFromJson(jsonString);

import 'dart:convert';

CreateAdminPostRequest createAdminPostRequestFromJson(String str) =>
    CreateAdminPostRequest.fromJson(json.decode(str));

String createAdminPostRequestToJson(CreateAdminPostRequest data) =>
    json.encode(data.toJson());

class CreateAdminPostRequest {
  String email;
  String hashedPassword;

  CreateAdminPostRequest({
    required this.email,
    required this.hashedPassword,
  });

  factory CreateAdminPostRequest.fromJson(Map<String, dynamic> json) =>
      CreateAdminPostRequest(
        email: json["email"],
        hashedPassword: json["hashed_password"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "hashed_password": hashedPassword,
      };
}
