import 'package:flutter/material.dart';

class Appdata with ChangeNotifier {
  KeepRoleUser keepUser = KeepRoleUser();
  NavBarSelectedPage navBarPage = NavBarSelectedPage();
  KeepIdBoard idBoard = KeepIdBoard();
  KeepSubjectReportPageAdmin subject = KeepSubjectReportPageAdmin();
  ChangeMyProfileProvider changeMyProfileProvider = ChangeMyProfileProvider();
}

//user page report admin
class KeepSubjectReportPageAdmin {
  String subjectReport = '';
}

//used to control users
class KeepRoleUser {
  String keepRoleUser = '';
  String keepActiveUser = '';
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
