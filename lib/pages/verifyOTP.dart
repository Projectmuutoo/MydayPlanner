import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/isVerifyUserPutRequest.dart';
import 'package:mydayplanner/models/request/reSendOtpPostRequest.dart';
import 'package:mydayplanner/models/request/sendOTPPostRequest.dart';
import 'package:mydayplanner/models/request/signInUserPostRequest.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
import 'package:mydayplanner/models/response/reSendOtpPostResponst.dart';
import 'package:mydayplanner/models/response/signInUserPostResponst.dart';
import 'package:mydayplanner/pages/login.dart';
import 'package:mydayplanner/pages/pageAdmin/navBarAdmin.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class VerifyotpPage extends StatefulWidget {
  const VerifyotpPage({super.key});

  @override
  State<VerifyotpPage> createState() => _VerifyotpPageState();
}

class _VerifyotpPageState extends State<VerifyotpPage> {
  String warning = '';
  String textNotification = '';
  String? expiresAtEmail;
  String countTheTime = "15:00";
  late String url;

  bool blockOTP = false;
  bool canResend = true;
  bool hasStartedCountdown = false;
  bool stopBlockOTP = false;

  int start = 900; // 15 นาที = 900 วินาที
  int countToRequest = 1;

  Timer? timer;

  var appData = Appdata();
  var box = GetStorage();
  final storage = FlutterSecureStorage();

  final focusNodes = List<FocusNode>.generate(6, (index) => FocusNode());
  final otpControllers = List<TextEditingController>.generate(
    6,
    (index) => TextEditingController(),
  );

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();

    appData = Provider.of<Appdata>(context, listen: false);

