import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/services.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/deleteUserDeleteRequest.dart';
import 'package:mydayplanner/models/request/editProfileUserPutRequest.dart';
import 'package:mydayplanner/models/request/getUserByEmailPostRequest.dart';
import 'package:mydayplanner/models/request/isVerifyUserPutRequest.dart';
import 'package:mydayplanner/models/request/logoutUserPostRequest.dart';
import 'package:mydayplanner/models/request/sendOTPPostRequest.dart';
import 'package:mydayplanner/models/response/getUserByEmailPostResponst.dart';
import 'package:mydayplanner/models/response/logoutUserPostResponse.dart';
import 'package:mydayplanner/models/response/sendOTPPostResponst.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:mydayplanner/splash.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ---------------------- 🧠 Logic / Data ----------------------
  var box = GetStorage();
  late Future<void> loadData;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ImagePicker picker = ImagePicker();

// ---------------------- 🧍‍♂️ User Info ----------------------
  String name = '';
  String userEmail = '';
  String userProfile = '';
  String userPassword = '';
  String warning = '';

// ---------------------- 🧮 State / Counter ----------------------
  int lists = 400;
  int group = 200;
  int priority = 200;
  int itemCount = 1;

// ---------------------- 🎛️ UI State ----------------------
  bool isLoadings = true;
  bool showShimmer = true;
  bool editInformation = false;
  bool notitext = false;
  bool isTyping = false;
  bool isTypingPasswordVerify = false;
  bool isTypingPassword = false;
  bool isCheckedPassword = false;
  bool isCheckedPasswordVerify = false;
  bool isCheckedPasswordConfirmDelete = false;
  bool isTogglePushNotification = false;
  bool isToggleEmailNotification = false;

// ---------------------- 🎯 Controllers ----------------------
  TextEditingController editNameCtl = TextEditingController();
  TextEditingController editPasswordCtl = TextEditingController();
  TextEditingController passwordVerifyCtl = TextEditingController();
  TextEditingController passwordConfirmDeleteCtl = TextEditingController();

// ---------------------- 👁️ Focus Nodes ----------------------
  FocusNode editNameFocusNode = FocusNode();
  FocusNode editPasswordFocusNode = FocusNode();

