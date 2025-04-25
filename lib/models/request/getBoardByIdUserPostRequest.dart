// To parse this JSON data, do
//
//     final getBoardByIdUserPostRequest = getBoardByIdUserPostRequestFromJson(jsonString);

import 'dart:convert';

GetBoardByIdUserPostRequest getBoardByIdUserPostRequestFromJson(String str) =>
    GetBoardByIdUserPostRequest.fromJson(json.decode(str));

String getBoardByIdUserPostRequestToJson(GetBoardByIdUserPostRequest data) =>
    json.encode(data.toJson());

class GetBoardByIdUserPostRequest {
  String userId;
  String isGroup;

  GetBoardByIdUserPostRequest({
    required this.userId,
    required this.isGroup,
  });

  factory GetBoardByIdUserPostRequest.fromJson(Map<String, dynamic> json) =>
      GetBoardByIdUserPostRequest(
        userId: json["UserId"],
        isGroup: json["is_group"],
      );

  Map<String, dynamic> toJson() => {
        "UserId": userId,
        "is_group": isGroup,
      };
}
