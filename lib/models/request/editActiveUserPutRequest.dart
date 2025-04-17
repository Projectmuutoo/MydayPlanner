// To parse this JSON data, do
//
//     final editActiveUserPutRequest = editActiveUserPutRequestFromJson(jsonString);

import 'dart:convert';

EditActiveUserPutRequest editActiveUserPutRequestFromJson(String str) =>
    EditActiveUserPutRequest.fromJson(json.decode(str));

String editActiveUserPutRequestToJson(EditActiveUserPutRequest data) =>
    json.encode(data.toJson());

class EditActiveUserPutRequest {
  String email;

  EditActiveUserPutRequest({
    required this.email,
  });

  factory EditActiveUserPutRequest.fromJson(Map<String, dynamic> json) =>
      EditActiveUserPutRequest(
        email: json["email"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
      };
}
