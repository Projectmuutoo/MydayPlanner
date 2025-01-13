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
  int createBy;
  int isGroup;

  CreateBoardListsPostRequest({
    required this.boardName,
    required this.createBy,
    required this.isGroup,
  });

  factory CreateBoardListsPostRequest.fromJson(Map<String, dynamic> json) =>
      CreateBoardListsPostRequest(
        boardName: json["board_name"],
        createBy: json["create_by"],
        isGroup: json["is_group"],
      );

  Map<String, dynamic> toJson() => {
        "board_name": boardName,
        "create_by": createBy,
        "is_group": isGroup,
      };
}
