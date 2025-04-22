import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:marquee/marquee.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/adminVerifyPutRequest.dart';
import 'package:mydayplanner/models/request/createAdminPostRequest.dart';
import 'package:mydayplanner/models/request/deleteUserDeleteRequest.dart';
import 'package:mydayplanner/models/request/editActiveUserPutRequest.dart';
import 'package:mydayplanner/models/request/sendOTPPostRequest.dart';
import 'package:mydayplanner/models/response/allUserGetResponse.dart';
import 'package:mydayplanner/models/response/sendOTPPostResponst.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // 📦 Storage
  var box = GetStorage();

// 📊 Integer Variables
  int itemCount = 1;

// 🔤 String Variables
  String textNotification = '';
  String warning = '';
  String selectedRole = 'All';

// 📥 TextEditingController
  TextEditingController emailCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController otpCtl = TextEditingController();

// 🧠 Boolean Variables
  bool isTyping = false;
  bool isCheckedPassword = false;
  bool isDropdownOpen = false;
  bool isDropdownOpenUser = false;
  bool isLoadings = true;
  bool showShimmer = true;
  bool displayEditAdmin = false;

// 📈 List Variables
  late List<User> allUsers = [];
  List<User> filteredUsers = [];

// 🧠 Map Variables
  Map<String, bool> isDropdownOpenUserMap = {};

