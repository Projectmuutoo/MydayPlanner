import 'package:demomydayplanner/pages/login.dart';
import 'package:demomydayplanner/pages/pageAdmin/navBarAdmin.dart';
import 'package:demomydayplanner/pages/pageMember/navBar.dart';
import 'package:demomydayplanner/shared/appData.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class DelaychangePage extends StatefulWidget {
  const DelaychangePage({super.key});

  @override
  State<DelaychangePage> createState() => _DelaychangePageState();
}

class _DelaychangePageState extends State<DelaychangePage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    var active = context.read<Appdata>().keepUser.keepActiveUser;
    var role = context.read<Appdata>().keepUser.keepRoleUser;
    Future.delayed(const Duration(seconds: 2), () {
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
