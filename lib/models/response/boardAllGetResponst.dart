// To parse this JSON data, do
//
//     final boardAllGetResponst = boardAllGetResponstFromJson(jsonString);

import 'dart:convert';

BoardAllGetResponst boardAllGetResponstFromJson(String str) =>
    BoardAllGetResponst.fromJson(json.decode(str));

String boardAllGetResponstToJson(BoardAllGetResponst data) =>
    json.encode(data.toJson());

class BoardAllGetResponst {
  List<Board> createdBoards;
  List<Board> memberBoards;

  BoardAllGetResponst({
    required this.createdBoards,
    required this.memberBoards,
  });

  factory BoardAllGetResponst.fromJson(Map<String, dynamic> json) =>
      BoardAllGetResponst(
        createdBoards: List<Board>.from(
          json["created_boards"].map((x) => Board.fromJson(x)),
        ),
        memberBoards: List<Board>.from(
          json["member_boards"].map((x) => Board.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "created_boards": List<dynamic>.from(createdBoards.map((x) => x.toJson())),
    "member_boards": List<dynamic>.from(memberBoards.map((x) => x.toJson())),
  };
}

class Board {
  int boardId;
  String boardName;
  String createdAt;
  int createdBy;
  Creator creator;

  Board({
    required this.boardId,
    required this.boardName,
    required this.createdAt,
    required this.createdBy,
    required this.creator,
  });

  factory Board.fromJson(Map<String, dynamic> json) => Board(
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
