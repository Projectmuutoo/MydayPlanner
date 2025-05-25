// To parse this JSON data, do
//
//     final allDataUserGetResponst = allDataUserGetResponstFromJson(jsonString);

import 'dart:convert';

AllDataUserGetResponst allDataUserGetResponstFromJson(String str) =>
    AllDataUserGetResponst.fromJson(json.decode(str));

String allDataUserGetResponstToJson(AllDataUserGetResponst data) =>
    json.encode(data.toJson());

class AllDataUserGetResponst {
  List<Board> board;
  List<Board> boardgroup;
  User user;

  AllDataUserGetResponst({
    required this.board,
    required this.boardgroup,
    required this.user,
  });

  factory AllDataUserGetResponst.fromJson(Map<String, dynamic> json) =>
      AllDataUserGetResponst(
        board: List<Board>.from(json["board"].map((x) => Board.fromJson(x))),
        boardgroup: List<Board>.from(
          json["boardgroup"].map((x) => Board.fromJson(x)),
        ),
        user: User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
    "board": List<dynamic>.from(board.map((x) => x.toJson())),
    "boardgroup": List<dynamic>.from(boardgroup.map((x) => x.toJson())),
    "user": user.toJson(),
  };
}

class Board {
  int boardId;
  String boardName;
  String createdAt;
  int createdBy;

  Board({
    required this.boardId,
    required this.boardName,
    required this.createdAt,
    required this.createdBy,
  });

  factory Board.fromJson(Map<String, dynamic> json) => Board(
    boardId: json["BoardID"],
    boardName: json["BoardName"],
    createdAt: json["CreatedAt"],
    createdBy: json["CreatedBy"],
  );

  Map<String, dynamic> toJson() => {
    "BoardID": boardId,
    "BoardName": boardName,
    "CreatedAt": createdAt,
    "CreatedBy": createdBy,
  };
}

class User {
  int userId;
  String name;
  String email;
  String profile;
  String role;
  String createdAt;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.profile,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json["UserID"],
    name: json["Name"],
    email: json["Email"],
    profile: json["Profile"],
    role: json["Role"],
    createdAt: json["CreatedAt"],
  );

  Map<String, dynamic> toJson() => {
    "UserID": userId,
    "Name": name,
    "Email": email,
    "Profile": profile,
    "Role": role,
    "CreatedAt": createdAt,
  };
}
