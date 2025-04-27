import 'package:flutter/material.dart';

class Appdata with ChangeNotifier {
  KeepRoleUser keepUser = KeepRoleUser();
  NavBarSelectedPage navBarPage = NavBarSelectedPage();
  KeepIdBoard idBoard = KeepIdBoard();
  BackPageSettingToHome keepPage = BackPageSettingToHome();
}

class KeepRoleUser {
  String keepRoleUser = '';
  String keepActiveUser = '';
}

class NavBarSelectedPage {
  int selectedPage = 0;
}

class KeepIdBoard {
  String idBoard = '';
}

class BackPageSettingToHome {
  bool keepPage = false;
  bool changeProfile = false;
  bool changeName = false;
}
