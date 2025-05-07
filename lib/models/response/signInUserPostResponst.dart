// To parse this JSON data, do
//
//     final signInUserPostResponst = signInUserPostResponstFromJson(jsonString);

import 'dart:convert';

SignInUserPostResponst signInUserPostResponstFromJson(String str) =>
    SignInUserPostResponst.fromJson(json.decode(str));

String signInUserPostResponstToJson(SignInUserPostResponst data) =>
    json.encode(data.toJson());

class SignInUserPostResponst {
  String message;
  Token token;

  SignInUserPostResponst({required this.message, required this.token});

  factory SignInUserPostResponst.fromJson(Map<String, dynamic> json) =>
      SignInUserPostResponst(
        message: json["message"],
        token: Token.fromJson(json["token"]),
      );

  Map<String, dynamic> toJson() => {
    "message": message,
    "token": token.toJson(),
  };
}

class Token {
  String accessToken;
  String refreshToken;

  Token({required this.accessToken, required this.refreshToken});

  factory Token.fromJson(Map<String, dynamic> json) => Token(
    accessToken: json["accessToken"],
    refreshToken: json["refreshToken"],
  );

  Map<String, dynamic> toJson() => {
    "accessToken": accessToken,
    "refreshToken": refreshToken,
  };
}