// ---------------------- 🖼️ Image / File ----------------------
  XFile? image;
  File? savedFile;

  // 📋 Global Keys
  GlobalKey iconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // var re = box.getKeys();
    // for (var i in re) {
    //   log(i);
    // }
    firstPageShow();
    loadData = loadDataAsync();
  }

  @override
  void dispose() {
    editNameCtl.dispose();
    editPasswordCtl.dispose();
    super.dispose();
  }

  Future<void> loadDataAsync() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    var responseGetUser = await http.post(
      Uri.parse("$url/user/api/get_user"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: getUserByEmailPostRequestToJson(
        GetUserByEmailPostRequest(
          email: box.read('email'),
        ),
      ),
    );

    if (responseGetUser.statusCode == 200) {
      GetUserByEmailPostResponst responst =
          getUserByEmailPostResponstFromJson(responseGetUser.body);
      name = responst.name;
      userEmail = responst.email;
      userPassword = responst.hashedPassword;
      userProfile = responst.profile;

      isLoadings = false;
      setState(() {});

      Timer(Duration(seconds: 2), () {
        showShimmer = false;
        setState(() {});
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
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) {
              itemCount = name.isEmpty ? 1 : name.length;
              setState(() {});
            }
          });
        }
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                right: width * 0.05,
                left: width * 0.05,
                top: height * 0.01,
                bottom: height * 0.01,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (context.read<Appdata>().keepPage.keepPage) {
                                BackPageSettingToHome keep =
                                    BackPageSettingToHome();
                                keep.keepPage = false;
                                context.read<Appdata>().keepPage = keep;
                                Get.to(() => NavbarPage());
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
                            'Settings',
                            style: TextStyle(
                              fontSize: Get.textTheme.titleLarge!.fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: width * 0.1),
                        ],
                      ),
                      Container(
                        width: width,
                        height: height * 0.05,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(242, 242, 246, 1),
                          borderRadius: BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: width * 0.03),
                        child: Row(
                          children: [
                            SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2A10.13 10.13 0 0 0 2 12a10 10 0 0 0 4 7.92V20h.1a9.7 9.7 0 0 0 11.8 0h.1v-.08A10 10 0 0 0 22 12 10.13 10.13 0 0 0 12 2zM8.07 18.93A3 3 0 0 1 11 16.57h2a3 3 0 0 1 2.93 2.36 7.75 7.75 0 0 1-7.86 0zm9.54-1.29A5 5 0 0 0 13 14.57h-2a5 5 0 0 0-4.61 3.07A8 8 0 0 1 4 12a8.1 8.1 0 0 1 8-8 8.1 8.1 0 0 1 8 8 8 8 0 0 1-2.39 5.64z"></path><path d="M12 6a3.91 3.91 0 0 0-4 4 3.91 3.91 0 0 0 4 4 3.91 3.91 0 0 0 4-4 3.91 3.91 0 0 0-4-4zm0 6a1.91 1.91 0 0 1-2-2 1.91 1.91 0 0 1 2-2 1.91 1.91 0 0 1 2 2 1.91 1.91 0 0 1-2 2z"></path></svg>',
                                height: height * 0.03,
                                fit: BoxFit.contain,
                                color: Color.fromRGBO(0, 122, 255, 1)),
                            SizedBox(
                              width: width * 0.01,
                            ),
                            Text(
                              'Account',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleLarge!.fontSize,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: isLoadings || showShimmer ? null : myProfile,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            width * 0.03,
                            height * 0.005,
                            0,
                            height * 0.005,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  isLoadings || showShimmer
                                      ? Shimmer.fromColors(
                                          baseColor: Color(0xFFF7F7F7),
                                          highlightColor: Colors.grey[300]!,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            width: height * 0.07,
                                            height: height * 0.07,
                                          ),
                                        )
                                      : ClipOval(
                                          child: userProfile == 'none-url'
                                              ? Container(
                                                  width: height * 0.07,
                                                  height: height * 0.07,
                                                  decoration:
                                                      const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Container(
                                                        height: height * 0.1,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Color.fromRGBO(
                                                              242, 242, 246, 1),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                      Positioned(
                                                        left: 0,
                                                        right: 0,
                                                        bottom: 0,
                                                        child:
                                                            SvgPicture.string(
                                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                          height: height * 0.05,
                                                          fit: BoxFit.contain,
                                                          color: Colors.grey,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                )
                                              : Image.network(
                                                  userProfile,
                                                  width: height * 0.07,
                                                  height: height * 0.07,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                  SizedBox(
                                    width: width * 0.02,
                                  ),
                                  Text(
                                    'Profile',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleLarge!.fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                height: height * 0.03,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: height * 0.02,
                      ),
                      Container(
                        width: width,
                        height: height * 0.05,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(242, 242, 246, 1),
                          borderRadius: BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: width * 0.03),
                        child: Row(
                          children: [
                            SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M19 13.586V10c0-3.217-2.185-5.927-5.145-6.742C13.562 2.52 12.846 2 12 2s-1.562.52-1.855 1.258C7.185 4.074 5 6.783 5 10v3.586l-1.707 1.707A.996.996 0 0 0 3 16v2a1 1 0 0 0 1 1h16a1 1 0 0 0 1-1v-2a.996.996 0 0 0-.293-.707L19 13.586zM19 17H5v-.586l1.707-1.707A.996.996 0 0 0 7 14v-4c0-2.757 2.243-5 5-5s5 2.243 5 5v4c0 .266.105.52.293.707L19 16.414V17zm-7 5a2.98 2.98 0 0 0 2.818-2H9.182A2.98 2.98 0 0 0 12 22z"></path></svg>',
                              height: height * 0.03,
                              fit: BoxFit.contain,
                              color: Color.fromRGBO(255, 58, 49, 1),
                            ),
                            SizedBox(
                              width: width * 0.01,
                            ),
                            Text(
                              'My notifications',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleLarge!.fontSize,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              width * 0.03,
                              height * 0.005,
                              0,
                              height * 0.005,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mobile push notifications',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                Text.rich(
                                  TextSpan(
                                    text: 'Receive push notifications\n',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Color.fromRGBO(151, 149, 149, 1),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'via your mobile app.',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme.titleSmall!.fontSize,
                                          fontWeight: FontWeight.normal,
                                          height: 0.9,
                                          color:
                                              Color.fromRGBO(151, 149, 149, 1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (!isTogglePushNotification) {
                                    log('noti push');
                                  }
                                  isTogglePushNotification =
                                      !isTogglePushNotification;
                                  setState(() {});
                                },
                                icon: Icon(
                                  isTogglePushNotification
                                      ? Icons.toggle_on_outlined
                                      : Icons.toggle_off_outlined,
                                  color: isTogglePushNotification
                                      ? Color.fromRGBO(0, 122, 255, 1)
                                      : Colors.grey,
                                ),
                                iconSize: height * 0.04,
                              ),
                              SizedBox(width: width * 0.02),
                            ],
                          ),
                        ],
                      ),
                      Divider(
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              width * 0.03,
                              0,
                              0,
                              height * 0.005,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send email notifications',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                Text.rich(
                                  TextSpan(
                                    text: 'Receive send notifications\n',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Color.fromRGBO(151, 149, 149, 1),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'via your email.',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme.titleSmall!.fontSize,
                                          fontWeight: FontWeight.normal,
                                          height: 0.9,
                                          color:
                                              Color.fromRGBO(151, 149, 149, 1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (!isToggleEmailNotification) {
                                    log('noti email');
                                  }
                                  isToggleEmailNotification =
                                      !isToggleEmailNotification;
                                  setState(() {});
                                },
                                icon: Icon(
                                  isToggleEmailNotification
                                      ? Icons.toggle_on_outlined
                                      : Icons.toggle_off_outlined,
                                  color: isToggleEmailNotification
                                      ? Color.fromRGBO(0, 122, 255, 1)
                                      : Colors.grey,
                                ),
                                iconSize: height * 0.04,
                              ),
                              SizedBox(width: width * 0.02),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: height * 0.02,
                      ),
                      Container(
                        width: width,
                        height: height * 0.05,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(242, 242, 246, 1),
                          borderRadius: BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: width * 0.03),
                        child: Row(
                          children: [
                            SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 16c2.206 0 4-1.794 4-4s-1.794-4-4-4-4 1.794-4 4 1.794 4 4 4zm0-6c1.084 0 2 .916 2 2s-.916 2-2 2-2-.916-2-2 .916-2 2-2z"></path><path d="m2.845 16.136 1 1.73c.531.917 1.809 1.261 2.73.73l.529-.306A8.1 8.1 0 0 0 9 19.402V20c0 1.103.897 2 2 2h2c1.103 0 2-.897 2-2v-.598a8.132 8.132 0 0 0 1.896-1.111l.529.306c.923.53 2.198.188 2.731-.731l.999-1.729a2.001 2.001 0 0 0-.731-2.732l-.505-.292a7.718 7.718 0 0 0 0-2.224l.505-.292a2.002 2.002 0 0 0 .731-2.732l-.999-1.729c-.531-.92-1.808-1.265-2.731-.732l-.529.306A8.1 8.1 0 0 0 15 4.598V4c0-1.103-.897-2-2-2h-2c-1.103 0-2 .897-2 2v.598a8.132 8.132 0 0 0-1.896 1.111l-.529-.306c-.924-.531-2.2-.187-2.731.732l-.999 1.729a2.001 2.001 0 0 0 .731 2.732l.505.292a7.683 7.683 0 0 0 0 2.223l-.505.292a2.003 2.003 0 0 0-.731 2.733zm3.326-2.758A5.703 5.703 0 0 1 6 12c0-.462.058-.926.17-1.378a.999.999 0 0 0-.47-1.108l-1.123-.65.998-1.729 1.145.662a.997.997 0 0 0 1.188-.142 6.071 6.071 0 0 1 2.384-1.399A1 1 0 0 0 11 5.3V4h2v1.3a1 1 0 0 0 .708.956 6.083 6.083 0 0 1 2.384 1.399.999.999 0 0 0 1.188.142l1.144-.661 1 1.729-1.124.649a1 1 0 0 0-.47 1.108c.112.452.17.916.17 1.378 0 .461-.058.925-.171 1.378a1 1 0 0 0 .471 1.108l1.123.649-.998 1.729-1.145-.661a.996.996 0 0 0-1.188.142 6.071 6.071 0 0 1-2.384 1.399A1 1 0 0 0 13 18.7l.002 1.3H11v-1.3a1 1 0 0 0-.708-.956 6.083 6.083 0 0 1-2.384-1.399.992.992 0 0 0-1.188-.141l-1.144.662-1-1.729 1.124-.651a1 1 0 0 0 .471-1.108z"></path></svg>',
                              height: height * 0.03,
                              fit: BoxFit.contain,
                              color: Color.fromRGBO(151, 149, 149, 1),
                            ),
                            SizedBox(
                              width: width * 0.01,
                            ),
                            Text(
                              'My settings',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleLarge!.fontSize,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              width * 0.03,
                              height * 0.005,
                              0,
                              height * 0.005,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'First page',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                Text.rich(
                                  TextSpan(
                                    text: 'Choose the home page\n',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Color.fromRGBO(151, 149, 149, 1),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'you want.',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme.titleSmall!.fontSize,
                                          fontWeight: FontWeight.normal,
                                          height: 0.9,
                                          color:
                                              Color.fromRGBO(151, 149, 149, 1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  if (mounted) {
                                    BackPageSettingToHome keep =
                                        BackPageSettingToHome();
                                    keep.keepPage = true;
                                    context.read<Appdata>().keepPage = keep;
                                    box.write('listsTF', true);
                                    box.write('groupTF', false);
                                    box.write('PriorityTF', false);

                                    lists = 400;
                                    group = 200;
                                    priority = 200;
                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.02,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lists == 400
                                        ? Color.fromRGBO(0, 122, 255, 1)
                                        : Colors.grey[lists],
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Lists',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: lists == 400
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: width * 0.01),
                              InkWell(
                                onTap: () {
                                  if (mounted) {
                                    BackPageSettingToHome keep =
                                        BackPageSettingToHome();
                                    keep.keepPage = true;
                                    context.read<Appdata>().keepPage = keep;
                                    box.write('listsTF', false);
                                    box.write('groupTF', true);
                                    box.write('PriorityTF', false);

                                    lists = 200;
                                    group = 400;
                                    priority = 200;
                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.02,
                                  ),
                                  decoration: BoxDecoration(
                                    color: group == 400
                                        ? Color.fromRGBO(0, 122, 255, 1)
                                        : Colors.grey[group],
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Groups',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: group == 400
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: height * 0.02,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Material(
                        color: Color.fromRGBO(242, 242, 246, 1),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            logout(context);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: height * 0.01),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sign Out',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: FontWeight.normal,
                                    color: Color.fromRGBO(255, 58, 49, 1),
                                  ),
                                ),
                              ],
                            ),
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
  }

  void myProfile() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height;

            editNameCtl.addListener(() {
              if (context.mounted) {
                isTyping = editNameCtl.text.isNotEmpty;
                setState(() {});
              }
            });
            editPasswordCtl.addListener(() {
              if (context.mounted) {
                isTypingPassword = editPasswordCtl.text.isNotEmpty;
                setState(() {});
              }
            });

            return PopScope(
              canPop: false,
              child: GestureDetector(
                onTap: () {
                  if (editNameFocusNode.hasFocus) {
                    editNameFocusNode.unfocus();
                    setState(() {});
                  }
                  if (editPasswordFocusNode.hasFocus) {
                    editPasswordFocusNode.unfocus();
                    setState(() {});
                  }
                },
                child: Scaffold(
                  body: Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.05,
                      right: width * 0.05,
                      top: height * 0.05,
                      bottom: height * 0.05,
                    ),
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: height * 0.9,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Get.back();
                                        editNameCtl.removeListener(() {});
                                        editPasswordCtl.removeListener(() {});
                                        savedFile = null;
                                        isTyping = false;
                                        isTypingPassword = false;
                                        editNameCtl.clear();
                                        editPasswordCtl.clear();
                                        passwordVerifyCtl.clear();
                                        isCheckedPassword = false;
                                        isCheckedPasswordConfirmDelete = false;
                                        passwordConfirmDeleteCtl.clear();
                                        notitext = false;
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
                                      'My profile',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleLarge!.fontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: width * 0.1),
                                  ],
                                ),
                                SizedBox(
                                  height: height * 0.02,
                                ),
                                InkWell(
                                  key: iconKey,
                                  onTap: () {
                                    final RenderBox renderBox = iconKey
                                        .currentContext!
                                        .findRenderObject() as RenderBox;
                                    final Offset offset =
                                        renderBox.localToGlobal(Offset.zero);
                                    final Size size = renderBox.size;
                                    showMenu(
                                      context: context,
                                      position: RelativeRect.fromLTRB(
                                        offset.dx,
                                        offset.dy + size.height,
                                        width - offset.dx - size.width * 2.5,
                                        0,
                                      ),
                                      color: Colors.white,
                                      items: [
                                        PopupMenuItem(
                                          value: 'แกลลอรี่',
                                          child: Text(
                                            'Choose Photo',
                                            style: TextStyle(
                                              fontSize: Get.textTheme
                                                  .titleMedium!.fontSize,
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'เลือกไฟล์',
                                          child: Text(
                                            'Choose file',
                                            style: TextStyle(
                                              fontSize: Get.textTheme
                                                  .titleMedium!.fontSize,
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'ถ่ายรูป',
                                          child: Text(
                                            'Take Photo',
                                            style: TextStyle(
                                              fontSize: Get.textTheme
                                                  .titleMedium!.fontSize,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ).then((value) async {
                                      if (value != null) {
                                        if (value == 'แกลลอรี่') {
                                          image = await picker.pickImage(
                                              source: ImageSource.gallery);
                                          if (image != null) {
                                            savedFile = File(image!.path);
                                            setState(() {});
                                          }
                                        } else if (value == 'เลือกไฟล์') {
                                          FilePickerResult? result =
                                              await FilePicker.platform
                                                  .pickFiles();
                                          if (result != null) {
                                            savedFile =
                                                File(result.files.first.path!);
                                            setState(() {});
                                          }
                                        } else if (value == 'ถ่ายรูป') {
                                          image = await picker.pickImage(
                                              source: ImageSource.camera);
                                          if (image != null) {
                                            savedFile = File(image!.path);
                                            setState(() {});
                                          }
                                        }
                                      }
                                    });
                                  },
                                  child: Container(
                                    height: height * 0.1,
                                    width: width * 0.22,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: Stack(
                                      children: [
                                        savedFile != null
                                            ? Positioned(
                                                right: -width * 0.005,
                                                top: -height * 0.005,
                                                child: InkWell(
                                                  onTap: () {
                                                    savedFile = null;
                                                    setState(() {});
                                                  },
                                                  child: SvgPicture.string(
                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m16.192 6.344-4.243 4.242-4.242-4.242-1.414 1.414L10.535 12l-4.242 4.242 1.414 1.414 4.242-4.242 4.243 4.242 1.414-1.414L13.364 12l4.242-4.242z"></path></svg>',
                                                    width: width * 0.06,
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                        Container(
                                          height: height * 0.1,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        savedFile == null
                                            ? Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: 0,
                                                child: ClipOval(
                                                  child: userProfile ==
                                                          'none-url'
                                                      ? Container(
                                                          height: height * 0.1,
                                                          width: width * 0.22,
                                                          decoration:
                                                              const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Stack(
                                                            children: [
                                                              Container(
                                                                height: height *
                                                                    0.1,
                                                                decoration:
                                                                    const BoxDecoration(
                                                                  color: Color
                                                                      .fromRGBO(
                                                                          242,
                                                                          242,
                                                                          246,
                                                                          1),
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                              ),
                                                              Positioned(
                                                                left: 0,
                                                                right: 0,
                                                                bottom: 0,
                                                                child:
                                                                    SvgPicture
                                                                        .string(
                                                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                                  height:
                                                                      height *
                                                                          0.07,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        )
                                                      : Image.network(
                                                          userProfile,
                                                          height: height * 0.1,
                                                          width: width * 0.22,
                                                          fit: BoxFit.cover,
                                                        ),
                                                ),
                                              )
                                            : Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: 0,
                                                child: ClipOval(
                                                  child: Image.file(
                                                    savedFile!,
                                                    height: height * 0.1,
                                                    width: width * 0.22,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          width: width * 0.1,
                                          child: Center(
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  height: height * 0.03,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                Container(
                                                  height: height * 0.025,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                SvgPicture.string(
                                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 8c-2.168 0-4 1.832-4 4s1.832 4 4 4 4-1.832 4-4-1.832-4-4-4zm0 6c-1.065 0-2-.935-2-2s.935-2 2-2 2 .935 2 2-.935 2-2 2z"></path><path d="M20 5h-2.586l-2.707-2.707A.996.996 0 0 0 14 2h-4a.996.996 0 0 0-.707.293L6.586 5H4c-1.103 0-2 .897-2 2v11c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V7c0-1.103-.897-2-2-2zM4 18V7h3c.266 0 .52-.105.707-.293L10.414 4h3.172l2.707 2.707A.996.996 0 0 0 17 7h3l.002 11H4z"></path></svg>',
                                                  height: height * 0.02,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: height * 0.01),
                                savedFile != null
                                    ? InkWell(
                                        onTap: () {
                                          if (savedFile != null) {
                                            confirmInformation(
                                              '',
                                              '',
                                              'newUrl',
                                            );
                                          }
                                        },
                                        child: SvgPicture.string(
                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m10 15.586-3.293-3.293-1.414 1.414L10 18.414l9.707-9.707-1.414-1.414z"></path></svg>',
                                          width: width * 0.08,
                                          color: Colors.green,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                                SizedBox(height: height * 0.03),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Name',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: width * 0.6,
                                          child: TextField(
                                            controller: editNameCtl,
                                            focusNode: editNameFocusNode,
                                            keyboardType: TextInputType.text,
                                            cursorColor: Colors.black,
                                            style: TextStyle(
                                              fontSize: Get.textTheme
                                                  .titleSmall!.fontSize,
                                            ),
                                            textAlign: TextAlign.end,
                                            decoration: InputDecoration(
                                              hintText: isTyping
                                                  ? 'Enter your name'
                                                  : name,
                                              hintStyle: TextStyle(
                                                fontSize: Get.textTheme
                                                    .titleSmall!.fontSize,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black,
                                              ),
                                              constraints: BoxConstraints(
                                                maxHeight: height * 0.05,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                horizontal: width * 0.02,
                                              ),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                        isTyping
                                            ? InkWell(
                                                onTap: () {
                                                  confirmInformation(
                                                    'newName',
                                                    '',
                                                    '',
                                                  );
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: width * 0.01,
                                                    vertical: height * 0.005,
                                                  ),
                                                  child: Text(
                                                    'confirm',
                                                    style: TextStyle(
                                                      fontSize: Get.textTheme
                                                          .titleSmall!.fontSize,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Color.fromRGBO(
                                                          0, 122, 255, 1),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : GestureDetector(
                                                onTap: () {
                                                  isTyping = true;
                                                  setState(() {});
                                                },
                                                child: SvgPicture.string(
                                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                                  height: height * 0.03,
                                                  fit: BoxFit.contain,
                                                ),
                                              )
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.01),
                                Padding(
                                  padding: EdgeInsets.only(right: width * 0.02),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Email address',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme.titleMedium!.fontSize,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        userEmail,
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme.titleSmall!.fontSize,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: height * 0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Password',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: width * 0.6,
                                          child: TextField(
                                            controller: editPasswordCtl,
                                            focusNode: editPasswordFocusNode,
                                            keyboardType:
                                                TextInputType.visiblePassword,
                                            obscureText: !isCheckedPassword,
                                            cursorColor: Colors.black,
                                            style: TextStyle(
                                              fontSize: Get.textTheme
                                                  .titleSmall!.fontSize,
                                            ),
                                            textAlign: TextAlign.end,
                                            decoration: InputDecoration(
                                              hintText: isCheckedPassword
                                                  ? userPassword == '-'
                                                      ? 'set your new password'
                                                      : box.read('password')
                                                  : userPassword == '-'
                                                      ? 'set your new password'
                                                      : obfuscatePasswordFully(
                                                          box.read('password')),
                                              hintStyle: TextStyle(
                                                fontSize: Get.textTheme
                                                    .titleSmall!.fontSize,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black,
                                              ),
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  if (userPassword == '-') {
                                                    isCheckedPassword =
                                                        !isCheckedPassword;
                                                    setState(() {});
                                                  } else {
                                                    if (isCheckedPassword) {
                                                      isCheckedPassword = false;
                                                      passwordVerifyCtl.clear();
                                                      setState(() {});
                                                      return;
                                                    }

                                                    Get.defaultDialog(
                                                      title: "",
                                                      titlePadding:
                                                          EdgeInsets.zero,
                                                      backgroundColor:
                                                          Colors.white,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                        horizontal:
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.04,
                                                        vertical: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.02,
                                                      ),
                                                      content: StatefulBuilder(
                                                          builder: (BuildContext
                                                                  context,
                                                              StateSetter
                                                                  setState) {
                                                        return Column(
                                                          children: [
                                                            Image.asset(
                                                              "assets/images/aleart/info.png",
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.1,
                                                              fit: BoxFit
                                                                  .contain,
                                                            ),
                                                            SizedBox(
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height *
                                                                    0.01),
                                                            Text(
                                                              'Verify!',
                                                              style: TextStyle(
                                                                fontSize: Get
                                                                    .textTheme
                                                                    .headlineSmall!
                                                                    .fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Color
                                                                    .fromRGBO(
                                                                        0,
                                                                        122,
                                                                        255,
                                                                        1),
                                                              ),
                                                            ),
                                                            Text(
                                                              'Enter your password to verify your identity',
                                                              style: TextStyle(
                                                                fontSize: Get
                                                                    .textTheme
                                                                    .titleMedium!
                                                                    .fontSize,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            SizedBox(
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height *
                                                                    0.01),
                                                            TextField(
                                                              controller:
                                                                  passwordVerifyCtl,
                                                              keyboardType:
                                                                  TextInputType
                                                                      .visiblePassword,
                                                              obscureText:
                                                                  !isCheckedPasswordVerify,
                                                              cursorColor:
                                                                  Colors.black,
                                                              style: TextStyle(
                                                                fontSize: Get
                                                                    .textTheme
                                                                    .titleMedium!
                                                                    .fontSize,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              decoration:
                                                                  InputDecoration(
                                                                hintText:
                                                                    isTypingPasswordVerify
                                                                        ? ''
                                                                        : 'Enter your password',
                                                                hintStyle:
                                                                    TextStyle(
                                                                  fontSize: Get
                                                                      .textTheme
                                                                      .titleMedium!
                                                                      .fontSize,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                                prefixIcon:
                                                                    SizedBox(),
                                                                suffixIcon:
                                                                    IconButton(
                                                                  onPressed:
                                                                      () {
                                                                    isCheckedPasswordVerify =
                                                                        !isCheckedPasswordVerify;
                                                                    setState(
                                                                        () {});
                                                                  },
                                                                  icon: Icon(
                                                                    isCheckedPasswordVerify
                                                                        ? Icons
                                                                            .visibility
                                                                        : Icons
                                                                            .visibility_off,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                ),
                                                                contentPadding:
                                                                    EdgeInsets
                                                                        .symmetric(
                                                                  horizontal:
                                                                      width *
                                                                          0.02,
                                                                ),
                                                                enabledBorder:
                                                                    OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  borderSide:
                                                                      const BorderSide(
                                                                    width: 0.5,
                                                                  ),
                                                                ),
                                                                focusedBorder:
                                                                    OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  borderSide:
                                                                      const BorderSide(
                                                                    width: 0.5,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            if (notitext ||
                                                                !notitext)
                                                              SizedBox(
                                                                height: height *
                                                                    0.02,
                                                              ),
                                                            if (notitext)
                                                              Text(
                                                                'Invalid password',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: Get
                                                                      .textTheme
                                                                      .titleMedium!
                                                                      .fontSize,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            if (notitext)
                                                              SizedBox(
                                                                height: height *
                                                                    0.02,
                                                              ),
                                                            ElevatedButton(
                                                              onPressed: () {
                                                                if (BCrypt.checkpw(
                                                                    passwordVerifyCtl
                                                                        .text,
                                                                    userPassword)) {
                                                                  Get.back();
                                                                  isCheckedPassword =
                                                                      !isCheckedPassword;
                                                                  editPasswordCtl
                                                                      .clear();
                                                                  notitext =
                                                                      false;
                                                                  setState(
                                                                      () {});
                                                                } else {
                                                                  notitext =
                                                                      true;
                                                                  setState(
                                                                      () {});
                                                                }
                                                              },
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                fixedSize: Size(
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .height *
                                                                      0.05,
                                                                ),
                                                                backgroundColor:
                                                                    Color
                                                                        .fromRGBO(
                                                                            0,
                                                                            122,
                                                                            255,
                                                                            1),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                ),
                                                                elevation: 1,
                                                              ),
                                                              child: Text(
                                                                'Confirm',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: Get
                                                                      .textTheme
                                                                      .titleLarge!
                                                                      .fontSize,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () {
                                                                Get.back();
                                                                isCheckedPassword =
                                                                    false;
                                                                notitext =
                                                                    false;
                                                                passwordVerifyCtl
                                                                    .clear();
                                                                setState(() {});
                                                              },
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                fixedSize: Size(
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .height *
                                                                      0.05,
                                                                ),
                                                                backgroundColor:
                                                                    Color
                                                                        .fromRGBO(
                                                                            231,
                                                                            243,
                                                                            255,
                                                                            1),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                ),
                                                                elevation: 1,
                                                              ),
                                                              child: Text(
                                                                'Back',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: Get
                                                                      .textTheme
                                                                      .titleLarge!
                                                                      .fontSize,
                                                                  color: Color
                                                                      .fromRGBO(
                                                                          0,
                                                                          122,
                                                                          255,
                                                                          1),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      }),
                                                    );
                                                  }
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
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                horizontal: width * 0.02,
                                                vertical: height * 0.01,
                                              ),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                        isTypingPassword
                                            ? InkWell(
                                                onTap: () {
                                                  confirmInformation(
                                                    '',
                                                    'newPassword',
                                                    '',
                                                  );
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: width * 0.01,
                                                    vertical: height * 0.005,
                                                  ),
                                                  child: Text(
                                                    'confirm',
                                                    style: TextStyle(
                                                      fontSize: Get.textTheme
                                                          .titleSmall!.fontSize,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Color.fromRGBO(
                                                          0, 122, 255, 1),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : GestureDetector(
                                                onTap: () {
                                                  isTypingPassword = true;
                                                  setState(() {});
                                                },
                                                child: SvgPicture.string(
                                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                                  height: height * 0.03,
                                                  fit: BoxFit.contain,
                                                ),
                                              )
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Material(
                                  color: Color.fromRGBO(242, 242, 246, 1),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: deleteUser,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: height * 0.01),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Delete account',
                                            style: TextStyle(
                                              fontSize: Get.textTheme
                                                  .titleMedium!.fontSize,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            )
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
      },
    );
  }

  void confirmInformation(
    String newName,
    String newPassword,
    String newUrl,
  ) async {
    log("message");
    // var config = await Configuration.getConfig();
    // var url = config['apiEndpoint'];
    // bool hasSuccess = false;

    // loadingDialog(); // แสดงโหลดล่วงหน้า

    // // 1. เปลี่ยนชื่อ
    // if (newName.isNotEmpty) {
    //   final res = await http.put(
    //     Uri.parse("$url/profile/api/edit_profile"),
    //     headers: {"Content-Type": "application/json; charset=utf-8"},
    //     body: editProfileUserPutRequestToJson(
    //       EditProfileUserPutRequest(
    //         email: userEmail,
    //         profileData: ProfileData(
    //           name: editNameCtl.text,
    //           hashedPassword: null,
    //           profile: null,
    //         ),
    //       ),
    //     ),
    //   );

    //   if (res.statusCode == 200) {
    //     hasSuccess = true;
    //     editNameCtl.clear();
    //   }
    // }

    // // 2. เปลี่ยนรหัสผ่าน
    // if (newPassword.isNotEmpty) {
    //   final res = await http.put(
    //     Uri.parse("$url/profile/api/edit_profile"),
    //     headers: {"Content-Type": "application/json; charset=utf-8"},
    //     body: editProfileUserPutRequestToJson(
    //       EditProfileUserPutRequest(
    //         email: userEmail,
    //         profileData: ProfileData(
    //           name: null,
    //           hashedPassword: editPasswordCtl.text,
    //           profile: null,
    //         ),
    //       ),
    //     ),
    //   );

    //   if (res.statusCode == 200) {
    //     box.write('password', editPasswordCtl.text);
    //     hasSuccess = true;
    //     editPasswordCtl.clear();
    //   }
    // }

    // // 3. เปลี่ยนรูปโปรไฟล์
    // if (newUrl.isNotEmpty && savedFile != null) {
    //   String downloadUrl = "";

    //   final storageReference = FirebaseStorage.instance.ref().child(
    //         'uploadsImageProfile/${DateTime.now().millisecondsSinceEpoch}_${savedFile!.path.split('/').last}',
    //       );

    //   final uploadTask = storageReference.putFile(savedFile!);
    //   final snapshot = await uploadTask;

    //   downloadUrl = await snapshot.ref.getDownloadURL();

    //   if (userProfile.isNotEmpty && userProfile != 'none-url') {
    //     final oldRef = FirebaseStorage.instance.refFromURL(userProfile);
    //     String oldUrl = await oldRef.getDownloadURL();
    //     if (userProfile == oldUrl) {
    //       await oldRef.delete();
    //     }
    //   }

    //   final res = await http.put(
    //     Uri.parse("$url/profile/api/edit_profile"),
    //     headers: {"Content-Type": "application/json; charset=utf-8"},
    //     body: editProfileUserPutRequestToJson(
    //       EditProfileUserPutRequest(
    //         email: userEmail,
    //         profileData: ProfileData(
    //           name: null,
    //           hashedPassword: null,
    //           profile: downloadUrl,
    //         ),
    //       ),
    //     ),
    //   );

    //   if (res.statusCode == 200) {
    //     hasSuccess = true;
    //     savedFile = null;
    //   }
    // }

    // // ถ้ามีอย่างใดอย่างหนึ่งสำเร็จ
    // if (hasSuccess) {
    //   Get.back(); // ปิด loading dialog
    //   isTyping = false;
    //   isTypingPassword = false;
    //   isCheckedPassword = false;
    //   loadDataAsync();

    //   BackPageSettingToHome keep = BackPageSettingToHome();
    //   keep.keepPage = true;
    //   context.read<Appdata>().keepPage = keep;

    //   Future.delayed(const Duration(milliseconds: 500), () {
    //     editNameFocusNode.unfocus();
    //     editPasswordFocusNode.unfocus();
    //     Get.defaultDialog(
    //       title: "",
    //       titlePadding: EdgeInsets.zero,
    //       backgroundColor: Colors.white,
    //       contentPadding: EdgeInsets.symmetric(
    //         horizontal: MediaQuery.of(context).size.width * 0.04,
    //         vertical: MediaQuery.of(context).size.height * 0.02,
    //       ),
    //       content: Column(
    //         children: [
    //           Image.asset(
    //             "assets/images/aleart/success.png",
    //             height: MediaQuery.of(context).size.height * 0.1,
    //             fit: BoxFit.contain,
    //           ),
    //           SizedBox(height: MediaQuery.of(context).size.height * 0.01),
    //           Text(
    //             'Successfully!!',
    //             style: TextStyle(
    //               fontSize: Get.textTheme.headlineSmall!.fontSize,
    //               fontWeight: FontWeight.w500,
    //               color: Color.fromRGBO(0, 122, 255, 1),
    //             ),
    //           ),
    //           Text(
    //             'Update your profile successfully',
    //             style: TextStyle(
    //               fontSize: Get.textTheme.titleMedium!.fontSize,
    //               color: Colors.black,
    //             ),
    //             textAlign: TextAlign.center,
    //           ),
    //         ],
    //       ),
    //       actions: [
    //         ElevatedButton(
    //           onPressed: () {
    //             Get.back();
    //           },
    //           style: ElevatedButton.styleFrom(
    //             fixedSize: Size(
    //               MediaQuery.of(context).size.width,
    //               MediaQuery.of(context).size.height * 0.05,
    //             ),
    //             backgroundColor: Color.fromRGBO(0, 122, 255, 1),
    //             shape: RoundedRectangleBorder(
    //               borderRadius: BorderRadius.circular(12),
    //             ),
    //             elevation: 1,
    //           ),
    //           child: Text(
    //             'Ok',
    //             style: TextStyle(
    //               fontSize: Get.textTheme.titleLarge!.fontSize,
    //               color: Colors.white,
    //             ),
    //           ),
    //         ),
    //       ],
    //     );
    //   });
    // } else {
    //   Get.back();
    // }
  }

  void firstPageShow() {
    if (box.read('listsTF')) {
      box.write('groupTF', false);
      box.write('PriorityTF', false);
      lists = 400;
      group = 200;
      priority = 200;
    } else if (box.read('groupTF')) {
      box.write('listsTF', false);
      box.write('PriorityTF', false);
      lists = 200;
      group = 400;
      priority = 200;
    } else if (box.read('PriorityTF')) {
      box.write('listsTF', false);
      box.write('groupTF', false);
      lists = 200;
      group = 200;
      priority = 400;
    }
    setState(() {});
    BackPageSettingToHome keep = BackPageSettingToHome();
    keep.keepPage = false;
    context.read<Appdata>().keepPage = keep;
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

  void logout(BuildContext context) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    // แสดง Loading Dialog
    loadingDialog();
    var responseLogot = await http.post(
      Uri.parse("$url/signin_up/api/logout"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: logoutUserPostRequestToJson(
        LogoutUserPostRequest(
          email: userEmail,
        ),
      ),
    );
    if (responseLogot.statusCode == 200) {
      Get.back();

      LogoutUserPostResponse response =
          logoutUserPostResponseFromJson(responseLogot.body);
      await googleSignIn.signOut();
      // Sign out from Firebase if needed
      await FirebaseAuth.instance.signOut();
      if (response.success) {
        Get.to(() => SplashPage());
      }
    }
  }

  String obfuscatePasswordFully(String password) {
    return '*' * password.length;
  }

  void deleteUser() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    if (box.read('password') == '-') {
      Get.defaultDialog(
        title: "",
        titlePadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        content: Builder(
          builder: (context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  children: [
                    Image.asset(
                      "assets/images/aleart/question.png",
                      height: MediaQuery.of(context).size.height * 0.1,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Text(
                      'Verify!!',
                      style: TextStyle(
                        fontSize: Get.textTheme.headlineSmall!.fontSize,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(0, 122, 255, 1),
                      ),
                    ),
                    Text(
                      'You must verify your otp email to delete this account',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: height * 0.01,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        //ส่ง OTP ไปที่ email
                        // แสดง Loading Dialog
                        loadingDialog();
                        var responseOtp = await http.post(
                          Uri.parse("$url/otp/api/otp"),
                          headers: {
                            "Content-Type": "application/json; charset=utf-8"
                          },
                          body: sendOtpPostRequestToJson(
                            SendOtpPostRequest(
                              recipient: userEmail,
                            ),
                          ),
                        );

                        if (responseOtp.statusCode == 200) {
                          Get.back();

                          SendOtpPostResponst sendOTPResponse =
                              sendOtpPostResponstFromJson(responseOtp.body);

                          //ส่ง email, otp, ref ไปยืนยันและ verify เมลหน้าต่อไป
                          verifyOTP(
                            userEmail,
                            sendOTPResponse.otp,
                            sendOTPResponse.ref,
                          );
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
                        'OK',
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
                        backgroundColor: Color.fromRGBO(231, 243, 255, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontSize: Get.textTheme.titleLarge!.fontSize,
                          color: Color.fromRGBO(0, 122, 255, 1),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    } else {
      //confirm password
      Get.defaultDialog(
        title: "",
        titlePadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        content: Builder(
          builder: (context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  children: [
                    Image.asset(
                      "assets/images/aleart/question.png",
                      height: MediaQuery.of(context).size.height * 0.1,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Text(
                      'Verify!!',
                      style: TextStyle(
                        fontSize: Get.textTheme.headlineSmall!.fontSize,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(0, 122, 255, 1),
                      ),
                    ),
                    Text(
                      'Enter your password to delete your account',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: height * 0.01,
                    ),
                    TextField(
                      controller: passwordConfirmDeleteCtl,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: !isCheckedPasswordConfirmDelete,
                      cursorColor: Colors.black,
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: isCheckedPasswordConfirmDelete
                            ? ''
                            : 'Enter your password',
                        hintStyle: TextStyle(
                          fontSize: Get.textTheme.titleMedium!.fontSize,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                        prefixIcon: SizedBox(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            isCheckedPasswordConfirmDelete =
                                !isCheckedPasswordConfirmDelete;
                            setState(() {});
                          },
                          icon: Icon(
                            isCheckedPasswordConfirmDelete
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
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
                    if (notitext || !notitext)
                      SizedBox(
                        height: height * 0.02,
                      ),
                    if (notitext)
                      Text(
                        'Invalid password',
                        style: TextStyle(
                          fontSize: Get.textTheme.titleMedium!.fontSize,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (notitext)
                      SizedBox(
                        height: height * 0.02,
                      ),
                    ElevatedButton(
                      onPressed: () {
                        if (BCrypt.checkpw(
                            passwordConfirmDeleteCtl.text, userPassword)) {
                          Get.back();
                          Get.defaultDialog(
                            title: "",
                            titlePadding: EdgeInsets.zero,
                            backgroundColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.04,
                              vertical:
                                  MediaQuery.of(context).size.height * 0.02,
                            ),
                            content: Column(
                              children: [
                                Image.asset(
                                  "assets/images/aleart/warning.png",
                                  height:
                                      MediaQuery.of(context).size.height * 0.1,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Text(
                                  'Confirm!!',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.headlineSmall!.fontSize,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromRGBO(0, 122, 255, 1),
                                  ),
                                ),
                                Text(
                                  'You confirm to delete this account',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
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
                                  var responseDelete = await http.delete(
                                    Uri.parse("$url/user/account"),
                                    headers: {
                                      "Content-Type":
                                          "application/json; charset=utf-8"
                                    },
                                    body: deleteUserDeleteRequestToJson(
                                      DeleteUserDeleteRequest(
                                        email: userEmail,
                                      ),
                                    ),
                                  );
                                  if (responseDelete.statusCode == 200) {
                                    Get.back();
                                    Get.back();

                                    Future.delayed(const Duration(seconds: 1),
                                        () async {
                                      loadingDialog();
                                      var responseLogot = await http.post(
                                        Uri.parse("$url/signin_up/api/logout"),
                                        headers: {
                                          "Content-Type":
                                              "application/json; charset=utf-8"
                                        },
                                        body: logoutUserPostRequestToJson(
                                          LogoutUserPostRequest(
                                            email: userEmail,
                                          ),
                                        ),
                                      );
                                      if (responseLogot.statusCode == 200) {
                                        await googleSignIn.signOut();
                                        // Sign out from Firebase if needed
                                        await FirebaseAuth.instance.signOut();
                                      }

                                      Get.to(() => SplashPage());
                                      box.remove('email');
                                      box.remove('password');
                                    });
                                  } else {
                                    Get.back();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width,
                                    MediaQuery.of(context).size.height * 0.05,
                                  ),
                                  backgroundColor:
                                      Color.fromRGBO(0, 122, 255, 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                ),
                                child: Text(
                                  'Confirm',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  passwordConfirmDeleteCtl.clear();
                                  Get.back();
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width,
                                    MediaQuery.of(context).size.height * 0.05,
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 239, 96, 86),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          notitext = true;
                          setState(() {});
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
                        'OK',
                        style: TextStyle(
                          fontSize: Get.textTheme.titleLarge!.fontSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        notitext = false;
                        setState(() {});
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize: Size(
                          MediaQuery.of(context).size.width,
                          MediaQuery.of(context).size.height * 0.05,
                        ),
                        backgroundColor: Color.fromRGBO(231, 243, 255, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontSize: Get.textTheme.titleLarge!.fontSize,
                          color: Color.fromRGBO(0, 122, 255, 1),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    }
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
      var responseDelete = await http.delete(
        Uri.parse("$url/user/account"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: deleteUserDeleteRequestToJson(
          DeleteUserDeleteRequest(
            email: userEmail,
          ),
        ),
      );
      if (responseDelete.statusCode == 200) {
        Get.back();
        Get.back();

        Future.delayed(const Duration(seconds: 1), () async {
          loadingDialog();
          var responseLogot = await http.post(
            Uri.parse("$url/signin_up/api/logout"),
            headers: {"Content-Type": "application/json; charset=utf-8"},
            body: logoutUserPostRequestToJson(
              LogoutUserPostRequest(
                email: userEmail,
              ),
            ),
          );
          if (responseLogot.statusCode == 200) {
            Get.back();
            await googleSignIn.signOut();
            // Sign out from Firebase if needed
            await FirebaseAuth.instance.signOut();
          }

          Get.to(() => SplashPage());
          box.remove('email');
          box.remove('password');
        });
      } else {
        Get.back();
      }
    } else {
      warning = 'F21F1F';
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
