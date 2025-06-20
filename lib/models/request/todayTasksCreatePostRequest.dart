// To parse this JSON data, do
//
//     final todayTasksCreatePostRequest = todayTasksCreatePostRequestFromJson(jsonString);

import 'dart:convert';

TodayTasksCreatePostRequest todayTasksCreatePostRequestFromJson(String str) =>
    TodayTasksCreatePostRequest.fromJson(json.decode(str));

String todayTasksCreatePostRequestToJson(TodayTasksCreatePostRequest data) =>
    json.encode(data.toJson());

class TodayTasksCreatePostRequest {
  String taskName;
  String description;
  String priority;
  Reminder reminder;
  String status;

  TodayTasksCreatePostRequest({
    required this.taskName,
    required this.description,
    required this.priority,
    required this.reminder,
    required this.status,
  });

  factory TodayTasksCreatePostRequest.fromJson(Map<String, dynamic> json) =>
      TodayTasksCreatePostRequest(
        taskName: json["task_name"],
        description: json["description"],
        priority: json["priority"],
        reminder: Reminder.fromJson(json["reminder"]),
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
    "task_name": taskName,
    "description": description,
    "priority": priority,
    "reminder": reminder.toJson(),
    "status": status,
  };
}

class Reminder {
  String dueDate;
  String recurringPattern;

  Reminder({required this.dueDate, required this.recurringPattern});

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    dueDate: json["due_date"],
    recurringPattern: json["recurring_pattern"],
  );

  Map<String, dynamic> toJson() => {
    "due_date": dueDate,
    "recurring_pattern": recurringPattern,
  };
}