// 🔮 Future
  late Future<void> loadData;

  @override
  void initState() {
    super.initState();
    loadData = loadDataAsync();
  }

  Future<void> loadDataAsync() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    var responseAllUser =
        await http.get(Uri.parse('$url/user/api/get_all_user'));
    if (responseAllUser.statusCode == 200) {
      AllUserGetResponse response =
          allUserGetResponseFromJson(responseAllUser.body);
      allUsers = response.users;
      filteredUsers = allUsers
          .where((user) => user.userId != 1)
          .toList()
          .where((user) => user.isActive != '2')
          .toList();

      if (box.read('email') == 'mydayplanner.noreply@gmail.com') {
        displayEditAdmin = true;
      }

      isLoadings = false;
      if (!mounted) return;
      setState(() {});

      Timer(Duration(seconds: 2), () {
        showShimmer = false;
        if (!mounted) return;
        setState(() {});
      });
    } else {
      log('message');
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
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) {
              itemCount = filteredUsers.isEmpty ? 1 : filteredUsers.length;
              if (!mounted) return;
              setState(() {});
            }
          });
        }

        return PopScope(
          canPop: false,
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: SizedBox(
                  height: height,
                  child: RefreshIndicator(
                    color: Colors.grey,
                    onRefresh: loadDataAsync,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: width * 0.05,
                        left: width * 0.05,
                      ),
                      child: Stack(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Users',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.displaySmall!.fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromRGBO(0, 122, 255, 1),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: height * 0.14),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Stack(
                                      children: [
                                        Column(
                                          children: isLoadings || showShimmer
                                              ? List.generate(
                                                  itemCount,
                                                  (index) => Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom: height * 0.01,
                                                      left: width * 0.01,
                                                      right: width * 0.01,
                                                    ),
                                                    child: Shimmer.fromColors(
                                                      baseColor:
                                                          Color(0xFFF7F7F7),
                                                      highlightColor:
                                                          Colors.grey[300]!,
                                                      child: Container(
                                                        width: width,
                                                        height: height * 0.08,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : filteredUsers.map(
                                                  (user) {
                                                    isDropdownOpenUserMap[
                                                        user.email] ??= false;
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
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Color
                                                                  .fromRGBO(
                                                                      242,
                                                                      242,
                                                                      246,
                                                                      1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                        8),
                                                                topRight: Radius
                                                                    .circular(
                                                                        8),
                                                                bottomLeft: isDropdownOpenUserMap[user
                                                                        .email]!
                                                                    ? Radius
                                                                        .circular(
                                                                            0)
                                                                    : Radius
                                                                        .circular(
                                                                            8),
                                                                bottomRight: isDropdownOpenUserMap[user
                                                                        .email]!
                                                                    ? Radius
                                                                        .circular(
                                                                            0)
                                                                    : Radius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                            ),
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              child: InkWell(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                onTap: () {
                                                                  isDropdownOpenUserMap[
                                                                          user.email] =
                                                                      !isDropdownOpenUserMap[
                                                                          user.email]!;
                                                                  setState(
                                                                      () {});
                                                                },
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Padding(
                                                                      padding:
                                                                          EdgeInsets
                                                                              .symmetric(
                                                                        horizontal:
                                                                            width *
                                                                                0.02,
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              ClipOval(
                                                                                child: user.profile == 'none-url'
                                                                                    ? Container(
                                                                                        width: height * 0.05,
                                                                                        height: height * 0.05,
                                                                                        decoration: const BoxDecoration(
                                                                                          shape: BoxShape.circle,
                                                                                        ),
                                                                                        child: Stack(
                                                                                          children: [
                                                                                            Container(
                                                                                              height: height * 0.1,
                                                                                              decoration: const BoxDecoration(
                                                                                                color: Color.fromRGBO(151, 149, 149, 1),
                                                                                                shape: BoxShape.circle,
                                                                                              ),
                                                                                            ),
                                                                                            Positioned(
                                                                                              left: 0,
                                                                                              right: 0,
                                                                                              bottom: 0,
                                                                                              child: SvgPicture.string(
                                                                                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                                                                height: height * 0.03,
                                                                                                fit: BoxFit.contain,
                                                                                                color: Color.fromRGBO(242, 242, 246, 1),
                                                                                              ),
                                                                                            )
                                                                                          ],
                                                                                        ),
                                                                                      )
                                                                                    : Image.network(
                                                                                        user.profile,
                                                                                        width: height * 0.05,
                                                                                        height: height * 0.05,
                                                                                        fit: BoxFit.cover,
                                                                                      ),
                                                                              ),
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Row(
                                                                                    children: [
                                                                                      SizedBox(width: width * 0.01),
                                                                                      SizedBox(
                                                                                        height: height * 0.02,
                                                                                        width: width * 0.6,
                                                                                        child: user.email.length > 25
                                                                                            ? Marquee(
                                                                                                text: '${user.email} ${box.read('email') == user.email ? '(You)' : ''}',
                                                                                                style: TextStyle(
                                                                                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                                                                                  fontWeight: FontWeight.w500,
                                                                                                  color: box.read('email') == user.email ? Colors.blue : null,
                                                                                                ),
                                                                                                scrollAxis: Axis.horizontal,
                                                                                                blankSpace: 20.0,
                                                                                                velocity: 30.0,
                                                                                                pauseAfterRound: Duration(seconds: 1),
                                                                                                startPadding: 0,
                                                                                                accelerationDuration: Duration(seconds: 1),
                                                                                                accelerationCurve: Curves.linear,
                                                                                                decelerationDuration: Duration(milliseconds: 500),
                                                                                                decelerationCurve: Curves.easeOut,
                                                                                              )
                                                                                            : Text(
                                                                                                '${user.email} ${box.read('email') == user.email ? '(You)' : ''}',
                                                                                                style: TextStyle(
                                                                                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                                                                                  fontWeight: FontWeight.w500,
                                                                                                  color: box.read('email') == user.email ? Colors.blue : null,
                                                                                                ),
                                                                                              ),
                                                                                      ),
                                                                                      user.isActive == '1'
                                                                                          ? SizedBox()
                                                                                          : SvgPicture.string(
                                                                                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zM4 12c0-1.846.634-3.542 1.688-4.897l11.209 11.209A7.946 7.946 0 0 1 12 20c-4.411 0-8-3.589-8-8zm14.312 4.897L7.103 5.688A7.948 7.948 0 0 1 12 4c4.411 0 8 3.589 8 8a7.954 7.954 0 0 1-1.688 4.897z"></path></svg>',
                                                                                              height: height * 0.03,
                                                                                              fit: BoxFit.contain,
                                                                                              color: Colors.red,
                                                                                            ),
                                                                                    ],
                                                                                  ),
                                                                                  Row(
                                                                                    children: [
                                                                                      SizedBox(width: width * 0.01),
                                                                                      Text(
                                                                                        'a ${user.role == 'admin' ? 'admin' : 'member'} on ${formatDate(user.createAt.toString())} - ${user.isVerify == 1 ? 'validated' : 'Invalidated'}',
                                                                                        style: TextStyle(
                                                                                          fontSize: Get.textTheme.titleSmall!.fontSize,
                                                                                          fontWeight: FontWeight.normal,
                                                                                        ),
                                                                                      ),
                                                                                      SvgPicture.string(
                                                                                        user.isVerify == 1 ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m10 15.586-3.293-3.293-1.414 1.414L10 18.414l9.707-9.707-1.414-1.414z"></path></svg>' : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m16.192 6.344-4.243 4.242-4.242-4.242-1.414 1.414L10.535 12l-4.242 4.242 1.414 1.414 4.242-4.242 4.243 4.242 1.414-1.414L13.364 12l4.242-4.242z"></path></svg>',
                                                                                        height: height * 0.03,
                                                                                        fit: BoxFit.contain,
                                                                                        color: user.isVerify == 1 ? Colors.green : Colors.red,
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          Row(
                                                                            children: [
                                                                              !isDropdownOpenUserMap[user.email]!
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
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          if (displayEditAdmin)
                                                            if (isDropdownOpenUserMap[
                                                                    user.email] =
                                                                isDropdownOpenUserMap[
                                                                    user.email]!)
                                                              Container(
                                                                width: width,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Color(
                                                                      0xFFF2F2F6),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .only(
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            8),
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            8),
                                                                  ),
                                                                ),
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .symmetric(
                                                                    horizontal:
                                                                        width *
                                                                            0.03,
                                                                    vertical:
                                                                        height *
                                                                            0.01,
                                                                  ),
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Material(
                                                                        color: Colors
                                                                            .white,
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                        child:
                                                                            InkWell(
                                                                          onTap:
                                                                              () {
                                                                            disableUser(user.email,
                                                                                user.isActive);
                                                                          },
                                                                          borderRadius:
                                                                              BorderRadius.circular(8),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.symmetric(
                                                                              horizontal: width * 0.02,
                                                                              vertical: height * 0.005,
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              children: [
                                                                                SvgPicture.string(
                                                                                  user.isActive == '1' ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zM4 12c0-1.846.634-3.542 1.688-4.897l11.209 11.209A7.946 7.946 0 0 1 12 20c-4.411 0-8-3.589-8-8zm14.312 4.897L7.103 5.688A7.948 7.948 0 0 1 12 4c4.411 0 8 3.589 8 8a7.954 7.954 0 0 1-1.688 4.897z"></path></svg>' : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 4c1.654 0 3 1.346 3 3h2c0-2.757-2.243-5-5-5S7 4.243 7 7v2H6c-1.103 0-2 .897-2 2v9c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2v-9c0-1.103-.897-2-2-2H9V7c0-1.654 1.346-3 3-3zm6.002 16H13v-2.278c.595-.347 1-.985 1-1.722 0-1.103-.897-2-2-2s-2 .897-2 2c0 .736.405 1.375 1 1.722V20H6v-9h12l.002 9z"></path></svg>',
                                                                                  height: height * 0.025,
                                                                                  fit: BoxFit.contain,
                                                                                  color: user.isActive == '1' ? Colors.orange : Colors.green,
                                                                                ),
                                                                                SizedBox(width: width * 0.02),
                                                                                Expanded(
                                                                                  child: Align(
                                                                                    alignment: Alignment.center,
                                                                                    child: Text(
                                                                                      user.isActive == '1' ? 'Disable user' : 'Active',
                                                                                      style: TextStyle(
                                                                                        fontSize: Get.textTheme.titleMedium!.fontSize,
                                                                                        fontWeight: FontWeight.normal,
                                                                                        color: user.isActive == '1' ? Colors.orange : Colors.green,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              height * 0.01),
                                                                      Material(
                                                                        color: Colors
                                                                            .white,
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                        child:
                                                                            InkWell(
                                                                          onTap:
                                                                              () {
                                                                            deleteUser(user.email);
                                                                          },
                                                                          borderRadius:
                                                                              BorderRadius.circular(8),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.symmetric(
                                                                              horizontal: width * 0.02,
                                                                              vertical: height * 0.005,
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              children: [
                                                                                SvgPicture.string(
                                                                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M5 20a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8h2V6h-4V4a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v2H3v2h2zM9 4h6v2H9zM8 8h9v12H7V8z"></path><path d="M9 10h2v8H9zm4 0h2v8h-2z"></path></svg>',
                                                                                  height: height * 0.025,
                                                                                  fit: BoxFit.contain,
                                                                                  color: Colors.red,
                                                                                ),
                                                                                Expanded(
                                                                                  child: Align(
                                                                                    alignment: Alignment.center,
                                                                                    child: Text(
                                                                                      'Delete user',
                                                                                      style: TextStyle(
                                                                                        fontSize: Get.textTheme.titleMedium!.fontSize,
                                                                                        fontWeight: FontWeight.normal,
                                                                                        color: Colors.red,
                                                                                      ),
                                                                                    ),
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
                                                          if (!displayEditAdmin)
                                                            if (isDropdownOpenUserMap[
                                                                    user.email] =
                                                                isDropdownOpenUserMap[user
                                                                        .email]! &&
                                                                    user.role ==
                                                                        'user')
                                                              Container(
                                                                width: width,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Color
                                                                      .fromRGBO(
                                                                          242,
                                                                          242,
                                                                          246,
                                                                          1),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .only(
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            8),
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            8),
                                                                  ),
                                                                ),
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .symmetric(
                                                                    horizontal:
                                                                        width *
                                                                            0.03,
                                                                    vertical:
                                                                        height *
                                                                            0.01,
                                                                  ),
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Material(
                                                                        color: Colors
                                                                            .white,
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                        child:
                                                                            InkWell(
                                                                          onTap: () => disableUser(
                                                                              user.email,
                                                                              user.isActive),
                                                                          borderRadius:
                                                                              BorderRadius.circular(8),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.symmetric(
                                                                              horizontal: width * 0.02,
                                                                              vertical: height * 0.005,
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              children: [
                                                                                SvgPicture.string(
                                                                                  user.isActive == '1' ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zM4 12c0-1.846.634-3.542 1.688-4.897l11.209 11.209A7.946 7.946 0 0 1 12 20c-4.411 0-8-3.589-8-8zm14.312 4.897L7.103 5.688A7.948 7.948 0 0 1 12 4c4.411 0 8 3.589 8 8a7.954 7.954 0 0 1-1.688 4.897z"></path></svg>' : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 4c1.654 0 3 1.346 3 3h2c0-2.757-2.243-5-5-5S7 4.243 7 7v2H6c-1.103 0-2 .897-2 2v9c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2v-9c0-1.103-.897-2-2-2H9V7c0-1.654 1.346-3 3-3zm6.002 16H13v-2.278c.595-.347 1-.985 1-1.722 0-1.103-.897-2-2-2s-2 .897-2 2c0 .736.405 1.375 1 1.722V20H6v-9h12l.002 9z"></path></svg>',
                                                                                  height: height * 0.025,
                                                                                  fit: BoxFit.contain,
                                                                                  color: user.isActive == '1' ? Colors.orange : Colors.green,
                                                                                ),
                                                                                SizedBox(width: width * 0.02),
                                                                                Expanded(
                                                                                  child: Align(
                                                                                    alignment: Alignment.center,
                                                                                    child: Text(
                                                                                      user.isActive == '1' ? 'Disable user' : 'Active',
                                                                                      style: TextStyle(
                                                                                        fontSize: Get.textTheme.titleMedium!.fontSize,
                                                                                        fontWeight: FontWeight.normal,
                                                                                        color: user.isActive == '1' ? Colors.orange : Colors.green,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              height * 0.01),
                                                                      Material(
                                                                        color: Colors
                                                                            .white,
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                        child:
                                                                            InkWell(
                                                                          onTap: () =>
                                                                              deleteUser(user.email),
                                                                          borderRadius:
                                                                              BorderRadius.circular(8),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.symmetric(
                                                                              horizontal: width * 0.02,
                                                                              vertical: height * 0.005,
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              children: [
                                                                                SvgPicture.string(
                                                                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M5 20a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8h2V6h-4V4a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v2H3v2h2zM9 4h6v2H9zM8 8h9v12H7V8z"></path><path d="M9 10h2v8H9zm4 0h2v8h-2z"></path></svg>',
                                                                                  height: height * 0.025,
                                                                                  fit: BoxFit.contain,
                                                                                  color: Colors.red,
                                                                                ),
                                                                                SizedBox(width: width * 0.02),
                                                                                Expanded(
                                                                                  child: Align(
                                                                                    alignment: Alignment.center,
                                                                                    child: Text(
                                                                                      'Delete user',
                                                                                      style: TextStyle(
                                                                                        fontSize: Get.textTheme.titleMedium!.fontSize,
                                                                                        fontWeight: FontWeight.normal,
                                                                                        color: Colors.red,
                                                                                      ),
                                                                                    ),
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
                                                    );
                                                  },
                                                ).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                            top: height * 0.08,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: [
                                Container(
                                  width: width,
                                  height: height * 0.05,
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(242, 242, 246, 1),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                      bottomLeft: isDropdownOpen
                                          ? Radius.circular(0)
                                          : Radius.circular(8),
                                      bottomRight: isDropdownOpen
                                          ? Radius.circular(0)
                                          : Radius.circular(8),
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        isDropdownOpen = !isDropdownOpen;
                                        setState(() {});
                                      },
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
                                                isLoadings || showShimmer
                                                    ? Shimmer.fromColors(
                                                        baseColor:
                                                            Color(0xFFF7F7F7),
                                                        highlightColor:
                                                            Colors.grey[300]!,
                                                        child: Container(
                                                          width:
                                                              calculateTextWidth(
                                                            '$selectedRole  (${filteredUsers.length})',
                                                            Get
                                                                .textTheme
                                                                .titleLarge!
                                                                .fontSize!,
                                                          ),
                                                          height: Get
                                                              .textTheme
                                                              .titleLarge!
                                                              .fontSize,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : Text(
                                                        '$selectedRole  (${filteredUsers.length})',
                                                        style: TextStyle(
                                                          fontSize: Get
                                                              .textTheme
                                                              .titleLarge!
                                                              .fontSize,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      )
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
                                  Container(
                                    width: width,
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(242, 242, 246, 1),
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
                                                selectedRole = 'All';
                                                isDropdownOpen =
                                                    !isDropdownOpen;
                                                filterUsersByRole('All');
                                                isDropdownOpenUserMap = {};
                                                setState(() {});
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
                                                        fontSize: Get
                                                            .textTheme
                                                            .titleLarge!
                                                            .fontSize,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                    isLoadings || showShimmer
                                                        ? Shimmer.fromColors(
                                                            baseColor: Color(
                                                                0xFFF7F7F7),
                                                            highlightColor:
                                                                Colors
                                                                    .grey[300]!,
                                                            child: Container(
                                                              width:
                                                                  calculateTextWidth(
                                                                '${allUsers.where((user) => user.isActive != '2').toList().length - 1}',
                                                                Get
                                                                    .textTheme
                                                                    .titleLarge!
                                                                    .fontSize!,
                                                              ),
                                                              height: Get
                                                                  .textTheme
                                                                  .titleLarge!
                                                                  .fontSize,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          )
                                                        : Text(
                                                            '${allUsers.where((user) => user.isActive != '2').toList().length - 1}',
                                                            style: TextStyle(
                                                              fontSize: Get
                                                                  .textTheme
                                                                  .titleLarge!
                                                                  .fontSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
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
                                                selectedRole = 'Admin';
                                                isDropdownOpen =
                                                    !isDropdownOpen;
                                                filterUsersByRole('Admin');
                                                isDropdownOpenUserMap = {};
                                                setState(() {});
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
                                                        fontSize: Get
                                                            .textTheme
                                                            .titleLarge!
                                                            .fontSize,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                    isLoadings || showShimmer
                                                        ? Shimmer.fromColors(
                                                            baseColor: Color(
                                                                0xFFF7F7F7),
                                                            highlightColor:
                                                                Colors
                                                                    .grey[300]!,
                                                            child: Container(
                                                              width:
                                                                  calculateTextWidth(
                                                                '${allUsers.where((user) => user.role == 'admin').toList().where((user) => user.isActive != '2').toList().length - 1}',
                                                                Get
                                                                    .textTheme
                                                                    .titleLarge!
                                                                    .fontSize!,
                                                              ),
                                                              height: Get
                                                                  .textTheme
                                                                  .titleLarge!
                                                                  .fontSize,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          )
                                                        : Text(
                                                            '${allUsers.where((user) => user.role == 'admin').toList().where((user) => user.isActive != '2').toList().length - 1}',
                                                            style: TextStyle(
                                                              fontSize: Get
                                                                  .textTheme
                                                                  .titleLarge!
                                                                  .fontSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
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
                                                selectedRole = 'User';
                                                isDropdownOpen =
                                                    !isDropdownOpen;
                                                filterUsersByRole('User');
                                                isDropdownOpenUserMap = {};
                                                setState(() {});
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
                                                        fontSize: Get
                                                            .textTheme
                                                            .titleLarge!
                                                            .fontSize,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                    isLoadings || showShimmer
                                                        ? Shimmer.fromColors(
                                                            baseColor: Color(
                                                                0xFFF7F7F7),
                                                            highlightColor:
                                                                Colors
                                                                    .grey[300]!,
                                                            child: Container(
                                                              width:
                                                                  calculateTextWidth(
                                                                '${allUsers.where((user) => user.role == 'user').toList().where((user) => user.isActive != '2').toList().length}',
                                                                Get
                                                                    .textTheme
                                                                    .titleLarge!
                                                                    .fontSize!,
                                                              ),
                                                              height: Get
                                                                  .textTheme
                                                                  .titleLarge!
                                                                  .fontSize,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          )
                                                        : Text(
                                                            '${allUsers.where((user) => user.role == 'user').toList().where((user) => user.isActive != '2').toList().length}',
                                                            style: TextStyle(
                                                              fontSize: Get
                                                                  .textTheme
                                                                  .titleLarge!
                                                                  .fontSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
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
          ),
        );
      },
    );
  }

  void deleteUser(String email) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

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
            var responseLogot = await http.delete(
              Uri.parse("$url/user/account"),
              headers: {"Content-Type": "application/json; charset=utf-8"},
              body: deleteUserDeleteRequestToJson(
                DeleteUserDeleteRequest(
                  email: email,
                ),
              ),
            );
            if (responseLogot.statusCode == 200) {
              Get.back();
              Get.back();
              loadDataAsync();
              selectedRole = 'All';
              if (!mounted) return;
              setState(() {});

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
                        color: Color.fromRGBO(0, 122, 255, 1),
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
                      backgroundColor: Color.fromRGBO(0, 122, 255, 1),
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
            }
          },
          style: ElevatedButton.styleFrom(
            fixedSize: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.05,
            ),
            backgroundColor: Color.fromRGBO(0, 122, 255, 1),
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
            backgroundColor: const Color.fromARGB(255, 239, 96, 86),
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
    final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textDirection: ui.TextDirection.ltr, // ใช้จาก dart:ui
      ),
    )
      ..pushStyle(ui.TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ))
      ..addText(text);

    final ui.Paragraph paragraph = paragraphBuilder.build()
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
                top: height * 0.02,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + height * 0.02,
              ),
              child: SizedBox(
                height: height * 0.35,
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
                              padding: EdgeInsets.only(
                                left: width * 0.03,
                              ),
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
                              borderSide: const BorderSide(
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: height * 0.01,
                        ),
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: width * 0.03,
                              ),
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
                                isCheckedPassword = !isCheckedPassword;
                                setState(() {});
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
                              borderSide: const BorderSide(
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: height * 0.01,
                        ),
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
                              showNotification('Email address is required');
                              setState(() {});
                              return;
                            }

                            if (!isValidEmail(emailCtl.text)) {
                              showNotification('Invalid email address');
                              setState(() {});
                              return;
                            }

                            // Password validation
                            if (passwordCtl.text.isEmpty) {
                              showNotification('Please enter your password');
                              setState(() {});
                              return;
                            } else if (!isValidPassword(passwordCtl.text)) {
                              showNotification(
                                  'Password must contain at least 8 digits\nor lowercase letters');
                              setState(() {});
                              return;
                            }

                            showNotification('');
                            setState(() {});

                            checkAndContinue;
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(
                              width,
                              height * 0.05,
                            ),
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
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    loadingDialog();
    var responseCreate = await http.post(
      Uri.parse("$url/admin/api/create_acc"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: createAdminPostRequestToJson(
        CreateAdminPostRequest(
          email: emailCtl.text,
          hashedPassword: passwordCtl.text,
        ),
      ),
    );

    if (responseCreate.statusCode == 201) {
      Get.back();

      loadingDialog();
      var responseOtp = await http.post(
        Uri.parse("$url/otp/api/otp"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: sendOtpPostRequestToJson(
          SendOtpPostRequest(
            recipient: emailCtl.text,
          ),
        ),
      );

      if (responseOtp.statusCode == 200) {
        Get.back();
        showNotification('');

        SendOtpPostResponst sendOTPResponse =
            sendOtpPostResponstFromJson(responseOtp.body);
        //ส่ง email, otp, ref ไปยืนยันและ verify เมลหน้าต่อไป
        verifyOTP(
          emailCtl.text,
          sendOTPResponse.otp,
          sendOTPResponse.ref,
        );
      }
    }
  }

  void showNotification(String message) {
    textNotification = message;
    setState(() {});
  }

  bool isValidEmail(String email) {
    final RegExp emailRegExp = RegExp(
        r"^[a-zA-Z0-9._%+-]+@(?:gmail\.com|hotmail\.com|outlook\.com|yahoo\.com|icloud\.com)$");
    return emailRegExp.hasMatch(email);
  }

  bool isValidPassword(String password) {
    if (password.length < 8) return false;

    // นับจำนวนตัวเลขและตัวพิมพ์เล็กรวมกัน
    int count = RegExp(r'[0-9a-z]').allMatches(password).length;

    return count >= 8;
  }

  void disableUser(String email, String isActive) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

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
            var responseLogot = await http.put(
              Uri.parse("$url/admin/api/edit_active"),
              headers: {"Content-Type": "application/json; charset=utf-8"},
              body: editActiveUserPutRequestToJson(
                EditActiveUserPutRequest(
                  email: email,
                ),
              ),
            );
            if (responseLogot.statusCode == 200) {
              Get.back();
              Get.back();
              loadDataAsync();
              selectedRole = 'All';
              if (!mounted) return;
              setState(() {});

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
                        color: Color.fromRGBO(0, 122, 255, 1),
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
                      backgroundColor: Color.fromRGBO(0, 122, 255, 1),
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
            }
          },
          style: ElevatedButton.styleFrom(
            fixedSize: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.05,
            ),
            backgroundColor:
                isActive == '1' ? Color.fromRGBO(0, 122, 255, 1) : Colors.green,
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
            backgroundColor: const Color.fromARGB(255, 239, 96, 86),
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

  String formatDate(String date) {
    // แปลงจาก String (ISO 8601) เป็น DateTime โดยไม่ระบุฟอร์แมต
    DateTime parsedDate = DateTime.parse(date);

    // แปลง DateTime เป็น String ในรูปแบบที่ต้องการ
    return DateFormat('dd/MM/yy').format(parsedDate);
  }

  void filterUsersByRole(String role) {
    if (role == 'All') {
      filteredUsers = allUsers
          .where((user) => user.userId != 1)
          .toList()
          .where((user) => user.isActive != '2')
          .toList();
    } else {
      filteredUsers = allUsers
          .where((user) => user.role.toLowerCase() == role.toLowerCase())
          .toList()
          .where((user) => user.userId != 1)
          .toList()
          .where((user) => user.isActive != '2')
          .toList();
    }
    setState(() {});
  }

  void loadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        content: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void verifyOTP(String email, String codeOTP, String ref) async {
    // สร้าง FocusNodes สำหรับทุกช่อง
    final focusNodes = List<FocusNode>.generate(6, (index) => FocusNode());
    final otpControllers = List<TextEditingController>.generate(
        6, (index) => TextEditingController());

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (BuildContext bc) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              double width = MediaQuery.of(context).size.width;
              double height = MediaQuery.of(context).size.height;

              return WillPopScope(
                onWillPop: () async => false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: height * 0.06,
                  ),
                  child: SizedBox(
                    height: height,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Verification Code',
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
                              'We have send the OTP code verification to',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              obfuscateEmail(email),
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: height * 0.02,
                        ),
                        Form(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) {
                                return SizedBox(
                                  height: height * 0.08,
                                  width: width * 0.14,
                                  child: TextFormField(
                                    focusNode: focusNodes[index],
                                    controller: otpControllers[index],
                                    cursorColor: Colors.grey,
                                    onChanged: (value) {
                                      if (value.length == 1) {
                                        if (index < 5) {
                                          focusNodes[index + 1]
                                              .requestFocus(); // โฟกัสไปยังช่องถัดไป
                                        } else {
                                          FocusScope.of(context)
                                              .unfocus(); // ปิดคีย์บอร์ด
                                          verifyEnteredOTP(
                                            otpControllers,
                                            codeOTP,
                                            email,
                                          ); // ตรวจสอบ OTP
                                        }
                                      } else if (value.isEmpty && index > 0) {
                                        focusNodes[index - 1]
                                            .requestFocus(); // กลับไปช่องก่อนหน้า
                                      }
                                    },
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(1),
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      focusColor: Colors.black,
                                      filled: true,
                                      fillColor: Colors.white, // สีพื้นหลัง
                                      contentPadding:
                                          EdgeInsets.all(8), // ระยะห่างภายใน
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            12), // มุมโค้ง
                                        borderSide: BorderSide(
                                          color: Colors.grey, // สีกรอบปกติ
                                          width: 2, // ความหนาของกรอบ
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey
                                              .shade300, // สีกรอบเมื่อไม่ได้โฟกัส
                                          width: 2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: warning.isNotEmpty
                                              ? Color(int.parse('0xff$warning'))
                                              : Colors.grey,
                                          width: 2,
                                        ),
                                      ),
                                      hintText: "-", // ข้อความตัวอย่าง
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (warning.isNotEmpty)
                          SizedBox(
                            height: height * 0.02,
                          ),
                        if (warning.isNotEmpty)
                          Text(
                            'OTP code is invalid',
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.red,
                            ),
                          ),
                        SizedBox(
                          height: height * 0.02,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'OTP copied',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            SizedBox(
                              width: width * 0.01,
                            ),
                            InkWell(
                              onTap: () async {
                                // ดึงข้อความจาก Clipboard
                                ClipboardData? data =
                                    await Clipboard.getData('text/plain');
                                if (data != null && data.text != null) {
                                  String copiedText = data.text!;
                                  if (copiedText.length == 6) {
                                    // ใส่ข้อความลงใน TextControllers
                                    for (int i = 0;
                                        i < copiedText.length;
                                        i++) {
                                      otpControllers[i].text = copiedText[i];
                                      // โฟกัสไปยังช่องสุดท้าย
                                      if (i == 5) {
                                        focusNodes[i].requestFocus();
                                      }
                                    }
                                    verifyEnteredOTP(
                                      otpControllers,
                                      codeOTP,
                                      email,
                                    ); // ตรวจสอบ OTP
                                  } else {
                                    warning = 'F21F1F';
                                    if (!mounted) return;
                                    setState(() {});
                                  }
                                }
                              },
                              child: Text(
                                'Paste',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'ref: $ref',
                          style: TextStyle(
                            fontSize: Get.textTheme.titleSmall!.fontSize,
                            fontWeight: FontWeight.normal,
                          ),
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
  }

  // ฟังก์ชันตรวจสอบ OTP
  void verifyEnteredOTP(
    List<TextEditingController> otpControllers,
    String codeOTP,
    String email,
  ) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];
    String enteredOTP = otpControllers
        .map((controller) => controller.text)
        .join(); // รวมค่าที่ป้อน
    if (enteredOTP == codeOTP) {
      // แสดง Loading Dialog
      loadingDialog();
      var responseIsverify = await http.put(
        Uri.parse("$url/admin/api/is_verify"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: adminVerifyPutRequestToJson(
          AdminVerifyPutRequest(
            email: email,
          ),
        ),
      );

      if (responseIsverify.statusCode == 200) {
        Get.back();
        Get.back();
        Get.back();
        emailCtl.text = '';
        passwordCtl.text = '';
        loadDataAsync();
        if (!mounted) return;
        setState(() {});

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
                  color: Color.fromRGBO(0, 122, 255, 1),
                ),
              ),
              Text(
                'Create account successfully',
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
                backgroundColor: Color.fromRGBO(0, 122, 255, 1),
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
      }
      warning = '';
      if (!mounted) return;
      setState(() {});
    } else {
      warning = 'F21F1F';
      if (!mounted) return;
      setState(() {});
    }
  }

  String obfuscateEmail(String email) {
    // แยกส่วนก่อนและหลัง '@'
    int atIndex = email.indexOf('@');

    String localPart = email.substring(0, atIndex); // ส่วนก่อน '@'
    String domainPart = email.substring(atIndex); // ส่วนหลัง '@'

    // กำหนดจำนวนตัวอักษรที่จะแสดงเป็นปกติ (3 ตัว)
    int visibleChars = localPart.length > 3 ? 3 : localPart.length;

    // แสดงตัวอักษรต้น
    String visiblePart = localPart.substring(0, visibleChars);
    // แปลงตัวอักษรที่เหลือเป็น '*'
    String obfuscatedPart = '*' * (localPart.length - visibleChars);

    // รวมข้อความที่แปลงแล้ว
    return visiblePart + obfuscatedPart + domainPart;
  }
}
