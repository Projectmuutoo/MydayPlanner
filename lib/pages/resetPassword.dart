import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/getUserByEmailPostRequest.dart';
import 'package:mydayplanner/models/request/isVerifyUserPutRequest.dart';
import 'package:mydayplanner/models/request/reSendOtpPostRequest.dart';
import 'package:mydayplanner/models/request/resetPasswordPutRequest.dart';
import 'package:mydayplanner/models/request/sendOTPPostRequest.dart';
import 'package:mydayplanner/models/response/getUserByEmailPostResponst.dart';
import 'package:mydayplanner/models/response/reSendOtpPostResponst.dart';
import 'package:mydayplanner/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ResetpasswordPage extends StatefulWidget {
  const ResetpasswordPage({super.key});

  @override
  State<ResetpasswordPage> createState() => _ResetpasswordPageState();
}

class _ResetpasswordPageState extends State<ResetpasswordPage> {
  // ---------------------- 🧮 State ----------------------
  bool isTyping = false;
  bool isCheckedPassword = false;
  bool isCheckedConfirmPassword = false;
  bool canResend = true;
  bool stopBlockOTP = false;
  bool hasStartedCountdown = false;
  int step = 1;
  int countToRequest = 1;

  // ---------------------- 🎯 Controllers ----------------------
  TextEditingController emailCtl = TextEditingController();
  TextEditingController otpCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController confirmPasswordCtl = TextEditingController();

  FocusNode emailFocusNode = FocusNode();
  FocusNode otpFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();

