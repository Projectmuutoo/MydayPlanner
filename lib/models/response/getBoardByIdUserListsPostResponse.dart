// To parse this JSON data, do
//
//     final getBoardByIdUserListsPostResponse = getBoardByIdUserListsPostResponseFromJson(jsonString);

import 'dart:convert';

List<GetBoardByIdUserListsPostResponse>
    getBoardByIdUserListsPostResponseFromJson(String str) =>
        List<GetBoardByIdUserListsPostResponse>.from(json
            .decode(str)
            .map((x) => GetBoardByIdUserListsPostResponse.fromJson(x)));

String getBoardByIdUserListsPostResponseToJson(
        List<GetBoardByIdUserListsPostResponse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetBoardByIdUserListsPostResponse {
  int boardId;
  String boardName;
  DateTime createAt;
  int createBy;

  GetBoardByIdUserListsPostResponse({
    required this.boardId,
    required this.boardName,
    required this.createAt,
    required this.createBy,
  });

  factory GetBoardByIdUserListsPostResponse.fromJson(
          Map<String, dynamic> json) =>
      GetBoardByIdUserListsPostResponse(
        boardId: json["board_id"],
        boardName: json["board_name"],
        createAt: DateTime.parse(json["create_at"]),
        createBy: json["create_by"],
      );

  Map<String, dynamic> toJson() => {
        "board_id": boardId,
        "board_name": boardName,
        "create_at": createAt.toIso8601String(),
        "create_by": createBy,
      };
}
