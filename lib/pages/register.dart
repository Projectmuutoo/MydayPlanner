import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/getUserByEmailPostRequest.dart';
import 'package:mydayplanner/models/request/registerAccountPostRequest.dart';
import 'package:mydayplanner/models/response/registerAccountPostResponse.dart';
import 'package:mydayplanner/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mydayplanner/pages/verifyOTP.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:provider/provider.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_enterprise.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ---------------------- 🎯 Controllers (TextEditing) ----------------------
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController emailConfirmOtpCtl = TextEditingController();

  // ---------------------- 🎯 Controllers (FocusNode) ----------------------
  FocusNode nameFocusNode = FocusNode();
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();
  FocusNode emailConfirmOtpFocusNode = FocusNode();

  // ---------------------- 🕒 Timer ----------------------
  Timer? _debounce;

  // ---------------------- 🧱 Local Storage ----------------------
  var box = GetStorage();

  // ---------------------- ✅ State Flags ----------------------
  bool isTyping = false;
  bool isCheckedPassword = false;
  bool isCheckedConfirmPassword = false;
  bool isCaptchaVerified = false;
  bool iamHuman = false;
  bool blockOTP = false;

  // ---------------------- 🔤 Strings (Validation / Alert Messages) ----------------------
  String alearIconEmail = '';
  String alearName = '';
  String alearEmail = '';
  String alearPassword = '';
  String alearConfirmPassword = '';
  String alearRecaptcha = '';
  String? expiresAtEmail;

  // ---------------------- 🎨 Colors ----------------------
  Color colorAlearName = Colors.black;
  Color colorAlearEmail = Colors.black;
  Color colorAlearPassword = Colors.black;
  Color colorAlearConfirmPassword = Colors.black;
  Color coloralearRecaptcha = Colors.grey;

  // ---------------------- 🔐 Keys ----------------------
  final String siteKey = dotenv.env['RECAPTCHA_SITE_KEY'] ?? '';

  late String url;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    // ลองเริ่มต้น reCAPTCHA client
    initCaptchaClient();

    emailController.addListener(_onTextChanged);
    emailFocusNode.addListener(_onFocusChange);
  }

  @override
  Widget build(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () async {
        if (nameFocusNode.hasFocus) {
          nameFocusNode.unfocus();
        }
        if (emailFocusNode.hasFocus) {
          emailFocusNode.unfocus();
        }
        if (passwordFocusNode.hasFocus) {
          passwordFocusNode.unfocus();
        }
        if (confirmPasswordFocusNode.hasFocus) {
          confirmPasswordFocusNode.unfocus();
        }
        bool hasError = false;
        if (!mounted) return;
        setState(() {
          // Name validation
          if (nameController.text.isEmpty) {
            alearName = 'Please enter your name';
            colorAlearName = Colors.red;
          } else {
            colorAlearName = Colors.green;
            alearName = '';
          }

          // Email validation
          if (emailController.text.isEmpty) {
            alearEmail = 'Please enter your email';
            colorAlearEmail = Colors.red;
            hasError = true;
          } else if (!isValidEmail(emailController.text)) {
            alearEmail = 'Invalid email format';
            colorAlearEmail = Colors.red;
            hasError = true;
          } else {
            colorAlearEmail = Colors.green;
            alearEmail = '';
            alearIconEmail = '';
          }

          // Password validation
          if (passwordController.text.isEmpty) {
            alearPassword = 'Please enter your password';
            colorAlearPassword = Colors.red;
            hasError = true;
          } else if (!isValidPassword(passwordController.text)) {
            alearPassword =
                'Password must contain at least 8 digits\nor lowercase letters';
            colorAlearPassword = Colors.red;
            hasError = true;
          } else {
            colorAlearPassword = Colors.green;
            alearPassword = '';
          }

          // Confirm password validation
          if (confirmPasswordController.text.isEmpty) {
            alearConfirmPassword = 'Please enter your confirm password';
            colorAlearConfirmPassword = Colors.red;
          } else if (confirmPasswordController.text !=
              passwordController.text) {
            alearConfirmPassword = 'Passwords do not match';
            colorAlearConfirmPassword = Colors.red;
          } else {
            colorAlearConfirmPassword = Colors.green;
            alearConfirmPassword = '';
          }

          // Check Recaptcha
          if (!isCaptchaVerified) {
            alearRecaptcha = 'Please verify you are human';
            coloralearRecaptcha = Colors.red;
          } else {
            coloralearRecaptcha = Colors.green;
            alearRecaptcha = '';
          }
        });

        if (hasError) return;

        url = await loadAPIEndpoint();

        var responseGetuser = await http.post(
          Uri.parse("$url/user/getemail"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: getUserByEmailPostRequestToJson(
            GetUserByEmailPostRequest(email: emailController.text.trim()),
          ),
        );

        if (responseGetuser.statusCode == 404) {
          // อีเมลยังไม่ถูกใช้ -> ผ่าน
          if (!mounted) return;
          setState(() {
            alearIconEmail =
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m10 15.586-3.293-3.293-1.414 1.414L10 18.414l9.707-9.707-1.414-1.414z"></path></svg>';
          });
        } else {
          // อีเมลนี้ถูกใช้แล้ว

          if (!mounted) return;
          setState(() {
            alearIconEmail =
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M11.953 2C6.465 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.493 2 11.953 2zM12 20c-4.411 0-8-3.589-8-8s3.567-8 7.953-8C16.391 4 20 7.589 20 12s-3.589 8-8 8z"></path><path d="M11 7h2v7h-2zm0 8h2v2h-2z"></path></svg>';
            colorAlearEmail = Colors.red;
            alearEmail = 'This email is already in use';
          });
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: backToLoginPage,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.01,
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.string(
                                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12.707 17.293 8.414 13H18v-2H8.414l4.293-4.293-1.414-1.414L4.586 12l6.707 6.707z"></path></svg>',
                                      color: Color(0x99000000),
                                    ),
                                    Text(
                                      'back',
                                      style: TextStyle(
                                        fontSize:
                                            Get
                                                .textTheme
                                                .titleMedium!
                                                .fontSize! *
                                            MediaQuery.of(
                                              context,
                                            ).textScaleFactor,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0x99000000),
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
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: height * 0.02),
                              child: Row(
                                children: [
                                  Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize:
                                          Get
                                              .textTheme
                                              .headlineMedium!
                                              .fontSize! *
                                          MediaQuery.of(
                                            context,
                                          ).textScaleFactor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Please register to login.',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize! *
                                        MediaQuery.of(context).textScaleFactor,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.02),
                    Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: width * 0.03),
                              child: Text(
                                'Name',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.titleSmall!.fontSize! *
                                      MediaQuery.of(context).textScaleFactor,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: nameController,
                          focusNode: nameFocusNode,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(20),
                          ],
                          keyboardType: TextInputType.text,
                          cursorColor: Colors.black,
                          style: TextStyle(
                            fontSize:
                                Get.textTheme.titleSmall!.fontSize! *
                                MediaQuery.of(context).textScaleFactor,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: isTyping ? '' : 'Enter your name',
                            hintStyle: TextStyle(
                              fontSize:
                                  Get.textTheme.titleSmall!.fontSize! *
                                  MediaQuery.of(context).textScaleFactor,
                              fontWeight: FontWeight.normal,
                              color: colorAlearName,
                            ),
                            prefixIcon: IconButton(
                              onPressed: null,
                              icon: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                color: Color(0xff7B7B7B),
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
                              borderSide: BorderSide(
                                width: colorAlearName == Colors.red ? 1 : 0.5,
                                color: colorAlearName,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                width: colorAlearName == Colors.red ? 1 : 0.5,
                                color: colorAlearName,
                              ),
                            ),
                          ),
                        ),
                        if (colorAlearName == Colors.red)
                          Padding(
                            padding: EdgeInsets.only(left: width * 0.03),
                            child: Row(
                              children: [
                                Text(
                                  alearName,
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleSmall!.fontSize! *
                                        MediaQuery.of(context).textScaleFactor,
                                    fontWeight: FontWeight.normal,
                                    color: colorAlearName,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: width * 0.03),
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.titleSmall!.fontSize! *
                                      MediaQuery.of(context).textScaleFactor,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: emailController,
                          focusNode: emailFocusNode,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(150),
                          ],
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: Colors.black,
                          style: TextStyle(
                            fontSize:
                                Get.textTheme.titleSmall!.fontSize! *
                                MediaQuery.of(context).textScaleFactor,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                isTyping ? '' : 'Enter your email address',
                            hintStyle: TextStyle(
                              fontSize:
                                  Get.textTheme.titleSmall!.fontSize! *
                                  MediaQuery.of(context).textScaleFactor,
                              fontWeight: FontWeight.normal,
                              color: colorAlearEmail,
                            ),
                            prefixIcon: IconButton(
                              onPressed: null,
                              icon: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M20 4H4c-1.103 0-2 .897-2 2v12c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2zm0 2v.511l-8 6.223-8-6.222V6h16zM4 18V9.044l7.386 5.745a.994.994 0 0 0 1.228 0L20 9.044 20.002 18H4z"></path></svg>',
                                color: Color(0xff7B7B7B),
                              ),
                            ),
                            suffixIcon:
                                alearIconEmail.isNotEmpty
                                    ? IconButton(
                                      onPressed: null,
                                      icon: SvgPicture.string(
                                        alearIconEmail,
                                        color:
                                            colorAlearEmail == Colors.red
                                                ? Colors.red
                                                : Colors.green,
                                      ),
                                    )
                                    : null,
                            constraints: BoxConstraints(
                              maxHeight: height * 0.05,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: width * 0.02,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                width: colorAlearEmail == Colors.red ? 1 : 0.5,
                                color: colorAlearEmail,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                width: colorAlearEmail == Colors.red ? 1 : 0.5,
                                color: colorAlearEmail,
                              ),
                            ),
                          ),
                        ),
                        if (colorAlearEmail == Colors.red)
                          Padding(
                            padding: EdgeInsets.only(left: width * 0.03),
                            child: Row(
                              children: [
                                Text(
                                  alearEmail,
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleSmall!.fontSize! *
                                        MediaQuery.of(context).textScaleFactor,
                                    fontWeight: FontWeight.normal,
                                    color: colorAlearEmail,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: width * 0.03),
                              child: Text(
                                'Password',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.titleSmall!.fontSize! *
                                      MediaQuery.of(context).textScaleFactor,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: passwordController,
                          focusNode: passwordFocusNode,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: !isCheckedPassword,
                          cursorColor: Colors.black,
                          style: TextStyle(
                            fontSize:
                                Get.textTheme.titleSmall!.fontSize! *
                                MediaQuery.of(context).textScaleFactor,
                          ),
                          decoration: InputDecoration(
                            hintText: isTyping ? '' : 'Enter your password',
                            hintStyle: TextStyle(
                              fontSize:
                                  Get.textTheme.titleSmall!.fontSize! *
                                  MediaQuery.of(context).textScaleFactor,
                              fontWeight: FontWeight.normal,
                              color: colorAlearPassword,
                            ),
                            prefixIcon: IconButton(
                              onPressed: null,
                              icon: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C9.243 2 7 4.243 7 7v2H6c-1.103 0-2 .897-2 2v9c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2v-9c0-1.103-.897-2-2-2h-1V7c0-2.757-2.243-5-5-5zM9 7c0-1.654 1.346-3 3-3s3 1.346 3 3v2H9V7zm9.002 13H13v-2.278c.595-.347 1-.985 1-1.722 0-1.103-.897-2-2-2s-2 .897-2 2c0 .736.405 1.375 1 1.722V20H6v-9h12l.002 9z"></path></svg>',
                                color: Color(0xff7B7B7B),
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
                                color: Color(0xff7B7B7B),
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
                              borderSide: BorderSide(
                                width:
                                    colorAlearPassword == Colors.red ? 1 : 0.5,
                                color: colorAlearPassword,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                width:
                                    colorAlearPassword == Colors.red ? 1 : 0.5,
                                color: colorAlearPassword,
                              ),
                            ),
                          ),
                        ),
                        if (colorAlearPassword == Colors.red)
                          Padding(
                            padding: EdgeInsets.only(left: width * 0.03),
                            child: Row(
                              children: [
                                Text(
                                  alearPassword,
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleSmall!.fontSize! *
                                        MediaQuery.of(context).textScaleFactor,
                                    fontWeight: FontWeight.normal,
                                    color: colorAlearPassword,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: width * 0.03),
                              child: Text(
                                'Confirm password',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.titleSmall!.fontSize! *
                                      MediaQuery.of(context).textScaleFactor,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: confirmPasswordController,
                          focusNode: confirmPasswordFocusNode,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: !isCheckedConfirmPassword,
                          cursorColor: Colors.black,
                          style: TextStyle(
                            fontSize:
                                Get.textTheme.titleSmall!.fontSize! *
                                MediaQuery.of(context).textScaleFactor,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                isTyping ? '' : 'Enter your confirm password',
                            hintStyle: TextStyle(
                              fontSize:
                                  Get.textTheme.titleSmall!.fontSize! *
                                  MediaQuery.of(context).textScaleFactor,
                              fontWeight: FontWeight.normal,
                              color: colorAlearConfirmPassword,
                            ),
                            prefixIcon: IconButton(
                              onPressed: null,
                              icon: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C9.243 2 7 4.243 7 7v2H6c-1.103 0-2 .897-2 2v9c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2v-9c0-1.103-.897-2-2-2h-1V7c0-2.757-2.243-5-5-5zM9 7c0-1.654 1.346-3 3-3s3 1.346 3 3v2H9V7zm9.002 13H13v-2.278c.595-.347 1-.985 1-1.722 0-1.103-.897-2-2-2s-2 .897-2 2c0 .736.405 1.375 1 1.722V20H6v-9h12l.002 9z"></path></svg>',
                                color: Color(0xff7B7B7B),
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
                                color: Color(0xff7B7B7B),
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
                              borderSide: BorderSide(
                                width:
                                    colorAlearConfirmPassword == Colors.red
                                        ? 1
                                        : 0.5,
                                color: colorAlearConfirmPassword,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                width:
                                    colorAlearConfirmPassword == Colors.red
                                        ? 1
                                        : 0.5,
                                color: colorAlearConfirmPassword,
                              ),
                            ),
                          ),
                        ),
                        if (colorAlearConfirmPassword == Colors.red)
                          Padding(
                            padding: EdgeInsets.only(left: width * 0.03),
                            child: Row(
                              children: [
                                Text(
                                  alearConfirmPassword,
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleSmall!.fontSize! *
                                        MediaQuery.of(context).textScaleFactor,
                                    fontWeight: FontWeight.normal,
                                    color: colorAlearConfirmPassword,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: height * 0.02),
                        // แสดงสถานะ CAPTCHA
                        !iamHuman
                            ? Container(
                              padding: EdgeInsets.symmetric(
                                vertical: height * 0.015,
                                horizontal: width * 0.025,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isCaptchaVerified
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      isCaptchaVerified
                                          ? Colors.green
                                          : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  isCaptchaVerified
                                      ? Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 18,
                                      )
                                      : SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          color: Colors.grey,
                                        ),
                                      ),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      isCaptchaVerified
                                          ? "Verification Complete"
                                          : "Verification Required",
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.bodySmall!.fontSize! *
                                            MediaQuery.of(
                                              context,
                                            ).textScaleFactor,
                                        color:
                                            isCaptchaVerified
                                                ? Colors.green
                                                : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : InkWell(
                              onTap: () {
                                setState(() {
                                  isCaptchaVerified = true;
                                  iamHuman = false;
                                  coloralearRecaptcha = Colors.green;
                                  alearRecaptcha = '';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: height * 0.01,
                                  horizontal: width * 0.025,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: coloralearRecaptcha,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.string(
                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12c.001 5.515 4.487 10.001 10 10.001 5.514 0 10-4.486 10.001-10.001 0-5.514-4.486-10-10.001-10zm0 18.001c-4.41 0-7.999-3.589-8-8.001 0-4.411 3.589-8 8-8 4.412 0 8.001 3.589 8.001 8-.001 4.412-3.59 8.001-8.001 8.001z"></path></svg>',
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: width * 0.02),
                                        Text(
                                          "I am human",
                                          style: TextStyle(
                                            fontSize:
                                                Get
                                                    .textTheme
                                                    .bodySmall!
                                                    .fontSize! *
                                                MediaQuery.of(
                                                  context,
                                                ).textScaleFactor,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        if (coloralearRecaptcha == Colors.red)
                          SizedBox(height: height * 0.01),
                        if (coloralearRecaptcha == Colors.red)
                          Text(
                            alearRecaptcha,
                            style: TextStyle(
                              fontSize:
                                  Get.textTheme.labelMedium!.fontSize! *
                                  MediaQuery.of(context).textScaleFactor,
                              fontWeight: FontWeight.normal,
                              color: coloralearRecaptcha,
                            ),
                          ),
                        SizedBox(height: height * 0.02),
                        ElevatedButton(
                          onPressed: register,
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(width, height * 0.04),
                            backgroundColor: Color(0xFF007AFF),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize:
                                  Get.textTheme.titleMedium!.fontSize! *
                                  MediaQuery.of(context).textScaleFactor,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            fontSize:
                                Get.textTheme.titleSmall!.fontSize! *
                                MediaQuery.of(context).textScaleFactor,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey,
                          ),
                        ),
                        InkWell(
                          onTap: goToLogin,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.02,
                            ),
                            child: Text(
                              'Sign in.',
                              style: TextStyle(
                                fontSize:
                                    Get.textTheme.titleSmall!.fontSize! *
                                    MediaQuery.of(context).textScaleFactor,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
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
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () async {
      if (!emailFocusNode.hasFocus) return;

      final email = emailController.text.trim();
      if (email.isEmpty) {
        if (!mounted) return;
        setState(() {
          alearEmail = '';
          alearIconEmail = '';
          colorAlearEmail = Colors.black;
        });
        return;
      }
      if (!isValidEmail(email)) {
        if (!mounted) return;
        setState(() {
          alearEmail = 'Invalid email format';
          colorAlearEmail = Colors.red;
          alearIconEmail = '';
        });
        return;
      }

      url = await loadAPIEndpoint();

      var response = await http.post(
        Uri.parse("$url/email"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: getUserByEmailPostRequestToJson(
          GetUserByEmailPostRequest(email: email),
        ),
      );

      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          alearEmail = '';
          alearIconEmail =
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m10 15.586-3.293-3.293-1.414 1.414L10 18.414l9.707-9.707-1.414-1.414z"></path></svg>';
          colorAlearEmail = Colors.green;
        });
      } else {
        if (!mounted) return;
        setState(() {
          alearEmail = 'This email is already in use';
          alearIconEmail =
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M11.953 2C6.465 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.493 2 11.953 2zM12 20c-4.411 0-8-3.589-8-8s3.567-8 7.953-8C16.391 4 20 7.589 20 12s-3.589 8-8 8z"></path><path d="M11 7h2v7h-2zm0 8h2v2h-2z"></path></svg>';
          colorAlearEmail = Colors.red;
        });
      }
    });
  }

  void _onFocusChange() {
    if (!emailFocusNode.hasFocus) {
      // ถ้าเลิก focus ก็ยกเลิก timer
      _debounce?.cancel();
    }
  }

  void backToLoginPage() {
    Get.back();
  }

  void goToLogin() {
    Get.to(() => LoginPage());
  }

  bool isValidEmail(String email) {
    final RegExp emailRegExp = RegExp(
      r"^[a-zA-Z0-9._%+-]+@(?:gmail\.com|hotmail\.com|outlook\.com|yahoo\.com|icloud\.com)$",
    );
    return emailRegExp.hasMatch(email);
  }

  bool isValidPassword(String password) {
    if (password.length < 8) return false;

    // นับจำนวนตัวเลขและตัวพิมพ์เล็กรวมกัน
    int count = RegExp(r'[0-9a-z]').allMatches(password).length;

    return count >= 8;
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

  void register() async {
    bool hasError = false;

    if (!mounted) return;
    setState(() {
      // Name validation
      if (nameController.text.isEmpty) {
        alearName = 'Please enter your name';
        colorAlearName = Colors.red;
        hasError = true;
      } else {
        colorAlearName = Colors.green;
        alearName = '';
      }

      // Email validation
      if (emailController.text.isEmpty) {
        alearEmail = 'Please enter your email';
        colorAlearEmail = Colors.red;
        hasError = true;
      } else if (!isValidEmail(emailController.text)) {
        alearEmail = 'Invalid email format';
        colorAlearEmail = Colors.red;
        hasError = true;
      } else {
        colorAlearEmail = Colors.green;
        alearEmail = '';
        alearIconEmail = '';
      }

      // Password validation
      if (passwordController.text.isEmpty) {
        alearPassword = 'Please enter your password';
        colorAlearPassword = Colors.red;
        hasError = true;
      } else if (!isValidPassword(passwordController.text)) {
        alearPassword =
            'Password must contain at least 8 digits\nor lowercase letters';
        colorAlearPassword = Colors.red;
        hasError = true;
      } else {
        colorAlearPassword = Colors.green;
        alearPassword = '';
      }

      // Confirm password validation
      if (confirmPasswordController.text.isEmpty) {
        alearConfirmPassword = 'Please enter your confirm password';
        colorAlearConfirmPassword = Colors.red;
        hasError = true;
      } else if (confirmPasswordController.text != passwordController.text) {
        alearConfirmPassword = 'Passwords do not match';
        colorAlearConfirmPassword = Colors.red;
        hasError = true;
      } else {
        colorAlearConfirmPassword = Colors.green;
        alearConfirmPassword = '';
      }

      // Check Recaptcha
      if (!isCaptchaVerified) {
        alearRecaptcha = 'Please verify you are human';
        coloralearRecaptcha = Colors.red;
        hasError = true;
      } else {
        coloralearRecaptcha = Colors.green;
        alearRecaptcha = '';
      }
    });

    // ❌ ถ้ามี error – ไม่ต้องเรียก API
    if (hasError) return;

    // ✅ ถ้าผ่านทุกช่อง – ค่อยเรียก API
    url = await loadAPIEndpoint();

    loadingDialog();
    var responseGetuser = await http.post(
      Uri.parse("$url/email"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: getUserByEmailPostRequestToJson(
        GetUserByEmailPostRequest(email: emailController.text.trim()),
      ),
    );

    Get.back();

    if (responseGetuser.statusCode != 200) {
      // อีเมลยังไม่ถูกใช้ -> ผ่าน
      if (!mounted) return;
      setState(() {
        alearIconEmail =
            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m10 15.586-3.293-3.293-1.414 1.414L10 18.414l9.707-9.707-1.414-1.414z"></path></svg>';
      });

      // แสดง Loading Dialog
      // loadingDialog();
      loadingDialog();
      var responseRegisterAccount = await http.post(
        Uri.parse("$url/auth/signup"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: registerAccountPostRequestToJson(
          RegisterAccountPostRequest(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          ),
        ),
      );

      if (responseRegisterAccount.statusCode == 200) {
        Get.back();

        RegisterAccountPostResponse responseGetUserByEmail =
            registerAccountPostResponseFromJson(responseRegisterAccount.body);

        if (responseGetUserByEmail.message == 'User created successfully') {
          nameFocusNode.unfocus();
          emailFocusNode.unfocus();
          passwordFocusNode.unfocus();
          confirmPasswordFocusNode.unfocus();
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
                      fontSize: Get.textTheme.titleLarge!.fontSize,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  Text(
                    'You have successfully registered for a new membership',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleSmall!.fontSize,
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
                  Get.to(() => LoginPage());
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
                    fontSize: Get.textTheme.titleMedium!.fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  if (!mounted) return;
                  setState(() {
                    nameController.clear();
                    emailController.clear();
                    passwordController.clear();
                    confirmPasswordController.clear();
                    isCaptchaVerified = false;
                    alearIconEmail = '';
                    colorAlearName = Colors.black;
                    colorAlearEmail = Colors.black;
                    colorAlearPassword = Colors.black;
                    colorAlearConfirmPassword = Colors.black;
                    coloralearRecaptcha = Colors.grey;
                  });
                  initCaptchaClient();
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
                    fontSize: Get.textTheme.titleMedium!.fontSize,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          );
          // Aleart Verify Account
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
                  'Confirm now?',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleLarge!.fontSize,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF007AFF),
                  ),
                ),
                Text(
                  'Your account must verify your email first',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleSmall!.fontSize,
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
                  showModalConfirmEmail(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
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
                    fontSize: Get.textTheme.titleMedium!.fontSize,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          );
        }
      }
    } else {
      // อีเมลนี้ถูกใช้แล้ว
      if (!mounted) return;
      setState(() {
        alearIconEmail =
            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M11.953 2C6.465 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.493 2 11.953 2zM12 20c-4.411 0-8-3.589-8-8s3.567-8 7.953-8C16.391 4 20 7.589 20 12s-3.589 8-8 8z"></path><path d="M11 7h2v7h-2zm0 8h2v2h-2z"></path></svg>';
        colorAlearEmail = Colors.red;
        alearEmail = 'This email is already in use';
      });
      return;
    }
  }

  void initCaptchaClient() async {
    try {
      // เริ่มต้น reCAPTCHA client
      bool isInitialized = await RecaptchaEnterprise.initClient(siteKey);

      if (isInitialized) {
        log("reCAPTCHA Client Initialized Successfully");
        executeCaptcha();
      } else {
        log("Failed to initialize reCAPTCHA Client");
        // _showErrorDialog("Failed to initialize reCAPTCHA Client");
      }
    } catch (e) {
      log("Error initializing reCAPTCHA Client: $e");
      // _showErrorDialog("Error initializing reCAPTCHA: $e");
    }
  }

  void executeCaptcha() async {
    try {
      final token = await RecaptchaEnterprise.execute(RecaptchaAction.SIGNUP());
      // log("CAPTCHA Token: $token");

      // ส่ง Token ไปตรวจสอบกับ Backend
      await verifyCaptchaOnServer(token);
    } catch (e) {
      log("Error executing reCAPTCHA: $e");
      // _showErrorDialog("Error executing reCAPTCHA: $e");
    }
  }

  Future<void> verifyCaptchaOnServer(String token) async {
    try {
      // ใช้ API endpoint ของคุณเพื่อยืนยัน reCAPTCHA token
      // หมายเหตุ: แนะนำให้ยืนยัน reCAPTCHA บน server ของคุณไม่ใช่จาก client โดยตรง
      url = await loadAPIEndpoint();
      final response = await http.post(
        Uri.parse('$url/auth/captcha'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'action': 'signup'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //ถ้า score มากกว่า 0.7 จะมองเป็นมนุษย์
        if (data['success'] == true && data['score'] > 0.7) {
          if (!mounted) return;
          setState(() {
            isCaptchaVerified = true;
            iamHuman = false;
          });
          log("CAPTCHA Verified Successfully");
        } else {
          // แสดง button ให้ผู้ใช้ยืนยันตัวตนด้วยการกดปุ่ม
          if (!mounted) return;
          setState(() {
            iamHuman = true;
          });
        }
      } else {
        // _showErrorDialog("Error verifying CAPTCHA: ${response.statusCode}");
      }
    } catch (e) {
      // _showErrorDialog("Error connecting to server: $e");
    }
  }

  showModalConfirmEmail(String email, String password) {
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
                                  blockOTP = false;
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
                                      .setPassword(password);
                                  appData.keepEmailToUserPageVerifyOTP.setRef(
                                    sendOTPResponse['ref'],
                                  );
                                  appData.keepEmailToUserPageVerifyOTP.setCase(
                                    'verifyEmail-Register',
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
                              backgroundColor: Color(0xFF007AFF),
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

  String formatTimestampTo12HourTimeWithSeconds(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('hh:mm:ss a').format(dateTime);
    return formattedTime;
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}
