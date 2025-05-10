import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/createAdminPostRequest.dart';
import 'package:mydayplanner/models/request/getUserByEmailPostRequest.dart';
import 'package:mydayplanner/models/response/allUserGetResponse.dart';
import 'package:http/http.dart' as http;
import 'package:mydayplanner/pages/verifyOTP.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:mydayplanner/splash.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ManageuserPage extends StatefulWidget {
  const ManageuserPage({super.key});

  @override
  State<ManageuserPage> createState() => _ManageuserPageState();
}

class _ManageuserPageState extends State<ManageuserPage> {
  // 📦 Storage
  var box = GetStorage();

  // 📊 Integer Variables
  int itemCount = 1;
  final storage = FlutterSecureStorage();
  // 🔤 String Variables
  String textNotification = '';
  String warning = '';
  String selectedRole = 'All';
  int countToRequest = 1;
  // 📥 TextEditingController
  TextEditingController emailCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController searchCtl = TextEditingController();
  TextEditingController emailConfirmOtpCtl = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  FocusNode emailConfirmOtpFocusNode = FocusNode();
  // 🧠 Boolean Variables
  bool isTyping = false;
  bool isCheckedPassword = false;
  bool isDropdownOpen = false;
  bool isLoadings = true;
  bool showShimmer = true;
  bool displayEditAdmin = false;
  bool blockOTP = false;

  String? expiresAtEmail;
  Timer? _debounce;

  // 📈 List Variables
  late List<AllUserGetResponse> allUsers = [];
  List<AllUserGetResponse> filteredUsers = [];

