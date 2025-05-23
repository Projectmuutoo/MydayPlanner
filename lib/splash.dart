import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mydayplanner/delayChange.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    KeepRoleUser keep = KeepRoleUser();
    keep.keepRoleUser = '';
    keep.keepActiveUser = '';
    context.read<Appdata>().keepUser = keep;
    final box = GetStorage();
    final userProfile = box.read('userProfile');
    final email = userProfile?['email'];
    if (email != null && email.isNotEmpty) {
      var results =
          FirebaseFirestore.instance
              .collection('usersLogin')
              .doc(email)
              .snapshots();
      results.listen((snapshot) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!snapshot.exists) {
            KeepRoleUser keep = KeepRoleUser();
            keep.keepActiveUser = '';
            keep.keepRoleUser = '';
            context.read<Appdata>().keepUser = keep;
            Get.to(() => DelaychangePage());
            return;
          }
          if (snapshot['active'] == '0') {
            KeepRoleUser keep = KeepRoleUser();
            keep.keepActiveUser = '0';
            context.read<Appdata>().keepUser = keep;
            Get.to(() => DelaychangePage());
            return;
          }
          if (snapshot['login'] == 1) {
            KeepRoleUser keep = KeepRoleUser();
            keep.keepRoleUser = snapshot['role'];
            context.read<Appdata>().keepUser = keep;
            Get.to(() => DelaychangePage());
            return;
          }
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.to(() => DelaychangePage());
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Color(0xFFF2F2F6)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [CircularProgressIndicator(color: Colors.white)],
        ),
      ),
    );
  }
}
