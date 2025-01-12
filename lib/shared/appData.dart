import 'package:flutter/material.dart';

class Appdata with ChangeNotifier {
  late NavBarSelectedPage navBarPage;
  late KeepIdBoard idBoard;
}

class NavBarSelectedPage {
  int selectedPage = 0;
}

class KeepIdBoard {
  String idBoard = '';
}
