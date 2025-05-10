// To parse this JSON data, do
//
//     final getUserByEmailPostRequest = getUserByEmailPostRequestFromJson(jsonString);

import 'dart:convert';

GetUserByEmailPostRequest getUserByEmailPostRequestFromJson(String str) =>
    GetUserByEmailPostRequest.fromJson(json.decode(str));

String getUserByEmailPostRequestToJson(GetUserByEmailPostRequest data) =>
    json.encode(data.toJson());

class GetUserByEmailPostRequest {
  String email;

  GetUserByEmailPostRequest({required this.email});

  factory GetUserByEmailPostRequest.fromJson(Map<String, dynamic> json) =>
      GetUserByEmailPostRequest(email: json["email"]);

  Map<String, dynamic> toJson() => {"email": email};
}
