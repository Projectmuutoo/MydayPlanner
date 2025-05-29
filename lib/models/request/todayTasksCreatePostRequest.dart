// To parse this JSON data, do
//
//     final todayTasksCreatePostRequest = todayTasksCreatePostRequestFromJson(jsonString);

import 'dart:convert';

TodayTasksCreatePostRequest todayTasksCreatePostRequestFromJson(String str) =>
    TodayTasksCreatePostRequest.fromJson(json.decode(str));

String todayTasksCreatePostRequestToJson(TodayTasksCreatePostRequest data) =>
    json.encode(data.toJson());

class TodayTasksCreatePostRequest {
  String email;
  String taskName;
  dynamic description;
  String status;
  String priority;

  TodayTasksCreatePostRequest({
    required this.email,
    required this.taskName,
    required this.description,
    required this.status,
    required this.priority,
  });

  factory TodayTasksCreatePostRequest.fromJson(Map<String, dynamic> json) =>
      TodayTasksCreatePostRequest(
        email: json["email"],
        taskName: json["task_name"],
        description: json["description"],
        status: json["status"],
        priority: json["priority"],
      );

  Map<String, dynamic> toJson() => {
    "email": email,
    "task_name": taskName,
    "description": description,
    "status": status,
    "priority": priority,
  };
}