  // ---------------------- 🔤 Strings ----------------------
  String textNotification = '';
  String ref = '';
  String? expiresAtEmail;
  String emailUser = '';
  Timer? timer;
  int start = 900; // 15 นาที = 900 วินาที
  String countTheTime = "15:00"; // เวลาเริ่มต้น
  late String url;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  Widget build(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        if (emailFocusNode.hasFocus) {
          emailFocusNode.unfocus();
        }
        if (otpFocusNode.hasFocus) {
          otpFocusNode.unfocus();
        }
        if (passwordFocusNode.hasFocus) {
          passwordFocusNode.unfocus();
        }
        if (confirmPasswordFocusNode.hasFocus) {
          confirmPasswordFocusNode.unfocus();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          if (step == 1 || step == 2)
                            InkWell(
                              onTap: () {
                                if (step == 1) {
                                  Get.back();
                                } else if (step == 2) {
                                  setState(() {
                                    step = 1;
                                    otpCtl.clear();
                                    showNotification('');
                                    start = 900;
                                    countTheTime = "15:00";
                                    countToRequest = 1;
                                  });
                                }
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
                                            Get.textTheme.titleLarge!.fontSize,
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
                          Text(
                            step == 1
                                ? 'Reset your password?'
                                : step == 2
                                ? 'Enter verification code.'
                                : 'Create new password.',
                            style: TextStyle(
                              fontSize: Get.textTheme.headlineMedium!.fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                step == 1
                                    ? 'Enter the email address\nyou use with your account to continue.'
                                    : step == 2
                                    ? 'We’ve sent a code to'
                                    : 'You new password must be different\nfrom previous used passwords.',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          if (step == 2)
                            Row(
                              children: [
                                Text(
                                  emailCtl.text,
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: height * 0.02),
                      if (step == 1 || step == 2)
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
                      if (step == 1 || step == 2)
                        TextField(
                          controller: emailCtl,
                          focusNode: emailFocusNode,
                          enabled: step == 2 ? false : true,
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
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(width: 0.5),
                            ),
                          ),
                        ),
                      if (step == 1 || step == 2)
                        SizedBox(height: height * 0.01),
                      if (step == 2)
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: width * 0.03),
                              child: Text(
                                'OTP Code',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (step == 2)
                        TextField(
                          controller: otpCtl,
                          focusNode: otpFocusNode,
                          keyboardType: TextInputType.number,
                          cursorColor: Colors.black,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(6),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                          ),
                          decoration: InputDecoration(
                            hintText: isTyping ? '' : 'Enter your code',
                            hintStyle: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                            ),
                            prefixIcon: IconButton(
                              onPressed: null,
                              icon: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M7 17a5.007 5.007 0 0 0 4.898-4H14v2h2v-2h2v3h2v-3h1v-2h-9.102A5.007 5.007 0 0 0 7 7c-2.757 0-5 2.243-5 5s2.243 5 5 5zm0-8c1.654 0 3 1.346 3 3s-1.346 3-3 3-3-1.346-3-3 1.346-3 3-3z"></path></svg>',
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
                      if (step == 2) SizedBox(height: height * 0.01),
                      if (step == 3)
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
                      if (step == 3)
                        TextField(
                          controller: passwordCtl,
                          focusNode: passwordFocusNode,
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
                      if (step == 3)
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: width * 0.03),
                              child: Text(
                                'Must be at least 8 characters.',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: height * 0.01),
                      if (step == 3)
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: width * 0.03),
                              child: Text(
                                'Confirm password',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (step == 3)
                        TextField(
                          controller: confirmPasswordCtl,
                          focusNode: confirmPasswordFocusNode,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: !isCheckedConfirmPassword,
                          cursorColor: Colors.black,
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                isTyping ? '' : 'Enter your confirm password',
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
                                  isCheckedConfirmPassword =
                                      !isCheckedConfirmPassword;
                                });
                              },
                              icon: Icon(
                                isCheckedConfirmPassword
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
                      if (step == 3)
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: width * 0.03),
                              child: Text(
                                'Both passwords must match.',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (textNotification.isNotEmpty)
                        Text(
                          textNotification,
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      SizedBox(height: height * 0.01),
                      if (step == 2)
                        Text(
                          'ref: $ref',
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      if (step == 2) SizedBox(height: height * 0.01),
                      if (step == 2)
                        Text(
                          countTheTime,
                          style: TextStyle(
                            fontSize: Get.textTheme.titleSmall!.fontSize,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      if (step == 2) SizedBox(height: height * 0.01),
                      if (step == 2)
                        InkWell(
                          onTap:
                              canResend
                                  ? () async {
                                    var result =
                                        await FirebaseFirestore.instance
                                            .collection('EmailBlocked')
                                            .doc(emailUser)
                                            .collection(
                                              'OTPRecords_resetpassword',
                                            )
                                            .doc(emailUser)
                                            .get();
                                    var data = result.data();
                                    if (data != null) {
                                      stopBlockOTP = true;
                                      canResend = false;
                                      expiresAtEmail =
                                          formatTimestampTo12HourTimeWithSeconds(
                                            data['expiresAt'] as Timestamp,
                                          );
                                      showNotification(
                                        'Your email has been blocked because you requested otp overdue and you will be able to request otp again after $expiresAtEmail',
                                      );
                                      return;
                                    }

                                    countToRequest++;

                                    if (countToRequest > 3) {
                                      Map<String, dynamic> data = {
                                        'email': emailUser,
                                        'createdAt': Timestamp.fromDate(
                                          DateTime.now(),
                                        ),
                                        'expiresAt': Timestamp.fromDate(
                                          DateTime.now().add(
                                            Duration(minutes: 10),
                                          ),
                                        ),
                                      };
                                      await FirebaseFirestore.instance
                                          .collection('EmailBlocked')
                                          .doc(emailUser)
                                          .collection(
                                            'OTPRecords_resetpassword',
                                          )
                                          .doc(emailUser)
                                          .set(data);
                                      if (!mounted) return;
                                      setState(() {
                                        stopBlockOTP = true;
                                        canResend = false;
                                        expiresAtEmail =
                                            formatTimestampTo12HourTimeWithSeconds(
                                              data['expiresAt'] as Timestamp,
                                            );
                                        showNotification(
                                          'Your email has been blocked because you requested otp overdue and you will be able to request otp again after $expiresAtEmail',
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
                                          email: emailUser,
                                          record: '2',
                                        ),
                                      ),
                                    );

                                    if (responseOtp.statusCode == 200) {
                                      Get.back();
                                      ReSendOtpPostResponst sendOTPResponse =
                                          reSendOtpPostResponstFromJson(
                                            responseOtp.body,
                                          );

                                      if (timer != null && timer!.isActive) {
                                        timer!.cancel();
                                      }

                                      setState(() {
                                        ref = sendOTPResponse.ref;
                                        hasStartedCountdown = true;
                                        canResend = false; // ล็อกการกดชั่วคราว
                                        otpCtl.clear();
                                      });
                                      startCountdown(setState, ref);
                                      // รอ 30 วิค่อยให้กดได้อีก
                                      Future.delayed(Duration(seconds: 30), () {
                                        if (!mounted) return;
                                        setState(() {
                                          canResend = true;
                                        });
                                      });
                                    } else {
                                      Get.back();
                                      var result =
                                          await FirebaseFirestore.instance
                                              .collection('EmailBlocked')
                                              .doc(emailUser)
                                              .collection(
                                                'OTPRecords_resetpassword',
                                              )
                                              .doc(emailUser)
                                              .get();
                                      var data = result.data();
                                      if (data != null) {
                                        stopBlockOTP = true;
                                        canResend = false;
                                        expiresAtEmail =
                                            formatTimestampTo12HourTimeWithSeconds(
                                              data['expiresAt'] as Timestamp,
                                            );
                                        showNotification(
                                          'Your email has been blocked because you requested otp overdue and you will be able to request otp again after $expiresAtEmail',
                                        );
                                        return;
                                      }
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
                                decoration:
                                    canResend
                                        ? TextDecoration.underline
                                        : TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'You remember your password?',
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              goToLoginPage();
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.01,
                              ),
                              child: Text(
                                'Sign in.',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: resetPassword,
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(width, height * 0.04),
                          backgroundColor: Color(0xFF007AFF),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          step == 1
                              ? 'Continue'
                              : step == 2
                              ? 'Verify Code'
                              : 'Reset Password',
                          style: TextStyle(
                            fontSize: Get.textTheme.titleLarge!.fontSize,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.02),
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

  void showNotification(String message) {
    setState(() {
      textNotification = message;
    });
  }

  void resetPassword() async {
    if (emailCtl.text.isEmpty) {
      showNotification('Please enter your email');
      return;
    } else if (!isValidEmail(emailCtl.text)) {
      showNotification('Invalid email format');
      return;
    }

    try {
      url = await loadAPIEndpoint();

      loadingDialog();

      switch (step) {
        case 1:
          await handleStep1(url);
          break;
        case 2:
          await handleStep2(url);
          break;
        case 3:
          await handleStep3(url);
          break;
      }
    } finally {
      Get.back();
    }
  }

  Future<void> handleStep1(String url) async {
    try {
      var responseGetuser = await http.post(
        Uri.parse("$url/email"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: getUserByEmailPostRequestToJson(
          GetUserByEmailPostRequest(email: emailCtl.text),
        ),
      );

      if (responseGetuser.statusCode == 200) {
        start = 900;
        countTheTime = "15:00";
        var responseGetUserByEmail = getUserByEmailPostResponstFromJson(
          responseGetuser.body,
        );

        var responseRef = await http.post(
          Uri.parse("$url/auth/resetpasswordOTP"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: jsonEncode({"email": responseGetUserByEmail.email}),
        );

        if (responseRef.statusCode == 200) {
          var sendOTPResponse = jsonDecode(responseRef.body);

          var responseOtp = await http.post(
            Uri.parse("$url/auth/sendemail"),
            headers: {"Content-Type": "application/json; charset=utf-8"},
            body: sendOtpPostRequestToJson(
              SendOtpPostRequest(
                email: responseGetUserByEmail.email,
                reference: sendOTPResponse['ref'],
                record: '2',
              ),
            ),
          );

          var result =
              await FirebaseFirestore.instance
                  .collection('EmailBlocked')
                  .doc(responseGetUserByEmail.email)
                  .collection('OTPRecords_resetpassword')
                  .doc(responseGetUserByEmail.email)
                  .get();
          var data = result.data();
          if (data != null) {
            expiresAtEmail = formatTimestampTo12HourTimeWithSeconds(
              data['expiresAt'] as Timestamp,
            );
            showNotification(
              'Your email has been blocked because you requested otp overdue and you will be able to request otp again after $expiresAtEmail',
            );
            return;
          }

          if (responseOtp.statusCode == 200) {
            showNotification('');

            ref = sendOTPResponse['ref'];
            emailUser = responseGetUserByEmail.email;

            if (!hasStartedCountdown) {
              hasStartedCountdown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                startCountdown(setState, ref);
              });
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              startOtpExpiryTimer(emailUser, setState);
            });

            if (!mounted) return;
            setState(() {
              step = 2;
            });
          }
        }
      } else {
        showNotification('Email not found');
      }
    } catch (e) {
      showNotification('Something went wrong. Please try again.');
    }
  }

  Future<void> handleStep2(String url) async {
    if (otpCtl.text.trim().isEmpty) {
      showNotification('OTP code is required');
      return;
    }

    if (otpCtl.text.trim().length == 6) {
      try {
        var responseIsverify = await http.put(
          Uri.parse("$url/auth/verifyOTP"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: isVerifyUserPutRequestToJson(
            IsVerifyUserPutRequest(
              email: emailUser,
              ref: ref,
              otp: otpCtl.text,
              record: '2',
            ),
          ),
        );

        if (responseIsverify.statusCode == 200) {
          setState(() {
            showNotification('');
          });

          await FirebaseFirestore.instance
              .collection('OTPRecords')
              .doc(emailUser)
              .collection('OTPRecords_resetpassword')
              .doc(ref)
              .delete();

          if (!mounted) return;
          setState(() {
            step = 3;
          });
        } else {
          showNotification('Invalid OTP. Please try again.');
        }
      } catch (e) {
        showNotification('Something went wrong. Please try again.');
      }
    }
  }

  Future<void> handleStep3(String url) async {
    if (passwordCtl.text.isEmpty) {
      showNotification('Please enter your password');
      return;
    } else if (!isValidPassword(passwordCtl.text)) {
      showNotification(
        'Password must contain at least 8 digits\nor lowercase letters',
      );
      return;
    }

    if (confirmPasswordCtl.text.isEmpty) {
      showNotification('Please enter your confirm password');
      return;
    } else if (passwordCtl.text != confirmPasswordCtl.text) {
      showNotification('Passwords do not match');
      return;
    }

    try {
      final response = await http.put(
        Uri.parse("$url/auth/resetpassword"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: resetPasswordPutRequestToJson(
          ResetPasswordPutRequest(email: emailUser, password: passwordCtl.text),
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          step = 1;
          emailCtl.clear();
          otpCtl.clear();
          passwordCtl.clear();
          confirmPasswordCtl.clear();
          showNotification('');
          start = 900;
          countTheTime = "15:00";
          countToRequest = 1;
          canResend = true;
          stopBlockOTP = false;
        });

        Future.delayed(Duration.zero, () {
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
                    'Your password has been reset successfully',
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
                  'OK!',
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
                  backgroundColor: Color(0xFFE7F3FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleLarge!.fontSize,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          );
        });
      } else {
        showNotification('Reset failed. Please try again.');
      }
    } catch (e) {
      showNotification('Something went wrong. Please try again.');
    }
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

  void goToLoginPage() {
    Get.to(() => LoginPage());
  }

  String formatTimestampTo12HourTimeWithSeconds(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('hh:mm:ss a').format(dateTime);
    return formattedTime;
  }

  void startCountdown(StateSetter setState, String ref) {
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
            .doc(emailUser)
            .collection('OTPRecords_resetpassword')
            .doc(ref)
            .delete();
        if (!mounted) return;
        setState(() {
          canResend = true;
        });
      } else {
        start--;
        if (!mounted) return;
        setState(() {
          countTheTime = formatTime(start);
        });
      }
    });
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void startOtpExpiryTimer(String email, StateSetter setState) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('EmailBlocked')
            .doc(email)
            .collection('OTPRecords_resetpassword')
            .doc(email)
            .get();

    var data = snapshot.data() as Map<String, dynamic>?;
    if (data == null || data['expiresAt'] == null) return;

    Timestamp expiresAt = data['expiresAt'] as Timestamp;
    DateTime expireTime = expiresAt.toDate();
    DateTime now = DateTime.now();

    if (now.isAfter(expireTime)) {
      if (!mounted) return;
      setState(() {
        stopBlockOTP = false;
        canResend = true;
        showNotification('');
      });
    }
  }
}
