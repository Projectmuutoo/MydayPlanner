// To parse this JSON data, do
//
//     final boardCreateByIdUserGetResponse = boardCreateByIdUserGetResponseFromJson(jsonString);

import 'dart:convert';

List<BoardCreateByIdUserGetResponse> boardCreateByIdUserGetResponseFromJson(
        String str) =>
    List<BoardCreateByIdUserGetResponse>.from(json
        .decode(str)
        .map((x) => BoardCreateByIdUserGetResponse.fromJson(x)));

String boardCreateByIdUserGetResponseToJson(
        List<BoardCreateByIdUserGetResponse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class BoardCreateByIdUserGetResponse {
  int boardId;
  String boardName;
  DateTime createAt;
  int createBy;

  BoardCreateByIdUserGetResponse({
    required this.boardId,
    required this.boardName,
    required this.createAt,
    required this.createBy,
  });

  factory BoardCreateByIdUserGetResponse.fromJson(Map<String, dynamic> json) =>
      BoardCreateByIdUserGetResponse(
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
