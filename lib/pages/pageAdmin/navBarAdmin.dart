import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mydayplanner/pages/pageAdmin/adminHome.dart';
import 'package:mydayplanner/pages/pageAdmin/report.dart';
import 'package:mydayplanner/pages/pageAdmin/user.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mydayplanner/splash.dart';
import 'package:provider/provider.dart';

class NavbaradminPage extends StatefulWidget {
  const NavbaradminPage({super.key});

  @override
  State<NavbaradminPage> createState() => _NavbaradminPageState();
}

class _NavbaradminPageState extends State<NavbaradminPage> {
  late final List<Widget> pageOptions;
  final storage = FlutterSecureStorage();
  DateTime? createdAtDate;
  Timer? _timer;
  StreamSubscription? _subscription;
  int? expiresIn;

  @override
  void initState() {
    super.initState();

    checkExpiresRefreshToken();

    NavBarSelectedPage keep = NavBarSelectedPage();
    keep.selectedPage = 1;
    context.read<Appdata>().navBarPage = keep;
    pageOptions = [ReportPage(), AdminhomePage(), UserPage()];
  }

  checkExpiresRefreshToken() {
    _subscription = FirebaseFirestore.instance
        .collection('refreshTokens')
        .doc(GetStorage().read('userProfile')['userid'].toString())
        .snapshots()
        .listen((snapshot) {
          int createdAt = snapshot['CreatedAt'];
          expiresIn = snapshot['ExpiresIn'];
          createdAtDate = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
        });

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (createdAtDate == null) return;

      DateTime expiryDate = createdAtDate!.add(Duration(seconds: expiresIn!));
      DateTime now = DateTime.now();

      if (now.isAfter(expiryDate)) {
        // 1. หยุด Stream
        _subscription?.cancel();
        // 2. หยุด Timer
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
                  'Waring!!',
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
                Get.back();
                await storage.deleteAll();
                GetStorage().remove('userProfile');
                Get.offAll(() => SplashPage());
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

  @override
  Widget build(BuildContext context) {
    // ใช้ width สำหรับ horizontal
    // left/right
    double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      child: Scaffold(
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
          currentIndex: context.read<Appdata>().navBarPage.selectedPage,
          onTap: (index) {
            setState(() {
              context.read<Appdata>().navBarPage.selectedPage = index;
            });
          },
          selectedLabelStyle: TextStyle(
            fontSize: Get.textTheme.titleSmall!.fontSize,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: Get.textTheme.titleSmall!.fontSize,
          ),
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF007AFF),
          unselectedItemColor: Color(0xFF979595),
          type: BottomNavigationBarType.fixed,
        ),
        // body: context.watch<Appdata>().navBarPage.selectedPage == 0
        //     ? pageOptions[0]
        //     : IndexedStack(
        //         index: context.watch<Appdata>().navBarPage.selectedPage,
        //         children: pageOptions,
        //       ),
        body: pageOptions[context.watch<Appdata>().navBarPage.selectedPage],
      ),
    );
  }
}
