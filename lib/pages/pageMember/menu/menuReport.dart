import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/sendReportPostRequest.dart';
import 'package:mydayplanner/splash.dart';

class MenureportPage extends StatefulWidget {
  const MenureportPage({super.key});

  @override
  State<MenureportPage> createState() => _MenureportPageState();
}

class _MenureportPageState extends State<MenureportPage> {
  bool openSubject = false;
  var box = GetStorage();
  final storage = FlutterSecureStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  String? selectedSubject;
  int selectedIndex = 0;
  TextEditingController detailsCtl = TextEditingController();
  FocusNode detailsFocusNode = FocusNode();
  Timer? _debounce;
  late String url;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    detailsCtl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    detailsCtl.removeListener(_onTextChanged);
    detailsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (openSubject) {
            openSubject = false;
          }
        });
        if (detailsFocusNode.hasFocus) {
          detailsFocusNode.unfocus();
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          Get.back();
          openSubject = false;
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
                Get.back();
                openSubject = false;
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
              'Send Report',
              style: TextStyle(
                fontSize: Get.textTheme.titleLarge!.fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    selectedSubject != null && detailsCtl.text.isNotEmpty
                        ? () {
                          sendSubmit(selectedSubject, detailsCtl.text);
                          if (detailsFocusNode.hasFocus) {
                            detailsFocusNode.unfocus();
                          }
                        }
                        : null,
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleLarge!.fontSize,
                    fontWeight: FontWeight.w500,
                    color:
                        selectedSubject != null && detailsCtl.text.isNotEmpty
                            ? Color(0xFF4790EB)
                            : Colors.grey,
                  ),
                ),
              ),
              SizedBox(width: width * 0.02),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: width * 0.03,
                                        ),
                                        child: Text(
                                          'Subject',
                                          style: TextStyle(
                                            fontSize:
                                                Get
                                                    .textTheme
                                                    .titleLarge!
                                                    .fontSize,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: width,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF2F2F6),
                                      borderRadius:
                                          openSubject
                                              ? BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              )
                                              : BorderRadius.circular(12),
                                      border:
                                          openSubject
                                              ? Border(
                                                bottom: BorderSide(
                                                  width: 2,
                                                  color: Color(0xFFF2F2F6),
                                                ),
                                              )
                                              : null,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius:
                                            openSubject
                                                ? BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                )
                                                : BorderRadius.circular(12),
                                        onTap: () {
                                          setState(() {
                                            openSubject = !openSubject;
                                          });
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.04,
                                            vertical: height * 0.01,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                selectedSubject ??
                                                    "Selete Subject",
                                                style: TextStyle(
                                                  fontSize:
                                                      Get
                                                          .textTheme
                                                          .titleLarge!
                                                          .fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      selectedSubject == null
                                                          ? Colors.grey
                                                          : Color(0xFF4790EB),
                                                ),
                                              ),
                                              SvgPicture.string(
                                                !openSubject
                                                    ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"/></svg>'
                                                    : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M16.293 9.293 12 13.586 7.707 9.293l-1.414 1.414L12 16.414l5.707-5.707z"/></svg>',
                                                width: width * 0.035,
                                                height: height * 0.035,
                                                color: Colors.grey,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.02),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: width * 0.03,
                                    ),
                                    child: Text(
                                      'Details',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleLarge!.fontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: height * 0.3,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF2F2F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.03,
                                      vertical: height * 0.01,
                                    ),
                                    child: TextField(
                                      controller: detailsCtl,
                                      focusNode: detailsFocusNode,
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                      expands: true,
                                      maxLength: 500,
                                      cursorColor: Color(0xFF4790EB),
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Describe your issue...',
                                        hintStyle: TextStyle(
                                          fontSize:
                                              Get
                                                  .textTheme
                                                  .titleMedium!
                                                  .fontSize,
                                          fontWeight: FontWeight.normal,
                                          color:
                                              detailsCtl.text.isNotEmpty
                                                  ? Colors.black
                                                  : Colors.grey,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.01),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.02,
                                    ),
                                    child: Text(
                                      'When you send us feedback, we collect it and we do not reply to feedback, but read all feedback.',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleSmall!.fontSize,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (openSubject)
                                Positioned(
                                  top: height * 0.09,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    width: width,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF2F2F6),
                                      borderRadius:
                                          openSubject
                                              ? BorderRadius.vertical(
                                                bottom: Radius.circular(12),
                                              )
                                              : BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              setState(() {
                                                selectedSubject = 'Suggestions';
                                                openSubject = false;
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.04,
                                                vertical: height * 0.01,
                                              ),
                                              child: Row(
                                                children: [
                                                  SvgPicture.string(
                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M9 20h6v2H9zm7.906-6.288C17.936 12.506 19 11.259 19 9c0-3.859-3.141-7-7-7S5 5.141 5 9c0 2.285 1.067 3.528 2.101 4.73.358.418.729.851 1.084 1.349.144.206.38.996.591 1.921H8v2h8v-2h-.774c.213-.927.45-1.719.593-1.925.352-.503.726-.94 1.087-1.363zm-2.724.213c-.434.617-.796 2.075-1.006 3.075h-2.351c-.209-1.002-.572-2.463-1.011-3.08a20.502 20.502 0 0 0-1.196-1.492C7.644 11.294 7 10.544 7 9c0-2.757 2.243-5 5-5s5 2.243 5 5c0 1.521-.643 2.274-1.615 3.413-.373.438-.796.933-1.203 1.512z"></path></svg>',
                                                    width: width * 0.025,
                                                    height: height * 0.025,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  SizedBox(width: width * 0.01),
                                                  Text(
                                                    "Suggestions",
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .titleMedium!
                                                              .fontSize,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(height: 10, thickness: 1),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              setState(() {
                                                selectedSubject =
                                                    'Incorrect Information';
                                                openSubject = false;
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.04,
                                                vertical: height * 0.01,
                                              ),
                                              child: Row(
                                                children: [
                                                  SvgPicture.string(
                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M11.953 2C6.465 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.493 2 11.953 2zM12 20c-4.411 0-8-3.589-8-8s3.567-8 7.953-8C16.391 4 20 7.589 20 12s-3.589 8-8 8z"></path><path d="M11 7h2v7h-2zm0 8h2v2h-2z"></path></svg>',
                                                    width: width * 0.025,
                                                    height: height * 0.025,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  SizedBox(width: width * 0.01),
                                                  Text(
                                                    "Incorrect Information",
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .titleMedium!
                                                              .fontSize,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(height: 10, thickness: 1),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              setState(() {
                                                selectedSubject =
                                                    'Problems or Issues';
                                                openSubject = false;
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.04,
                                                vertical: height * 0.01,
                                              ),
                                              child: Row(
                                                children: [
                                                  SvgPicture.string(
                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M11.001 10h2v5h-2zM11 16h2v2h-2z"></path><path d="M13.768 4.2C13.42 3.545 12.742 3.138 12 3.138s-1.42.407-1.768 1.063L2.894 18.064a1.986 1.986 0 0 0 .054 1.968A1.984 1.984 0 0 0 4.661 21h14.678c.708 0 1.349-.362 1.714-.968a1.989 1.989 0 0 0 .054-1.968L13.768 4.2zM4.661 19 12 5.137 19.344 19H4.661z"></path></svg>',
                                                    width: width * 0.025,
                                                    height: height * 0.025,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  SizedBox(width: width * 0.01),
                                                  Text(
                                                    "Problems or Issues",
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .titleMedium!
                                                              .fontSize,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(height: 10, thickness: 1),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              setState(() {
                                                selectedSubject =
                                                    'Accessibility Issues';
                                                openSubject = false;
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.04,
                                                vertical: height * 0.01,
                                              ),
                                              child: Row(
                                                children: [
                                                  SvgPicture.string(
                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><circle cx="18" cy="4" r="2"></circle><path d="m17.836 12.014-4.345.725 3.29-4.113a1 1 0 0 0-.227-1.457l-6-4a.999.999 0 0 0-1.262.125l-4 4 1.414 1.414 3.42-3.42 2.584 1.723-2.681 3.352a5.913 5.913 0 0 0-5.5.752l1.451 1.451A3.972 3.972 0 0 1 8 12c2.206 0 4 1.794 4 4 0 .739-.216 1.425-.566 2.02l1.451 1.451A5.961 5.961 0 0 0 14 16c0-.445-.053-.878-.145-1.295L17 14.181V20h2v-7a.998.998 0 0 0-1.164-.986zM8 20c-2.206 0-4-1.794-4-4 0-.739.216-1.425.566-2.02l-1.451-1.451A5.961 5.961 0 0 0 2 16c0 3.309 2.691 6 6 6 1.294 0 2.49-.416 3.471-1.115l-1.451-1.451A3.972 3.972 0 0 1 8 20z"></path></svg>',
                                                    width: width * 0.025,
                                                    height: height * 0.025,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  SizedBox(width: width * 0.01),
                                                  Text(
                                                    "Accessibility Issues",
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .titleMedium!
                                                              .fontSize,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(height: 10, thickness: 1),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              setState(() {
                                                selectedSubject =
                                                    'Notification Issues';
                                                openSubject = false;
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.04,
                                                vertical: height * 0.01,
                                              ),
                                              child: Row(
                                                children: [
                                                  SvgPicture.string(
                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 22a2.98 2.98 0 0 0 2.818-2H9.182A2.98 2.98 0 0 0 12 22zm9-4v-2a.996.996 0 0 0-.293-.707L19 13.586V10c0-3.217-2.185-5.927-5.145-6.742C13.562 2.52 12.846 2 12 2s-1.562.52-1.855 1.258c-1.323.364-2.463 1.128-3.346 2.127L3.707 2.293 2.293 3.707l18 18 1.414-1.414-1.362-1.362A.993.993 0 0 0 21 18zM12 5c2.757 0 5 2.243 5 5v4c0 .266.105.52.293.707L19 16.414V17h-.586L8.207 6.793C9.12 5.705 10.471 5 12 5zm-5.293 9.707A.996.996 0 0 0 7 14v-2.879L5.068 9.189C5.037 9.457 5 9.724 5 10v3.586l-1.707 1.707A.996.996 0 0 0 3 16v2a1 1 0 0 0 1 1h10.879l-2-2H5v-.586l1.707-1.707z"></path></svg>',
                                                    width: width * 0.025,
                                                    height: height * 0.025,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  SizedBox(width: width * 0.01),
                                                  Text(
                                                    "Notification Issues",
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .titleMedium!
                                                              .fontSize,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(height: 10, thickness: 1),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              setState(() {
                                                selectedSubject =
                                                    'Security Issues';
                                                openSubject = false;
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.04,
                                                vertical: height * 0.01,
                                              ),
                                              child: Row(
                                                children: [
                                                  SvgPicture.string(
                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M20.995 6.9a.998.998 0 0 0-.548-.795l-8-4a1 1 0 0 0-.895 0l-8 4a1.002 1.002 0 0 0-.547.795c-.011.107-.961 10.767 8.589 15.014a.987.987 0 0 0 .812 0c9.55-4.247 8.6-14.906 8.589-15.014zM12 19.897V12H5.51a15.473 15.473 0 0 1-.544-4.365L12 4.118V12h6.46c-.759 2.74-2.498 5.979-6.46 7.897z"></path></svg>',
                                                    width: width * 0.025,
                                                    height: height * 0.025,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  SizedBox(width: width * 0.01),
                                                  Text(
                                                    "Security Issues",
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .titleMedium!
                                                              .fontSize,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {});
    });
  }

  void sendSubmit(String? subject, String details) async {
    url = await loadAPIEndpoint();

    loadingDialog();

    int getCategoryIndex(String? subject) {
      switch (subject) {
        case "Suggestions":
          return 1;
        case "Incorrect Information":
          return 2;
        case "Problems or Issues":
          return 3;
        case "Accessibility Issues":
          return 4;
        case "Notification Issues":
          return 5;
        case "Security Issues":
          return 6;
        default:
          return 0;
      }
    }

    var responseSendReport = await http.post(
      Uri.parse("$url/report/send"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: sendReportPostRequestToJson(
        SendReportPostRequest(
          category: getCategoryIndex(subject),
          description: details,
        ),
      ),
    );
    Get.back();

    if (responseSendReport.statusCode == 403) {
      loadingDialog();
      await loadNewRefreshToken();
      responseSendReport = await http.post(
        Uri.parse("$url/report/send"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: sendReportPostRequestToJson(
          SendReportPostRequest(
            category: getCategoryIndex(subject),
            description: details,
          ),
        ),
      );
      Get.back();
    }

    if (responseSendReport.statusCode == 200) {
      selectedSubject = null;
      detailsCtl.clear();

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
                  color: Color(0xFF007AFF),
                ),
              ),
              Text(
                'Thank you for sending feedback',
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
            onPressed: () {
              Get.back();
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
              'Ok!',
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

  Future<void> loadNewRefreshToken() async {
    url = await loadAPIEndpoint();
    var value = await storage.read(key: 'refreshToken');
    loadingDialog();
    var loadtoketnew = await http.post(
      Uri.parse("$url/auth/newaccesstoken"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer $value",
      },
    );
    Get.back();
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
  }
}
