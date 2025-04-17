// To parse this JSON data, do
//
//     final deleteUserDeleteRequest = deleteUserDeleteRequestFromJson(jsonString);

import 'dart:convert';

DeleteUserDeleteRequest deleteUserDeleteRequestFromJson(String str) =>
    DeleteUserDeleteRequest.fromJson(json.decode(str));

String deleteUserDeleteRequestToJson(DeleteUserDeleteRequest data) =>
    json.encode(data.toJson());

class DeleteUserDeleteRequest {
  String email;

  DeleteUserDeleteRequest({
    required this.email,
  });

  factory DeleteUserDeleteRequest.fromJson(Map<String, dynamic> json) =>
      DeleteUserDeleteRequest(
        email: json["email"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
      };
}
