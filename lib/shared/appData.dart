import 'package:flutter/material.dart';

class Appdata with ChangeNotifier {
  KeepRoleUser keepUser = KeepRoleUser();
  NavBarSelectedPage navBarPage = NavBarSelectedPage();
  KeepIdBoard idBoard = KeepIdBoard();
  KeepSubjectReportPageAdmin subject = KeepSubjectReportPageAdmin();
  ChangeMyProfileProvider changeMyProfileProvider = ChangeMyProfileProvider();
  KeepEmailToUserPageVerifyOTP keepEmailToUserPageVerifyOTP =
      KeepEmailToUserPageVerifyOTP();
}

//use page verify otp
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
