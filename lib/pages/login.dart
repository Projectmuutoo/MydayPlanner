import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/getUserByEmailPostRequest.dart';
import 'package:mydayplanner/models/request/googleLoginUserPostRequest.dart';
import 'package:mydayplanner/models/request/isVerifyUserPutRequest.dart';
import 'package:mydayplanner/models/request/sendOTPPostRequest.dart';
import 'package:mydayplanner/models/request/signInUserPostRequest.dart';
import 'package:mydayplanner/models/response/getUserByEmailPostResponst.dart';
import 'package:mydayplanner/models/response/googleLoginUserPostResponse.dart';
import 'package:mydayplanner/models/response/sendOTPPostResponst.dart';
import 'package:mydayplanner/models/response/signInUserPostResponst.dart';
import 'package:mydayplanner/pages/pageAdmin/navBarAdmin.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:mydayplanner/pages/register.dart';
import 'package:mydayplanner/pages/resetPassword.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

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
  bool isCheckedEmail = false;
  bool canResend = true;
  bool hasStartedCountdown = false;
  bool blockOTP = false;
  bool stopBlockOTP = false;

// ---------------------- 🔐 Auth ----------------------
  final GoogleSignIn googleSignIn = GoogleSignIn();
  int signInAttempts = 0;
  int countToRequest = 1;

// ---------------------- 🧱 Local Storage ----------------------
  var box = GetStorage();

