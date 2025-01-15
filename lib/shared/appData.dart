import 'package:flutter/material.dart';

class Appdata with ChangeNotifier {
  late NavBarSelectedPage navBarPage;
  late KeepIdBoard idBoard;
  late BackPageSettingToHome keepPage;
}

class NavBarSelectedPage {
  int selectedPage = 0;
}

class KeepIdBoard {
  String idBoard = '';
}

class BackPageSettingToHome {
  bool keepPage = false;
}
