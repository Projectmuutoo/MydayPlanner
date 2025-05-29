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
  List<Boardgroup> boardgroup;
  List<Todaytask> todaytasks;
  User user;

  AllDataUserGetResponst({
    required this.board,
    required this.boardgroup,
    required this.todaytasks,
    required this.user,
  });

  factory AllDataUserGetResponst.fromJson(Map<String, dynamic> json) =>
      AllDataUserGetResponst(
        board: List<Board>.from(json["board"].map((x) => Board.fromJson(x))),
        boardgroup: List<Boardgroup>.from(
          json["boardgroup"].map((x) => Boardgroup.fromJson(x)),
        ),
        todaytasks: List<Todaytask>.from(
          json["todaytasks"].map((x) => Todaytask.fromJson(x)),
        ),
        user: User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
    "board": List<dynamic>.from(board.map((x) => x.toJson())),
    "boardgroup": List<dynamic>.from(boardgroup.map((x) => x.toJson())),
    "todaytasks": List<dynamic>.from(todaytasks.map((x) => x.toJson())),
    "user": user.toJson(),
  };
}

class Board {
  int boardId;
  String boardName;
  String createdAt;
  int createdBy;
  List<BoardTask> tasks;

  Board({
    required this.boardId,
    required this.boardName,
    required this.createdAt,
    required this.createdBy,
    required this.tasks,
  });

