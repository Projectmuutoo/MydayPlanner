// To parse this JSON data, do
//
//     final getBoardByIdUserGroupsPostResponse = getBoardByIdUserGroupsPostResponseFromJson(jsonString);

import 'dart:convert';

List<GetBoardByIdUserGroupsPostResponse>
    getBoardByIdUserGroupsPostResponseFromJson(String str) =>
        List<GetBoardByIdUserGroupsPostResponse>.from(json
            .decode(str)
            .map((x) => GetBoardByIdUserGroupsPostResponse.fromJson(x)));

String getBoardByIdUserGroupsPostResponseToJson(
        List<GetBoardByIdUserGroupsPostResponse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetBoardByIdUserGroupsPostResponse {
  int boardId;
  String boardName;
  DateTime createAt;
  int createBy;
  int boardUserId;
  int userId;
  DateTime addedAt;

  GetBoardByIdUserGroupsPostResponse({
    required this.boardId,
    required this.boardName,
    required this.createAt,
    required this.createBy,
    required this.boardUserId,
    required this.userId,
    required this.addedAt,
  });

  factory GetBoardByIdUserGroupsPostResponse.fromJson(
          Map<String, dynamic> json) =>
      GetBoardByIdUserGroupsPostResponse(
        boardId: json["board_id"],
        boardName: json["board_name"],
        createAt: DateTime.parse(json["create_at"]),
        createBy: json["create_by"],
        boardUserId: json["board_user_id"],
        userId: json["user_id"],
        addedAt: DateTime.parse(json["added_at"]),
      );

  Map<String, dynamic> toJson() => {
        "board_id": boardId,
        "board_name": boardName,
        "create_at": createAt.toIso8601String(),
        "create_by": createBy,
        "board_user_id": boardUserId,
        "user_id": userId,
        "added_at": addedAt.toIso8601String(),
      };
}
