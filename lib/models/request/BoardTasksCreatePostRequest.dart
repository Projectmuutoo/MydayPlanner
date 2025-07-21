// To parse this JSON data, do
//
//     final boardTasksCreatePostRequest = boardTasksCreatePostRequestFromJson(jsonString);

import 'dart:convert';

BoardTasksCreatePostRequest boardTasksCreatePostRequestFromJson(String str) =>
    BoardTasksCreatePostRequest.fromJson(json.decode(str));

String boardTasksCreatePostRequestToJson(BoardTasksCreatePostRequest data) =>
    json.encode(data.toJson());

class BoardTasksCreatePostRequest {
  int boardId;
  String taskName;
  String description;
  String priority;
  Reminder reminder;
  String status;

  BoardTasksCreatePostRequest({
    required this.boardId,
    required this.taskName,
    required this.description,
    required this.priority,
    required this.reminder,
    required this.status,
  });

  factory BoardTasksCreatePostRequest.fromJson(Map<String, dynamic> json) =>
      BoardTasksCreatePostRequest(
        boardId: json["board_id"],
        taskName: json["task_name"],
        description: json["description"],
        priority: json["priority"],
        reminder: Reminder.fromJson(json["reminder"]),
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
    "board_id": boardId,
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
