// To parse this JSON data, do
//
//     final editProfileUserPutRequest = editProfileUserPutRequestFromJson(jsonString);

import 'dart:convert';

EditProfileUserPutRequest editProfileUserPutRequestFromJson(String str) =>
    EditProfileUserPutRequest.fromJson(json.decode(str));

String editProfileUserPutRequestToJson(EditProfileUserPutRequest data) =>
    json.encode(data.toJson());

class EditProfileUserPutRequest {
  String name;
  String password;
  String profile;

  EditProfileUserPutRequest({
    required this.name,
    required this.password,
    required this.profile,
  });

  factory EditProfileUserPutRequest.fromJson(Map<String, dynamic> json) =>
      EditProfileUserPutRequest(
        name: json["name"],
        password: json["password"],
        profile: json["profile"],
      );

  Map<String, dynamic> toJson() => {
    "name": name,
    "password": password,
    "profile": profile,
  };
}
