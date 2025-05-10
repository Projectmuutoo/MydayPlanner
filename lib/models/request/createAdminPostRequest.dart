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
  String password;

  CreateAdminPostRequest({required this.email, required this.password});

  factory CreateAdminPostRequest.fromJson(Map<String, dynamic> json) =>
      CreateAdminPostRequest(email: json["email"], password: json["password"]);

  Map<String, dynamic> toJson() => {"email": email, "password": password};
}
