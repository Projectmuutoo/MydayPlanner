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
  String createdAt;
  int createdBy;
  Creator creator;

  GetBoardByIdUserListsPostResponse({
    required this.boardId,
    required this.boardName,
    required this.createdAt,
    required this.createdBy,
    required this.creator,
  });

  factory GetBoardByIdUserListsPostResponse.fromJson(
          Map<String, dynamic> json) =>
      GetBoardByIdUserListsPostResponse(
        boardId: json["BoardID"],
        boardName: json["BoardName"],
        createdAt: json["CreatedAt"],
        createdBy: json["CreatedBy"],
        creator: Creator.fromJson(json["Creator"]),
      );

  Map<String, dynamic> toJson() => {
        "BoardID": boardId,
        "BoardName": boardName,
        "CreatedAt": createdAt,
        "CreatedBy": createdBy,
        "Creator": creator.toJson(),
      };
}

class Creator {
  int userId;
  String name;
  String email;
  String hashedPassword;
  String profile;
  String role;
  String isVerify;
  String isActive;
  String createdAt;

  Creator({
    required this.userId,
    required this.name,
    required this.email,
    required this.hashedPassword,
    required this.profile,
    required this.role,
    required this.isVerify,
    required this.isActive,
    required this.createdAt,
  });

  factory Creator.fromJson(Map<String, dynamic> json) => Creator(
        userId: json["UserID"],
        name: json["Name"],
        email: json["Email"],
        hashedPassword: json["HashedPassword"],
        profile: json["Profile"],
        role: json["Role"],
        isVerify: json["IsVerify"],
        isActive: json["IsActive"],
        createdAt: json["CreatedAt"],
      );

  Map<String, dynamic> toJson() => {
        "UserID": userId,
        "Name": name,
        "Email": email,
        "HashedPassword": hashedPassword,
        "Profile": profile,
        "Role": role,
        "IsVerify": isVerify,
        "IsActive": isActive,
        "CreatedAt": createdAt,
      };
}
