import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demomydayplanner/pages/login.dart';
import 'package:demomydayplanner/pages/pageAdmin/navBarAdmin.dart';
import 'package:demomydayplanner/pages/pageMember/navBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    Future.delayed(const Duration(seconds: 2), () {
      final box = GetStorage();
      final email = box.read('email');
      if (email != null && email.isNotEmpty) {
        var results = FirebaseFirestore.instance
            .collection('usersLogin')
            .doc(email)
            .snapshots();
        results.listen((snapshot) {
          if (snapshot['active'] == '0') {
            Get.to(() => LoginPage());
            return;
          }
          if (snapshot['login'] == 1) {
            snapshot['role'] == "admin"
                ? Get.to(() => NavbaradminPage())
                : Get.to(() => NavbarPage());
            return;
          } else {
            Get.to(() => LoginPage());
            return;
          }
        });
      } else {
        Get.to(() => LoginPage());
        return;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/LogoApp.png',
              width: 100,
              height: 100,
            ),
          ],
        ),
      ),
    );
  }
}
