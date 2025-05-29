import 'package:flutter/material.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';

class Appdata with ChangeNotifier {
  NavBarSelectedPage navBarPage = NavBarSelectedPage();
  KeepIdBoard idBoard = KeepIdBoard();
  KeepSubjectReportPageAdmin subject = KeepSubjectReportPageAdmin();
  ChangeMyProfileProvider changeMyProfileProvider = ChangeMyProfileProvider();
  KeepEmailToUserPageVerifyOTP keepEmailToUserPageVerifyOTP =
      KeepEmailToUserPageVerifyOTP();
  ShowMyBoards showMyBoards = ShowMyBoards();
  ShowMyTasks showMyTasks = ShowMyTasks();
}

//use page todayuser
class ShowMyTasks extends ChangeNotifier {
  List<Todaytask> _allTasks = [];

  List<Todaytask> get tasks => _allTasks;

  void setTasks(List<Todaytask> tasksData) {
    _allTasks = tasksData;
    notifyListeners();
  }

  void addTask(Todaytask task) {
    _allTasks.add(task);
    notifyListeners();
  }

  void removeTaskById(String value) {
    _allTasks.removeWhere((task) => task.taskId == value);
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

//use change page
class NavBarSelectedPage {
  int selectedPage = 0;
}

//use page homeuser
class KeepIdBoard {
  String idBoard = '';
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
