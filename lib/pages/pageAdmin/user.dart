import 'dart:developer';

import 'package:demomydayplanner/config/config.dart';
import 'package:demomydayplanner/models/response/allUserGetResponse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late Future<void> loadData;
  late List<User> allUsers = [];
  List<User> filteredUsers = [];
  String selectedRole = 'All';
  bool isDropdownOpen = false;
  bool isDropdownOpenUser = false;
  Map<String, bool> isDropdownOpenUserMap = {};

  @override
  void initState() {
    loadData = loadDataAsync();
    super.initState();
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
      filteredUsers = allUsers;
      setState(() {});
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
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return Scaffold(
          appBar: null,
          body: Center(
            child: SizedBox(
              height: height,
              child: RefreshIndicator(
                color: Color(0xffCDBEAE),
                onRefresh: loadDataAsync,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.05,
                    vertical: height * 0.05,
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'User',
                              style: TextStyle(
                                fontSize: Get.textTheme.displaySmall!.fontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: height * 0.06),
                              child: Column(
                                children: filteredUsers.map(
                                  (user) {
                                    isDropdownOpenUserMap[user.email] ??= false;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: height * 0.01,
                                      ),
                                      child: Container(
                                        width: width,
                                        height: height * 0.08,
                                        decoration: BoxDecoration(
                                          color: const Color(0xffEFEEEC),
                                          borderRadius:
                                              BorderRadius.circular(9),
                                          boxShadow: [
                                            BoxShadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 1,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                isDropdownOpenUserMap[
                                                        user.email] =
                                                    !isDropdownOpenUserMap[
                                                        user.email]!;
                                                setState(() {});
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.02,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        SvgPicture.string(
                                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2A10.13 10.13 0 0 0 2 12a10 10 0 0 0 4 7.92V20h.1a9.7 9.7 0 0 0 11.8 0h.1v-.08A10 10 0 0 0 22 12 10.13 10.13 0 0 0 12 2zM8.07 18.93A3 3 0 0 1 11 16.57h2a3 3 0 0 1 2.93 2.36 7.75 7.75 0 0 1-7.86 0zm9.54-1.29A5 5 0 0 0 13 14.57h-2a5 5 0 0 0-4.61 3.07A8 8 0 0 1 4 12a8.1 8.1 0 0 1 8-8 8.1 8.1 0 0 1 8 8 8 8 0 0 1-2.39 5.64z"></path><path d="M12 6a3.91 3.91 0 0 0-4 4 3.91 3.91 0 0 0 4 4 3.91 3.91 0 0 0 4-4 3.91 3.91 0 0 0-4-4zm0 6a1.91 1.91 0 0 1-2-2 1.91 1.91 0 0 1 2-2 1.91 1.91 0 0 1 2 2 1.91 1.91 0 0 1-2 2z"></path></svg>',
                                                          height: height * 0.05,
                                                          fit: BoxFit.contain,
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  '${user.email} ',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize: Get
                                                                        .textTheme
                                                                        .titleMedium!
                                                                        .fontSize,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                                user.isActive ==
                                                                        '1'
                                                                    ? SizedBox()
                                                                    : SvgPicture
                                                                        .string(
                                                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zM4 12c0-1.846.634-3.542 1.688-4.897l11.209 11.209A7.946 7.946 0 0 1 12 20c-4.411 0-8-3.589-8-8zm14.312 4.897L7.103 5.688A7.948 7.948 0 0 1 12 4c4.411 0 8 3.589 8 8a7.954 7.954 0 0 1-1.688 4.897z"></path></svg>',
                                                                        height: height *
                                                                            0.03,
                                                                        fit: BoxFit
                                                                            .contain,
                                                                        color: Colors
                                                                            .red,
                                                                      ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  'a ${user.role == 'admin' ? 'admin' : 'member'} on ${formatDate(user.createAt.toString())} - ${user.isVerify == 1 ? 'validated' : 'Invalidated'}',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize: Get
                                                                        .textTheme
                                                                        .titleSmall!
                                                                        .fontSize,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                  ),
                                                                ),
                                                                SvgPicture
                                                                    .string(
                                                                  user.isVerify ==
                                                                          1
                                                                      ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m10 15.586-3.293-3.293-1.414 1.414L10 18.414l9.707-9.707-1.414-1.414z"></path></svg>'
                                                                      : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m16.192 6.344-4.243 4.242-4.242-4.242-1.414 1.414L10.535 12l-4.242 4.242 1.414 1.414 4.242-4.242 4.243 4.242 1.414-1.414L13.364 12l4.242-4.242z"></path></svg>',
                                                                  height:
                                                                      height *
                                                                          0.03,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                  color: user.isVerify ==
                                                                          1
                                                                      ? Colors
                                                                          .green
                                                                      : Colors
                                                                          .red,
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        !isDropdownOpenUserMap[
                                                                user.email]!
                                                            ? SvgPicture.string(
                                                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                                                height: height *
                                                                    0.03,
                                                                fit: BoxFit
                                                                    .contain,
                                                              )
                                                            : SvgPicture.string(
                                                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M16.293 9.293 12 13.586 7.707 9.293l-1.414 1.414L12 16.414l5.707-5.707z"></path></svg>',
                                                                height: height *
                                                                    0.03,
                                                                fit: BoxFit
                                                                    .contain,
                                                              ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  Container(
                                    width: width,
                                    height: height * 0.05,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          136, 158, 158, 158),
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
                                    child: InkWell(
                                      onTap: () {
                                        isDropdownOpen = !isDropdownOpen;
                                        setState(() {});
                                      },
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
                                                  selectedRole,
                                                  style: TextStyle(
                                                    fontSize: Get.textTheme
                                                        .titleLarge!.fontSize,
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
                                  if (isDropdownOpen)
                                    Container(
                                      width: width,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 213, 213, 213),
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.03,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                selectedRole = 'All';
                                                isDropdownOpen =
                                                    !isDropdownOpen;
                                                filterUsersByRole('All');
                                                setState(() {});
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  top: height * 0.01,
                                                  left: width * 0.02,
                                                ),
                                                child: Row(
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
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Divider(
                                              color: Colors.grey,
                                              thickness: 0.6,
                                            ),
                                            InkWell(
                                              onTap: () {
                                                selectedRole = 'Admin';
                                                isDropdownOpen =
                                                    !isDropdownOpen;
                                                filterUsersByRole('Admin');
                                                setState(() {});
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  left: width * 0.02,
                                                ),
                                                child: Row(
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
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Divider(
                                              color: Colors.grey,
                                              thickness: 0.6,
                                            ),
                                            InkWell(
                                              onTap: () {
                                                selectedRole = 'User';
                                                isDropdownOpen =
                                                    !isDropdownOpen;
                                                filterUsersByRole('User');
                                                setState(() {});
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: height * 0.01,
                                                  left: width * 0.02,
                                                ),
                                                child: Row(
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
                                                  ],
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

  String formatDate(String date) {
    // แปลงจาก String (ISO 8601) เป็น DateTime โดยไม่ระบุฟอร์แมต
    DateTime parsedDate = DateTime.parse(date);

    // แปลง DateTime เป็น String ในรูปแบบที่ต้องการ
    return DateFormat('dd/MM/yy').format(parsedDate);
  }

  void filterUsersByRole(String role) {
    if (role == 'All') {
      filteredUsers = allUsers;
    } else {
      filteredUsers = allUsers
          .where((user) => user.role.toLowerCase() == role.toLowerCase())
          .toList();
    }
    setState(() {});
  }
}