  factory Board.fromJson(Map<String, dynamic> json) => Board(
    boardId: json["BoardID"],
    boardName: json["BoardName"],
    createdAt: json["CreatedAt"],
    createdBy: json["CreatedBy"],
    tasks: List<BoardTask>.from(
      json["tasks"].map((x) => BoardTask.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "BoardID": boardId,
    "BoardName": boardName,
    "CreatedAt": createdAt,
    "CreatedBy": createdBy,
    "tasks": List<dynamic>.from(tasks.map((x) => x.toJson())),
  };
}

class BoardTask {
  bool archived;
  List<TaskAttachment> attachments;
  List<TaskChecklist> checklists;
  String createdAt;
  int createdBy;
  String description;
  String priority;
  String status;
  int taskId;
  String taskName;

  BoardTask({
    required this.archived,
    required this.attachments,
    required this.checklists,
    required this.createdAt,
    required this.createdBy,
    required this.description,
    required this.priority,
    required this.status,
    required this.taskId,
    required this.taskName,
  });

  factory BoardTask.fromJson(Map<String, dynamic> json) => BoardTask(
    archived: json["Archived"],
    attachments: List<TaskAttachment>.from(
      json["Attachments"].map((x) => TaskAttachment.fromJson(x)),
    ),
    checklists: List<TaskChecklist>.from(
      json["Checklists"].map((x) => TaskChecklist.fromJson(x)),
    ),
    createdAt: json["CreatedAt"],
    createdBy: json["CreatedBy"],
    description: json["Description"],
    priority: json["Priority"],
    status: json["Status"],
    taskId: json["TaskID"],
    taskName: json["TaskName"],
  );

  Map<String, dynamic> toJson() => {
    "Archived": archived,
    "Attachments": List<dynamic>.from(attachments.map((x) => x.toJson())),
    "Checklists": List<dynamic>.from(checklists.map((x) => x.toJson())),
    "CreatedAt": createdAt,
    "CreatedBy": createdBy,
    "Description": description,
    "Priority": priority,
    "Status": status,
    "TaskID": taskId,
    "TaskName": taskName,
  };
}

class TaskAttachment {
  int attachmentId;
  String filename;
  String filepath;
  String filetype;
  int taskId;
  String uploadAt;

  TaskAttachment({
    required this.attachmentId,
    required this.filename,
    required this.filepath,
    required this.filetype,
    required this.taskId,
    required this.uploadAt,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) => TaskAttachment(
    attachmentId: json["AttachmentID"],
    filename: json["Filename"],
    filepath: json["Filepath"],
    filetype: json["Filetype"],
    taskId: json["TaskID"],
    uploadAt: json["UploadAt"],
  );

  Map<String, dynamic> toJson() => {
    "AttachmentID": attachmentId,
    "Filename": filename,
    "Filepath": filepath,
    "Filetype": filetype,
    "TaskID": taskId,
    "UploadAt": uploadAt,
  };
}

class TaskChecklist {
  int checklistId;
  String checklistName;
  String createdAt;
  int taskId;

  TaskChecklist({
    required this.checklistId,
    required this.checklistName,
    required this.createdAt,
    required this.taskId,
  });

  factory TaskChecklist.fromJson(Map<String, dynamic> json) => TaskChecklist(
    checklistId: json["ChecklistID"],
    checklistName: json["ChecklistName"],
    createdAt: json["CreatedAt"],
    taskId: json["TaskID"],
  );

  Map<String, dynamic> toJson() => {
    "ChecklistID": checklistId,
    "ChecklistName": checklistName,
    "CreatedAt": createdAt,
    "TaskID": taskId,
  };
}

class Boardgroup {
  int boardId;
  String boardName;
  String createdAt;
  int createdBy;
  List<BoardgroupTask> tasks;

  Boardgroup({
    required this.boardId,
    required this.boardName,
    required this.createdAt,
    required this.createdBy,
    required this.tasks,
  });

  factory Boardgroup.fromJson(Map<String, dynamic> json) => Boardgroup(
    boardId: json["BoardID"],
    boardName: json["BoardName"],
    createdAt: json["CreatedAt"],
    createdBy: json["CreatedBy"],
    tasks: List<BoardgroupTask>.from(
      json["tasks"].map((x) => BoardgroupTask.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "BoardID": boardId,
    "BoardName": boardName,
    "CreatedAt": createdAt,
    "CreatedBy": createdBy,
    "tasks": List<dynamic>.from(tasks.map((x) => x.toJson())),
  };
}

class BoardgroupTask {
  bool archived;
  List<Assigned> assigned;
  List<TaskAttachment> attachments;
  List<TaskChecklist> checklists;
  String createdAt;
  int createdBy;
  String description;
  String priority;
  String status;
  int taskId;
  String taskName;

  BoardgroupTask({
    required this.archived,
    required this.assigned,
    required this.attachments,
    required this.checklists,
    required this.createdAt,
    required this.createdBy,
    required this.description,
    required this.priority,
    required this.status,
    required this.taskId,
    required this.taskName,
  });

  factory BoardgroupTask.fromJson(Map<String, dynamic> json) => BoardgroupTask(
    archived: json["Archived"],
    assigned: List<Assigned>.from(
      json["Assigned"].map((x) => Assigned.fromJson(x)),
    ),
    attachments: List<TaskAttachment>.from(
      json["Attachments"].map((x) => TaskAttachment.fromJson(x)),
    ),
    checklists: List<TaskChecklist>.from(
      json["Checklists"].map((x) => TaskChecklist.fromJson(x)),
    ),
    createdAt: json["CreatedAt"],
    createdBy: json["CreatedBy"],
    description: json["Description"],
    priority: json["Priority"],
    status: json["Status"],
    taskId: json["TaskID"],
    taskName: json["TaskName"],
  );

  Map<String, dynamic> toJson() => {
    "Archived": archived,
    "Assigned": List<dynamic>.from(assigned.map((x) => x.toJson())),
    "Attachments": List<dynamic>.from(attachments.map((x) => x.toJson())),
    "Checklists": List<dynamic>.from(checklists.map((x) => x.toJson())),
    "CreatedAt": createdAt,
    "CreatedBy": createdBy,
    "Description": description,
    "Priority": priority,
    "Status": status,
    "TaskID": taskId,
    "TaskName": taskName,
  };
}

class Assigned {
  int assId;
  String assignedAt;
  int taskId;
  int userId;

  Assigned({
    required this.assId,
    required this.assignedAt,
    required this.taskId,
    required this.userId,
  });

  factory Assigned.fromJson(Map<String, dynamic> json) => Assigned(
    assId: json["assID"],
    assignedAt: json["assignedAt"],
    taskId: json["taskID"],
    userId: json["userID"],
  );

  Map<String, dynamic> toJson() => {
    "assID": assId,
    "assignedAt": assignedAt,
    "taskID": taskId,
    "userID": userId,
  };
}

class Todaytask {
  bool archived;
  List<TodaytaskAttachment> attachments;
  List<TodaytaskChecklist> checklists;
  String createdAt;
  int createdBy;
  String description;
  String priority;
  String status;
  String taskId;
  String taskName;
  String? updatedAt;

  Todaytask({
    required this.archived,
    required this.attachments,
    required this.checklists,
    required this.createdAt,
    required this.createdBy,
    required this.description,
    required this.priority,
    required this.status,
    required this.taskId,
    required this.taskName,
    this.updatedAt,
  });

  factory Todaytask.fromJson(Map<String, dynamic> json) => Todaytask(
    archived: json["Archived"],
    attachments: List<TodaytaskAttachment>.from(
      json["Attachments"].map((x) => TodaytaskAttachment.fromJson(x)),
    ),
    checklists: List<TodaytaskChecklist>.from(
      json["Checklists"].map((x) => TodaytaskChecklist.fromJson(x)),
    ),
    createdAt: json["CreatedAt"],
    createdBy: json["CreatedBy"],
    description: json["Description"],
    priority: json["Priority"],
    status: json["Status"],
    taskId: json["TaskID"],
    taskName: json["TaskName"],
    updatedAt: json["updated_at"],
  );

  Map<String, dynamic> toJson() => {
    "Archived": archived,
    "Attachments": List<dynamic>.from(attachments.map((x) => x.toJson())),
    "Checklists": List<dynamic>.from(checklists.map((x) => x.toJson())),
    "CreatedAt": createdAt,
    "CreatedBy": createdBy,
    "Description": description,
    "Priority": priority,
    "Status": status,
    "TaskID": taskId,
    "TaskName": taskName,
    "updated_at": updatedAt,
  };
}

class TodaytaskAttachment {
  String attachmentsId;
  String fileName;
  String filePath;
  String fileType;
  String uploadAt;

  TodaytaskAttachment({
    required this.attachmentsId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.uploadAt,
  });

  factory TodaytaskAttachment.fromJson(Map<String, dynamic> json) =>
      TodaytaskAttachment(
        attachmentsId: json["AttachmentsID"],
        fileName: json["FileName"],
        filePath: json["FilePath"],
        fileType: json["FileType"],
        uploadAt: json["UploadAt"],
      );

  Map<String, dynamic> toJson() => {
    "AttachmentsID": attachmentsId,
    "FileName": fileName,
    "FilePath": filePath,
    "FileType": fileType,
    "UploadAt": uploadAt,
  };
}

class TodaytaskChecklist {
  bool archived;
  String checklistId;
  String checklistName;
  String createdAt;

  TodaytaskChecklist({
    required this.archived,
    required this.checklistId,
    required this.checklistName,
    required this.createdAt,
  });

  factory TodaytaskChecklist.fromJson(Map<String, dynamic> json) =>
      TodaytaskChecklist(
        archived: json["Archived"],
        checklistId: json["ChecklistID"],
        checklistName: json["ChecklistName"],
        createdAt: json["CreatedAt"],
      );

  Map<String, dynamic> toJson() => {
    "Archived": archived,
    "ChecklistID": checklistId,
    "ChecklistName": checklistName,
    "CreatedAt": createdAt,
  };
}

class User {
  String createdAt;
  String email;
  String name;
  String profile;
  String role;
  int userId;

  User({
    required this.createdAt,
    required this.email,
    required this.name,
    required this.profile,
    required this.role,
    required this.userId,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    createdAt: json["CreatedAt"],
    email: json["Email"],
    name: json["Name"],
    profile: json["Profile"],
    role: json["Role"],
    userId: json["UserID"],
  );

  Map<String, dynamic> toJson() => {
    "CreatedAt": createdAt,
    "Email": email,
    "Name": name,
    "Profile": profile,
    "Role": role,
    "UserID": userId,
  };
}
