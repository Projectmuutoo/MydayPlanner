// To parse this JSON data, do
//
//     final getUserByEmailPostResponst = getUserByEmailPostResponstFromJson(jsonString);

import 'dart:convert';

GetUserByEmailPostResponst getUserByEmailPostResponstFromJson(String str) =>
    GetUserByEmailPostResponst.fromJson(json.decode(str));

String getUserByEmailPostResponstToJson(GetUserByEmailPostResponst data) =>
    json.encode(data.toJson());

class GetUserByEmailPostResponst {
  String email;
  int userId;

  GetUserByEmailPostResponst({required this.email, required this.userId});

  factory GetUserByEmailPostResponst.fromJson(Map<String, dynamic> json) =>
      GetUserByEmailPostResponst(email: json["Email"], userId: json["UserID"]);

  Map<String, dynamic> toJson() => {"Email": email, "UserID": userId};
}