    if (!hasStartedCountdown) {
      hasStartedCountdown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startCountdown(appData.keepEmailToUserPageVerifyOTP.ref);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startOtpExpiryTimer(appData.keepEmailToUserPageVerifyOTP.email);
    });

    sendOtpToEmail();
  }

  void sendOtpToEmail() async {
    url = await loadAPIEndpoint();
    await http.post(
      Uri.parse("$url/auth/sendemail"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: sendOtpPostRequestToJson(
        SendOtpPostRequest(
          email: appData.keepEmailToUserPageVerifyOTP.email,
          reference: appData.keepEmailToUserPageVerifyOTP.ref,
          record: '1',
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final node in focusNodes) {
      node.dispose();
    }

    for (final controller in otpControllers) {
      controller.dispose();
    }
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Verification Code',
                            style: TextStyle(
                              fontSize: Get.textTheme.headlineMedium!.fontSize,
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
                            appData.keepEmailToUserPageVerifyOTP.email,
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.02),
                      Form(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
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
                                      FocusScope.of(
                                        context,
                                      ).unfocus(); // ปิดคีย์บอร์ด
                                      verifyEnteredOTP(
                                        otpControllers,
                                        appData
                                            .keepEmailToUserPageVerifyOTP
                                            .email,
                                        appData
                                            .keepEmailToUserPageVerifyOTP
                                            .ref,
                                      ).then((success) {
                                        if (success &&
                                            appData
                                                    .keepEmailToUserPageVerifyOTP
                                                    .cases ==
                                                'verifyEmail-Register') {
                                          Get.offAll(() => LoginPage());
                                          Get.defaultDialog(
                                            title: '',
                                            titlePadding: EdgeInsets.zero,
                                            backgroundColor: Colors.white,
                                            barrierDismissible: false,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.04,
                                                  vertical:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.height *
                                                      0.02,
                                                ),
                                            content: WillPopScope(
                                              onWillPop: () async => false,
                                              child: Column(
                                                children: [
                                                  Image.asset(
                                                    "assets/images/aleart/success.png",
                                                    height:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.height *
                                                        0.1,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.height *
                                                        0.01,
                                                  ),
                                                  Text(
                                                    'Successfully!!',
                                                    style: TextStyle(
                                                      fontSize: Get
                                                          .textTheme
                                                          .headlineSmall!
                                                          .fontSize,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF007AFF),
                                                    ),
                                                  ),
                                                  Text(
                                                    'You have successfully confirmed your email',
                                                    style: TextStyle(
                                                      fontSize: Get
                                                          .textTheme
                                                          .titleMedium!
                                                          .fontSize,
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
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width,
                                                    MediaQuery.of(
                                                          context,
                                                        ).size.height *
                                                        0.05,
                                                  ),
                                                  backgroundColor: Color(
                                                    0xFFE7F3FF,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  elevation: 1,
                                                ),
                                                child: Text(
                                                  'Ok!',
                                                  style: TextStyle(
                                                    fontSize: Get
                                                        .textTheme
                                                        .titleLarge!
                                                        .fontSize,
                                                    color: Color(0xFF007AFF),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        } else if (success &&
                                            appData
                                                    .keepEmailToUserPageVerifyOTP
                                                    .cases ==
                                                'verifyEmail-Admin') {
                                          Get.offAll(() => NavbaradminPage());
                                          Get.defaultDialog(
                                            title: '',
                                            titlePadding: EdgeInsets.zero,
                                            backgroundColor: Colors.white,
                                            barrierDismissible: false,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.04,
                                                  vertical:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.height *
                                                      0.02,
                                                ),
                                            content: WillPopScope(
                                              onWillPop: () async => false,
                                              child: Column(
                                                children: [
                                                  Image.asset(
                                                    "assets/images/aleart/success.png",
                                                    height:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.height *
                                                        0.1,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.height *
                                                        0.01,
                                                  ),
                                                  Text(
                                                    'Successfully!!',
                                                    style: TextStyle(
                                                      fontSize: Get
                                                          .textTheme
                                                          .headlineSmall!
                                                          .fontSize,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF007AFF),
                                                    ),
                                                  ),
                                                  Text(
                                                    'You have successfully confirmed your email',
                                                    style: TextStyle(
                                                      fontSize: Get
                                                          .textTheme
                                                          .titleMedium!
                                                          .fontSize,
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
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width,
                                                    MediaQuery.of(
                                                          context,
                                                        ).size.height *
                                                        0.05,
                                                  ),
                                                  backgroundColor: Color(
                                                    0xFFE7F3FF,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  elevation: 1,
                                                ),
                                                child: Text(
                                                  'Ok!',
                                                  style: TextStyle(
                                                    fontSize: Get
                                                        .textTheme
                                                        .titleLarge!
                                                        .fontSize,
                                                    color: Color(0xFF007AFF),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      });
                                    }
                                  } else if (value.isEmpty && index > 0) {
                                    focusNodes[index - 1]
                                        .requestFocus(); // กลับไปช่องก่อนหน้า
                                  }
                                },
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(1),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  focusColor: Colors.black,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.all(8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
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
                                  hintText: "-",
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      if (blockOTP || warning.isNotEmpty)
                        SizedBox(height: height * 0.02),
                      if (textNotification.isNotEmpty)
                        SizedBox(height: height * 0.02),
                      if (warning.isNotEmpty)
                        Text(
                          'OTP code is invalid',
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: Colors.red,
                          ),
                        ),
                      if (textNotification.isNotEmpty)
                        Text(
                          textNotification,
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: Colors.red,
                          ),
                        ),
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
                      SizedBox(height: height * 0.02),
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
                          SizedBox(width: width * 0.01),
                          InkWell(
                            onTap: () async {
                              // ดึงข้อความจาก Clipboard
                              ClipboardData? data = await Clipboard.getData(
                                'text/plain',
                              );
                              if (data != null && data.text != null) {
                                String copiedText = data.text!;
                                if (copiedText.length == 6) {
                                  // ใส่ข้อความลงใน TextControllers
                                  for (int i = 0; i < copiedText.length; i++) {
                                    otpControllers[i].text = copiedText[i];
                                    // โฟกัสไปยังช่องสุดท้าย
                                    if (i == 5) {
                                      focusNodes[i].requestFocus();
                                    }
                                  }
                                  verifyEnteredOTP(
                                    otpControllers,
                                    appData.keepEmailToUserPageVerifyOTP.email,
                                    appData.keepEmailToUserPageVerifyOTP.ref,
                                  ).then((success) {
                                    if (success &&
                                        appData
                                                .keepEmailToUserPageVerifyOTP
                                                .cases ==
                                            'verifyEmail-Register') {
                                      Get.offAll(() => LoginPage());
                                      Get.defaultDialog(
                                        title: '',
                                        titlePadding: EdgeInsets.zero,
                                        backgroundColor: Colors.white,
                                        barrierDismissible: false,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.04,
                                          vertical:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.02,
                                        ),
                                        content: WillPopScope(
                                          onWillPop: () async => false,
                                          child: Column(
                                            children: [
                                              Image.asset(
                                                "assets/images/aleart/success.png",
                                                height:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.1,
                                                fit: BoxFit.contain,
                                              ),
                                              SizedBox(
                                                height:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.01,
                                              ),
                                              Text(
                                                'Successfully!!',
                                                style: TextStyle(
                                                  fontSize: Get
                                                      .textTheme
                                                      .headlineSmall!
                                                      .fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF007AFF),
                                                ),
                                              ),
                                              Text(
                                                'You have successfully confirmed your email',
                                                style: TextStyle(
                                                  fontSize: Get
                                                      .textTheme
                                                      .titleMedium!
                                                      .fontSize,
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
                                                MediaQuery.of(
                                                  context,
                                                ).size.width,
                                                MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.05,
                                              ),
                                              backgroundColor: Color(
                                                0xFFE7F3FF,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 1,
                                            ),
                                            child: Text(
                                              'Ok!',
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .titleLarge!
                                                    .fontSize,
                                                color: Color(0xFF007AFF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    } else if (success &&
                                        appData
                                                .keepEmailToUserPageVerifyOTP
                                                .cases ==
                                            'verifyEmail-Admin') {
                                      Get.offAll(() => NavbaradminPage());
                                      Get.defaultDialog(
                                        title: '',
                                        titlePadding: EdgeInsets.zero,
                                        backgroundColor: Colors.white,
                                        barrierDismissible: false,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.04,
                                          vertical:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.02,
                                        ),
                                        content: WillPopScope(
                                          onWillPop: () async => false,
                                          child: Column(
                                            children: [
                                              Image.asset(
                                                "assets/images/aleart/success.png",
                                                height:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.1,
                                                fit: BoxFit.contain,
                                              ),
                                              SizedBox(
                                                height:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.01,
                                              ),
                                              Text(
                                                'Successfully!!',
                                                style: TextStyle(
                                                  fontSize: Get
                                                      .textTheme
                                                      .headlineSmall!
                                                      .fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF007AFF),
                                                ),
                                              ),
                                              Text(
                                                'You have successfully confirmed your email',
                                                style: TextStyle(
                                                  fontSize: Get
                                                      .textTheme
                                                      .titleMedium!
                                                      .fontSize,
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
                                                MediaQuery.of(
                                                  context,
                                                ).size.width,
                                                MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.05,
                                              ),
                                              backgroundColor: Color(
                                                0xFFE7F3FF,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 1,
                                            ),
                                            child: Text(
                                              'Ok!',
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .titleLarge!
                                                    .fontSize,
                                                color: Color(0xFF007AFF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  }); // ตรวจสอบ OTP
                                } else {
                                  setState(() {
                                    warning = 'F21F1F';
                                  });
                                }
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.01,
                              ),
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
                          ),
                        ],
                      ),
                      Text(
                        'ref: ${appData.keepEmailToUserPageVerifyOTP.ref}',
                        style: TextStyle(
                          fontSize: Get.textTheme.titleSmall!.fontSize,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: height * 0.01),
                      Text(
                        countTheTime,
                        style: TextStyle(
                          fontSize: Get.textTheme.titleSmall!.fontSize,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: height * 0.01),
                      InkWell(
                        onTap: canResend
                            ? () async {
                                countToRequest++;

                                if (countToRequest > 3) {
                                  Map<String, dynamic> data = {
                                    'email': appData
                                        .keepEmailToUserPageVerifyOTP
                                        .email,
                                    'createdAt': Timestamp.fromDate(
                                      DateTime.now(),
                                    ),
                                    'expiresAt': Timestamp.fromDate(
                                      DateTime.now().add(Duration(minutes: 10)),
                                    ),
                                  };
                                  await FirebaseFirestore.instance
                                      .collection('EmailBlocked')
                                      .doc(
                                        appData
                                            .keepEmailToUserPageVerifyOTP
                                            .email,
                                      )
                                      .collection('OTPRecords_verify')
                                      .doc(
                                        appData
                                            .keepEmailToUserPageVerifyOTP
                                            .email,
                                      )
                                      .set(data);

                                  setState(() {
                                    blockOTP = true;
                                    stopBlockOTP = true;
                                    canResend = false;
                                    expiresAtEmail =
                                        formatTimestampTo12HourTimeWithSeconds(
                                          data['expiresAt'] as Timestamp,
                                        );
                                  });
                                  return;
                                }

                                url = await loadAPIEndpoint();
                                loadingDialog();
                                var responseOtp = await http.post(
                                  Uri.parse("$url/auth/resendotp"),
                                  headers: {
                                    "Content-Type":
                                        "application/json; charset=utf-8",
                                  },
                                  body: reSendOtpPostRequestToJson(
                                    ReSendOtpPostRequest(
                                      email: appData
                                          .keepEmailToUserPageVerifyOTP
                                          .email,
                                      record: '1',
                                    ),
                                  ),
                                );

                                if (responseOtp.statusCode == 200) {
                                  Get.back();
                                  ReSendOtpPostResponst sendOTPResponse =
                                      reSendOtpPostResponstFromJson(
                                        responseOtp.body,
                                      );

                                  if (timer!.isActive) {
                                    timer!.cancel();
                                  }

                                  setState(() {
                                    appData.keepEmailToUserPageVerifyOTP.setRef(
                                      sendOTPResponse.ref,
                                    );
                                    hasStartedCountdown = true;
                                    canResend = false; // ล็อกการกดชั่วคราว
                                    warning = '';
                                    for (var controller in otpControllers) {
                                      controller.clear();
                                    }
                                  });
                                  startCountdown(
                                    appData.keepEmailToUserPageVerifyOTP.ref,
                                  );
                                  // รอ 30 วิค่อยให้กดได้อีก
                                  Future.delayed(Duration(seconds: 30), () {
                                    setState(() {
                                      canResend = true;
                                    });
                                  });
                                } else {
                                  Get.back();
                                }
                              }
                            : null,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.01,
                          ),
                          child: Text(
                            'Resend Code',
                            style: TextStyle(
                              fontSize: Get.textTheme.titleSmall!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: canResend ? Colors.blue : Colors.grey,
                              decoration: canResend
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (stopBlockOTP)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Get.offAll(() => LoginPage());
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(width, height * 0.04),
                            backgroundColor: Colors.black54,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Sign in',
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
        ),
      ),
    );
  }

  // ฟังก์ชันตรวจสอบ OTP
  Future<bool> verifyEnteredOTP(
    List<TextEditingController> otpControllers,
    String email,
    String ref,
  ) async {
    url = await loadAPIEndpoint();
    String enteredOTP = otpControllers
        .map((controller) => controller.text)
        .join(); // รวมค่าที่ป้อน
    if (enteredOTP.length == 6) {
      // แสดง Loading Dialog
      loadingDialog();
      var responseIsverify = await http.put(
        Uri.parse("$url/auth/verifyOTP"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: isVerifyUserPutRequestToJson(
          IsVerifyUserPutRequest(
            email: email,
            ref: ref,
            otp: enteredOTP,
            record: appData.keepEmailToUserPageVerifyOTP.cases == 'verifyEmail'
                ? "1"
                : appData.keepEmailToUserPageVerifyOTP.cases ==
                      'verifyEmail-Register'
                ? "1"
                : appData.keepEmailToUserPageVerifyOTP.cases ==
                      'verifyEmail-Admin'
                ? "1"
                : "2",
          ),
        ),
      );
      Get.back();

      if (appData.keepEmailToUserPageVerifyOTP.cases == 'verifyEmail') {
        if (responseIsverify.statusCode == 200) {
          setState(() {
            warning = '';
          });

          loadingDialog();
          await FirebaseFirestore.instance
              .collection('OTPRecords')
              .doc(appData.keepEmailToUserPageVerifyOTP.email)
              .collection('OTPRecords_verify')
              .doc(appData.keepEmailToUserPageVerifyOTP.ref)
              .delete();
          await FirebaseFirestore.instance
              .collection('EmailBlocked')
              .doc(appData.keepEmailToUserPageVerifyOTP.email)
              .collection('OTPRecords_verify')
              .doc(appData.keepEmailToUserPageVerifyOTP.email)
              .delete();

          if (timer != null && timer!.isActive) {
            timer!.cancel();
          }
          final responseGetuser = await http.post(
            Uri.parse("$url/auth/signin"),
            headers: {"Content-Type": "application/json; charset=utf-8"},
            body: signInUserPostRequestToJson(
              SignInUserPostRequest(
                email: email,
                password: appData.keepEmailToUserPageVerifyOTP.password,
              ),
            ),
          );
          Get.back();

          if (responseGetuser.statusCode != 200) {
            final results = jsonDecode(responseGetuser.body);
            showNotification(results['error']);
            return false;
          }

          final signInResponse = signInUserPostResponstFromJson(
            responseGetuser.body,
          );
          await storage.write(
            key: 'refreshToken',
            value: signInResponse.token.refreshToken,
          );
          box.write('accessToken', signInResponse.token.accessToken);

          loadingDialog();
          final responseAll = await http.get(
            Uri.parse("$url/user/data"),
            headers: {
              "Content-Type": "application/json; charset=utf-8",
              "Authorization": "Bearer ${box.read('accessToken')}",
            },
          );

          if (responseAll.statusCode != 200) {
            Get.back();
            return false;
          }

          final response = allDataUserGetResponstFromJson(responseAll.body);

          await box.write('userProfile', {
            'userid': response.user.userId,
            'name': response.user.name,
            'email': response.user.email,
            'profile': response.user.profile,
            'role': response.user.role,
          });

          String deviceName = await getDeviceName();
          await FirebaseFirestore.instance
              .collection('usersLogin')
              .doc(response.user.email)
              .update({
                'deviceName': deviceName,
                'changePassword': response.user.role == "admin"
                    ? FieldValue.delete()
                    : true,
              });

          if (response.user.role != "admin") {
            await box.write('userDataAll', response.toJson());
          }

          Get.back();
          if (response.user.role == "admin") {
            Get.offAll(() => NavbaradminPage());
            return false;
          } else {
            Get.offAll(() => NavbarPage());
            return false;
          }
        } else {
          setState(() {
            warning = 'F21F1F';
          });
        }
      } else if (appData.keepEmailToUserPageVerifyOTP.cases ==
          'verifyEmail-Register') {
        loadingDialog();
        await FirebaseFirestore.instance
            .collection('OTPRecords')
            .doc(appData.keepEmailToUserPageVerifyOTP.email)
            .collection('OTPRecords_verify')
            .doc(appData.keepEmailToUserPageVerifyOTP.ref)
            .delete();
        await FirebaseFirestore.instance
            .collection('EmailBlocked')
            .doc(appData.keepEmailToUserPageVerifyOTP.email)
            .collection('OTPRecords_verify')
            .doc(appData.keepEmailToUserPageVerifyOTP.email)
            .delete();
        if (timer != null && timer!.isActive) {
          timer!.cancel();
        }
        Get.back();
        return true;
      } else if (appData.keepEmailToUserPageVerifyOTP.cases ==
          'verifyEmail-Admin') {
        loadingDialog();
        await FirebaseFirestore.instance
            .collection('OTPRecords')
            .doc(appData.keepEmailToUserPageVerifyOTP.email)
            .collection('OTPRecords_verify')
            .doc(appData.keepEmailToUserPageVerifyOTP.ref)
            .delete();
        await FirebaseFirestore.instance
            .collection('EmailBlocked')
            .doc(appData.keepEmailToUserPageVerifyOTP.email)
            .collection('OTPRecords_verify')
            .doc(appData.keepEmailToUserPageVerifyOTP.email)
            .delete();
        if (timer != null && timer!.isActive) {
          timer!.cancel();
        }
        Get.back();
        return true;
      }
    }
    return false;
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

  void showNotification(String message) {
    setState(() {
      textNotification = message;
    });
  }

  String formatTimestampTo12HourTimeWithSeconds(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('hh:mm:ss a').format(dateTime);
    return formattedTime;
  }

  void startCountdown(String ref) {
    // ยกเลิก timer เดิมถ้ามี
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }

    // รีเซ็ตค่าเริ่มต้น
    start = 900;
    countTheTime = "15:00";

    // เริ่ม timer ใหม่
    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (start == 0) {
        timer.cancel();
        await FirebaseFirestore.instance
            .collection('OTPRecords')
            .doc(appData.keepEmailToUserPageVerifyOTP.email)
            .collection('OTPRecords_verify')
            .doc(appData.keepEmailToUserPageVerifyOTP.ref)
            .delete();

        setState(() {
          canResend = true;
        });
      } else {
        start--;

        setState(() {
          countTheTime = formatTime(start);
        });
      }
    });
  }

  void startOtpExpiryTimer(String email) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('EmailBlocked')
        .doc(email)
        .collection('OTPRecords_verify')
        .doc(email)
        .get();

    var data = snapshot.data() as Map<String, dynamic>?;
    if (data == null || data['expiresAt'] == null) return;

    Timestamp expiresAt = data['expiresAt'] as Timestamp;
    DateTime expireTime = expiresAt.toDate();
    DateTime now = DateTime.now();

    if (now.isAfter(expireTime)) {
      setState(() {
        stopBlockOTP = false;
        blockOTP = false;
        canResend = true;
      });
    }
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}