  // 🔮 Future
  late Future<void> loadData;
  late String url;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    searchCtl.addListener(_onTextChanged);
    searchFocusNode.addListener(_onFocusChange);
    loadData = loadDataAsync();
  }

  Future<void> loadDataAsync() async {
    url = await loadAPIEndpoint();

    final responseAllUser = await http.get(
      Uri.parse("$url/user/ReadAllUser"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );
    if (responseAllUser.statusCode == 200) {
      List<AllUserGetResponse> response = allUserGetResponseFromJson(
        responseAllUser.body,
      );
      allUsers = response;
      filteredUsers =
          response
              .where((user) => user.userId != 1)
              .toList()
              .where((user) => user.isActive != '2')
              .toList();

      if (box.read('userProfile')['email'] ==
          'mydayplanner.noreply@gmail.com') {
        displayEditAdmin = true;
      }

      if (!mounted) return;
      setState(() {
        isLoadings = false;
      });

      Timer(Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() {
          showShimmer = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    return FutureBuilder(
      future: loadData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Future.delayed(Duration.zero, () {
            if (!mounted) return;
            setState(() {
              itemCount = filteredUsers.isEmpty ? 1 : filteredUsers.length;
            });
          });
        }

        return GestureDetector(
          onTap: () {
            if (searchFocusNode.hasFocus) {
              searchFocusNode.unfocus();
            }
          },
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: RefreshIndicator(
                  color: Colors.grey,
                  onRefresh: loadDataAsync,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                    child: Stack(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                if (searchFocusNode.hasFocus) {
                                  searchFocusNode.unfocus();
                                  Future.delayed(
                                    Duration(milliseconds: 100),
                                    () {
                                      Get.back();
                                    },
                                  );
                                } else {
                                  Get.back();
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.02,
                                  vertical: height * 0.01,
                                ),
                                child: SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M21 11H6.414l5.293-5.293-1.414-1.414L2.586 12l7.707 7.707 1.414-1.414L6.414 13H21z"></path></svg>',
                                  height: height * 0.03,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Text(
                              'Manage Users',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleLarge!.fontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: width * 0.1),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top:
                                searchCtl.text.isEmpty
                                    ? height * 0.18
                                    : height * 0.12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: Scrollbar(
                                  interactive: true,
                                  child: SingleChildScrollView(
                                    child: Stack(
                                      children: [
                                        Column(
                                          children:
                                              isLoadings || showShimmer
                                                  ? List.generate(
                                                    itemCount,
                                                    (index) => Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom: height * 0.01,
                                                        left: width * 0.01,
                                                        right: width * 0.01,
                                                      ),
                                                      child: Shimmer.fromColors(
                                                        baseColor: Color(
                                                          0xFFF7F7F7,
                                                        ),
                                                        highlightColor:
                                                            Colors.grey[300]!,
                                                        child: Container(
                                                          width: width,
                                                          height: height * 0.08,
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  : filteredUsers.map((user) {
                                                    return Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom: height * 0.01,
                                                        left: width * 0.01,
                                                        right: width * 0.01,
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            width: width,
                                                            height:
                                                                height * 0.08,
                                                            decoration: BoxDecoration(
                                                              color: ui.Color(
                                                                0xFFF2F2F6,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: Material(
                                                              color:
                                                                  Colors
                                                                      .transparent,
                                                              child: InkWell(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                                onTap:
                                                                    user.role ==
                                                                                'user' ||
                                                                            displayEditAdmin
                                                                        ? () {
                                                                          showModal(
                                                                            user.userId,
                                                                            user.profile,
                                                                            user.name,
                                                                            user.email,
                                                                            user.role,
                                                                            user.createdAt,
                                                                            user.isVerify,
                                                                            user.isActive,
                                                                          );
                                                                        }
                                                                        : null,
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            width *
                                                                            0.02,
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              ClipOval(
                                                                                child:
                                                                                    user.profile ==
                                                                                            'none-url'
                                                                                        ? Container(
                                                                                          width:
                                                                                              height *
                                                                                              0.05,
                                                                                          height:
                                                                                              height *
                                                                                              0.05,
                                                                                          decoration: BoxDecoration(
                                                                                            shape:
                                                                                                BoxShape.circle,
                                                                                          ),
                                                                                          child:
                                                                                              user.isActive ==
                                                                                                      '1'
                                                                                                  ? Stack(
                                                                                                    children: [
                                                                                                      Container(
                                                                                                        height:
                                                                                                            height *
                                                                                                            0.1,
                                                                                                        decoration: BoxDecoration(
                                                                                                          color: ui.Color(
                                                                                                            0xFF979595,
                                                                                                          ),
                                                                                                          shape:
                                                                                                              BoxShape.circle,
                                                                                                        ),
                                                                                                      ),
                                                                                                      Positioned(
                                                                                                        left:
                                                                                                            0,
                                                                                                        right:
                                                                                                            0,
                                                                                                        bottom:
                                                                                                            0,
                                                                                                        child: SvgPicture.string(
                                                                                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                                                                          height:
                                                                                                              height *
                                                                                                              0.03,
                                                                                                          fit:
                                                                                                              BoxFit.contain,
                                                                                                          color: ui.Color(
                                                                                                            0xFFF2F2F6,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ],
                                                                                                  )
                                                                                                  : Stack(
                                                                                                    children: [
                                                                                                      Container(
                                                                                                        height:
                                                                                                            height *
                                                                                                            0.1,
                                                                                                        decoration: BoxDecoration(
                                                                                                          color: ui.Color(
                                                                                                            0xFF979595,
                                                                                                          ),
                                                                                                          shape:
                                                                                                              BoxShape.circle,
                                                                                                        ),
                                                                                                      ),
                                                                                                      Positioned(
                                                                                                        left:
                                                                                                            0,
                                                                                                        right:
                                                                                                            0,
                                                                                                        bottom:
                                                                                                            0,
                                                                                                        child: SvgPicture.string(
                                                                                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                                                                          height:
                                                                                                              height *
                                                                                                              0.03,
                                                                                                          fit:
                                                                                                              BoxFit.contain,
                                                                                                          color: ui.Color(
                                                                                                            0xFFF2F2F6,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                      SvgPicture.string(
                                                                                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zM4 12c0-1.846.634-3.542 1.688-4.897l11.209 11.209A7.946 7.946 0 0 1 12 20c-4.411 0-8-3.589-8-8zm14.312 4.897L7.103 5.688A7.948 7.948 0 0 1 12 4c4.411 0 8 3.589 8 8a7.954 7.954 0 0 1-1.688 4.897z"></path></svg>',
                                                                                                        width:
                                                                                                            height *
                                                                                                            0.05,
                                                                                                        height:
                                                                                                            height *
                                                                                                            0.05,
                                                                                                        fit:
                                                                                                            BoxFit.cover,
                                                                                                        color:
                                                                                                            Colors.red,
                                                                                                      ),
                                                                                                    ],
                                                                                                  ),
                                                                                        )
                                                                                        : user.isActive ==
                                                                                            '1'
                                                                                        ? Image.network(
                                                                                          user.profile,
                                                                                          width:
                                                                                              height *
                                                                                              0.05,
                                                                                          height:
                                                                                              height *
                                                                                              0.05,
                                                                                          fit:
                                                                                              BoxFit.cover,
                                                                                        )
                                                                                        : Stack(
                                                                                          children: [
                                                                                            Image.network(
                                                                                              user.profile,
                                                                                              width:
                                                                                                  height *
                                                                                                  0.05,
                                                                                              height:
                                                                                                  height *
                                                                                                  0.05,
                                                                                              fit:
                                                                                                  BoxFit.cover,
                                                                                            ),
                                                                                            SvgPicture.string(
                                                                                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zM4 12c0-1.846.634-3.542 1.688-4.897l11.209 11.209A7.946 7.946 0 0 1 12 20c-4.411 0-8-3.589-8-8zm14.312 4.897L7.103 5.688A7.948 7.948 0 0 1 12 4c4.411 0 8 3.589 8 8a7.954 7.954 0 0 1-1.688 4.897z"></path></svg>',
                                                                                              width:
                                                                                                  height *
                                                                                                  0.05,
                                                                                              height:
                                                                                                  height *
                                                                                                  0.05,
                                                                                              fit:
                                                                                                  BoxFit.cover,
                                                                                              color:
                                                                                                  Colors.red,
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                              ),
                                                                              Column(
                                                                                crossAxisAlignment:
                                                                                    CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Row(
                                                                                    children: [
                                                                                      SizedBox(
                                                                                        width:
                                                                                            width *
                                                                                            0.01,
                                                                                      ),
                                                                                      SizedBox(
                                                                                        height:
                                                                                            height *
                                                                                            0.022,
                                                                                        width:
                                                                                            width *
                                                                                            0.6,
                                                                                        child:
                                                                                            user.email.length >
                                                                                                    25
                                                                                                ? Marquee(
                                                                                                  text:
                                                                                                      '${user.email} ${box.read('userProfile')['email'] == user.email ? '(You)' : ''}',
                                                                                                  style: TextStyle(
                                                                                                    fontSize:
                                                                                                        Get.textTheme.titleMedium!.fontSize,
                                                                                                    fontWeight:
                                                                                                        FontWeight.w500,
                                                                                                    color:
                                                                                                        box.read(
                                                                                                                  'userProfile',
                                                                                                                )['email'] ==
                                                                                                                user.email
                                                                                                            ? Colors.blue
                                                                                                            : null,
                                                                                                  ),
                                                                                                  scrollAxis:
                                                                                                      Axis.horizontal,
                                                                                                  blankSpace:
                                                                                                      20.0,
                                                                                                  velocity:
                                                                                                      30.0,
                                                                                                  pauseAfterRound: Duration(
                                                                                                    seconds:
                                                                                                        1,
                                                                                                  ),
                                                                                                  startPadding:
                                                                                                      0,
                                                                                                  accelerationDuration: Duration(
                                                                                                    seconds:
                                                                                                        1,
                                                                                                  ),
                                                                                                  accelerationCurve:
                                                                                                      Curves.linear,
                                                                                                  decelerationDuration: Duration(
                                                                                                    milliseconds:
                                                                                                        500,
                                                                                                  ),
                                                                                                  decelerationCurve:
                                                                                                      Curves.easeOut,
                                                                                                )
                                                                                                : Text(
                                                                                                  '${user.email} ${box.read('userProfile')['email'] == user.email ? '(You)' : ''}',
                                                                                                  style: TextStyle(
                                                                                                    fontSize:
                                                                                                        Get.textTheme.titleMedium!.fontSize,
                                                                                                    fontWeight:
                                                                                                        FontWeight.w500,
                                                                                                    color:
                                                                                                        box.read(
                                                                                                                  'userProfile',
                                                                                                                )['email'] ==
                                                                                                                user.email
                                                                                                            ? Colors.blue
                                                                                                            : null,
                                                                                                  ),
                                                                                                ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                  Row(
                                                                                    children: [
                                                                                      SizedBox(
                                                                                        width:
                                                                                            width *
                                                                                            0.01,
                                                                                      ),
                                                                                      Text(
                                                                                        'a ${user.role == 'admin' ? 'admin' : 'member'} on ${timeAgo(user.createdAt.toString())}',
                                                                                        style: TextStyle(
                                                                                          fontSize:
                                                                                              Get.textTheme.titleSmall!.fontSize,
                                                                                          fontWeight:
                                                                                              FontWeight.normal,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          user.role ==
                                                                                      'user' ||
                                                                                  displayEditAdmin
                                                                              ? Row(
                                                                                children: [
                                                                                  SvgPicture.string(
                                                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                                                                    height:
                                                                                        height *
                                                                                        0.03,
                                                                                    fit:
                                                                                        BoxFit.contain,
                                                                                  ),
                                                                                ],
                                                                              )
                                                                              : SizedBox.shrink(),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selectedRole == 'Admin')
                          Positioned(
                            bottom: height * 0.03,
                            right: width * 0.03,
                            child: GestureDetector(
                              onTap: createAdmin,
                              child: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm5 11h-4v4h-2v-4H7v-2h4V7h2v4h4v2z"></path></svg>',
                                height: height * 0.08,
                                fit: BoxFit.contain,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        Positioned(
                          top: height * 0.06,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              TextField(
                                controller: searchCtl,
                                focusNode: searchFocusNode,
                                keyboardType: TextInputType.text,
                                cursorColor: Colors.black,
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                ),
                                decoration: InputDecoration(
                                  hintText: isTyping ? '' : 'Search',
                                  hintStyle: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey,
                                  ),
                                  prefixIcon: IconButton(
                                    onPressed: null,
                                    icon: SvgPicture.string(
                                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10 18a7.952 7.952 0 0 0 4.897-1.688l4.396 4.396 1.414-1.414-4.396-4.396A7.952 7.952 0 0 0 18 10c0-4.411-3.589-8-8-8s-8 3.589-8 8 3.589 8 8 8zm0-14c3.309 0 6 2.691 6 6s-2.691 6-6 6-6-2.691-6-6 2.691-6 6-6z"></path></svg>',
                                      color: Colors.grey,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      searchCtl.clear();
                                      filteredUsers =
                                          allUsers
                                              .where((user) => user.userId != 1)
                                              .toList()
                                              .where(
                                                (user) => user.isActive != '2',
                                              )
                                              .toList();
                                    },
                                    icon: SvgPicture.string(
                                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M9.172 16.242 12 13.414l2.828 2.828 1.414-1.414L13.414 12l2.828-2.828-1.414-1.414L12 10.586 9.172 7.758 7.758 9.172 10.586 12l-2.828 2.828z"></path><path d="M12 22c5.514 0 10-4.486 10-10S17.514 2 12 2 2 6.486 2 12s4.486 10 10 10zm0-18c4.411 0 8 3.589 8 8s-3.589 8-8 8-8-3.589-8-8 3.589-8 8-8z"></path></svg>',
                                      color: Colors.grey,
                                    ),
                                  ),
                                  constraints: BoxConstraints(
                                    maxHeight: height * 0.05,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: width * 0.02,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: BorderSide(width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: BorderSide(width: 1),
                                  ),
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              if (searchCtl.text.isEmpty)
                                Container(
                                  width: width,
                                  height: height * 0.05,
                                  decoration: BoxDecoration(
                                    color: ui.Color(0xFFF2F2F6),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                      bottomLeft:
                                          isDropdownOpen
                                              ? Radius.circular(0)
                                              : Radius.circular(8),
                                      bottomRight:
                                          isDropdownOpen
                                              ? Radius.circular(0)
                                              : Radius.circular(8),
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap:
                                          !isLoadings || !showShimmer
                                              ? () {
                                                setState(() {
                                                  isDropdownOpen =
                                                      !isDropdownOpen;
                                                });
                                              }
                                              : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.02,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                SvgPicture.string(
                                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                  height: height * 0.03,
                                                  fit: BoxFit.contain,
                                                ),
                                                SizedBox(width: width * 0.02),
                                                Text(
                                                  '$selectedRole  (${filteredUsers.length})',
                                                  style: TextStyle(
                                                    fontSize:
                                                        Get
                                                            .textTheme
                                                            .titleLarge!
                                                            .fontSize,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            !isDropdownOpen
                                                ? SvgPicture.string(
                                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                                  height: height * 0.03,
                                                  fit: BoxFit.contain,
                                                )
                                                : SvgPicture.string(
                                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M16.293 9.293 12 13.586 7.707 9.293l-1.414 1.414L12 16.414l5.707-5.707z"></path></svg>',
                                                  height: height * 0.03,
                                                  fit: BoxFit.contain,
                                                ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (isDropdownOpen)
                                if (searchCtl.text.isEmpty)
                                  Container(
                                    width: width,
                                    decoration: BoxDecoration(
                                      color: ui.Color(0xFFF2F2F6),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.03,
                                        vertical: height * 0.01,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  selectedRole = 'All';
                                                  isDropdownOpen =
                                                      !isDropdownOpen;
                                                  filterUsersByRole('All');
                                                });
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  top: height * 0.005,
                                                  left: width * 0.03,
                                                  right: width * 0.03,
                                                  bottom: height * 0.005,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'All',
                                                      style: TextStyle(
                                                        fontSize:
                                                            Get
                                                                .textTheme
                                                                .titleLarge!
                                                                .fontSize,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${allUsers.where((user) => user.isActive != '2').toList().length - 1}',
                                                      style: TextStyle(
                                                        fontSize:
                                                            Get
                                                                .textTheme
                                                                .titleLarge!
                                                                .fontSize,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Divider(
                                            color: Colors.grey,
                                            thickness: 1,
                                            height: 3,
                                          ),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  selectedRole = 'Admin';
                                                  isDropdownOpen =
                                                      !isDropdownOpen;
                                                  filterUsersByRole('Admin');
                                                });
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  top: height * 0.005,
                                                  left: width * 0.03,
                                                  right: width * 0.03,
                                                  bottom: height * 0.005,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Admin',
                                                      style: TextStyle(
                                                        fontSize:
                                                            Get
                                                                .textTheme
                                                                .titleLarge!
                                                                .fontSize,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${allUsers.where((user) => user.role == 'admin').toList().where((user) => user.isActive != '2').toList().length - 1}',
                                                      style: TextStyle(
                                                        fontSize:
                                                            Get
                                                                .textTheme
                                                                .titleLarge!
                                                                .fontSize,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Divider(
                                            color: Colors.grey,
                                            thickness: 1,
                                            height: 3,
                                          ),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  selectedRole = 'User';
                                                  isDropdownOpen =
                                                      !isDropdownOpen;
                                                  filterUsersByRole('User');
                                                });
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  top: height * 0.005,
                                                  left: width * 0.03,
                                                  right: width * 0.03,
                                                  bottom: height * 0.005,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'User',
                                                      style: TextStyle(
                                                        fontSize:
                                                            Get
                                                                .textTheme
                                                                .titleLarge!
                                                                .fontSize,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${allUsers.where((user) => user.role == 'user').toList().where((user) => user.isActive != '2').toList().length}',
                                                      style: TextStyle(
                                                        fontSize:
                                                            Get
                                                                .textTheme
                                                                .titleLarge!
                                                                .fontSize,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showModal(
    int userid,
    String profile,
    String name,
    String email,
    String role,
    String createdAt,
    String isVerify,
    String isActive,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  right: width * 0.05,
                  left: width * 0.05,
                  top: height * 0.02,
                ),
                child: SizedBox(
                  height: height * 0.9,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {
                                  Get.back();
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.02,
                                    vertical: height * 0.01,
                                  ),
                                  child: SvgPicture.string(
                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M21 11H6.414l5.293-5.293-1.414-1.414L2.586 12l7.707 7.707 1.414-1.414L6.414 13H21z"></path></svg>',
                                    height: height * 0.03,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Text(
                                'Profile',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleLarge!.fontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: width * 0.1),
                            ],
                          ),
                          SizedBox(height: height * 0.01),
                          Container(
                            width: width,
                            height: height * 0.15,
                            decoration: BoxDecoration(
                              color: Color(0xFFF2F2F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipOval(
                                  child:
                                      profile == 'none-url'
                                          ? Container(
                                            height: height * 0.1,
                                            width: width * 0.22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                            ),
                                            child: Stack(
                                              children: [
                                                Container(
                                                  height: height * 0.1,
                                                  decoration: BoxDecoration(
                                                    color: ui.Color(0xFF979595),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                Positioned(
                                                  left: 0,
                                                  right: 0,
                                                  bottom: 0,
                                                  child: SvgPicture.string(
                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                    height: height * 0.07,
                                                    fit: BoxFit.contain,
                                                    color: ui.Color(0xFFF2F2F6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          : Stack(
                                            children: [
                                              Image.network(
                                                profile,
                                                height: height * 0.1,
                                                width: width * 0.22,
                                                fit: BoxFit.cover,
                                              ),
                                            ],
                                          ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          Container(
                            width: width,
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.02,
                              vertical: height * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFF2F2F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Name: ',
                                          style: TextStyle(
                                            fontSize:
                                                Get
                                                    .textTheme
                                                    .titleMedium!
                                                    .fontSize,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize:
                                                Get
                                                    .textTheme
                                                    .titleMedium!
                                                    .fontSize,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.01),
                                    Row(
                                      children: [
                                        Text(
                                          'Email: ',
                                          style: TextStyle(
                                            fontSize:
                                                Get
                                                    .textTheme
                                                    .titleMedium!
                                                    .fontSize,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            fontSize:
                                                Get
                                                    .textTheme
                                                    .titleMedium!
                                                    .fontSize,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          Container(
                            width: width,
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.02,
                              vertical: height * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFF2F2F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'a ${role == 'admin' ? 'admin' : 'member'} on ${timeAgo(createdAt)}',
                                          style: TextStyle(
                                            fontSize:
                                                Get
                                                    .textTheme
                                                    .titleMedium!
                                                    .fontSize,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.01),
                                    Row(
                                      children: [
                                        Text(
                                          isVerify == '1'
                                              ? 'Validated'
                                              : 'Invalidated',
                                          style: TextStyle(
                                            fontSize:
                                                Get
                                                    .textTheme
                                                    .titleMedium!
                                                    .fontSize,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                        SvgPicture.string(
                                          isVerify == '1'
                                              ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m10 15.586-3.293-3.293-1.414 1.414L10 18.414l9.707-9.707-1.414-1.414z"></path></svg>'
                                              : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m16.192 6.344-4.243 4.242-4.242-4.242-1.414 1.414L10.535 12l-4.242 4.242 1.414 1.414 4.242-4.242 4.243 4.242 1.414-1.414L13.364 12l4.242-4.242z"></path></svg>',
                                          height: height * 0.03,
                                          fit: BoxFit.contain,
                                          color:
                                              isVerify == '1'
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                disableUser(userid, email, isActive);
                                Get.back();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.02,
                                  vertical: height * 0.01,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.string(
                                      isActive == '1'
                                          ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zM4 12c0-1.846.634-3.542 1.688-4.897l11.209 11.209A7.946 7.946 0 0 1 12 20c-4.411 0-8-3.589-8-8zm14.312 4.897L7.103 5.688A7.948 7.948 0 0 1 12 4c4.411 0 8 3.589 8 8a7.954 7.954 0 0 1-1.688 4.897z"></path></svg>'
                                          : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 4c1.654 0 3 1.346 3 3h2c0-2.757-2.243-5-5-5S7 4.243 7 7v2H6c-1.103 0-2 .897-2 2v9c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2v-9c0-1.103-.897-2-2-2H9V7c0-1.654 1.346-3 3-3zm6.002 16H13v-2.278c.595-.347 1-.985 1-1.722 0-1.103-.897-2-2-2s-2 .897-2 2c0 .736.405 1.375 1 1.722V20H6v-9h12l.002 9z"></path></svg>',
                                      height: height * 0.025,
                                      fit: BoxFit.contain,
                                      color:
                                          isActive == '1'
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                    SizedBox(width: width * 0.02),
                                    Text(
                                      isActive == '1'
                                          ? 'Disable user'
                                          : 'Active',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isActive == '1'
                                                ? Colors.orange
                                                : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                deleteUser(userid, email);
                                Get.back();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.02,
                                  vertical: height * 0.01,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.string(
                                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M5 20a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8h2V6h-4V4a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v2H3v2h2zM9 4h6v2H9zM8 8h9v12H7V8z"></path><path d="M9 10h2v8H9zm4 0h2v8h-2z"></path></svg>',
                                      height: height * 0.025,
                                      fit: BoxFit.contain,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: width * 0.02),
                                    Text(
                                      'Delete user',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void deleteUser(int userid, String email) async {
    url = await loadAPIEndpoint();

    Get.defaultDialog(
      title: '',
      titlePadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      content: Column(
        children: [
          Image.asset(
            "assets/images/aleart/question.png",
            height: MediaQuery.of(context).size.height * 0.1,
            fit: BoxFit.contain,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Text(
            'Delete?',
            style: TextStyle(
              fontSize: Get.textTheme.headlineSmall!.fontSize,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
          Text(
            'You confirm to delete this user email',
            style: TextStyle(
              fontSize: Get.textTheme.titleMedium!.fontSize,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            email,
            style: TextStyle(
              fontSize: Get.textTheme.titleMedium!.fontSize,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            // แสดง Loading Dialog
            loadingDialog();
            var responseDelete = await http.put(
              Uri.parse("$url/admin/deleteaccount/$userid"),
              headers: {
                "Content-Type": "application/json; charset=utf-8",
                "Authorization": "Bearer ${box.read('accessToken')}",
              },
            );
            Get.back();
            if (responseDelete.statusCode == 403) {
              loadingDialog();
              await loadNewRefreshToken();
              responseDelete = await http.put(
                Uri.parse("$url/admin/deleteaccount/$userid"),
                headers: {
                  "Content-Type": "application/json; charset=utf-8",
                  "Authorization": "Bearer ${box.read('accessToken')}",
                },
              );
              Get.back();
            }

            if (responseDelete.statusCode == 200) {
              Get.back();
              loadDataAsync();
              if (!mounted) return;
              setState(() {
                selectedRole = 'All';
              });

              Get.defaultDialog(
                title: "",
                titlePadding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                content: Column(
                  children: [
                    Image.asset(
                      "assets/images/aleart/success.png",
                      height: MediaQuery.of(context).size.height * 0.1,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Text(
                      'Successfully!!',
                      style: TextStyle(
                        fontSize: Get.textTheme.headlineSmall!.fontSize,
                        fontWeight: FontWeight.w500,
                        color: ui.Color(0xFF007AFF),
                      ),
                    ),
                    Text(
                      'You delete email',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'successfully',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(
                        MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height * 0.05,
                      ),
                      backgroundColor: ui.Color(0xFF007AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    child: Text(
                      'Ok',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleLarge!.fontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              Get.back();
              loadDataAsync();
              if (!mounted) return;
              setState(() {
                selectedRole = 'All';
              });
            }
          },
          style: ElevatedButton.styleFrom(
            fixedSize: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.05,
            ),
            backgroundColor: ui.Color(0xFF007AFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
          ),
          child: Text(
            'Confirm',
            style: TextStyle(
              fontSize: Get.textTheme.titleLarge!.fontSize,
              color: Colors.white,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            fixedSize: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.05,
            ),
            backgroundColor: ui.Color(0xFFEF6056),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: Get.textTheme.titleLarge!.fontSize,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  double calculateTextWidth(String text, double fontSize) {
    final ui.ParagraphBuilder paragraphBuilder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textDirection: ui.TextDirection.ltr, // ใช้จาก dart:ui
            ),
          )
          ..pushStyle(
            ui.TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
          )
          ..addText(text);

    final ui.Paragraph paragraph =
        paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: double.infinity));

    return paragraph.longestLine;
  }

  void createAdmin() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height;

            return Padding(
              padding: EdgeInsets.only(
                left: width * 0.05,
                right: width * 0.05,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + height * 0.02,
              ),
              child: SizedBox(
                height: height * 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Add Admin',
                              style: TextStyle(
                                fontSize:
                                    Get.textTheme.headlineMedium!.fontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: width * 0.03),
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: emailCtl,
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: Colors.black,
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                isTyping ? '' : 'Enter your email address…',
                            hintStyle: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                            ),
                            prefixIcon: IconButton(
                              onPressed: null,
                              icon: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M20 4H4c-1.103 0-2 .897-2 2v12c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2zm0 2v.511l-8 6.223-8-6.222V6h16zM4 18V9.044l7.386 5.745a.994.994 0 0 0 1.228 0L20 9.044 20.002 18H4z"></path></svg>',
                                color: Colors.grey,
                              ),
                            ),
                            constraints: BoxConstraints(
                              maxHeight: height * 0.05,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: width * 0.02,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(width: 0.5),
                            ),
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: width * 0.03),
                              child: Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: passwordCtl,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: !isCheckedPassword,
                          cursorColor: Colors.black,
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                          ),
                          decoration: InputDecoration(
                            hintText: isTyping ? '' : 'Enter your password',
                            hintStyle: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                            ),
                            prefixIcon: IconButton(
                              onPressed: null,
                              icon: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C9.243 2 7 4.243 7 7v2H6c-1.103 0-2 .897-2 2v9c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2v-9c0-1.103-.897-2-2-2h-1V7c0-2.757-2.243-5-5-5zM9 7c0-1.654 1.346-3 3-3s3 1.346 3 3v2H9V7zm9.002 13H13v-2.278c.595-.347 1-.985 1-1.722 0-1.103-.897-2-2-2s-2 .897-2 2c0 .736.405 1.375 1 1.722V20H6v-9h12l.002 9z"></path></svg>',
                                color: Colors.grey,
                              ),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isCheckedPassword = !isCheckedPassword;
                                });
                              },
                              icon: Icon(
                                isCheckedPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                            ),
                            constraints: BoxConstraints(
                              maxHeight: height * 0.05,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: width * 0.02,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(width: 0.5),
                            ),
                          ),
                        ),
                        if (textNotification.isNotEmpty)
                          SizedBox(height: height * 0.02),
                        if (textNotification.isNotEmpty)
                          Text(
                            textNotification,
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.red, // สีสำหรับแจ้งเตือน
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (emailCtl.text.isEmpty) {
                              setState(() {
                                showNotification('Email address is required');
                              });
                              return;
                            }

                            if (!isValidEmail(emailCtl.text)) {
                              setState(() {
                                showNotification('Invalid email address');
                              });
                              return;
                            }

                            // Password validation
                            if (passwordCtl.text.isEmpty) {
                              setState(() {
                                showNotification('Please enter your password');
                              });
                              return;
                            } else if (!isValidPassword(passwordCtl.text)) {
                              setState(() {
                                showNotification(
                                  'Password must contain at least 8 digits\nor lowercase letters',
                                );
                              });
                              return;
                            }

                            setState(() {
                              showNotification('');
                            });

                            checkAndContinue();
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(width, height * 0.05),
                            backgroundColor: Colors.black,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: Get.textTheme.titleLarge!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      emailCtl.clear();
      passwordCtl.clear();
      textNotification = '';
      isCheckedPassword = false;
      isTyping = false;
    });
  }

  void checkAndContinue() async {
    url = await loadAPIEndpoint();

    loadingDialog();
    var responseGetuser = await http.post(
      Uri.parse("$url/email"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: getUserByEmailPostRequestToJson(
        GetUserByEmailPostRequest(email: emailCtl.text),
      ),
    );
    Get.back();

    if (responseGetuser.statusCode == 200) {
      showNotification('This email is already in use');
      return;
    } else {
      loadingDialog();
      var responseCreate = await http.post(
        Uri.parse("$url/admin/createadmin"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: createAdminPostRequestToJson(
          CreateAdminPostRequest(
            email: emailCtl.text.trim(),
            password: passwordCtl.text.trim(),
          ),
        ),
      );

      Get.back();
      if (responseCreate.statusCode == 201) {
        showModalConfirmEmail(emailCtl.text.trim());
      }
    }
  }

  void showNotification(String message) {
    setState(() {
      textNotification = message;
    });
  }

  bool isValidEmail(String email) {
    final RegExp emailRegExp = RegExp(
      r"^[a-zA-Z0-9._%+-]+@(?:gmail\.com|hotmail\.com|outlook\.com|yahoo\.com|icloud\.com|msu\.ac\.th)$",
    );
    return emailRegExp.hasMatch(email);
  }

  bool isValidPassword(String password) {
    if (password.length < 8) return false;

    // นับจำนวนตัวเลขและตัวพิมพ์เล็กรวมกัน
    int count = RegExp(r'[0-9a-z]').allMatches(password).length;

    return count >= 8;
  }

  void disableUser(int userid, String email, String isActive) async {
    url = await loadAPIEndpoint();

    Get.defaultDialog(
      title: "",
      titlePadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      content: Column(
        children: [
          Image.asset(
            "assets/images/aleart/question.png",
            height: MediaQuery.of(context).size.height * 0.1,
            fit: BoxFit.contain,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Text(
            isActive == '1' ? 'Disable?' : 'Undisable?',
            style: TextStyle(
              fontSize: Get.textTheme.headlineSmall!.fontSize,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
          Text(
            'You confirm to ${isActive == '1' ? 'disable' : 'undisable'} this user email',
            style: TextStyle(
              fontSize: Get.textTheme.titleMedium!.fontSize,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            email,
            style: TextStyle(
              fontSize: Get.textTheme.titleMedium!.fontSize,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            // แสดง Loading Dialog
            loadingDialog();
            var responseDisable = await http.put(
              Uri.parse("$url/admin/disableactive/$userid"),
              headers: {
                "Content-Type": "application/json; charset=utf-8",
                "Authorization": "Bearer ${box.read('accessToken')}",
              },
            );
            Get.back();
            if (responseDisable.statusCode == 403) {
              loadingDialog();
              await loadNewRefreshToken();
              responseDisable = await http.put(
                Uri.parse("$url/admin/disableactive/$userid"),
                headers: {
                  "Content-Type": "application/json; charset=utf-8",
                  "Authorization": "Bearer ${box.read('accessToken')}",
                },
              );
              Get.back();
            }

            if (responseDisable.statusCode == 200) {
              Get.back();
              searchCtl.clear();
              loadDataAsync();
              if (!mounted) return;
              setState(() {
                selectedRole = 'All';
              });

              Get.defaultDialog(
                title: "",
                titlePadding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                content: Column(
                  children: [
                    Image.asset(
                      "assets/images/aleart/success.png",
                      height: MediaQuery.of(context).size.height * 0.1,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Text(
                      'Successfully!!',
                      style: TextStyle(
                        fontSize: Get.textTheme.headlineSmall!.fontSize,
                        fontWeight: FontWeight.w500,
                        color: ui.Color(0xFF007AFF),
                      ),
                    ),
                    Text(
                      'You ${isActive == '1' ? 'disable' : 'undisable'} email',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'successfully',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(
                        MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height * 0.05,
                      ),
                      backgroundColor: ui.Color(0xFF007AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    child: Text(
                      'Ok',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleLarge!.fontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
              searchFocusNode.unfocus();
            } else {
              Get.back();
              searchCtl.clear();
              loadDataAsync();
              if (!mounted) return;
              setState(() {
                selectedRole = 'All';
              });
            }
          },
          style: ElevatedButton.styleFrom(
            fixedSize: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.05,
            ),
            backgroundColor:
                isActive == '1' ? ui.Color(0xFF007AFF) : Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
          ),
          child: Text(
            'Confirm',
            style: TextStyle(
              fontSize: Get.textTheme.titleLarge!.fontSize,
              color: Colors.white,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            fixedSize: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.05,
            ),
            backgroundColor: ui.Color(0xFFEF6056),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: Get.textTheme.titleLarge!.fontSize,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String timeAgo(String timestamp) {
    final DateTime postTimeUtc = DateTime.parse(timestamp);
    final DateTime postTimeLocal = postTimeUtc.toLocal();
    final DateTime nowLocal = DateTime.now();

    final Duration difference = nowLocal.difference(postTimeLocal);
    String formattedTime = DateFormat('HH:mm').format(postTimeLocal);

    if (difference.inSeconds < 10) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      bool isSameDay =
          postTimeLocal.year == nowLocal.year &&
          postTimeLocal.month == nowLocal.month &&
          postTimeLocal.day == nowLocal.day;

      if (isSameDay) {
        return '${difference.inHours}h ago';
      } else {
        return 'Yesterday, $formattedTime';
      }
    } else if (difference.inDays < 7) {
      DateTime yesterday = nowLocal.subtract(Duration(days: 1));
      bool isYesterday =
          postTimeLocal.year == yesterday.year &&
          postTimeLocal.month == yesterday.month &&
          postTimeLocal.day == yesterday.day;

      if (isYesterday) {
        return 'Yesterday, $formattedTime';
      } else {
        return '${difference.inDays}d ago, $formattedTime';
      }
    } else {
      return DateFormat('d MMM yyyy, HH:mm').format(postTimeLocal);
    }
  }

  void filterUsersByRole(String role) {
    setState(() {
      if (role == 'All') {
        filteredUsers =
            allUsers
                .where((user) => user.userId != 1)
                .toList()
                .where((user) => user.isActive != '2')
                .toList();
      } else {
        filteredUsers =
            allUsers
                .where((user) => user.role.toLowerCase() == role.toLowerCase())
                .toList()
                .where((user) => user.userId != 1)
                .toList()
                .where((user) => user.isActive != '2')
                .toList();
      }
    });
  }

  void loadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            content: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
    );
  }

  String formatTimestampTo12HourTimeWithSeconds(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('hh:mm:ss a').format(dateTime);
    return formattedTime;
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () async {
      if (!searchFocusNode.hasFocus) return;
      if (searchCtl.text.isNotEmpty) {
        filteredUsers =
            allUsers
                .where(
                  (user) =>
                      user.userId != 1 &&
                          user.isActive != '2' &&
                          user.name.toLowerCase().contains(
                            searchCtl.text.toLowerCase(),
                          ) ||
                      user.email.toLowerCase().contains(
                        searchCtl.text.toLowerCase(),
                      ),
                )
                .toList();
      } else {
        filteredUsers =
            allUsers
                .where((user) => user.userId != 1)
                .toList()
                .where((user) => user.isActive != '2')
                .toList();
      }
      setState(() {});
    });
  }

  void _onFocusChange() {
    if (!searchFocusNode.hasFocus) {
      // ถ้าเลิก focus ก็ยกเลิก timer
      _debounce?.cancel();
    }
  }

  showModalConfirmEmail(String email) {
    emailConfirmOtpCtl.text = email;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height;

            return GestureDetector(
              onTap: () {
                if (emailConfirmOtpFocusNode.hasFocus) {
                  emailConfirmOtpFocusNode.unfocus();
                }
              },
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: width * 0.05,
                    left: width * 0.05,
                    top: height * 0.05,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom +
                        height * 0.02,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  blockOTP = false;
                                  emailCtl.clear();
                                  passwordCtl.clear();
                                  Get.back();
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.01,
                                  ),
                                  child: Row(
                                    children: [
                                      SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12.707 17.293 8.414 13H18v-2H8.414l4.293-4.293-1.414-1.414L4.586 12l6.707 6.707z"></path></svg>',
                                        color: Colors.grey,
                                      ),
                                      Text(
                                        'back',
                                        style: TextStyle(
                                          fontSize:
                                              Get
                                                  .textTheme
                                                  .titleLarge!
                                                  .fontSize,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Image.asset(
                                "assets/images/LogoApp.png",
                                height: height * 0.07,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.01),
                          Row(
                            children: [
                              Text(
                                'Verify your email',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.headlineMedium!.fontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'We will send the otp code to the email you entered',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.01),
                          Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: width * 0.03),
                                child: Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            controller: emailConfirmOtpCtl,
                            focusNode: emailConfirmOtpFocusNode,
                            keyboardType: TextInputType.emailAddress,
                            cursorColor: Colors.black,
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  isTyping ? '' : 'Enter your email address…',
                              hintStyle: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey,
                              ),
                              prefixIcon: IconButton(
                                onPressed: null,
                                icon: SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M20 4H4c-1.103 0-2 .897-2 2v12c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2zm0 2v.511l-8 6.223-8-6.222V6h16zM4 18V9.044l7.386 5.745a.994.994 0 0 0 1.228 0L20 9.044 20.002 18H4z"></path></svg>',
                                  color: Colors.grey,
                                ),
                              ),
                              constraints: BoxConstraints(
                                maxHeight: height * 0.05,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: width * 0.02,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(width: 0.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(width: 0.5),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          if (blockOTP)
                            Text(
                              'Your email has been blocked because you requested otp overdue and you will be able to request otp again after $expiresAtEmail',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize,
                                fontWeight: FontWeight.normal,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (blockOTP) {
                                blockOTP = false;
                                Get.back();
                              } else {
                                url = await loadAPIEndpoint();
                                // แสดง Loading Dialog
                                loadingDialog();
                                var responseRef = await http.post(
                                  Uri.parse("$url/auth/IdentityOTP"),
                                  headers: {
                                    "Content-Type":
                                        "application/json; charset=utf-8",
                                  },
                                  body: jsonEncode({
                                    "email": emailConfirmOtpCtl.text,
                                  }),
                                );

                                Get.back();
                                if (responseRef.statusCode == 200) {
                                  Get.back();
                                  setState(() {
                                    showNotification('');
                                    blockOTP = false;
                                  });
                                  var sendOTPResponse = jsonDecode(
                                    responseRef.body,
                                  );

                                  //ส่ง email, otp, ref ไปยืนยันและ verify เมลหน้าต่อไป
                                  var appData = Provider.of<Appdata>(
                                    context,
                                    listen: false,
                                  );
                                  appData.keepEmailToUserPageVerifyOTP.setEmail(
                                    emailConfirmOtpCtl.text,
                                  );
                                  appData.keepEmailToUserPageVerifyOTP
                                      .setPassword(passwordCtl.text);
                                  appData.keepEmailToUserPageVerifyOTP.setRef(
                                    sendOTPResponse['ref'],
                                  );
                                  appData.keepEmailToUserPageVerifyOTP.setCase(
                                    'verifyEmail-Admin',
                                  );
                                  Get.to(() => VerifyotpPage());
                                } else {
                                  var result =
                                      await FirebaseFirestore.instance
                                          .collection('EmailBlocked')
                                          .doc(email)
                                          .collection('OTPRecords_verify')
                                          .doc(email)
                                          .get();
                                  var data = result.data();
                                  if (data != null) {
                                    setState(() {
                                      blockOTP = true;
                                      expiresAtEmail =
                                          formatTimestampTo12HourTimeWithSeconds(
                                            data['expiresAt'] as Timestamp,
                                          );
                                    });
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              fixedSize: Size(width, height * 0.04),
                              backgroundColor: Colors.black,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              blockOTP ? 'Back' : 'Request code',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> loadNewRefreshToken() async {
    url = await loadAPIEndpoint();
    var value = await storage.read(key: 'refreshToken');
    var loadtoketnew = await http.post(
      Uri.parse("$url/auth/newaccesstoken"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer $value",
      },
    );

    if (loadtoketnew.statusCode == 200) {
      var reponse = jsonDecode(loadtoketnew.body);
      box.write('accessToken', reponse['accessToken']);
    } else if (loadtoketnew.statusCode == 403) {
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
              box.remove('userProfile');
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
  }
}
