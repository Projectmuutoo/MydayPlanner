import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/editProfileUserPutRequest.dart';
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ---------------------- 🧠 Logic / Data ----------------------
  var box = GetStorage();
  final storage = FlutterSecureStorage();
  late Future<void> loadData;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ImagePicker picker = ImagePicker();

  // ---------------------- 🧍‍♂️ User Info ----------------------
  String name = '';
  String userEmail = '';
  String userProfile = '';
  String warning = '';
  String textNotification = '';

  // ---------------------- 🧮 State / Counter ----------------------
  int private = 400;
  int group = 200;
  int itemCount = 1;
  int countToRequest = 1;

  // ---------------------- 🎛️ UI State ----------------------
  bool isLoadings = true;
  bool showShimmer = true;
  bool notitext = false;
  bool isTyping = false;
  bool isTypingPassword = false;
  bool isCheckedPassword = false;
  bool isTogglePushNotification = false;
  bool isToggleEmailNotification = false;
  bool isConfirmMatched = false;
  bool hasSuccess = false;
  bool isChangePassword = false;
  bool loginWithGoogle = false;

  // ---------------------- 🎯 Controllers ----------------------
  TextEditingController editNameCtl = TextEditingController();
  TextEditingController currentPasswordCtl = TextEditingController();
  TextEditingController newPasswordCtl = TextEditingController();
  TextEditingController confirmPasswordCtl = TextEditingController();
  TextEditingController conFirmDeleteCtl = TextEditingController();

  // ---------------------- 👁️ Focus Nodes ----------------------
  FocusNode editNameFocusNode = FocusNode();
  FocusNode currentPasswordCtlFocusNode = FocusNode();
  FocusNode newPasswordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();
  FocusNode conFirmDeleteFocusNode = FocusNode();

  // ---------------------- 🖼️ Image / File ----------------------
  XFile? image;
  File? savedFile;

  // 📋 Global Keys
  GlobalKey iconKey = GlobalKey();
  late String url;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

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

  Future<void> loadDataAsync() async {
    name = box.read('userProfile')['name'];
    userEmail = box.read('userProfile')['email'];
    userProfile = box.read('userProfile')['profile'];
    var result = await FirebaseFirestore.instance
        .collection('usersLogin')
        .doc(userEmail)
        .get();
    final data = result.data();
    if (data != null) {
      isChangePassword = data['changePassword'] == true;
      loginWithGoogle = data['loginWithGoogle'] == true;
    }
    if (mounted) {
      setState(() {
        isLoadings = false;
        showShimmer = false;
      });
    }
  }

  @override
  void dispose() {
    editNameCtl.dispose();
    currentPasswordCtl.dispose();
    newPasswordCtl.dispose();
    confirmPasswordCtl.dispose();
    conFirmDeleteCtl.dispose();
    editNameFocusNode.dispose();
    currentPasswordCtlFocusNode.dispose();
    newPasswordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    conFirmDeleteFocusNode.dispose();
    super.dispose();
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
            if (!mounted) return;
            setState(() {
              itemCount = name.isEmpty ? 1 : name.length;
            });
          });
        }
        editNameCtl.addListener(() {
          if (context.mounted) {
            if (!mounted) return;
            setState(() {
              isTyping = editNameCtl.text.isNotEmpty;
            });
          }
        });
        return GestureDetector(
          onTap: () {
            if (editNameFocusNode.hasFocus) {
              editNameFocusNode.unfocus();
            }
            isTyping = false;
          },
          child: WillPopScope(
            onWillPop: () async {
              if (box.read('showDisplays')['groupTF'] ||
                  box.read('showDisplays')['privateTF']) {
                Navigator.pop(context, 'refresh');
              } else if (hasSuccess) {
                Navigator.pop(context, 'loadDisplays');
              } else {
                Get.back();
              }
              return false;
            },
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                foregroundColor: Colors.black,
                centerTitle: true,
                leading: InkWell(
                  onTap: () {
                    if (box.read('showDisplays')['groupTF'] ||
                        box.read('showDisplays')['privateTF']) {
                      Navigator.pop(context, 'refresh');
                    } else if (hasSuccess) {
                      Navigator.pop(context, 'loadDisplays');
                    } else {
                      Get.back();
                    }
                  },
                  child: Center(
                    child: SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);"><path d="M21 11H6.414l5.293-5.293-1.414-1.414L2.586 12l7.707 7.707 1.414-1.414L6.414 13H21z"></path></svg>',
                      height: height * 0.03,
                      width: width * 0.03,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                title: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleMedium!.fontSize!,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: width,
                              height: height * 0.05,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2F2F6),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.only(left: width * 0.03),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2A10.13 10.13 0 0 0 2 12a10 10 0 0 0 4 7.92V20h.1a9.7 9.7 0 0 0 11.8 0h.1v-.08A10 10 0 0 0 22 12 10.13 10.13 0 0 0 12 2zM8.07 18.93A3 3 0 0 1 11 16.57h2a3 3 0 0 1 2.93 2.36 7.75 7.75 0 0 1-7.86 0zm9.54-1.29A5 5 0 0 0 13 14.57h-2a5 5 0 0 0-4.61 3.07A8 8 0 0 1 4 12a8.1 8.1 0 0 1 8-8 8.1 8.1 0 0 1 8 8 8 8 0 0 1-2.39 5.64z"></path><path d="M12 6a3.91 3.91 0 0 0-4 4 3.91 3.91 0 0 0 4 4 3.91 3.91 0 0 0 4-4 3.91 3.91 0 0 0-4-4zm0 6a1.91 1.91 0 0 1-2-2 1.91 1.91 0 0 1 2-2 1.91 1.91 0 0 1 2 2 1.91 1.91 0 0 1-2 2z"></path></svg>',
                                        height: height * 0.03,
                                        fit: BoxFit.contain,
                                        color: Color(0xFF007AFF),
                                      ),
                                      SizedBox(width: width * 0.01),
                                      Text(
                                        'Account',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (savedFile != null)
                                    TextButton(
                                      onPressed: () {
                                        if (savedFile != null) {
                                          confirmInformation('', 'newUrl');
                                        }
                                      },
                                      child: Text(
                                        "Save",
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.normal,
                                          color: Color(0xFF007AFF),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: height * 0.01),
                            InkWell(
                              key: iconKey,
                              onTap: () {
                                final RenderBox renderBox =
                                    iconKey.currentContext!.findRenderObject()
                                        as RenderBox;
                                final Offset offset = renderBox.localToGlobal(
                                  Offset.zero,
                                );
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
                                      height: height * 0.05,
                                      value: 'แกลลอรี่',
                                      child: Text(
                                        'Choose Photo',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleSmall!
                                              .fontSize!,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      height: height * 0.05,
                                      value: 'เลือกไฟล์',
                                      child: Text(
                                        'Choose file',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleSmall!
                                              .fontSize!,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      height: height * 0.05,
                                      value: 'ถ่ายรูป',
                                      child: Text(
                                        'Take Photo',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleSmall!
                                              .fontSize!,
                                        ),
                                      ),
                                    ),
                                  ],
                                ).then((value) async {
                                  if (value != null) {
                                    if (value == 'แกลลอรี่') {
                                      image = await picker.pickImage(
                                        source: ImageSource.gallery,
                                      );
                                      if (image != null) {
                                        if (!mounted) return;
                                        setState(() {
                                          savedFile = File(image!.path);
                                        });
                                      }
                                    } else if (value == 'เลือกไฟล์') {
                                      FilePickerResult? result =
                                          await FilePicker.platform.pickFiles();
                                      if (result != null) {
                                        if (!mounted) return;
                                        setState(() {
                                          savedFile = File(
                                            result.files.first.path!,
                                          );
                                        });
                                      }
                                    } else if (value == 'ถ่ายรูป') {
                                      image = await picker.pickImage(
                                        source: ImageSource.camera,
                                      );
                                      if (image != null) {
                                        if (!mounted) return;
                                        setState(() {
                                          savedFile = File(image!.path);
                                        });
                                      }
                                    }
                                  }
                                });
                              },
                              child: Stack(
                                children: [
                                  savedFile != null
                                      ? Positioned(
                                          right: -width * 0.012,
                                          top: -height * 0.008,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                savedFile = null;
                                              });
                                            },
                                            child: SvgPicture.string(
                                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m16.192 6.344-4.243 4.242-4.242-4.242-1.414 1.414L10.535 12l-4.242 4.242 1.414 1.414 4.242-4.242 4.243 4.242 1.414-1.414L13.364 12l4.242-4.242z"></path></svg>',
                                              width: width * 0.06,
                                            ),
                                          ),
                                        )
                                      : SizedBox.shrink(),
                                  Container(
                                    height: height * 0.08,
                                    width: width * 0.18,
                                    decoration: BoxDecoration(
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
                                            child: userProfile == 'none-url'
                                                ? Container(
                                                    height: height * 0.08,
                                                    width: width * 0.18,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Stack(
                                                      children: [
                                                        Container(
                                                          height: height * 0.1,
                                                          decoration:
                                                              BoxDecoration(
                                                                color: Color(
                                                                  0xFFF2F2F6,
                                                                ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                        ),
                                                        Positioned(
                                                          left: 0,
                                                          right: 0,
                                                          bottom: 0,
                                                          child: SvgPicture.string(
                                                            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                            height:
                                                                height * 0.05,
                                                            fit: BoxFit.contain,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black12,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Image.network(
                                                      userProfile,
                                                      height: height * 0.08,
                                                      width: width * 0.18,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                          ),
                                        )
                                      : Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: ClipOval(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black12,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Image.file(
                                                savedFile!,
                                                height: height * 0.08,
                                                width: width * 0.18,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                  Positioned(
                                    bottom: -5,
                                    right: -10,
                                    width: width * 0.1,
                                    child: Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            height: height * 0.03,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Container(
                                            height: height * 0.025,
                                            decoration: BoxDecoration(
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
                            SizedBox(height: height * 0.02),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                width * 0.03,
                                0,
                                0,
                                height * 0.005,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Name',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize!,
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
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(
                                              20,
                                            ),
                                          ],
                                          keyboardType: TextInputType.text,
                                          cursorColor: Colors.black,
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .labelMedium!
                                                .fontSize!,
                                          ),
                                          textAlign: TextAlign.end,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            hintText: isTyping
                                                ? 'Enter your name'
                                                : name,
                                            hintStyle: TextStyle(
                                              fontSize: Get
                                                  .textTheme
                                                  .labelMedium!
                                                  .fontSize!,
                                              fontWeight: FontWeight.normal,
                                              color: Color(0xFF000000),
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
                                                    fontSize: Get
                                                        .textTheme
                                                        .labelMedium!
                                                        .fontSize!,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: Color(0xFF007AFF),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  isTyping = true;
                                                });
                                              },
                                              child: SvgPicture.string(
                                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                                height: height * 0.03,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                width * 0.03,
                                height * 0.01,
                                0,
                                height * 0.005,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Password',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize!,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: changePassword,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(6),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: height * 0.035,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.02,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(6),
                                        ),
                                        border: Border.all(
                                          width: 0.5,
                                          color: Colors.black38,
                                        ),
                                      ),
                                      child: Text(
                                        isChangePassword
                                            ? 'Change password'
                                            : 'Add password',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .labelMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: height * 0.01),
                            Container(
                              width: width,
                              height: height * 0.05,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2F2F6),
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
                                    color: Color(0xFFFF3A31),
                                  ),
                                  SizedBox(width: width * 0.01),
                                  Text(
                                    'My notifications',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize!,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mobile push notifications',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          text: 'Receive push notifications\n',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .labelMedium!
                                                .fontSize!,
                                            fontWeight: FontWeight.normal,
                                            color: Color(0xFF979595),
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'via your mobile app.',
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .labelMedium!
                                                    .fontSize!,
                                                fontWeight: FontWeight.normal,
                                                height: 0.9,
                                                color: Color(0xFF979595),
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
                                        setState(() {
                                          isTogglePushNotification =
                                              !isTogglePushNotification;
                                        });
                                      },
                                      icon: Icon(
                                        isTogglePushNotification
                                            ? Icons.toggle_on_outlined
                                            : Icons.toggle_off_outlined,
                                        color: isTogglePushNotification
                                            ? Color(0xFF007AFF)
                                            : Colors.grey,
                                      ),
                                      iconSize: height * 0.04,
                                    ),
                                    SizedBox(width: width * 0.02),
                                  ],
                                ),
                              ],
                            ),
                            Divider(thickness: 1, indent: 10, endIndent: 10),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Send email notifications',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          text: 'Receive send notifications\n',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .labelMedium!
                                                .fontSize!,
                                            fontWeight: FontWeight.normal,
                                            color: Color(0xFF979595),
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'via your email.',
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .labelMedium!
                                                    .fontSize!,
                                                fontWeight: FontWeight.normal,
                                                height: 0.9,
                                                color: Color(0xFF979595),
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
                                        setState(() {
                                          isToggleEmailNotification =
                                              !isToggleEmailNotification;
                                        });
                                      },
                                      icon: Icon(
                                        isToggleEmailNotification
                                            ? Icons.toggle_on_outlined
                                            : Icons.toggle_off_outlined,
                                        color: isToggleEmailNotification
                                            ? Color(0xFF007AFF)
                                            : Colors.grey,
                                      ),
                                      iconSize: height * 0.04,
                                    ),
                                    SizedBox(width: width * 0.02),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: height * 0.02),
                            Container(
                              width: width,
                              height: height * 0.05,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2F2F6),
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
                                    color: Color(0xFF979595),
                                  ),
                                  SizedBox(width: width * 0.01),
                                  Text(
                                    'My settings',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize!,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'First page',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          text: 'Choose the home page\n',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .labelMedium!
                                                .fontSize!,
                                            fontWeight: FontWeight.normal,
                                            color: Color(0xFF979595),
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'you want.',
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .labelMedium!
                                                    .fontSize!,
                                                fontWeight: FontWeight.normal,
                                                height: 0.9,
                                                color: Color(0xFF979595),
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
                                          box.write('showDisplays', {
                                            'privateTF': true,
                                            'groupTF': false,
                                          });

                                          setState(() {
                                            private = 400;
                                            group = 200;
                                          });
                                        }
                                      },
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.02,
                                        ),
                                        decoration: BoxDecoration(
                                          color: private == 400
                                              ? Color(0xFF007AFF)
                                              : Colors.grey[private],
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'Private',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .labelMedium!
                                                .fontSize!,
                                            fontWeight: private == 400
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                            color: private == 400
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
                                          box.write('showDisplays', {
                                            'privateTF': false,
                                            'groupTF': true,
                                          });
                                          setState(() {
                                            private = 200;
                                            group = 400;
                                          });
                                        }
                                      },
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.02,
                                        ),
                                        decoration: BoxDecoration(
                                          color: group == 400
                                              ? Color(0xFF007AFF)
                                              : Colors.grey[group],
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'Groups',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .labelMedium!
                                                .fontSize!,
                                            fontWeight: group == 400
                                                ? FontWeight.w500
                                                : FontWeight.normal,
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
                            Divider(thickness: 1, indent: 10, endIndent: 10),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Delete my account',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.red,
                                        ),
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          text: 'Delete your account and\n',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .labelMedium!
                                                .fontSize!,
                                            fontWeight: FontWeight.normal,
                                            color: Color(0xFF979595),
                                          ),
                                          children: [
                                            TextSpan(
                                              text:
                                                  'also delete all your workspaces.',
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .labelMedium!
                                                    .fontSize!,
                                                fontWeight: FontWeight.normal,
                                                height: 0.9,
                                                color: Color(0xFF979595),
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
                                      onTap: deleteUser,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(6),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: height * 0.04,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.02,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(6),
                                          ),
                                          border: Border.all(
                                            width: 0.5,
                                            color: Colors.red,
                                          ),
                                        ),
                                        child: Text(
                                          'Delete my account',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .labelMedium!
                                                .fontSize!,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: height * 0.07),
                        Column(
                          children: [
                            Material(
                              color: Color(0xFFF2F2F6),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () {
                                  logout();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: height * 0.01,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sign Out',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.normal,
                                          color: Color(0xFFFF3A31),
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
              ),
            ),
          ),
        );
      },
    );
  }

  void changePassword() async {
    url = await loadAPIEndpoint();

    Get.defaultDialog(
      title: "",
      titlePadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: 0,
      ),
      content: StatefulBuilder(
        builder: (BuildContext context, setState) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  isChangePassword ? 'Change password' : 'Set password',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleMedium!.fontSize!,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF007AFF),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                Text(
                  'Use a password at least 8 letters long, or at least 8 characters long with both letters and numbers.',
                  style: TextStyle(
                    fontSize: Get.textTheme.labelMedium!.fontSize!,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                if (isChangePassword) ...[
                  Row(
                    children: [
                      Text(
                        'Enter your current password',
                        style: TextStyle(
                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: currentPasswordCtl,
                    focusNode: currentPasswordCtlFocusNode,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    cursorColor: Colors.black,
                    style: TextStyle(
                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Current password',
                      hintStyle: TextStyle(
                        fontSize: Get.textTheme.labelMedium!.fontSize!,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                      suffixIcon: currentPasswordCtl.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  currentPasswordCtl.clear();
                                });
                              },
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 16,
                              ),
                            )
                          : null,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.04,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.03,
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Row(
                    children: [
                      Text(
                        'Enter a new password',
                        style: TextStyle(
                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: newPasswordCtl,
                    focusNode: newPasswordFocusNode,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    cursorColor: Colors.black,
                    style: TextStyle(
                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                    ),
                    decoration: InputDecoration(
                      hintText: 'New password',
                      hintStyle: TextStyle(
                        fontSize: Get.textTheme.labelMedium!.fontSize!,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                      suffixIcon: newPasswordCtl.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  newPasswordCtl.clear();
                                });
                              },
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 16,
                              ),
                            )
                          : null,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.04,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.03,
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Row(
                    children: [
                      Text(
                        'Confirm your new password',
                        style: TextStyle(
                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: confirmPasswordCtl,
                    focusNode: confirmPasswordFocusNode,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    cursorColor: Colors.black,
                    style: TextStyle(
                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Confirm password',
                      hintStyle: TextStyle(
                        fontSize: Get.textTheme.labelMedium!.fontSize!,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                      suffixIcon: confirmPasswordCtl.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  confirmPasswordCtl.clear();
                                });
                              },
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 16,
                              ),
                            )
                          : null,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.04,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.03,
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
                ] else ...[
                  Row(
                    children: [
                      Text(
                        'Enter a new password',
                        style: TextStyle(
                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: newPasswordCtl,
                    focusNode: newPasswordFocusNode,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    cursorColor: Colors.black,
                    style: TextStyle(
                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                    ),
                    decoration: InputDecoration(
                      hintText: 'New password',
                      hintStyle: TextStyle(
                        fontSize: Get.textTheme.labelMedium!.fontSize!,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                      suffixIcon: newPasswordCtl.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  newPasswordCtl.clear();
                                });
                              },
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 16,
                              ),
                            )
                          : null,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.04,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.03,
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Row(
                    children: [
                      Text(
                        'Confirm your new password',
                        style: TextStyle(
                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: confirmPasswordCtl,
                    focusNode: confirmPasswordFocusNode,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    cursorColor: Colors.black,
                    style: TextStyle(
                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Confirm password',
                      hintStyle: TextStyle(
                        fontSize: Get.textTheme.labelMedium!.fontSize!,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                      suffixIcon: confirmPasswordCtl.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  confirmPasswordCtl.clear();
                                });
                              },
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 16,
                              ),
                            )
                          : null,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.04,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.03,
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
                ],
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                if (textNotification.isNotEmpty)
                  Text(
                    textNotification,
                    style: TextStyle(
                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                      color: Colors.red,
                    ),
                  ),
                if (textNotification.isNotEmpty)
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                ElevatedButton(
                  onPressed: () async {
                    final validations = [
                      if (isChangePassword)
                        if (currentPasswordCtl.text.isEmpty)
                          'Please enter your old password.',
                      if (newPasswordCtl.text.isEmpty)
                        'Please enter a password.',
                      if (!isValidPassword(newPasswordCtl.text) ||
                          !isValidPassword(confirmPasswordCtl.text))
                        'Please include additional unique characters.',
                      if (newPasswordCtl.text != confirmPasswordCtl.text)
                        'Your passwords do not match.',
                    ];

                    if (validations.isNotEmpty) {
                      setState(() => showNotification(validations.first));
                      return;
                    }

                    loadingDialog();
                    if (isChangePassword) {
                      var res = await http.put(
                        Uri.parse("$url/user/removepassword"),
                        headers: {
                          "Content-Type": "application/json; charset=utf-8",
                          "Authorization": "Bearer ${box.read('accessToken')}",
                        },
                        body: jsonEncode({
                          "oldpassword": currentPasswordCtl.text.trim(),
                          "newpassword": newPasswordCtl.text.trim(),
                        }),
                      );

                      if (res.statusCode == 403) {
                        await loadNewRefreshToken();
                        res = await http.put(
                          Uri.parse("$url/user/removepassword"),
                          headers: {
                            "Content-Type": "application/json; charset=utf-8",
                            "Authorization":
                                "Bearer ${box.read('accessToken')}",
                          },
                          body: jsonEncode({
                            "oldpassword": currentPasswordCtl.text.trim(),
                            "newpassword": newPasswordCtl.text.trim(),
                          }),
                        );
                      }

                      if (res.statusCode == 401) {
                        Get.back();
                        setState(() => showNotification('Incorrect password.'));
                      }
                      if (res.statusCode == 200) {
                        Get.back();
                        Get.back();

                        setState(() {
                          hasSuccess = true;
                        });
                        FirebaseFirestore.instance
                            .collection('usersLogin')
                            .doc(userEmail)
                            .update({'changePassword': true});
                      }
                    } else {
                      var res = await updateProfile(
                        name: '',
                        password: newPasswordCtl.text.trim(),
                        profile: '',
                      );
                      if (res.statusCode == 200) {
                        Get.back();
                        Get.back();

                        setState(() {
                          hasSuccess = true;
                        });
                        FirebaseFirestore.instance
                            .collection('usersLogin')
                            .doc(userEmail)
                            .update({'changePassword': true});
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height * 0.03,
                    ),
                    backgroundColor: Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                  child: Text(
                    isChangePassword ? 'Change password' : 'Set password',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleSmall!.fontSize!,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isChangePassword && loginWithGoogle)
                  ElevatedButton(
                    onPressed: removePassword,
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(MediaQuery.of(context).size.width, 0),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    child: Text(
                      'Remove password',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleSmall!.fontSize!,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() async {
      showNotification('');
      currentPasswordCtl.clear();
      newPasswordCtl.clear();
      confirmPasswordCtl.clear();
      isChangePassword = true;
      loadDataAsync();

      if (hasSuccess) {
        hasSuccess = false;
        if (mounted) {
          setState(() {});
        }
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
                  fontSize: Get.textTheme.titleLarge!.fontSize!,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF007AFF),
                ),
              ),
              Text(
                'Update your profile successfully',
                style: TextStyle(
                  fontSize: Get.textTheme.titleSmall!.fontSize!,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
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
                'Ok',
                style: TextStyle(
                  fontSize: Get.textTheme.titleMedium!.fontSize!,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      }
    });
    if (mounted) {
      setState(() {});
    }
  }

  void removePassword() async {
    url = await loadAPIEndpoint();
    Get.back();
    if (loginWithGoogle) {
      Get.defaultDialog(
        title: "",
        titlePadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: 0,
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, setState1) {
            return Column(
              children: [
                Text(
                  'Remove password',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleMedium!.fontSize!,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF007AFF),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                Row(
                  children: [
                    Text(
                      'Enter your current password',
                      style: TextStyle(
                        fontSize: Get.textTheme.labelMedium!.fontSize!,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: currentPasswordCtl,
                  focusNode: currentPasswordCtlFocusNode,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  cursorColor: Colors.black,
                  style: TextStyle(
                    fontSize: Get.textTheme.labelMedium!.fontSize!,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Current password',
                    hintStyle: TextStyle(
                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                    suffixIcon: currentPasswordCtl.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState1(() {
                                currentPasswordCtl.clear();
                              });
                            },
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 16,
                            ),
                          )
                        : null,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.04,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03,
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                if (textNotification.isNotEmpty)
                  Text(
                    textNotification,
                    style: TextStyle(
                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                      color: Colors.red,
                    ),
                  ),
                if (textNotification.isNotEmpty)
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                ElevatedButton(
                  onPressed: () async {
                    final validations = [
                      if (currentPasswordCtl.text.isEmpty)
                        'Please enter your old password.',
                    ];

                    if (validations.isNotEmpty) {
                      setState1(() => showNotification(validations.first));
                      return;
                    }

                    loadingDialog();
                    var res = await http.put(
                      Uri.parse("$url/user/removepassword"),
                      headers: {
                        "Content-Type": "application/json; charset=utf-8",
                        "Authorization": "Bearer ${box.read('accessToken')}",
                      },
                      body: jsonEncode({
                        "oldpassword": currentPasswordCtl.text.trim(),
                        "newpassword": '-',
                      }),
                    );

                    if (res.statusCode == 403) {
                      await loadNewRefreshToken();
                      res = await http.put(
                        Uri.parse("$url/user/removepassword"),
                        headers: {
                          "Content-Type": "application/json; charset=utf-8",
                          "Authorization": "Bearer ${box.read('accessToken')}",
                        },
                        body: jsonEncode({
                          "oldpassword": currentPasswordCtl.text.trim(),
                          "newpassword": '-',
                        }),
                      );
                    }

                    if (res.statusCode == 401) {
                      Get.back();
                      setState(() => showNotification('Incorrect password.'));
                    }
                    if (res.statusCode == 200) {
                      Get.back();
                      Get.back();

                      if (mounted) {
                        setState1(() {
                          hasSuccess = true;
                        });
                      }
                      FirebaseFirestore.instance
                          .collection('usersLogin')
                          .doc(userEmail)
                          .update({'changePassword': false});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height * 0.04,
                    ),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                  child: Text(
                    'Remove password',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleMedium!.fontSize!,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ).whenComplete(() async {
        showNotification('');
        currentPasswordCtl.clear();
        isChangePassword = false;
        loadDataAsync();

        if (hasSuccess) {
          hasSuccess = false;
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
                    fontSize: Get.textTheme.titleLarge!.fontSize!,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF007AFF),
                  ),
                ),
                Text(
                  'Update your profile successfully',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleSmall!.fontSize!,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Get.back(),
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
                  'Ok',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleMedium!.fontSize!,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        }
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  void showNotification(String message) {
    setState(() {
      textNotification = message;
    });
  }

  bool isValidPassword(String password) {
    if (password.length < 8) return false;

    // นับจำนวนตัวเลขและตัวพิมพ์เล็กรวมกัน
    int count = RegExp(r'[0-9a-z]').allMatches(password).length;

    return count >= 8;
  }

  Future<http.Response> updateProfile({
    required String name,
    required String password,
    required String profile,
  }) async {
    var res = await http.put(
      Uri.parse("$url/user/profile"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: editProfileUserPutRequestToJson(
        EditProfileUserPutRequest(
          name: name,
          password: password,
          profile: profile,
        ),
      ),
    );

    if (res.statusCode == 403) {
      await loadNewRefreshToken();
      res = await http.put(
        Uri.parse("$url/user/profile"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: editProfileUserPutRequestToJson(
          EditProfileUserPutRequest(
            name: name,
            password: password,
            profile: profile,
          ),
        ),
      );
    }
    return res;
  }

  void confirmInformation(String newName, String newUrl) async {
    url = await loadAPIEndpoint();

    loadingDialog();

    // 1. เปลี่ยนชื่อ
    if (newName.isNotEmpty) {
      if (editNameCtl.text.isEmpty) {
        Get.back();
        setState(() => showNotification('Please enter your name'));
        return;
      }
      setState(() => showNotification(''));
      var res = await updateProfile(
        name: editNameCtl.text.trim(),
        password: '',
        profile: '',
      );
      if (res.statusCode == 200) {
        hasSuccess = true;
        name = editNameCtl.text.trim();
        editNameCtl.clear();
        context.read<Appdata>().changeMyProfileProvider.setName(name);
        // ดึงข้อมูล userProfile ปัจจุบันจาก box
        Map<String, dynamic> currentUserProfile = Map<String, dynamic>.from(
          box.read('userProfile'),
        );
        // แก้ไขเฉพาะค่า profile
        currentUserProfile['name'] = name;
        // เขียนกลับไปที่ box
        box.write('userProfile', currentUserProfile);
      } else {
        hasSuccess = false;
        editNameCtl.clear();
      }
    }

    // 2. เปลี่ยนรูปโปรไฟล์
    if (newUrl.isNotEmpty && savedFile != null) {
      String downloadUrl = "";

      final storageReference = FirebaseStorage.instance.ref().child(
        'uploadsImageProfile/${DateTime.now().millisecondsSinceEpoch}_${savedFile!.path.split('/').last}',
      );

      final uploadTask = storageReference.putFile(savedFile!);
      final snapshot = await uploadTask;
      downloadUrl = await snapshot.ref.getDownloadURL();

      if (userProfile.isNotEmpty &&
          userProfile != 'none-url' &&
          userProfile.contains("firebasestorage.googleapis.com")) {
        final oldRef = FirebaseStorage.instance.refFromURL(userProfile);
        String oldUrl = await oldRef.getDownloadURL();
        if (userProfile == oldUrl) {
          await oldRef.delete();
        }
      }

      var res = await updateProfile(
        name: '',
        password: '',
        profile: downloadUrl,
      );

      if (res.statusCode == 200) {
        hasSuccess = true;
        savedFile = null;
        userProfile = downloadUrl;
        context.read<Appdata>().changeMyProfileProvider.setProfile(userProfile);
        // ดึงข้อมูล userProfile ปัจจุบันจาก box
        Map<String, dynamic> currentUserProfile = Map<String, dynamic>.from(
          box.read('userProfile'),
        );
        // แก้ไขเฉพาะค่า profile
        currentUserProfile['profile'] = downloadUrl;
        // เขียนกลับไปที่ box
        box.write('userProfile', currentUserProfile);
      } else {
        hasSuccess = false;
        savedFile = null;
      }
    }

    // แสดงผลลัพธ์
    Get.back();
    if (hasSuccess) {
      setState(() {
        isTyping = false;
        isTypingPassword = false;
        isCheckedPassword = false;
      });

      editNameFocusNode.unfocus();
      Future.delayed(Duration(milliseconds: 500), () {
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
                  fontSize: Get.textTheme.titleLarge!.fontSize!,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF007AFF),
                ),
              ),
              Text(
                'Update your profile successfully',
                style: TextStyle(
                  fontSize: Get.textTheme.titleSmall!.fontSize!,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
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
                'Ok',
                style: TextStyle(
                  fontSize: Get.textTheme.titleMedium!.fontSize!,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      });
    }
  }

  void firstPageShow() {
    setState(() {
      if (box.read('showDisplays')['privateTF']) {
        box.write('showDisplays', {'privateTF': true, 'groupTF': false});
        private = 400;
        group = 200;
      } else if (box.read('showDisplays')['groupTF']) {
        box.write('showDisplays', {'privateTF': false, 'groupTF': true});
        private = 200;
        group = 400;
      }
    });
  }

  void loadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        content: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }

  void logout() async {
    try {
      url = await loadAPIEndpoint();
      loadingDialog();
      var responseLogout = await http.post(
        Uri.parse("$url/auth/signout"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );

      if (responseLogout.statusCode == 403) {
        await loadNewRefreshToken();
        responseLogout = await http.post(
          Uri.parse("$url/auth/signout"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
        );
      }

      await _performCleanup();
    } catch (e) {
      await _performCleanup();
    }
  }

  Future<void> _performCleanup() async {
    final userProfile = box.read('userProfile');
    if (userProfile != null && userProfile['email'] != null) {
      await FirebaseFirestore.instance
          .collection('usersLogin')
          .doc(userProfile['email'])
          .update({'deviceName': FieldValue.delete()});
    }

    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      await storage.deleteAll();
      await box.remove('userDataAll');
      await box.remove('userLogin');
      await box.remove('userProfile');
      await box.remove('accessToken');
      Get.back();
      Get.offAll(() => SplashPage(), arguments: {'fromLogout': true});
    } catch (e) {
      Get.offAll(() => SplashPage(), arguments: {'fromLogout': true});
    }
  }

  String obfuscatePasswordFully(String password) {
    return '*' * password.length;
  }

  void deleteUser() async {
    url = await loadAPIEndpoint();
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    Get.defaultDialog(
      title: "",
      titlePadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: 0,
      ),
      content: Builder(
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              conFirmDeleteCtl.addListener(() {
                if (context.mounted) {
                  if (!mounted) return;
                  setState(() {});
                }
              });
              Future.delayed(Duration(microseconds: 500), () {
                conFirmDeleteFocusNode.requestFocus();
              });
              return Column(
                children: [
                  Image.asset(
                    "assets/images/aleart/question.png",
                    height: MediaQuery.of(context).size.height * 0.1,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Text(
                    'Delete this account?',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleLarge!.fontSize!,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: Get.textTheme.labelMedium!.fontSize!,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'Confirm you want to delete this account by typing its: ',
                        ),
                        TextSpan(
                          text: 'Confirm',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            height: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  TextField(
                    controller: conFirmDeleteCtl,
                    onChanged: (val) {
                      setState(() {
                        isConfirmMatched = val.trim() == 'Confirm';
                      });
                    },
                    focusNode: conFirmDeleteFocusNode,
                    keyboardType: TextInputType.text,
                    cursorColor: Colors.black,
                    style: TextStyle(
                      fontSize: Get.textTheme.titleSmall!.fontSize!,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Confirm',
                      hintStyle: TextStyle(
                        fontSize: Get.textTheme.titleSmall!.fontSize!,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: width * 0.02,
                        vertical: height * 0.01,
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
                  ElevatedButton(
                    onPressed: isConfirmMatched
                        ? () async {
                            if (conFirmDeleteFocusNode.hasFocus) {
                              conFirmDeleteFocusNode.unfocus();
                            }
                            loadingDialog();
                            var responseLogout = await http.post(
                              Uri.parse("$url/auth/signout"),
                              headers: {
                                "Content-Type":
                                    "application/json; charset=utf-8",
                                "Authorization":
                                    "Bearer ${box.read('accessToken')}",
                              },
                            );
                            if (responseLogout.statusCode == 403) {
                              await loadNewRefreshToken();
                              responseLogout = await http.post(
                                Uri.parse("$url/auth/signout"),
                                headers: {
                                  "Content-Type":
                                      "application/json; charset=utf-8",
                                  "Authorization":
                                      "Bearer ${box.read('accessToken')}",
                                },
                              );
                            }
                            Get.back();

                            if (responseLogout.statusCode == 200) {
                              loadingDialog();
                              var responseDelete = await http.delete(
                                Uri.parse("$url/user/account"),
                                headers: {
                                  "Content-Type":
                                      "application/json; charset=utf-8",
                                  "Authorization":
                                      "Bearer ${box.read('accessToken')}",
                                },
                              );
                              Get.back();

                              if (responseDelete.statusCode == 200) {
                                await FirebaseFirestore.instance
                                    .collection('usersLogin')
                                    .doc(box.read('userProfile')['email'])
                                    .update({
                                      'deviceName': FieldValue.delete(),
                                    });
                                await box.erase();
                                await googleSignIn.signOut();
                                await FirebaseAuth.instance.signOut();
                                await storage.deleteAll();
                                Get.offAll(
                                  () => SplashPage(),
                                  arguments: {'fromLogout': true},
                                );
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(
                        MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height * 0.05,
                      ),
                      backgroundColor: isConfirmMatched
                          ? Colors.red
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize!,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        notitext = false;
                        conFirmDeleteCtl.clear();
                        isConfirmMatched = false;
                      });
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(
                        MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height * 0.05,
                      ),
                      backgroundColor: Color.from(
                        alpha: 1,
                        red: 0.906,
                        green: 0.953,
                        blue: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleMedium!.fontSize!,
                        color: Color(0xFF007AFF),
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
    } else if (loadtoketnew.statusCode == 403 ||
        loadtoketnew.statusCode == 401) {
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
                  fontSize: Get.textTheme.headlineSmall!.fontSize!,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              Text(
                'The system has expired. Please log in again.',
                style: TextStyle(
                  fontSize: Get.textTheme.titleSmall!.fontSize!,
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
              box.remove('userDataAll');
              box.remove('userLogin');
              box.remove('userProfile');
              box.remove('accessToken');
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
                fontSize: Get.textTheme.titleMedium!.fontSize!,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
  }
}
