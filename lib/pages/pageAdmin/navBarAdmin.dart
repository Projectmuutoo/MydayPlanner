import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/pages/pageAdmin/adminHome.dart';
import 'package:mydayplanner/pages/pageAdmin/report.dart';
import 'package:mydayplanner/pages/pageAdmin/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:mydayplanner/splash.dart';
import 'package:http/http.dart' as http;

mixin RealtimeUserStatusMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  final box = GetStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  void startRealtimeMonitoring() {
    final userProfile = box.read('userProfile');
    if (userProfile != null && userProfile['email'] != null) {
      _statusSubscription = FirebaseFirestore.instance
          .collection('usersLogin')
          .doc(userProfile['email'])
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && snapshot['active'] == '0') {
              Future.delayed(Duration.zero, () {
                if (mounted) {
                  Get.snackbar(
                    '⚠️ Warning',
                    'You have been blocked!',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red.shade600,
                    colorText: Colors.white,
                    duration: Duration(seconds: 3),
                  );
                  logout();
                  Get.offAll(
                    () => SplashPage(),
                    arguments: {'fromLogout': true},
                  );
                }
              });
            }
            if (snapshot['active'] == '1') {
              box.write('userLogin', {
                'keepActiveUser': snapshot['active'] == '0' ? '0' : '1',
                'keepRoleUser': snapshot['role'],
              });
            }
          });
    }
  }

  void logout() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();

    var responseLogout = await http.post(
      Uri.parse("$url/auth/signout"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );

    if (responseLogout.statusCode == 403) {
      await AppDataLoadNewRefreshToken().loadNewRefreshToken();
      responseLogout = await http.post(
        Uri.parse("$url/auth/signout"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}

class NavbaradminPage extends StatefulWidget {
  const NavbaradminPage({super.key});

  @override
  State<NavbaradminPage> createState() => _NavbaradminPageState();
}

class _NavbaradminPageState extends State<NavbaradminPage>
    with RealtimeUserStatusMixin<NavbaradminPage> {
  int selectedIndex = 1;
  late final List<Widget> pageOptions;
  DateTime? createdAtDate;
  Timer? _timer;
  Timer? _timer2;
  int? expiresIn;

  @override
  void initState() {
    super.initState();
    pageOptions = [ReportPage(), AdminhomePage(), UserPage()];

    checkExpiresRefreshToken();
    checkInSystem();
    startRealtimeMonitoring();
  }

  void checkExpiresRefreshToken() async {
    final userProfile = box.read('userProfile');
    if (userProfile == null) return;

    await FirebaseFirestore.instance
        .collection('refreshTokens')
        .doc(userProfile['userid'].toString())
        .get()
        .then((snapshot) {
          if (snapshot.exists) {
            var createdAt = snapshot['CreatedAt'];
            expiresIn = snapshot['ExpiresIn'];
            createdAtDate = DateTime.fromMillisecondsSinceEpoch(
              createdAt * 1000,
            );
          }
        });

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (createdAtDate == null) return;

      DateTime expiryDate = createdAtDate!.add(Duration(seconds: expiresIn!));
      DateTime now = DateTime.now();

      if (now.isAfter(expiryDate)) {
        //1. หยุด Timer
        _timer?.cancel();

        Get.defaultDialog(
          title: '',
          titlePadding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          barrierDismissible: false,
          contentPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.02,
          ),
          content: WillPopScope(
            onWillPop: () async => false,
            child: Column(
              children: [
                Image.asset(
                  "assets/images/aleart/warning.png",
                  height: MediaQuery.of(context).size.height * 0.1,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Text(
                  'Warning!!',
                  style: TextStyle(
                    fontSize: Get.textTheme.headlineSmall!.fontSize,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF007AFF),
                  ),
                ),
                Text(
                  'The system has expired. Please log in again.',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleMedium!.fontSize,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final currentUserProfile = box.read('userProfile');
                if (currentUserProfile != null && currentUserProfile is Map) {
                  await FirebaseFirestore.instance
                      .collection('usersLogin')
                      .doc(currentUserProfile['email'])
                      .update({'deviceName': FieldValue.delete()});
                }
                await box.remove('userProfile');
                await box.remove('userLogin');
                await googleSignIn.signOut();
                await FirebaseAuth.instance.signOut();
                await storage.deleteAll();
                Get.offAll(() => SplashPage(), arguments: {'fromLogout': true});
              },
              style: ElevatedButton.styleFrom(
                fixedSize: Size(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height * 0.05,
                ),
                backgroundColor: Color(0xFF007AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
              ),
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: Get.textTheme.titleLarge!.fontSize,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      }
    });
  }

  Future<String> getDeviceName() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      final model = androidInfo.model;
      final id = androidInfo.id;
      return '${model}_$id';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      final model = iosInfo.modelName;
      final id = iosInfo.identifierForVendor!;
      return '${model}_$id';
    } else {
      return 'Unknown_${Random().nextInt(100000000)}';
    }
  }

  void checkInSystem() async {
    final userProfile = box.read('userProfile');
    final userLogin = box.read('userLogin');
    if (userProfile == null || userLogin == null) return;
    String deviceName = await getDeviceName();

    FirebaseFirestore.instance.collection('usersLogin').snapshots().listen((
      snapshot,
    ) {
      for (var i in snapshot.docChanges) {
        final data = i.doc;
        final change = i.type;
        if (change == DocumentChangeType.modified) {
          final serverdeviceName = data['deviceName'].toString();
          if (data['email'] == userProfile['email']) {
            if ((serverdeviceName != deviceName)) {
              if (!mounted) return;
              Get.defaultDialog(
                title: '',
                titlePadding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                barrierDismissible: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                content: WillPopScope(
                  onWillPop: () async => false,
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/aleart/warning.png",
                        height: MediaQuery.of(context).size.height * 0.1,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      Text(
                        'Warning!!',
                        style: TextStyle(
                          fontSize: Get.textTheme.titleLarge!.fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        'Detected login from another device.',
                        style: TextStyle(
                          fontSize: Get.textTheme.titleMedium!.fontSize,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () async {
                      await box.remove('userProfile');
                      await box.remove('userLogin');
                      await googleSignIn.initialize();
                      await googleSignIn.signOut();
                      await FirebaseAuth.instance.signOut();
                      await storage.deleteAll();
                      Get.offAll(
                        () => SplashPage(),
                        arguments: {'fromLogout': true},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(
                        MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height * 0.05,
                      ),
                      backgroundColor: Color(0xFF007AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer2?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ width สำหรับ horizontal
    // left/right
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M200-120v-680h360l16 80h224v400H520l-16-80H280v280h-80Zm300-440Zm86 160h134v-240H510l-16-80H280v240h290l16 80Z"/></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF979595),
            ),
            activeIcon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M200-120v-680h360l16 80h224v400H520l-16-80H280v280h-80Z"/></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF007AFF),
            ),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <path d="M3.99999 10L12 3L20 10L20 20H15V16C15 15.2044 14.6839 14.4413 14.1213 13.8787C13.5587 13.3161 12.7956 13 12 13C11.2043 13 10.4413 13.3161 9.87868 13.8787C9.31607 14.4413 9 15.2043 9 16V20H4L3.99999 10Z" stroke="#000000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path> </g></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF979595),
            ),
            activeIcon: SvgPicture.string(
              '<svg viewBox="-1.6 -1.6 19.20 19.20" fill="none" xmlns="http://www.w3.org/2000/svg"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <path d="M1 6V15H6V11C6 9.89543 6.89543 9 8 9C9.10457 9 10 9.89543 10 11V15H15V6L8 0L1 6Z" fill="#000000"></path> </g></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF007AFF),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF979595),
            ),
            activeIcon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M7.5 6.5C7.5 8.981 9.519 11 12 11s4.5-2.019 4.5-4.5S14.481 2 12 2 7.5 4.019 7.5 6.5zM20 21h1v-1c0-3.859-3.141-7-7-7h-4c-3.86 0-7 3.141-7 7v1h17z"></path></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF007AFF),
            ),
            label: 'User',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        selectedLabelStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.03,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.03,
        ),
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF007AFF),
        unselectedItemColor: Color(0xFF979595),
        type: BottomNavigationBarType.fixed,
      ),
      body: pageOptions[selectedIndex],
    );
  }
}
