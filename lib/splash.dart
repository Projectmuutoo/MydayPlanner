import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mydayplanner/pages/login.dart';
import 'package:mydayplanner/pages/pageAdmin/navBarAdmin.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final box = GetStorage();
  StreamSubscription<DocumentSnapshot>? _subscription;
  bool _isFromLogout = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    final arguments = Get.arguments;
    _isFromLogout = arguments?['fromLogout'] == true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _initializeApp() {
    final appData = Provider.of<Appdata>(context, listen: false);
    final userProfile = box.read('userProfile');

    if (_isFromLogout) {
      box.write('userLogin', {'keepActiveUser': '', 'keepRoleUser': ''});
    }

    if (userProfile == null || userProfile['email'] == null) {
      goToPage();
      return;
    }

    var existingUserLogin = box.read('userLogin');
    if (existingUserLogin != null &&
        existingUserLogin['keepActiveUser'] != null &&
        existingUserLogin['keepActiveUser'] != '' &&
        existingUserLogin['keepRoleUser'] != null &&
        existingUserLogin['keepRoleUser'] != '') {
      goToPage();
      return;
    }

    if (!_isFromLogout) {
      _startFirebaseListenerWithTimeout(appData, userProfile);
    } else {
      goToPage();
    }
  }

  void _startFirebaseListenerWithTimeout(Appdata appData, userProfile) {
    bool hasNavigated = false;

    Timer timeoutTimer = Timer(Duration(seconds: 5), () {
      if (!hasNavigated && mounted) {
        hasNavigated = true;
        _subscription?.cancel();
        goToPage();
      }
    });

    _subscription = FirebaseFirestore.instance
        .collection('usersLogin')
        .doc(userProfile['email'])
        .snapshots()
        .listen(
          (snapshot) {
            if (_isNavigating || hasNavigated) return;

            timeoutTimer.cancel();
            hasNavigated = true;

            if (snapshot.exists && ['0', '1'].contains(snapshot['active'])) {
              box.write('userLogin', {
                'keepActiveUser': snapshot['active'] == '0' ? '0' : '1',
                'keepRoleUser': snapshot['role'],
              });
            } else {
              Future.delayed(Duration.zero, () {
                if (mounted) {
                  goToPage();
                }
              });
            }
          },
          onError: (error) {
            timeoutTimer.cancel();
            if (!hasNavigated && mounted) {
              hasNavigated = true;
              goToPage();
            }
          },
        );
  }

  void goToPage() {
    if (_isNavigating) return;
    _isNavigating = true;

    var userLogin = box.read('userLogin');
    if (userLogin == null) {
      Get.offAll(() => LoginPage());
      return;
    }
    var keepActiveUser = userLogin['keepActiveUser'];
    var keepRoleUser = userLogin['keepRoleUser'];

    Future.delayed(Duration(seconds: 1), () {
      if (keepRoleUser == "admin" && keepActiveUser == '1') {
        Get.offAll(() => NavbaradminPage());
      } else if (keepRoleUser == "user" && keepActiveUser == '1') {
        Get.offAll(() => NavbarPage());
      } else {
        Get.offAll(() => LoginPage());
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
