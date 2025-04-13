import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/getUserByEmailPostRequest.dart';
import 'package:mydayplanner/models/request/isVerifyUserPutRequest.dart';
import 'package:mydayplanner/models/request/registerAccountPostRequest.dart';
import 'package:mydayplanner/models/request/sendOTPPostRequest.dart';
import 'package:mydayplanner/models/response/getUserByEmailPostResponst.dart';
import 'package:mydayplanner/models/response/registerAccountPostResponse.dart';
import 'package:mydayplanner/models/response/sendOTPPostResponst.dart';
import 'package:mydayplanner/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mydayplanner/pages/pageAdmin/navBarAdmin.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_enterprise.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controller สำหรับเก็บค่า input
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  FocusNode nameFocusNode = FocusNode();
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();

  Timer? _debounce;

  // สร้าง WebViewController
  late final WebViewController _controller;

  final String siteKey = dotenv.env['RECAPTCHA_SITE_KEY'] ?? '';

  var box = GetStorage();

  bool isTyping = false;
  bool isCheckedPassword = false;
  bool isCheckedConfirmPassword = false;
  bool isCaptchaVerified = false;
  bool iamHuman = false;

  String alearIconEmail = '';
  String alearName = '';
  String alearEmail = '';
  String alearPassword = '';
  String alearConfirmPassword = '';
  String alearRecaptcha = '';
  String warning = '';

  Color colorAlearName = Colors.black;
  Color colorAlearEmail = Colors.black;
  Color colorAlearPassword = Colors.black;
  Color colorAlearConfirmPassword = Colors.black;
  Color coloralearRecaptcha = Colors.grey;

  @override
  void initState() {
    super.initState();
    // ลองเริ่มต้น reCAPTCHA client
    initCaptchaClient();

    emailController.addListener(_onTextChanged);
    emailFocusNode.addListener(_onFocusChange);

    // สร้าง WebViewController สำหรับใช้เป็น fallback
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'captchaToken',
        onMessageReceived: (JavaScriptMessage message) {
          Navigator.of(context).pop(); // ปิด dialog
          _verifyWebViewCaptcha(message.message);
        },
      )
      ..loadRequest(Uri.dataFromString(
        _getCaptchaHTML(),
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ));
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () async {
      if (!emailFocusNode.hasFocus) return;

      final email = emailController.text.trim();
      if (email.isEmpty) {
        setState(() {
          alearEmail = '';
          alearIconEmail = '';
          colorAlearEmail = Colors.black;
        });
        return;
      }
      if (!isValidEmail(email)) {
        setState(() {
          alearEmail = 'Invalid email format';
          colorAlearEmail = Colors.red;
          alearIconEmail = '';
        });
        return;
      }

      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      var response = await http.post(
        Uri.parse("$url/user/api/get_user"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: getUserByEmailPostRequestToJson(
          GetUserByEmailPostRequest(email: email),
        ),
      );

      if (response.statusCode == 404) {
        setState(() {
          alearEmail = '';
          alearIconEmail =
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m10 15.586-3.293-3.293-1.414 1.414L10 18.414l9.707-9.707-1.414-1.414z"></path></svg>';
          colorAlearEmail = Colors.green;
        });
      } else {
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

        var config = await Configuration.getConfig();
        var url = config['apiEndpoint'];

        var responseGetuser = await http.post(
          Uri.parse("$url/user/api/get_user"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: getUserByEmailPostRequestToJson(
            GetUserByEmailPostRequest(
              email: emailController.text.trim(),
            ),
          ),
        );

        if (responseGetuser.statusCode == 404) {
          // อีเมลยังไม่ถูกใช้ -> ผ่าน
          setState(() {
            alearIconEmail =
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m10 15.586-3.293-3.293-1.414 1.414L10 18.414l9.707-9.707-1.414-1.414z"></path></svg>';
          });
        } else {
          // อีเมลนี้ถูกใช้แล้ว

          setState(() {
            alearIconEmail =
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M11.953 2C6.465 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.493 2 11.953 2zM12 20c-4.411 0-8-3.589-8-8s3.567-8 7.953-8C16.391 4 20 7.589 20 12s-3.589 8-8 8z"></path><path d="M11 7h2v7h-2zm0 8h2v2h-2z"></path></svg>';
            colorAlearEmail = Colors.red;
            alearEmail = 'This email is already in use';
          });
        }
      },
      child: Scaffold(
        appBar: null,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
                vertical: height * 0.05,
              ),
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
                            child: Row(
                              children: [
                                SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12.707 17.293 8.414 13H18v-2H8.414l4.293-4.293-1.414-1.414L4.586 12l6.707 6.707z"></path></svg>',
                                  color: const Color.fromRGBO(0, 0, 0, 0.6),
                                ),
                                Text(
                                  'back',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
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
                            padding: EdgeInsets.only(
                              bottom: height * 0.02,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.displaySmall!.fontSize,
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
                                  fontSize: Get.textTheme.titleLarge!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: height * 0.02,
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.03,
                            ),
                            child: Text(
                              'Name',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize,
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
                          fontSize: Get.textTheme.titleMedium!.fontSize,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: isTyping ? '' : 'Enter your name',
                          hintStyle: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: colorAlearName,
                          ),
                          prefixIcon: IconButton(
                            onPressed: null,
                            icon: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
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
                          padding: EdgeInsets.only(
                            left: width * 0.03,
                          ),
                          child: Row(
                            children: [
                              Text(
                                alearName,
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
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
                        controller: emailController,
                        focusNode: emailFocusNode,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(150),
                        ],
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: Colors.black,
                        style: TextStyle(
                          fontSize: Get.textTheme.titleMedium!.fontSize,
                        ),
                        decoration: InputDecoration(
                          hintText: isTyping ? '' : 'Enter your email address',
                          hintStyle: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: colorAlearEmail,
                          ),
                          prefixIcon: IconButton(
                            onPressed: null,
                            icon: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M20 4H4c-1.103 0-2 .897-2 2v12c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2zm0 2v.511l-8 6.223-8-6.222V6h16zM4 18V9.044l7.386 5.745a.994.994 0 0 0 1.228 0L20 9.044 20.002 18H4z"></path></svg>',
                              color: const Color(0xff7B7B7B),
                            ),
                          ),
                          suffixIcon: alearIconEmail.isNotEmpty
                              ? IconButton(
                                  onPressed: null,
                                  icon: SvgPicture.string(
                                    alearIconEmail,
                                    color: colorAlearEmail == Colors.red
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
                          padding: EdgeInsets.only(
                            left: width * 0.03,
                          ),
                          child: Row(
                            children: [
                              Text(
                                alearEmail,
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
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
                        controller: passwordController,
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
                            color: colorAlearPassword,
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
                              isCheckedPassword = !isCheckedPassword;
                              setState(() {});
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
                            borderSide: BorderSide(
                              width: colorAlearPassword == Colors.red ? 1 : 0.5,
                              color: colorAlearPassword,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              width: colorAlearPassword == Colors.red ? 1 : 0.5,
                              color: colorAlearPassword,
                            ),
                          ),
                        ),
                      ),
                      if (colorAlearPassword == Colors.red)
                        Padding(
                          padding: EdgeInsets.only(
                            left: width * 0.03,
                          ),
                          child: Row(
                            children: [
                              Text(
                                alearPassword,
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
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
                            padding: EdgeInsets.only(
                              left: width * 0.03,
                            ),
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
                      TextField(
                        controller: confirmPasswordController,
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
                            color: colorAlearConfirmPassword,
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
                              isCheckedConfirmPassword =
                                  !isCheckedConfirmPassword;
                              setState(() {});
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
                            borderSide: BorderSide(
                              width: colorAlearConfirmPassword == Colors.red
                                  ? 1
                                  : 0.5,
                              color: colorAlearConfirmPassword,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              width: colorAlearConfirmPassword == Colors.red
                                  ? 1
                                  : 0.5,
                              color: colorAlearConfirmPassword,
                            ),
                          ),
                        ),
                      ),
                      if (colorAlearConfirmPassword == Colors.red)
                        Padding(
                          padding: EdgeInsets.only(
                            left: width * 0.03,
                          ),
                          child: Row(
                            children: [
                              Text(
                                alearConfirmPassword,
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                  color: colorAlearConfirmPassword,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        height: height * 0.02,
                      ),
                      // แสดงสถานะ CAPTCHA
                      !iamHuman
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isCaptchaVerified
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCaptchaVerified
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
                                            Get.textTheme.bodyMedium!.fontSize,
                                        color: isCaptchaVerified
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
                                  vertical: 12,
                                  horizontal: 16,
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
                                        SizedBox(width: 12),
                                        Text(
                                          "I am human",
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme.bodyMedium!.fontSize,
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
                        SizedBox(
                          height: height * 0.01,
                        ),
                      if (coloralearRecaptcha == Colors.red)
                        Text(
                          alearRecaptcha,
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: coloralearRecaptcha,
                          ),
                        ),
                      SizedBox(
                        height: height * 0.02,
                      ),
                      ElevatedButton(
                        onPressed: register,
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(
                            width,
                            height * 0.04,
                          ),
                          backgroundColor: Color.fromRGBO(0, 122, 255, 1),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: Get.textTheme.titleLarge!.fontSize,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: height * 0.02,
                      ),
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          fontSize: Get.textTheme.titleMedium!.fontSize,
                          fontWeight: FontWeight.normal,
                          color: const Color.fromRGBO(0, 0, 0, 0.6),
                        ),
                      ),
                      InkWell(
                        onTap: goToLogin,
                        child: Text(
                          'Sign in.',
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
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

  void backToLoginPage() {
    Get.back();
  }

  void goToLogin() {
    Get.to(() => const LoginPage());
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$");
    return emailRegex.hasMatch(email);
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

  void register() async {
    bool hasError = false;

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
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    loadingDialog();
    var responseGetuser = await http.post(
      Uri.parse("$url/user/api/get_user"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: getUserByEmailPostRequestToJson(
        GetUserByEmailPostRequest(
          email: emailController.text.trim(),
        ),
      ),
    );

    Get.back();

    if (responseGetuser.statusCode == 404) {
      // อีเมลยังไม่ถูกใช้ -> ผ่าน
      setState(() {
        alearIconEmail =
            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m10 15.586-3.293-3.293-1.414 1.414L10 18.414l9.707-9.707-1.414-1.414z"></path></svg>';
      });

      // แสดง Loading Dialog
      // loadingDialog();
      // var responseRegisterAccount = await http.post(
      //   Uri.parse("$url/user/api/create_acc"),
      //   headers: {"Content-Type": "application/json; charset=utf-8"},
      //   body: registerAccountPostRequestToJson(
      //     RegisterAccountPostRequest(
      //       name: nameController.text,
      //       email: emailController.text.trim(),
      //       hashedPassword: passwordController.text,
      //       profile: "none-url",
      //     ),
      //   ),
      // );

      // if (responseRegisterAccount.statusCode == 201) {
      //   Get.back();

      //   RegisterAccountPostResponse responseGetUserByEmail =
      //       registerAccountPostResponseFromJson(responseRegisterAccount.body);

      //   if (responseGetUserByEmail.userId > 0) {
      //     nameFocusNode.unfocus();
      //     emailFocusNode.unfocus();
      //     passwordFocusNode.unfocus();
      //     confirmPasswordFocusNode.unfocus();
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
                  color: Color.fromRGBO(0, 122, 255, 1),
                ),
              ),
              Text(
                'You have successfully registered for a new membership',
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
              Get.to(() => const LoginPage());
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
              'Login',
              style: TextStyle(
                fontSize: Get.textTheme.titleLarge!.fontSize,
                color: Colors.white,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              nameController.clear();
              emailController.clear();
              passwordController.clear();
              confirmPasswordController.clear();
              isCaptchaVerified = false;
              setState(() {
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
                fontSize: Get.textTheme.headlineSmall!.fontSize,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(0, 122, 255, 1),
              ),
            ),
            Text(
              'Your account must verify your email first',
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
            onPressed: () async {
              Get.back();
              // แสดง Loading Dialog
              loadingDialog();
              var responseOtp = await http.post(
                Uri.parse("$url/otp/api/otp"),
                headers: {"Content-Type": "application/json; charset=utf-8"},
                body: sendOtpPostRequestToJson(
                  SendOtpPostRequest(
                    recipient: emailController.text.trim(),
                  ),
                ),
              );

              if (responseOtp.statusCode == 200) {
                Get.back();

                SendOtpPostResponst sendOTPResponse =
                    sendOtpPostResponstFromJson(responseOtp.body);

                //ส่ง email, otp, ref ไปยืนยันและ verify เมลหน้าต่อไป
                verifyOTP(
                  emailController.text,
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
      //   }
      // }
    } else {
      // อีเมลนี้ถูกใช้แล้ว
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
      var config = await Configuration.getConfig();
      var urls = config['apiEndpoint'];
      final url = Uri.parse('$urls/verify/verify-recaptcha');
      final response = await http.post(
        url,
        body: jsonEncode({'token': token, 'action': 'signup'}),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //ถ้า score มากกว่า 0.7 จะมองเป็นมนุษย์
        if (data['success'] == true && data['score'] > 0.7) {
          setState(() {
            isCaptchaVerified = true;
            iamHuman = false;
          });
          log("CAPTCHA Verified Successfully");
        } else {
          // แสดง button ให้ผู้ใช้ยืนยันตัวตนด้วยการกดปุ่ม
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

  void _verifyWebViewCaptcha(String token) async {
    try {
      await verifyCaptchaOnServer(token);
    } catch (e) {
      // _showErrorDialog("Error verifying CAPTCHA: $e");
    }
  }

  // Webview implementation for reCAPTCHA fallback
  String _getCaptchaHTML() {
    return '''
<html>
<head>
  <title>reCAPTCHA</title>
  <script src="https://www.google.com/recaptcha/enterprise.js" async defer></script>
  <style>
    body {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background-color: #f9f9f9;
      font-family: Arial, sans-serif;
    }
    .captcha-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
      background-color: white;
    }
    .captcha-title {
      margin-bottom: 20px;
      font-size: 16px;
      color: #333;
    }
  </style>
  <script>
    function onSubmit(token) {
      window.captchaToken.postMessage(token);
    }
  </script>
</head>
<body>
  <div class="captcha-container">
    <div class="captcha-title">Please verify you're human</div>
    <div class="g-recaptcha"
         data-sitekey="$siteKey"
         data-callback="onSubmit"
         data-action="LOGIN">
    </div>
  </div>
</body>
</html>
  ''';
  }

  void _showCaptchaWebView() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Verify you\'re human',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 320,
                  width: 320,
                  child: WebViewWidget(controller: _controller),
                ),
                const SizedBox(height: 16),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
  } // ฟังก์ชันตรวจสอบ OTP

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
        Uri.parse("$url/otp/api/is_verify"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: isVerifyUserPutRequestToJson(
          IsVerifyUserPutRequest(
            email: email,
          ),
        ),
      );

      if (responseIsverify.statusCode == 200) {
        Get.back();
        setState(() {});

        loadingDialog();
        var responseGetuser = await http.post(
          Uri.parse("$url/user/api/get_user"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: getUserByEmailPostRequestToJson(
            GetUserByEmailPostRequest(
              email: email,
            ),
          ),
        );
        if (responseGetuser.statusCode == 200) {
          Get.back();
          setState(() {});

          //เก็บ email user ไว้ใน storage ไว้ใช้ด้วย
          box.write('email', email);

          Get.back();
        }
      } else {
        Get.back();
        setState(() {});
      }

      warning = '';
      setState(() {});
    } else {
      warning = 'F21F1F';
      setState(() {});
    }
  }
}
