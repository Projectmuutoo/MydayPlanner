// To parse this JSON data, do
//
//     final googleLoginUserPostRequest = googleLoginUserPostRequestFromJson(jsonString);

import 'dart:convert';

GoogleLoginUserPostRequest googleLoginUserPostRequestFromJson(String str) =>
    GoogleLoginUserPostRequest.fromJson(json.decode(str));

String googleLoginUserPostRequestToJson(GoogleLoginUserPostRequest data) =>
    json.encode(data.toJson());

class GoogleLoginUserPostRequest {
  String email;
  String name;
  String profile;

  GoogleLoginUserPostRequest({
    required this.email,
    required this.name,
    required this.profile,
  });

  factory GoogleLoginUserPostRequest.fromJson(Map<String, dynamic> json) =>
      GoogleLoginUserPostRequest(
        email: json["email"],
        name: json["name"],
        profile: json["profile"],
      );

  Map<String, dynamic> toJson() => {
    "email": email,
    "name": name,
    "profile": profile,
  };
}
