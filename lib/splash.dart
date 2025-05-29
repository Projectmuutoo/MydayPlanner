import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mydayplanner/pages/login.dart';
import 'package:mydayplanner/pages/pageAdmin/navBarAdmin.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    final box = GetStorage();
    box.write('userLogin', {'keepActiveUser': '', 'keepRoleUser': ''});
    final userProfile = box.read('userProfile');
    final email = userProfile?['email'];

    if (email != null && email.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('usersLogin')
          .doc(email)
          .snapshots()
          .listen((snapshot) {
            if (!snapshot.exists) {
              box.write('userLogin', {
                'keepActiveUser': '',
                'keepRoleUser': '',
              });
            } else if (snapshot['active'] == '0') {
              box.write('userLogin', {
                'keepActiveUser': '0',
                'keepRoleUser': '',
              });
              Get.snackbar(
                '⚠️ Warning',
                'You have been blocked!',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.red.shade600,
                colorText: Colors.white,
                duration: Duration(seconds: 3),
                forwardAnimationCurve: Curves.easeOutBack,
              );
            } else if (snapshot['login'] == 1) {
              box.write('userLogin', {'keepRoleUser': snapshot['role']});
            }
            goToPage();
          });
    } else {
      goToPage();
    }
  }

  void goToPage() {
    if (!mounted) return;
    final box = GetStorage();
    var keepActiveUser = box.read('userLogin')['keepActiveUser'];
    var keepRoleUser = box.read('userLogin')['keepRoleUser'];
    Future.delayed(Duration(seconds: 1), () {
      if (keepActiveUser == '' && keepRoleUser == '') {
        Get.offAll(() => LoginPage());
      }
      if (keepActiveUser == '0') {
        Get.offAll(() => LoginPage());
      }
      if (keepRoleUser == "admin") {
        Get.offAll(() => NavbaradminPage());
      } else if (keepRoleUser == "user") {
        Get.offAll(() => NavbarPage());
      } else {
        Get.offAll(() => LoginPage());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Color(0xFFF2F2F6)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/LogoApp.png', width: 100, height: 100),
          ],
        ),
      ),
    );
  }
}
