import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:demomydayplanner/main.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen.fadeIn(
      backgroundColor: Colors.white,
      onInit: () {
        Future.delayed(Duration(seconds: 3), () {
          debugPrint("On Init");
        });
      },
      onEnd: () {
        debugPrint("On End");
      },
      childWidget: SizedBox(
        height: 200,
        width: 200,
        child: Image.asset("assets/images/LogoApp.png"),
      ),
      onAnimationEnd: () => debugPrint("On Fade In End"),
      nextScreen: const MainApp(),
    );
  }
}
