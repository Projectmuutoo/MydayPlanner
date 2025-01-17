import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:demomydayplanner/config/config.dart';
import 'package:demomydayplanner/models/request/deleteUserDeleteRequest.dart';
import 'package:demomydayplanner/models/request/editProfileUserPutRequest.dart';
import 'package:demomydayplanner/models/request/getUserByEmailPostRequest.dart';
import 'package:demomydayplanner/models/request/logoutUserPostRequest.dart';
import 'package:demomydayplanner/models/response/getUserByEmailPostResponst.dart';
import 'package:demomydayplanner/models/response/logoutUserPostResponse.dart';
import 'package:demomydayplanner/pages/login.dart';
import 'package:demomydayplanner/pages/pageMember/home.dart';
import 'package:demomydayplanner/pages/pageMember/navBar.dart';
import 'package:demomydayplanner/pages/splash.dart';
import 'package:demomydayplanner/shared/appData.dart';
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
  var box = GetStorage();
  late Future<void> loadData;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  TextEditingController editNameCtl = TextEditingController();
  TextEditingController editPasswordCtl = TextEditingController();
  TextEditingController passwordVerifyCtl = TextEditingController();
  int lists = 400;
  int group = 200;
  int priority = 200;
  String name = '';
  String userEmail = '';
  String userProfile = '';
  String userPassword = '';
  int itemCount = 1;
  bool isLoadings = true;
  bool showShimmer = true;
  bool editInformation = false;
  final ImagePicker picker = ImagePicker();
  XFile? image;
  File? savedFile;
  bool isTyping = false;
  bool isTypingPassword = false;
  bool isCheckedPassword = false;
  bool isCheckedPasswordVerify = false;

  @override
  void initState() {
    super.initState();

    // var re = box.getKeys();
    // for (var i in re) {
    //   log(i);
    // }
    editNameCtl.addListener(() {
      isTyping = editNameCtl.text.isNotEmpty;
      setState(() {});
    });
    editPasswordCtl.addListener(() {
      isTypingPassword = editPasswordCtl.text.isNotEmpty;
      setState(() {});
    });
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
          appBar: null,
          body: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
                vertical: height * 0.05,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
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
                      SizedBox(
                        width: width * 0.05,
                      ),
                    ],
                  ),
                  Container(
                    width: width,
                    height: height * 0.05,
                    decoration: BoxDecoration(
                      color: Color(0xffD9D9D9),
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
                          color: Colors.black,
                        ),
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
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
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
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                              ),
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    height: height * 0.1,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color(0xffd9d9d9),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    bottom: 0,
                                                    child: SvgPicture.string(
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
                                  fontSize: Get.textTheme.titleLarge!.fontSize,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xff272727),
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
                      color: Color(0xffD9D9D9),
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
                          color: Colors.black,
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
                                fontSize: Get.textTheme.titleLarge!.fontSize,
                                fontWeight: FontWeight.normal,
                                color: Color(0xff272727),
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                text: 'Choose the home page\n',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xff272727),
                                ),
                                children: [
                                  TextSpan(
                                    text: 'you want.',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.normal,
                                      height: 0.9,
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
                                color: Colors.grey[lists],
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                border:
                                    box.read('listsTF') ? Border.all() : null,
                              ),
                              child: Text(
                                'Lists',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize,
                                  fontWeight: FontWeight.normal,
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
                                color: Colors.grey[group],
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                border:
                                    box.read('groupTF') ? Border.all() : null,
                              ),
                              child: Text(
                                'Groups',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize,
                                  fontWeight: FontWeight.normal,
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
                  Container(
                    width: width,
                    height: height * 0.05,
                    decoration: BoxDecoration(
                      color: Color(0xffD9D9D9),
                      borderRadius: BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: width * 0.03),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleLarge!.fontSize,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      logout(context);
                    },
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            width * 0.03,
                            height * 0.005,
                            0,
                            height * 0.005,
                          ),
                          child: Text(
                            'Log out',
                            style: TextStyle(
                              fontSize: Get.textTheme.titleLarge!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.red,
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

            return WillPopScope(
              onWillPop: () async => false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: width * 0.05,
                  right: width * 0.05,
                  top: height * 0.02,
                  bottom: height * 0.03,
                ),
                child: SizedBox(
                  height: height,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
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
                                  savedFile = null;
                                  isTyping = false;
                                  isTypingPassword = false;
                                  editNameCtl.clear();
                                  editPasswordCtl.clear();
                                  isCheckedPassword = false;
                                  setState(() {});
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
                                  fontSize: Get.textTheme.titleLarge!.fontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                width: width * 0.05,
                              ),
                            ],
                          ),
                          SizedBox(
                            height: height * 0.02,
                          ),
                          InkWell(
                            onTap: () {
                              showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  1,
                                  height * 0.18,
                                  0,
                                  0,
                                ),
                                color: const Color.fromARGB(255, 203, 203, 203),
                                items: [
                                  PopupMenuItem(
                                    value: 'แกลลอรี่',
                                    child: Text(
                                      'Choose Photo',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'เลือกไฟล์',
                                    child: Text(
                                      'Choose file',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'ถ่ายรูป',
                                    child: Text(
                                      'Take Photo',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
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
                                      setState(() {
                                        savedFile = File(image!.path);
                                      });
                                    }
                                  } else if (value == 'เลือกไฟล์') {
                                    FilePickerResult? result =
                                        await FilePicker.platform.pickFiles();
                                    if (result != null) {
                                      setState(() {
                                        savedFile =
                                            File(result.files.first.path!);
                                      });
                                    }
                                  } else if (value == 'ถ่ายรูป') {
                                    image = await picker.pickImage(
                                        source: ImageSource.camera);
                                    if (image != null) {
                                      setState(() {
                                        savedFile = File(image!.path);
                                      });
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
                                      color: Color(0xffd9d9d9),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  savedFile == null
                                      ? Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: ClipOval(
                                            child: userProfile == 'none-url'
                                                ? Container(
                                                    height: height * 0.1,
                                                    width: width * 0.22,
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
                                                            color: Color(
                                                                0xffd9d9d9),
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
                                                            height:
                                                                height * 0.07,
                                                            fit: BoxFit.contain,
                                                            color: Colors.grey,
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
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Container(
                                            height: height * 0.025,
                                            decoration: const BoxDecoration(
                                              color: Color(0xffd9d9d9),
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
                                      confirmInformation();
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Name',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: width * 0.6,
                                    child: TextField(
                                      controller: editNameCtl,
                                      keyboardType: TextInputType.text,
                                      cursorColor: Colors.black,
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleSmall!.fontSize,
                                      ),
                                      textAlign: TextAlign.end,
                                      decoration: InputDecoration(
                                        hintText:
                                            isTyping ? 'Enter your name' : name,
                                        hintStyle: TextStyle(
                                          fontSize: Get
                                              .textTheme.titleSmall!.fontSize,
                                          fontWeight: FontWeight.normal,
                                          color: const Color.fromARGB(
                                              255, 0, 0, 0),
                                        ),
                                        constraints: BoxConstraints(
                                          maxHeight: height * 0.05,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
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
                                            confirmInformation();
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
                                                fontWeight: FontWeight.normal,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        )
                                      : InkWell(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Email address',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleSmall!.fontSize,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: width * 0.6,
                                    child: TextField(
                                      controller: editPasswordCtl,
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      obscureText: !isCheckedPassword,
                                      cursorColor: Colors.black,
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleSmall!.fontSize,
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
                                          fontSize: Get
                                              .textTheme.titleSmall!.fontSize,
                                          fontWeight: FontWeight.normal,
                                          color: const Color.fromARGB(
                                              255, 0, 0, 0),
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
                                                return;
                                              }

                                              Get.defaultDialog(
                                                title: "",
                                                barrierDismissible: true,
                                                titlePadding: EdgeInsets.zero,
                                                backgroundColor: Colors.white,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  horizontal: width * 0.02,
                                                  vertical: height * 0.02,
                                                ),
                                                content: Column(
                                                  children: [
                                                    Text(
                                                      'Enter your password to verify your identity',
                                                      style: TextStyle(
                                                        fontSize: Get
                                                            .textTheme
                                                            .titleMedium!
                                                            .fontSize,
                                                        color: Colors.black,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    SizedBox(
                                                      height: height * 0.03,
                                                    ),
                                                    TextField(
                                                      controller:
                                                          passwordVerifyCtl,
                                                      keyboardType:
                                                          TextInputType
                                                              .visiblePassword,
                                                      obscureText:
                                                          !isCheckedPasswordVerify,
                                                      cursorColor: Colors.black,
                                                      style: TextStyle(
                                                        fontSize: Get
                                                            .textTheme
                                                            .titleMedium!
                                                            .fontSize,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: isTyping
                                                            ? ''
                                                            : 'Enter your password',
                                                        hintStyle: TextStyle(
                                                          fontSize: Get
                                                              .textTheme
                                                              .titleMedium!
                                                              .fontSize,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          color: const Color
                                                              .fromARGB(
                                                              255, 0, 0, 0),
                                                        ),
                                                        prefixIcon: SizedBox(),
                                                        suffixIcon: IconButton(
                                                          onPressed: () {
                                                            isCheckedPasswordVerify =
                                                                !isCheckedPasswordVerify;
                                                            setState(() {});
                                                          },
                                                          icon: Icon(
                                                            isCheckedPasswordVerify
                                                                ? Icons
                                                                    .visibility
                                                                : Icons
                                                                    .visibility_off,
                                                            color: const Color(
                                                                0xff7B7B7B),
                                                          ),
                                                        ),
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                          horizontal:
                                                              width * 0.02,
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              const BorderSide(
                                                            width: 0.5,
                                                          ),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              const BorderSide(
                                                            width: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
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
                                                          } else {}
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          fixedSize: Size(
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.3,
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.05,
                                                          ),
                                                          backgroundColor:
                                                              Color(0xffD5843D),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Confirm',
                                                          style: TextStyle(
                                                            fontSize: Get
                                                                .textTheme
                                                                .titleMedium!
                                                                .fontSize,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Get.back();
                                                          isCheckedPassword =
                                                              false;
                                                          setState(() {});
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          fixedSize: Size(
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.3,
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.05,
                                                          ),
                                                          backgroundColor:
                                                              const Color
                                                                  .fromARGB(255,
                                                                  212, 68, 68),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Cancel',
                                                          style: TextStyle(
                                                            fontSize: Get
                                                                .textTheme
                                                                .titleMedium!
                                                                .fontSize,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            isCheckedPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: const Color(0xff7B7B7B),
                                          ),
                                        ),
                                        constraints: BoxConstraints(
                                          maxHeight: height * 0.05,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
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
                                            confirmInformation();
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
                                                fontWeight: FontWeight.normal,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        )
                                      : InkWell(
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
                          InkWell(
                            onTap: deleteUser,
                            child: Text(
                              'Delete account',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize,
                                fontWeight: FontWeight.normal,
                                color: Colors.red,
                              ),
                            ),
                          )
                        ],
                      )
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

  void confirmInformation() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    String downloadUrl = "";
    loadingDialog();
    if (savedFile != null) {
      // สร้างอ้างอิงไปยัง Firebase Storage
      Reference storageReference = FirebaseStorage.instance.ref().child(
          'uploadsImageProfile/${DateTime.now().millisecondsSinceEpoch}_${savedFile!.path.split('/').last}');

      // อัพโหลดไฟล์และรอจนกว่าจะเสร็จสิ้น
      UploadTask uploadTask = storageReference.putFile(savedFile!);
      TaskSnapshot taskSnapshot = await uploadTask;

      // รับ URL ของรูปที่อัพโหลดสำเร็จ
      downloadUrl = await taskSnapshot.ref.getDownloadURL();
      // ลบรูปเดิมหากมี
      if (userProfile.isNotEmpty && userProfile != 'none-url') {
        Reference oldImageRef =
            FirebaseStorage.instance.refFromURL(userProfile);
        await oldImageRef.delete();
      }
    }

    var responseEditProfile = await http.put(
      Uri.parse("$url/profile/api/edit_profile"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: editProfileUserPutRequestToJson(
        EditProfileUserPutRequest(
          email: userEmail,
          profileData: ProfileData(
            name: editNameCtl.text.isNotEmpty ? editNameCtl.text : name,
            hashedPassword: editPasswordCtl.text.isNotEmpty
                ? editPasswordCtl.text
                : userPassword == '-'
                    ? '-'
                    : box.read('password'),
            profile: savedFile != null ? downloadUrl : userProfile,
          ),
        ),
      ),
    );
    if (responseEditProfile.statusCode == 200) {
      Get.back();
      box.write('password', editPasswordCtl.text);
      savedFile = null;
      isTyping = false;
      isTypingPassword = false;
      editNameCtl.clear();
      editPasswordCtl.clear();
      isCheckedPassword = false;
      loadDataAsync();
      setState(() {});

      BackPageSettingToHome keep = BackPageSettingToHome();
      keep.keepPage = true;
      context.read<Appdata>().keepPage = keep;

      double width = MediaQuery.of(context).size.width;
      double height = MediaQuery.of(context).size.height;

      Get.defaultDialog(
        title: "",
        barrierDismissible: true,
        titlePadding: EdgeInsets.zero,
        backgroundColor: Color(0xff494949),
        contentPadding: EdgeInsets.symmetric(
          horizontal: width * 0.02,
          vertical: height * 0.02,
        ),
        content: Column(
          children: [
            Text(
              'Update your profile successfully.',
              style: TextStyle(
                fontSize: Get.textTheme.titleMedium!.fontSize,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: height * 0.02,
            )
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(
                    MediaQuery.of(context).size.width * 0.3,
                    MediaQuery.of(context).size.height * 0.05,
                  ),
                  backgroundColor: const Color(0xffD5843D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Ok',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleMedium!.fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      Get.back();
    }
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
            color: Color(0xffCDBEAE),
          ),
        ),
      ),
    );
  }

  void logout(BuildContext context) async {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    Get.defaultDialog(
      title: "",
      barrierDismissible: true,
      titlePadding: EdgeInsets.zero,
      backgroundColor: Color(0xff494949),
      contentPadding: EdgeInsets.symmetric(
        horizontal: width * 0.02,
        vertical: height * 0.02,
      ),
      content: Column(
        children: [
          Text(
            'Log out account',
            style: TextStyle(
              fontSize: Get.textTheme.headlineSmall!.fontSize,
              color: Colors.white,
            ),
          ),
          SizedBox(
            height: height * 0.02,
          )
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            // แสดง Loading Dialog
            loadingDialog();
            var responseLogot = await http.post(
              Uri.parse("$url/signin_up/api/logout"),
              headers: {"Content-Type": "application/json; charset=utf-8"},
              body: logoutUserPostRequestToJson(
                LogoutUserPostRequest(
                  email: box.read('email'),
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
          },
          style: ElevatedButton.styleFrom(
            fixedSize: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.05,
            ),
            backgroundColor: const Color(0xffD5843D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Log out',
            style: TextStyle(
              fontSize: Get.textTheme.titleMedium!.fontSize,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
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

    Get.defaultDialog(
      title: "",
      barrierDismissible: true,
      titlePadding: EdgeInsets.zero,
      backgroundColor: Color(0xff494949),
      contentPadding: EdgeInsets.symmetric(
        horizontal: width * 0.02,
        vertical: height * 0.02,
      ),
      content: Column(
        children: [
          Text(
            'You confirm to delete this account',
            style: TextStyle(
              fontSize: Get.textTheme.titleMedium!.fontSize,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: height * 0.02,
          )
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () async {
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

                  Future.delayed(const Duration(seconds: 4), () async {
                    var responseLogot = await http.post(
                      Uri.parse("$url/signin_up/api/logout"),
                      headers: {
                        "Content-Type": "application/json; charset=utf-8"
                      },
                      body: logoutUserPostRequestToJson(
                        LogoutUserPostRequest(
                          email: box.read('email'),
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

                  Get.defaultDialog(
                    title: "",
                    barrierDismissible: true,
                    titlePadding: EdgeInsets.zero,
                    backgroundColor: Color(0xff494949),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: width * 0.02,
                      vertical: height * 0.02,
                    ),
                    content: Column(
                      children: [
                        Text(
                          'You delete this account successfully.',
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else {
                  Get.back();
                }
              },
              style: ElevatedButton.styleFrom(
                fixedSize: Size(
                  MediaQuery.of(context).size.width * 0.3,
                  MediaQuery.of(context).size.height * 0.05,
                ),
                backgroundColor: Color(0xffD5843D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirm',
                style: TextStyle(
                  fontSize: Get.textTheme.titleMedium!.fontSize,
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
                  MediaQuery.of(context).size.width * 0.3,
                  MediaQuery.of(context).size.height * 0.05,
                ),
                backgroundColor: const Color.fromARGB(255, 212, 68, 68),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: Get.textTheme.titleMedium!.fontSize,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
