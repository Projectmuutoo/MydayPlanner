import 'package:flutter/material.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';

class Appdata with ChangeNotifier {
  KeepIdBoard boardDatas = KeepIdBoard();
  KeepSubjectReportPageAdmin subject = KeepSubjectReportPageAdmin();
  ChangeMyProfileProvider changeMyProfileProvider = ChangeMyProfileProvider();
  KeepEmailToUserPageVerifyOTP keepEmailToUserPageVerifyOTP =
      KeepEmailToUserPageVerifyOTP();
  ShowMyBoards showMyBoards = ShowMyBoards();
  ShowMyTasks showMyTasks = ShowMyTasks();
  ShowDetailTask showDetailTask = ShowDetailTask();
}

class ShowDetailTask extends ChangeNotifier {
  Task? _currentTask;
  bool _isGroupTask = false;

  Task? get currentTask => _currentTask;
  bool get isGroupTask => _isGroupTask;

  // ===== Set Task =====
  void setCurrentTask(Task task, {bool isGroup = false}) {
    _currentTask = task;
    _isGroupTask = isGroup;
    notifyListeners();
  }

  // ===== Clear Data =====
  void clearData() {
    _currentTask = null;
    notifyListeners();
  }
}

//use page todayuser
class ShowMyTasks extends ChangeNotifier {
  List<Task> _allTasks = [];

  List<Task> get tasks => _allTasks;

  void setTasks(List<Task> tasksData) {
    _allTasks = tasksData;
    notifyListeners();
  }

  void addTask(Task task) {
    _allTasks.add(task);
    notifyListeners();
  }

  void removeTaskById(String value) {
    _allTasks.removeWhere((task) => task.taskId.toString() == value);
    notifyListeners();
  }
}

//use page homeuser
class ShowMyBoards extends ChangeNotifier {
  List<Board> _createdBoards = [];
  List<Boardgroup> _memberBoards = [];

  List<Board> get createdBoards => _createdBoards;
  List<Boardgroup> get memberBoards => _memberBoards;

  void setBoards(AllDataUserGetResponst boardData) {
    _createdBoards = boardData.board;
    _memberBoards = boardData.boardgroup;
    notifyListeners();
  }

  void addCreatedBoard(Board board) {
    _createdBoards.add(board);
    notifyListeners();
  }

  void addMemberBoard(Boardgroup board) {
    _memberBoards.add(board);
    notifyListeners();
  }

  void removeCreatedBoardById(int boardId) {
    _createdBoards.removeWhere((board) => board.boardId == boardId);
    notifyListeners();
  }

  void removeMemberBoardById(int boardId) {
    _memberBoards.removeWhere((board) => board.boardId == boardId);
    notifyListeners();
  }
}

class KeepEmailToUserPageVerifyOTP extends ChangeNotifier {
  String _email = '';
  String _password = '';
  String _ref = '';
  String _case = '';

  String get email => _email;
  String get password => _password;
  String get ref => _ref;
  String get cases => _case;

  void setEmail(String newEmail) {
    _email = newEmail;
    notifyListeners();
  }

  void setPassword(String newPassword) {
    _password = newPassword;
    notifyListeners();
  }

  void setRef(String newRef) {
    _ref = newRef;
    notifyListeners();
  }

  void setCase(String newCase) {
    _case = newCase;
    notifyListeners();
  }
}

//user page report admin
class KeepSubjectReportPageAdmin {
  String subjectReport = '';
}

//use page homeuser
class KeepIdBoard extends ChangeNotifier {
  String _idBoard = '';
  String _boardName = '';
  String _boardToken = '';

  String get idBoard => _idBoard;
  String get boardName => _boardName;
  String get boardToken => _boardToken;

  void setIdBoard(String newIdBoard) {
    _idBoard = newIdBoard;
    notifyListeners();
  }

  void setBoardName(String newBoardName) {
    _boardName = newBoardName;
    notifyListeners();
  }

  void setBoardToken(String newBoardToken) {
    _boardToken = newBoardToken;
    notifyListeners();
  }
}

//use page homeuser
class ChangeMyProfileProvider extends ChangeNotifier {
  String _name = '';
  String _profile = '';

  String get name => _name;
  String get profile => _profile;

  void setName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void setProfile(String newProfile) {
    _profile = newProfile;
    notifyListeners();
  }
}
