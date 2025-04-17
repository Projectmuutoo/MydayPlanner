// To parse this JSON data, do
//
//     final editProfileUserPutRequest = editProfileUserPutRequestFromJson(jsonString);

import 'dart:convert';

EditProfileUserPutRequest editProfileUserPutRequestFromJson(String str) =>
    EditProfileUserPutRequest.fromJson(json.decode(str));

String editProfileUserPutRequestToJson(EditProfileUserPutRequest data) =>
    json.encode(data.toJson());

class EditProfileUserPutRequest {
  String email;
  ProfileData profileData;

  EditProfileUserPutRequest({
    required this.email,
    required this.profileData,
  });

  factory EditProfileUserPutRequest.fromJson(Map<String, dynamic> json) =>
      EditProfileUserPutRequest(
        email: json["email"],
        profileData: ProfileData.fromJson(json["profileData"]),
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "profileData": profileData.toJson(),
      };
}

class ProfileData {
  String name;
  String hashedPassword;
  String profile;

  ProfileData({
    required this.name,
    required this.hashedPassword,
    required this.profile,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
        name: json["name"],
        hashedPassword: json["hashed_password"],
        profile: json["profile"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "hashed_password": hashedPassword,
        "profile": profile,
      };
}
