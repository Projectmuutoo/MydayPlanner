import 'dart:developer';

import 'package:demomydayplanner/config/config.dart';
import 'package:demomydayplanner/models/request/getUserByEmailPostRequest.dart';
import 'package:demomydayplanner/models/request/resetPasswordPutRequest.dart';
import 'package:demomydayplanner/models/request/sendOTPPostRequest.dart';
import 'package:demomydayplanner/models/response/getUserByEmailPostResponst.dart';
import 'package:demomydayplanner/models/response/sendOTPPostResponst.dart';
import 'package:demomydayplanner/pages/login.dart';
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
  bool isTyping = false;
  bool isCheckedPassword = false;
  bool isCheckedConfirmPassword = false;
  int step = 1;
  TextEditingController emailCtl = TextEditingController();
  TextEditingController otpCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController confirmPasswordCtl = TextEditingController();
  String textNotification = '';
  bool isLoading = false;
  String otp = '';

  @override
  Widget build(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: null,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05,
              vertical: height * 0.05,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: backToLoginPage,
                          child: Row(
                            children: [
                              SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12.707 17.293 8.414 13H18v-2H8.414l4.293-4.293-1.414-1.414L4.586 12l6.707 6.707z"></path></svg>',
                                color: const Color.fromRGBO(0, 0, 0, 0.6),
                              ),
                              Text(
                                'back',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleLarge!.fontSize,
                                  fontWeight: FontWeight.normal,
                                  color: const Color.fromRGBO(0, 0, 0, 0.6),
                                ),
                              ),
                            ],
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
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(
                      height: height * 0.02,
                    ),
                    if (step == 1 || step == 2)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.03,
                            ),
                            child: Text(
                              'Email',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleLarge!.fontSize,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (step == 1 || step == 2)
                      TextField(
                        controller: emailCtl,
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: Colors.black,
                        style: TextStyle(
                          fontSize: Get.textTheme.titleLarge!.fontSize,
                        ),
                        decoration: InputDecoration(
                          hintText: isTyping ? '' : 'Enter your email address…',
                          hintStyle: TextStyle(
                            fontSize: Get.textTheme.titleLarge!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: const Color.fromRGBO(0, 0, 0, 0.3),
                          ),
                          prefixIcon: IconButton(
                            onPressed: null,
                            icon: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M20 4H4c-1.103 0-2 .897-2 2v12c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2zm0 2v.511l-8 6.223-8-6.222V6h16zM4 18V9.044l7.386 5.745a.994.994 0 0 0 1.228 0L20 9.044 20.002 18H4z"></path></svg>',
                              color: const Color(0xff7B7B7B),
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
                    if (step == 1 || step == 2)
                      SizedBox(
                        height: height * 0.01,
                      ),
                    if (step == 2)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.03,
                            ),
                            child: Text(
                              'OTP Code',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleLarge!.fontSize,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (step == 2)
                      TextField(
                        controller: otpCtl,
                        keyboardType: TextInputType.number,
                        cursorColor: Colors.black,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(6),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          fontSize: Get.textTheme.titleLarge!.fontSize,
                        ),
                        decoration: InputDecoration(
                          hintText: isTyping ? '' : 'Enter your code',
                          hintStyle: TextStyle(
                            fontSize: Get.textTheme.titleLarge!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: const Color.fromRGBO(0, 0, 0, 0.3),
                          ),
                          prefixIcon: IconButton(
                            onPressed: null,
                            icon: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M7 17a5.007 5.007 0 0 0 4.898-4H14v2h2v-2h2v3h2v-3h1v-2h-9.102A5.007 5.007 0 0 0 7 7c-2.757 0-5 2.243-5 5s2.243 5 5 5zm0-8c1.654 0 3 1.346 3 3s-1.346 3-3 3-3-1.346-3-3 1.346-3 3-3z"></path></svg>',
                              color: const Color(0xff7B7B7B),
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
                    if (step == 2)
                      SizedBox(
                        height: height * 0.01,
                      ),
                    if (step == 3)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.03,
                            ),
                            child: Text(
                              'Password',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleLarge!.fontSize,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (step == 3)
                      TextField(
                        controller: passwordCtl,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: !isCheckedPassword,
                        cursorColor: Colors.black,
                        style: TextStyle(
                          fontSize: Get.textTheme.titleLarge!.fontSize,
                        ),
                        decoration: InputDecoration(
                          hintText: isTyping ? '' : 'Enter your password',
                          hintStyle: TextStyle(
                            fontSize: Get.textTheme.titleLarge!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: const Color.fromRGBO(0, 0, 0, 0.3),
                          ),
                          prefixIcon: IconButton(
                            onPressed: null,
                            icon: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C9.243 2 7 4.243 7 7v2H6c-1.103 0-2 .897-2 2v9c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2v-9c0-1.103-.897-2-2-2h-1V7c0-2.757-2.243-5-5-5zM9 7c0-1.654 1.346-3 3-3s3 1.346 3 3v2H9V7zm9.002 13H13v-2.278c.595-.347 1-.985 1-1.722 0-1.103-.897-2-2-2s-2 .897-2 2c0 .736.405 1.375 1 1.722V20H6v-9h12l.002 9z"></path></svg>',
                              color: const Color(0xff7B7B7B),
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
                              color: const Color(0xff7B7B7B),
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
                    if (step == 3)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.03,
                            ),
                            child: Text(
                              'Must be at least 8 characters.',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleSmall!.fontSize,
                                fontWeight: FontWeight.normal,
                                color: const Color.fromRGBO(0, 0, 0, 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(
                      height: height * 0.01,
                    ),
                    if (step == 3)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.03,
                            ),
                            child: Text(
                              'Confirm password',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleLarge!.fontSize,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (step == 3)
                      TextField(
                        controller: confirmPasswordCtl,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: !isCheckedConfirmPassword,
                        cursorColor: Colors.black,
                        style: TextStyle(
                          fontSize: Get.textTheme.titleLarge!.fontSize,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              isTyping ? '' : 'Enter your confirm password',
                          hintStyle: TextStyle(
                            fontSize: Get.textTheme.titleLarge!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: const Color.fromRGBO(0, 0, 0, 0.3),
                          ),
                          prefixIcon: IconButton(
                            onPressed: null,
                            icon: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C9.243 2 7 4.243 7 7v2H6c-1.103 0-2 .897-2 2v9c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2v-9c0-1.103-.897-2-2-2h-1V7c0-2.757-2.243-5-5-5zM9 7c0-1.654 1.346-3 3-3s3 1.346 3 3v2H9V7zm9.002 13H13v-2.278c.595-.347 1-.985 1-1.722 0-1.103-.897-2-2-2s-2 .897-2 2c0 .736.405 1.375 1 1.722V20H6v-9h12l.002 9z"></path></svg>',
                              color: const Color(0xff7B7B7B),
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
                              color: const Color(0xff7B7B7B),
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
                    if (step == 3)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.03,
                            ),
                            child: Text(
                              'Both passwords must match.',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleSmall!.fontSize,
                                fontWeight: FontWeight.normal,
                                color: const Color.fromRGBO(0, 0, 0, 0.6),
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
                          color: Colors.red, // สีสำหรับแจ้งเตือน
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
                          ),
                        ),
                        SizedBox(
                          width: width * 0.01,
                        ),
                        InkWell(
                          onTap: () {
                            goToLoginPage();
                          },
                          child: Text(
                            'Sign in.',
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: Color(0xffAF4C31),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: resetPassword,
                      style: ElevatedButton.styleFrom(
                        fixedSize: Size(
                          width,
                          height * 0.04,
                        ),
                        backgroundColor: const Color(0xffD5843D),
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  void showNotification(String message) {
    textNotification = message;
    setState(() {});
  }

  void resetPassword() async {
    if (emailCtl.text.isEmpty) {
      showNotification('Email address is required');
      return;
    }

    if (!isValidEmail(emailCtl.text)) {
      showNotification('Invalid email address');
      return;
    }

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      loadingDialog();

      if (step == 1) {
        await handleStep1(url);
      } else if (step == 2) {
        await handleStep2();
      } else if (step == 3) {
        await handleStep3(url);
      }
    } finally {
      Get.back();
      isLoading = false;
    }
  }

  Future<void> handleStep1(String url) async {
    var responseGetuser = await http.post(
      Uri.parse("$url/user/api/get_user"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: getUserByEmailPostRequestToJson(
        GetUserByEmailPostRequest(
          email: emailCtl.text,
        ),
      ),
    );

    if (responseGetuser.statusCode == 200) {
      var responseGetUserByEmail =
          getUserByEmailPostResponstFromJson(responseGetuser.body);

      var responseOtp = await http.post(
        Uri.parse("$url/resetpassword/api/otp"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: sendOtpPostRequestToJson(
          SendOtpPostRequest(
            recipient: responseGetUserByEmail.email,
          ),
        ),
      );

      if (responseOtp.statusCode == 200) {
        var sendOTPResponse = sendOtpPostResponstFromJson(responseOtp.body);
        otp = sendOTPResponse.otp;
        showNotification('ref: ${sendOTPResponse.ref}');
        setState(() {
          step = 2;
        });
      }
    } else {
      Get.back();
      isLoading = false;
    }
  }

  Future<void> handleStep2() async {
    if (otpCtl.text.trim().isEmpty) {
      showNotification('OTP code is required');
      return;
    }

    if (otpCtl.text.trim() == otp.trim()) {
      setState(() {
        textNotification = '';
        step = 3;
      });
    } else {
      showNotification('OTP code is invalid');
    }
  }

  Future<void> handleStep3(String url) async {
    if (passwordCtl.text.isEmpty || confirmPasswordCtl.text.isEmpty) {
      showNotification('Password fields cannot be empty');
      return;
    }

    if (passwordCtl.text != confirmPasswordCtl.text) {
      showNotification('Passwords do not match');
      return;
    }

    var response = await http.put(
      Uri.parse("$url/resetpassword/api/resetpassword"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: resetPasswordPutRequestToJson(
        ResetPasswordPutRequest(
          email: emailCtl.text,
          hashedPassword: passwordCtl.text,
        ),
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        step = 1;
        textNotification = '';
      });
      Future.delayed(
        Duration.zero,
        () {
          Get.defaultDialog(
            title: "",
            barrierDismissible: false,
            titlePadding: EdgeInsets.zero,
            backgroundColor: Color(0xff494949),
            contentPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.02,
              vertical: MediaQuery.of(context).size.height * 0.02,
            ),
            content: Column(
              children: [
                Text(
                  'Success!',
                  style: TextStyle(
                    fontSize: Get.textTheme.headlineSmall!.fontSize,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Text(
                  'Your password has been reset successfully!',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleMedium!.fontSize,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Get.back();
                  Get.to(() => LoginPage());
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
                  'OK!',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleMedium!.fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void loadingDialog() {
    setState(() {
      isLoading = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        content: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xffCDBEAE),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void backToLoginPage() {
    Get.back();
  }

  void goToLoginPage() {
    Get.to(() => LoginPage());
  }
}
