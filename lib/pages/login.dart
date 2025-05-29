import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/googleLoginUserPostRequest.dart';
import 'package:mydayplanner/models/request/signInUserPostRequest.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
import 'package:mydayplanner/models/response/googleLoginPostResponse.dart';
import 'package:mydayplanner/models/response/signInUserPostResponst.dart';
import 'package:mydayplanner/pages/pageAdmin/navBarAdmin.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:mydayplanner/pages/register.dart';
import 'package:mydayplanner/pages/resetPassword.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mydayplanner/pages/verifyOTP.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ---------------------- 🎯 Controllers (TextEditing) ----------------------
  TextEditingController emailCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController emailConfirmOtpCtl = TextEditingController();

  // ---------------------- 🎯 Controllers (FocusNode) ----------------------
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode emailConfirmOtpFocusNode = FocusNode();

  // ---------------------- ✅ State Flags ----------------------
  bool isTyping = false;
  bool isCheckedPassword = false;
  bool blockOTP = false;

  // ---------------------- 🔐 Auth ----------------------
  final GoogleSignIn googleSignIn = GoogleSignIn();

  // ---------------------- 🧱 Local Storage ----------------------
  var box = GetStorage();
  final storage = FlutterSecureStorage();
  // ---------------------- 🔤 Strings ----------------------
  String textNotification = '';
  String? expiresAtEmail;
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
  }

  @override
  Widget build(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      child: Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () {
              if (emailFocusNode.hasFocus) {
                emailFocusNode.unfocus();
              }
              if (passwordFocusNode.hasFocus) {
                passwordFocusNode.unfocus();
              }
            },
            child: Scaffold(
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: width * 0.05,
                        left: width * 0.05,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
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
                                          'Welcome!',
                                          style: TextStyle(
                                            fontSize:
                                                Get
                                                    .textTheme
                                                    .displaySmall!
                                                    .fontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Please Sign in to continue.',
                                        style: TextStyle(
                                          fontSize:
                                              Get
                                                  .textTheme
                                                  .titleLarge!
                                                  .fontSize,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              SizedBox(height: height * 0.02),
                              Image.asset(
                                "assets/images/ImageShow.png",
                                height: height * 0.2,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: height * 0.02),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: width * 0.03,
                                    ),
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
                                controller: emailCtl,
                                focusNode: emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                cursorColor: Colors.black,
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      isTyping
                                          ? ''
                                          : 'Enter your email address…',
                                  hintStyle: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
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

                              SizedBox(height: height * 0.01),

                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: width * 0.03,
                                    ),
                                    child: Text(
                                      'Password',
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
                                controller: passwordCtl,
                                focusNode: passwordFocusNode,
                                keyboardType: TextInputType.visiblePassword,
                                obscureText: !isCheckedPassword,
                                cursorColor: Colors.black,
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      isTyping ? '' : 'Enter your password',
                                  hintStyle: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
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

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                    onTap: forgotPassword,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.02,
                                      ),
                                      child: Text(
                                        'Forgot password?',
                                        style: TextStyle(
                                          fontSize:
                                              Get
                                                  .textTheme
                                                  .titleMedium!
                                                  .fontSize,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: height * 0.01),
                              ElevatedButton(
                                onPressed: login,
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(width, height * 0.04),
                                  backgroundColor: Color(0xFF007AFF),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Sign in',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (textNotification.isNotEmpty)
                                SizedBox(height: height * 0.01),
                              if (textNotification.isNotEmpty)
                                Text(
                                  textNotification,
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.red,
                                  ),
                                ),
                              SizedBox(height: height * 0.01),
                              Text(
                                '- or -',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              ElevatedButton(
                                onPressed: signInWithGoogle,
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(width, height * 0.05),
                                  backgroundColor: Colors.white,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/LogoGoogle.png',
                                      height: height * 0.08,
                                      fit: BoxFit.contain,
                                    ),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleLarge!.fontSize,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              Text(
                                'Don’t have an account?',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey,
                                ),
                              ),
                              InkWell(
                                onTap: goToRegisterPage,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.02,
                                  ),
                                  child: Text(
                                    'Create yours now.',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize,
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
        },
      ),
    );
  }

  void forgotPassword() {
    Get.to(() => ResetpasswordPage());
  }

  void showNotification(String message) {
    setState(() {
      textNotification = message;
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      url = await loadAPIEndpoint();

      loadingDialog(); // แสดง Loading Dialog

      GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // ผู้ใช้ยกเลิกการเข้าสู่ระบบ
      if (googleUser == null) {
        Get.back();
        return;
      }

      try {
        // เรียกเมธอด authentication จากออบเจกต์ googleUser เพื่อขอรับข้อมูลการตรวจสอบสิทธิ์ (tokens)
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      } finally {
        Get.back();
      }

      GoogleLoginUserPostRequest jsonLoginGoogleUser =
          GoogleLoginUserPostRequest(
            email: googleUser.email,
            name: googleUser.displayName.toString(),
            profile: googleUser.photoUrl.toString(),
          );

      loadingDialog();
      var responseLoginGoogle = await http.post(
        Uri.parse("$url/auth/googlelogin"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: googleLoginUserPostRequestToJson(jsonLoginGoogleUser),
      );
      Get.back();

      if (responseLoginGoogle.statusCode == 403) {
        final results = jsonDecode(responseLoginGoogle.body);
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        showNotification(results['message']);
        return;
      }

      GoogleLoginPostResponse response = googleLoginPostResponseFromJson(
        responseLoginGoogle.body,
      );
      if (response.success) {
        await storage.write(
          key: 'refreshToken',
          value: response.token.refreshToken,
        );
        box.write('accessToken', response.token.accessToken);

        loadingDialog();
        final responseAll = await http.get(
          Uri.parse("$url/user/AlldataUser"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
        );
        Get.back();

        if (responseAll.statusCode != 200) return;

        final response2 = allDataUserGetResponstFromJson(responseAll.body);

        box.write('userProfile', {
          'userid': response2.user.userId,
          'name': response2.user.name,
          'email': response2.user.email,
          'profile': response2.user.profile,
          'role': response2.user.role,
        });

        if (response.user.role == "admin") {
          Get.offAll(() => NavbaradminPage());
        } else {
          box.write('userDataAll', response.toJson());
          Get.offAll(() => NavbarPage());
        }
      } else {
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      showNotification('Something went wrong. Please try again.');
    }
  }

  bool isValidEmail(String email) {
    final RegExp emailRegExp = RegExp(
      r"^[a-zA-Z0-9._%+-]+@(?:gmail\.com|hotmail\.com|outlook\.com|yahoo\.com|icloud\.com|msu\.ac\.th)$",
    );
    return emailRegExp.hasMatch(email);
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

  void login() async {
    if (emailCtl.text.trim().isEmpty) {
      showNotification('Email address is required');
      return;
    } else if (!isValidEmail(emailCtl.text.trim())) {
      showNotification('Invalid email address');
      return;
    }

    if (passwordCtl.text.trim().isEmpty) {
      showNotification('Please enter your password');
      return;
    }

    try {
      final url = await loadAPIEndpoint();

      loadingDialog();
      final responseGetuser = await http.post(
        Uri.parse("$url/auth/signin"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: signInUserPostRequestToJson(
          SignInUserPostRequest(
            email: emailCtl.text.trim(),
            password: passwordCtl.text.trim(),
          ),
        ),
      );
      Get.back();

      if (responseGetuser.statusCode == 403) {
        showNotification('Your account must verify your email first');
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
                  color: Color(0xFF007AFF),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.width * 0.02),
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
              onPressed: () {
                Get.back();
                showModalConfirmEmail(emailCtl.text);
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
        return;
      } else if (responseGetuser.statusCode != 200) {
        final results = jsonDecode(responseGetuser.body);
        showNotification(results['error']);
        return;
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
        Uri.parse("$url/user/alldata"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
      Get.back();

      if (responseAll.statusCode != 200) return;

      final response = allDataUserGetResponstFromJson(responseAll.body);

      box.write('userProfile', {
        'userid': response.user.userId,
        'name': response.user.name,
        'email': response.user.email,
        'profile': response.user.profile,
        'role': response.user.role,
      });

      if (response.user.role == "admin") {
        Get.offAll(() => NavbaradminPage());
      } else {
        box.write('userDataAll', response.toJson());
        Get.offAll(() => NavbarPage());
      }
    } catch (e) {
      showNotification('Something went wrong. Please try again.');
    }
  }

  void backToLoginPage() {
    Get.back();
  }

  void goToRegisterPage() {
    Get.to(() => RegisterPage());
  }

  String formatTimestampTo12HourTimeWithSeconds(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('hh:mm:ss a').format(dateTime);
    return formattedTime;
  }

  showModalConfirmEmail(String email) {
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
                                onTap: () async {
                                  blockOTP = false;
                                  await googleSignIn.signOut();
                                  await FirebaseAuth.instance.signOut();
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
                                  setState(() {
                                    showNotification('');
                                    blockOTP = false;
                                  });
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
                                      .setPassword(passwordCtl.text);
                                  appData.keepEmailToUserPageVerifyOTP.setRef(
                                    sendOTPResponse['ref'],
                                  );
                                  appData.keepEmailToUserPageVerifyOTP.setCase(
                                    'verifyEmail',
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
                              backgroundColor: Colors.black54,
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
    ).whenComplete(() async {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    });
  }
}
