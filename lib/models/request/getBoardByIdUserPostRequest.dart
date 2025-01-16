// To parse this JSON data, do
//
//     final getBoardByIdUserPostRequest = getBoardByIdUserPostRequestFromJson(jsonString);

import 'dart:convert';

GetBoardByIdUserPostRequest getBoardByIdUserPostRequestFromJson(String str) =>
    GetBoardByIdUserPostRequest.fromJson(json.decode(str));

String getBoardByIdUserPostRequestToJson(GetBoardByIdUserPostRequest data) =>
    json.encode(data.toJson());

class GetBoardByIdUserPostRequest {
  int userId;
  int group;

  GetBoardByIdUserPostRequest({
    required this.userId,
    required this.group,
  });

  factory GetBoardByIdUserPostRequest.fromJson(Map<String, dynamic> json) =>
      GetBoardByIdUserPostRequest(
        userId: json["userID"],
        group: json["group"],
      );

  Map<String, dynamic> toJson() => {
        "userID": userId,
        "group": group,
      };
}
