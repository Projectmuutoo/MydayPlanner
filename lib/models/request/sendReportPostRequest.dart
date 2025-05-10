// To parse this JSON data, do
//
//     final sendReportPostRequest = sendReportPostRequestFromJson(jsonString);

import 'dart:convert';

SendReportPostRequest sendReportPostRequestFromJson(String str) =>
    SendReportPostRequest.fromJson(json.decode(str));

String sendReportPostRequestToJson(SendReportPostRequest data) =>
    json.encode(data.toJson());

class SendReportPostRequest {
  int category;
  String description;

  SendReportPostRequest({required this.category, required this.description});

  factory SendReportPostRequest.fromJson(Map<String, dynamic> json) =>
      SendReportPostRequest(
        category: json["category"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
    "category": category,
    "description": description,
  };
}
