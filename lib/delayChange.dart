import 'package:mydayplanner/pages/login.dart';
import 'package:mydayplanner/pages/pageAdmin/navBarAdmin.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class DelaychangePage extends StatefulWidget {
  const DelaychangePage({super.key});

  @override
  State<DelaychangePage> createState() => _DelaychangePageState();
}

class _DelaychangePageState extends State<DelaychangePage> {
  @override
  void initState() {
    super.initState();
    var active = context.read<Appdata>().keepUser.keepActiveUser;
    var role = context.read<Appdata>().keepUser.keepRoleUser;
    Future.delayed(Duration(seconds: 1), () {
      if (active == '' && role == '') {
        Get.to(() => LoginPage());
      }
      if (active == '0') {
        Get.to(() => LoginPage());
      }
      if (role == "admin") {
        Get.to(() => NavbaradminPage());
      } else if (role == "user") {
        Get.to(() => NavbarPage());
      } else {
        Get.to(() => LoginPage());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFFF2F2F6),
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