// ---------------------- 🔤 Strings ----------------------
  String textNotification = '';
  String warning = '';
  String? expiresAtEmail;

  Timer? timer;
  int start = 900; // 15 นาที = 900 วินาที
  String countTheTime = "15:00"; // เวลาเริ่มต้น

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
      child: Builder(builder: (context) {
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
                                          fontSize: Get
                                              .textTheme.displaySmall!.fontSize,
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
                                            Get.textTheme.titleLarge!.fontSize,
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
                            SizedBox(
                              height: height * 0.02,
                            ),
                            Image.asset(
                              "assets/images/ImageShow.png",
                              height: height * 0.2,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(
                              height: height * 0.02,
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
                            if (isCheckedEmail) SizedBox(height: height * 0.01),
                            if (isCheckedEmail)
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
                            if (isCheckedEmail)
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
                            if (isCheckedEmail)
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
                                          fontSize: Get
                                              .textTheme.titleMedium!.fontSize,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(
                              height: height * 0.01,
                            ),
                            ElevatedButton(
                              onPressed: login,
                              style: ElevatedButton.styleFrom(
                                fixedSize: Size(
                                  width,
                                  height * 0.04,
                                ),
                                backgroundColor: Color(0xFF007AFF),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                !isCheckedEmail ? 'Continue' : 'Sign in',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleLarge!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                            if (textNotification.isNotEmpty)
                              SizedBox(
                                height: height * 0.01,
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
                            SizedBox(
                              height: height * 0.02,
                            ),
                            Text(
                              '- or -',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            SizedBox(
                              height: height * 0.01,
                            ),
                            ElevatedButton(
                              onPressed: signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                fixedSize: Size(
                                  width,
                                  height * 0.05,
                                ),
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
                            SizedBox(
                              height: height * 0.01,
                            ),
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
      }),
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

  Future<void> delay(Function action, {int milliseconds = 1000}) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
    action();
  }

  Future<void> signInWithGoogle() async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      loadingDialog(); // แสดง Loading Dialog

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } finally {
        Get.back(); // ปิด Loading Dialog ไม่ว่า signIn จะสำเร็จหรือไม่
      }

      // ผู้ใช้ยกเลิกการเข้าสู่ระบบ
      if (googleUser == null) {
        return;
      }

      loadingDialog(); // แสดง Loading Dialog สำหรับขั้นตอนถัดไป

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
        Get.back(); // ปิด Loading Dialog หลัง auth เสร็จ
      }

      loadingDialog(); // แสดง Loading Dialog สำหรับเรียก API /user/getemail

      var responseGetUser = await http.post(
        Uri.parse("$url/user/getemail"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: getUserByEmailPostRequestToJson(
          GetUserByEmailPostRequest(
            email: googleUser.email,
          ),
        ),
      );

      GoogleLoginUserPostRequest jsonLoginGoogleUser =
          GoogleLoginUserPostRequest(
        email: googleUser.email,
        name: googleUser.displayName.toString(),
        profile: googleUser.photoUrl.toString(),
      );
      Get.back();
      if (responseGetUser.statusCode == 200) {
        showNotification('');

        GetUserByEmailPostResponst getUserByEmailPostResponst =
            getUserByEmailPostResponstFromJson(responseGetUser.body);

        // ถ้า admin ปิดการใช้งาน จะทำการยกเลิก GoogleSignInAccount ทันที
        if (getUserByEmailPostResponst.isActive == '0') {
          showNotification('Your account has been disabled');
          googleUser = null;
          return;
        }

        // กรณีไม่ได้ยืนยัน otp
        if (getUserByEmailPostResponst.isVerify != '1') {
          showNotification('Your account must verify your email first');
          delay(() {
            // ส่งไปยืนยันเมล
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
                      color: Color.fromRGBO(0, 122, 255, 1),
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
                    showModalConfirmEmail(googleUser!.email, false);
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
                  onPressed: () async {
                    googleUser = null;
                    await googleSignIn.signOut();
                    // Sign out from Firebase if needed
                    await FirebaseAuth.instance.signOut();
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
            ).whenComplete(() async {
              await googleSignIn.signOut();
              // Sign out from Firebase if needed
              await FirebaseAuth.instance.signOut();
            });
          }, milliseconds: 500);
          return;
        }

        var result = await FirebaseFirestore.instance
            .collection('usersLogin')
            .doc(googleUser.email)
            .get();
        var data = result.data();
        if (data != null) {
          if (data['active'] != '1') {
            googleUser = null;
            showNotification('Your account has been disabled');
            return;
          }
        }

        // กรณีมี email และทำการเข้าระบบไปเลย
        loadingDialog(); // แสดง Loading Dialog

        try {
          var responseLoginGoogle = await http.post(
            Uri.parse("$url/auth/googlesignin"),
            headers: {"Content-Type": "application/json; charset=utf-8"},
            body: googleLoginUserPostRequestToJson(jsonLoginGoogleUser),
          );

          if (responseLoginGoogle.statusCode == 200) {
            showNotification('');

            GoogleLoginUserPostResponse responseGoogleLogin =
                googleLoginUserPostResponseFromJson(responseLoginGoogle.body);

            if (responseGoogleLogin.status == 'success') {
              box.write('email', googleUser.email);
              if (getUserByEmailPostResponst.hashedPassword == '-') {
                box.write('password', "-");
              }

              // โหลดข้อมูล user ซ้ำอีกครั้ง
              var responseGetUser = await http.post(
                Uri.parse("$url/user/getemail"),
                headers: {"Content-Type": "application/json; charset=utf-8"},
                body: getUserByEmailPostRequestToJson(
                  GetUserByEmailPostRequest(
                    email: googleUser.email,
                  ),
                ),
              );

              if (responseGetUser.statusCode == 200) {
                GetUserByEmailPostResponst getUserByEmailPostResponst =
                    getUserByEmailPostResponstFromJson(responseGetUser.body);

                if (getUserByEmailPostResponst.role == "admin") {
                  Get.offAll(() => const NavbaradminPage());
                } else {
                  Get.offAll(() => const NavbarPage());
                }
              }
            }
          }
        } finally {
          Get.back(); // ปิด Loading Dialog
        }
      } else {
        showNotification('');

        // กรณีไม่มี email และทำการสมัครให้
        loadingDialog(); // แสดง Loading Dialog
        var responseLoginGoogle = await http.post(
          Uri.parse("$url/auth/googlesignin"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: googleLoginUserPostRequestToJson(jsonLoginGoogleUser),
        );

        Get.back();
        if (responseLoginGoogle.statusCode == 200) {
          showNotification('');

          var results = jsonDecode(responseLoginGoogle.body);

          if (results['status'] == 'not_found') {
            showModalConfirmEmail(results['email'], true);
          }
        } else {
          showNotification('error!');
          googleUser = null;
        }
      }
    } catch (e) {
      Get.back(); // ปิด dialog ถ้าเปิดอยู่
      showNotification('Something went wrong. Please try again.');
    }
  }

  bool isValidEmail(String email) {
    final RegExp emailRegExp = RegExp(
        r"^[a-zA-Z0-9._%+-]+@(?:gmail\.com|hotmail\.com|outlook\.com|yahoo\.com|icloud\.com|msu\.ac\.th)$");
    return emailRegExp.hasMatch(email);
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

  void login() async {
    // ถ้า email ว่าง
    if (emailCtl.text.isEmpty) {
      passwordCtl.text = '';
      isCheckedEmail = false;
      showNotification('Email address is required');
      return;
    }

    // ถ้า email format บ่ถูก
    if (!isValidEmail(emailCtl.text)) {
      passwordCtl.text = '';
      isCheckedEmail = false;
      showNotification('Invalid email address');
      return;
    }

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      // แสดง Loading Dialog
      loadingDialog();

      var responseGetuser = await http.post(
        Uri.parse("$url/user/getemail"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: getUserByEmailPostRequestToJson(
          GetUserByEmailPostRequest(
            email: emailCtl.text,
          ),
        ),
      );

      if (responseGetuser.statusCode == 200) {
        Get.back(); // ปิด loading dialog
        showNotification('');

        GetUserByEmailPostResponst responseGetUserByEmail =
            getUserByEmailPostResponstFromJson(responseGetuser.body);

        // เช็คว่าไม่พบอีเมลในระบบถ้ามีรหัสเป็น '-'
        if (responseGetUserByEmail.hashedPassword == '-') {
          passwordCtl.text = '';
          isCheckedEmail = false;
          showNotification('Email not found');
          return;
        }

        // ถ้า admin ปิดการใช้งาน
        if (responseGetUserByEmail.isActive == '0') {
          passwordCtl.text = '';
          isCheckedEmail = false;
          showNotification('Your account has been disabled');
          return;
        }

        // ถ้า ปิดบัญชี
        if (responseGetUserByEmail.isActive == '2') {
          passwordCtl.text = '';
          isCheckedEmail = false;
          showNotification('You have already deleted this account');
          return;
        }

        // ดึงข้อมูลจาก Firestore
        var result = await FirebaseFirestore.instance
            .collection('usersLogin')
            .doc(emailCtl.text)
            .get();

        var data = result.data();
        if (data != null) {
          if (data['active'] != '1') {
            passwordCtl.text = '';
            isCheckedEmail = false;
            showNotification('Your account has been disabled');
            return;
          }
        }

        // เปิดให้ใส่รหัสผ่าน
        isCheckedEmail = true;
        showNotification('');

        if (passwordCtl.text == '-') {
          showNotification('Invalid password');
          return;
        }

        if (passwordCtl.text.isEmpty) {
          signInAttempts++;
          if (signInAttempts > 1) {
            showNotification('Password fields cannot be empty');
          }
          return;
        }

        if (passwordFocusNode.hasFocus) {
          passwordFocusNode.unfocus();
        }

        // อันนี้คือเข้ารหัส password BCrypt
        if (BCrypt.checkpw(
            passwordCtl.text, responseGetUserByEmail.hashedPassword)) {
          try {
            // แสดง Loading Dialog
            loadingDialog();

            var responseLogin = await http.post(
              Uri.parse("$url/auth/signin"),
              headers: {"Content-Type": "application/json; charset=utf-8"},
              body: signInUserPostRequestToJson(
                SignInUserPostRequest(
                  email: emailCtl.text,
                  hashedPassword: passwordCtl.text,
                ),
              ),
            );

            if (responseLogin.statusCode == 200) {
              Get.back(); // ปิด loading dialog
              showNotification('');

              SignInUserPostResponst getUserByEmailResponse =
                  signInUserPostResponstFromJson(responseLogin.body);

              if (getUserByEmailResponse.email ==
                  responseGetUserByEmail.email) {
                // เก็บ email user ไว้ใน storage ไว้ใช้ด้วย
                box.write('email', emailCtl.text);
                box.write('password', passwordCtl.text);

                // แยกทางใครทางมัน
                if (getUserByEmailResponse.role == "admin") {
                  Get.offAll(() => const NavbaradminPage());
                } else {
                  Get.offAll(() => const NavbarPage());
                }
              }
            } else {
              Get.back(); // ปิด loading dialog

              // กรณีไม่ได้ยืนยัน otp
              if (responseGetUserByEmail.isVerify != '1') {
                showNotification('Your account must verify your email first');
                delay(() {
                  // ส่งไปยืนยันเมล
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
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.01),
                        Text(
                          'Confirm now?',
                          style: TextStyle(
                            fontSize: Get.textTheme.headlineSmall!.fontSize,
                            fontWeight: FontWeight.w500,
                            color: Color.fromRGBO(0, 122, 255, 1),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.width * 0.02),
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
                          showModalConfirmEmail(
                              responseGetUserByEmail.email, false);
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
                }, milliseconds: 500);
              } else {
                showNotification('Unable to sign in');
              }
            }
          } catch (e) {
            Get.back(); // ปิด loading dialog
            showNotification('An error occurred during sign in');
          }
        } else {
          showNotification('Invalid password');
        }
      } else {
        Get.back(); // ปิด loading dialog
        passwordCtl.text = '';
        isCheckedEmail = false;
        showNotification('Unable to contact');
      }
    } catch (e) {
      Get.back(); // ปิด loading dialog
      passwordCtl.text = '';
      isCheckedEmail = false;
      showNotification('An unexpected error occurred');
    }
  }

  void verifyOTP(String email, String ref, bool withGoogle) async {
    // สร้าง FocusNodes สำหรับทุกช่อง
    final focusNodes = List<FocusNode>.generate(6, (index) => FocusNode());
    final otpControllers = List<TextEditingController>.generate(
        6, (index) => TextEditingController());

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

            if (!hasStartedCountdown) {
              hasStartedCountdown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                startCountdown(setState, ref);
              });
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              startOtpExpiryTimer(email, setState);
            });

            return WillPopScope(
              onWillPop: () async {
                return false;
              },
              child: Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: width * 0.04,
                      left: width * 0.04,
                      top: height * 0.06,
                    ),
                    child: SizedBox(
                      height: height,
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
                                      fontSize: Get
                                          .textTheme.headlineMedium!.fontSize,
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
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                                  email,
                                                  ref,
                                                  setState,
                                                  withGoogle == true,
                                                );
                                              }
                                            } else if (value.isEmpty &&
                                                index > 0) {
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
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: InputDecoration(
                                            focusColor: Colors.black,
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: EdgeInsets.all(8),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey,
                                                width: 2,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 2,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: warning.isNotEmpty
                                                    ? Color(int.parse(
                                                        '0xff$warning'))
                                                    : Colors.grey,
                                                width: 2,
                                              ),
                                            ),
                                            hintText: "-",
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
                              if (blockOTP || warning.isNotEmpty)
                                SizedBox(
                                  height: height * 0.02,
                                ),
                              if (warning.isNotEmpty)
                                Text(
                                  'OTP code is invalid',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.red,
                                  ),
                                ),
                              if (blockOTP)
                                Text(
                                  'Your email has been blocked because you requested otp overdue and you will be able to request otp again after $expiresAtEmail',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
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
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize,
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
                                            otpControllers[i].text =
                                                copiedText[i];
                                            // โฟกัสไปยังช่องสุดท้าย
                                            if (i == 5) {
                                              focusNodes[i].requestFocus();
                                            }
                                          }
                                          verifyEnteredOTP(
                                            otpControllers,
                                            email,
                                            ref,
                                            setState,
                                            withGoogle == true,
                                          ); // ตรวจสอบ OTP
                                        } else {
                                          setState(() {
                                            warning = 'F21F1F';
                                          });
                                        }
                                      }
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.01),
                                      child: Text(
                                        'Paste',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme.titleMedium!.fontSize,
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
                                'ref: $ref',
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
                                            'email': email,
                                            'createdAt': Timestamp.fromDate(
                                                DateTime.now()),
                                            'expiresAt': Timestamp.fromDate(
                                              DateTime.now()
                                                  .add(Duration(minutes: 10)),
                                            ),
                                          };
                                          await FirebaseFirestore.instance
                                              .collection('EmailBlocked')
                                              .doc(email)
                                              .set(data);
                                          if (!mounted) return;
                                          setState(() {
                                            blockOTP = true;
                                            stopBlockOTP = true;
                                            canResend = false;
                                            expiresAtEmail =
                                                formatTimestampTo12HourTimeWithSeconds(
                                                    data['expiresAt']
                                                        as Timestamp);
                                          });
                                          return;
                                        }

                                        var config =
                                            await Configuration.getConfig();
                                        var url = config['apiEndpoint'];
                                        loadingDialog();
                                        var responseOtp = await http.post(
                                          Uri.parse(
                                              "$url/auth/requestverifyOTP"),
                                          headers: {
                                            "Content-Type":
                                                "application/json; charset=utf-8"
                                          },
                                          body: sendOtpPostRequestToJson(
                                            SendOtpPostRequest(
                                              email: email,
                                            ),
                                          ),
                                        );

                                        if (responseOtp.statusCode == 200) {
                                          Get.back();
                                          SendOtpPostResponst sendOTPResponse =
                                              sendOtpPostResponstFromJson(
                                                  responseOtp.body);

                                          if (timer != null &&
                                              timer!.isActive) {
                                            timer!.cancel();
                                          }

                                          setState(() {
                                            ref = sendOTPResponse.ref;
                                            hasStartedCountdown = true;
                                            canResend =
                                                false; // ล็อกการกดชั่วคราว
                                            warning = '';
                                            for (var controller
                                                in otpControllers) {
                                              controller.clear();
                                            }
                                          });
                                          startCountdown(setState, ref);
                                          // รอ 30 วิค่อยให้กดได้อีก
                                          Future.delayed(Duration(seconds: 30),
                                              () {
                                            if (!mounted) return;
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
                                      horizontal: width * 0.01),
                                  child: Text(
                                    'Resend Code',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.normal,
                                      color:
                                          canResend ? Colors.blue : Colors.grey,
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
                                    fixedSize: Size(
                                      width,
                                      height * 0.04,
                                    ),
                                    backgroundColor: Colors.black,
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign in',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize,
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
          },
        );
      },
    ).whenComplete(() {
      if (timer != null && timer!.isActive) {
        timer!.cancel();
      }
    });
  }

  // ฟังก์ชันตรวจสอบ OTP
  void verifyEnteredOTP(
    List<TextEditingController> otpControllers,
    String email,
    String ref,
    StateSetter setState1,
    bool withGoogle,
  ) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];
    String enteredOTP = otpControllers
        .map((controller) => controller.text)
        .join(); // รวมค่าที่ป้อน
    if (enteredOTP.length == 6) {
      // แสดง Loading Dialog
      loadingDialog();
      var responseIsverify = await http.post(
        Uri.parse("$url/auth/verifyOTP"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: isVerifyUserPutRequestToJson(
          IsVerifyUserPutRequest(
            email: email,
            ref: ref,
            otp: enteredOTP,
            record: "verify",
          ),
        ),
      );

      // Close loading dialog first
      Get.back();
      if (!mounted) return;

      if (responseIsverify.statusCode == 200) {
        setState1(() {
          warning = ''; // Clear warning when successful
        });

        loadingDialog();
        var responseGetuser = await http.post(
          Uri.parse("$url/user/getemail"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: getUserByEmailPostRequestToJson(
            GetUserByEmailPostRequest(
              email: email,
            ),
          ),
        );

        Get.back();
        if (!mounted) return;

        if (responseGetuser.statusCode == 200) {
          GetUserByEmailPostResponst responseGetUserByEmail =
              getUserByEmailPostResponstFromJson(responseGetuser.body);

          await FirebaseFirestore.instance
              .collection('OTPRecords')
              .doc(ref)
              .delete();
          await FirebaseFirestore.instance
              .collection('EmailBlocked')
              .doc(email)
              .delete();
          if (timer != null && timer!.isActive) {
            timer!.cancel();
          }

          //เก็บ email user ไว้ใน storage ไว้ใช้ด้วย
          box.write('email', email);
          if (withGoogle) {
            box.write('password', '-');
          }
          //เข้าไปเรียบร้อบละ
          if (responseGetUserByEmail.role == "admin") {
            Get.offAll(() => const NavbaradminPage());
          } else {
            Get.offAll(() => const NavbarPage());
          }
        }
      } else {
        setState1(() {
          warning = 'F21F1F';
        });
      }
    }
  }

  void backToLoginPage() {
    Get.back();
  }

  void goToRegisterPage() {
    Get.to(() => const RegisterPage());
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
            .collection('OTPRecords_verify')
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

  showModalConfirmEmail(String email, bool withGoogle) async {
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

            emailConfirmOtpCtl = emailCtl;
            if (withGoogle) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                emailConfirmOtpCtl.text = email;
              });
            }

            return GestureDetector(
              onTap: () {
                if (emailConfirmOtpFocusNode.hasFocus) {
                  emailConfirmOtpFocusNode.unfocus();
                }
              },
              child: Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.04,
                      right: width * 0.04,
                      top: height * 0.05,
                    ),
                    child: SizedBox(
                      height: height,
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
                                      // Sign out from Firebase if needed
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
                                              fontSize: Get.textTheme
                                                  .titleLarge!.fontSize,
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
                                      fontSize: Get
                                          .textTheme.headlineMedium!.fontSize,
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
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: height * 0.01),
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
                                controller: emailConfirmOtpCtl,
                                focusNode: emailConfirmOtpFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                cursorColor: Colors.black,
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                ),
                                decoration: InputDecoration(
                                  hintText: isTyping
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
                              SizedBox(height: height * 0.02),
                              if (blockOTP)
                                Text(
                                  'Your email has been blocked because you requested otp overdue and you will be able to request otp again after $expiresAtEmail',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
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
                                    var config =
                                        await Configuration.getConfig();
                                    var url = config['apiEndpoint'];
                                    // แสดง Loading Dialog
                                    loadingDialog();
                                    var responseOtp = await http.post(
                                      Uri.parse("$url/auth/requestverifyOTP"),
                                      headers: {
                                        "Content-Type":
                                            "application/json; charset=utf-8"
                                      },
                                      body: sendOtpPostRequestToJson(
                                        SendOtpPostRequest(
                                          email: email,
                                        ),
                                      ),
                                    );

                                    if (responseOtp.statusCode == 200) {
                                      Get.back();
                                      Get.back();
                                      setState(() {
                                        showNotification('');
                                        blockOTP = false;
                                      });
                                      SendOtpPostResponst sendOTPResponse =
                                          sendOtpPostResponstFromJson(
                                              responseOtp.body);

                                      //ส่ง email, otp, ref ไปยืนยันและ verify เมลหน้าต่อไป
                                      verifyOTP(
                                        email,
                                        sendOTPResponse.ref,
                                        withGoogle == true,
                                      );
                                    } else {
                                      Get.back();
                                      var result = await FirebaseFirestore
                                          .instance
                                          .collection('EmailBlocked')
                                          .doc(email)
                                          .get();
                                      var data = result.data();
                                      if (data != null) {
                                        if (!mounted) return;
                                        setState(() {
                                          blockOTP = true;
                                          expiresAtEmail =
                                              formatTimestampTo12HourTimeWithSeconds(
                                                  data['expiresAt']
                                                      as Timestamp);
                                        });
                                      }
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(
                                    width,
                                    height * 0.04,
                                  ),
                                  backgroundColor: Colors.black,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  blockOTP ? 'Back' : 'Request code',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
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
          },
        );
      },
    ).whenComplete(() async {
      await googleSignIn.signOut();
      // Sign out from Firebase if needed
      await FirebaseAuth.instance.signOut();
    });
  }

  String formatTimestampTo12HourTimeWithSeconds(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('hh:mm:ss a').format(dateTime);
    return formattedTime;
  }

  void startOtpExpiryTimer(String email, StateSetter setState) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('EmailBlocked')
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
        blockOTP = false;
        canResend = true;
      });
    }
  }
}
