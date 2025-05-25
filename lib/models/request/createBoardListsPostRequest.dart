// To parse this JSON data, do
//
//     final createBoardListsPostRequest = createBoardListsPostRequestFromJson(jsonString);

import 'dart:convert';

CreateBoardListsPostRequest createBoardListsPostRequestFromJson(String str) =>
    CreateBoardListsPostRequest.fromJson(json.decode(str));

String createBoardListsPostRequestToJson(CreateBoardListsPostRequest data) =>
    json.encode(data.toJson());

class CreateBoardListsPostRequest {
  String boardName;
  int createdBy;
  String isGroup;

  CreateBoardListsPostRequest({
    required this.boardName,
    required this.createdBy,
    required this.isGroup,
  });

  factory CreateBoardListsPostRequest.fromJson(Map<String, dynamic> json) =>
      CreateBoardListsPostRequest(
        boardName: json["board_name"],
        createdBy: json["created_by"],
        isGroup: json["is_group"],
      );

  Map<String, dynamic> toJson() => {
    "board_name": boardName,
    "created_by": createdBy,
    "is_group": isGroup,
  };
}
