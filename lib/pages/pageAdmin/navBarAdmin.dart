import 'package:demomydayplanner/pages/pageAdmin/adminHome.dart';
import 'package:demomydayplanner/pages/pageAdmin/report.dart';
import 'package:demomydayplanner/pages/pageAdmin/user.dart';
import 'package:demomydayplanner/pages/pageMember/toDay.dart';
import 'package:demomydayplanner/shared/appData.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class NavbaradminPage extends StatefulWidget {
  const NavbaradminPage({super.key});

  @override
  State<NavbaradminPage> createState() => _NavbaradminPageState();
}

class _NavbaradminPageState extends State<NavbaradminPage> {
  late final List<Widget> pageOptions;

  @override
  void initState() {
    NavBarSelectedPage keep = NavBarSelectedPage();
    keep.selectedPage = 1;
    context.read<Appdata>().navBarPage = keep;
    pageOptions = [
      ReportPage(),
      AdminhomePage(),
      UserPage(),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ width สำหรับ horizontal
    // left/right
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: null,
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M200-120v-680h360l16 80h224v400H520l-16-80H280v280h-80Zm300-440Zm86 160h134v-240H510l-16-80H280v240h290l16 80Z"/></svg>',
              width: width * 0.08,
              height: width * 0.08,
              fit: BoxFit.cover,
              color: const Color(0xff787564),
            ),
            activeIcon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M200-120v-680h360l16 80h224v400H520l-16-80H280v280h-80Z"/></svg>',
              width: width * 0.08,
              height: width * 0.08,
              fit: BoxFit.cover,
              color: const Color(0xff3C3022),
            ),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <path d="M3.99999 10L12 3L20 10L20 20H15V16C15 15.2044 14.6839 14.4413 14.1213 13.8787C13.5587 13.3161 12.7956 13 12 13C11.2043 13 10.4413 13.3161 9.87868 13.8787C9.31607 14.4413 9 15.2043 9 16V20H4L3.99999 10Z" stroke="#000000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path> </g></svg>',
              width: width * 0.08,
              height: width * 0.08,
              fit: BoxFit.cover,
              color: const Color(0xff787564),
            ),
            activeIcon: SvgPicture.string(
              '<svg viewBox="-1.6 -1.6 19.20 19.20" fill="none" xmlns="http://www.w3.org/2000/svg"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <path d="M1 6V15H6V11C6 9.89543 6.89543 9 8 9C9.10457 9 10 9.89543 10 11V15H15V6L8 0L1 6Z" fill="#000000"></path> </g></svg>',
              width: width * 0.08,
              height: width * 0.08,
              fit: BoxFit.cover,
              color: const Color(0xff3C3022),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
              width: width * 0.08,
              height: width * 0.08,
              fit: BoxFit.cover,
              color: const Color(0xff787564),
            ),
            activeIcon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M7.5 6.5C7.5 8.981 9.519 11 12 11s4.5-2.019 4.5-4.5S14.481 2 12 2 7.5 4.019 7.5 6.5zM20 21h1v-1c0-3.859-3.141-7-7-7h-4c-3.86 0-7 3.141-7 7v1h17z"></path></svg>',
              width: width * 0.08,
              height: width * 0.08,
              fit: BoxFit.cover,
              color: const Color(0xff3C3022),
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
        // showSelectedLabels: false,
        // showUnselectedLabels: false,
        backgroundColor: const Color(0xFFF3F3F3),
        selectedItemColor: const Color(0xff3C3022),
        unselectedItemColor: const Color(0xff787564),
        type: BottomNavigationBarType.fixed,
      ),
      body: pageOptions[context.read<Appdata>().navBarPage.selectedPage],
    );
  }
}
