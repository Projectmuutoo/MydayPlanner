// To parse this JSON data, do
//
//     final googleLoginPostResponse = googleLoginPostResponseFromJson(jsonString);

import 'dart:convert';

GoogleLoginPostResponse googleLoginPostResponseFromJson(String str) =>
    GoogleLoginPostResponse.fromJson(json.decode(str));

String googleLoginPostResponseToJson(GoogleLoginPostResponse data) =>
    json.encode(data.toJson());

class GoogleLoginPostResponse {
  String message;
  String status;
  bool success;
  Token token;
  User user;

  GoogleLoginPostResponse({
    required this.message,
    required this.status,
    required this.success,
    required this.token,
    required this.user,
  });

  factory GoogleLoginPostResponse.fromJson(Map<String, dynamic> json) =>
      GoogleLoginPostResponse(
        message: json["message"],
        status: json["status"],
        success: json["success"],
        token: Token.fromJson(json["token"]),
        user: User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
    "message": message,
    "status": status,
    "success": success,
    "token": token.toJson(),
    "user": user.toJson(),
  };
}

class Token {
  String accessToken;
  int expiresIn;
  String refreshToken;

  Token({
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
  });

  factory Token.fromJson(Map<String, dynamic> json) => Token(
    accessToken: json["accessToken"],
    expiresIn: json["expiresIn"],
    refreshToken: json["refreshToken"],
  );

  Map<String, dynamic> toJson() => {
    "accessToken": accessToken,
    "expiresIn": expiresIn,
    "refreshToken": refreshToken,
  };
}

class User {
  String email;
  int id;
  String name;
  String role;

  User({
    required this.email,
    required this.id,
    required this.name,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    email: json["email"],
    id: json["id"],
    name: json["name"],
    role: json["role"],
  );

  Map<String, dynamic> toJson() => {
    "email": email,
    "id": id,
    "name": name,
    "role": role,
  };
}
