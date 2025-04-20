import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

// ---------------------- 🎯 Controllers (FocusNode) ----------------------
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

// ---------------------- ✅ State Flags ----------------------
  bool isTyping = false;
  bool isCheckedPassword = false;
  bool isCheckedEmail = false;

// ---------------------- 🔐 Auth ----------------------
  final GoogleSignIn googleSignIn = GoogleSignIn();
  int signInAttempts = 0;

// ---------------------- 🧱 Local Storage ----------------------
  var box = GetStorage();

// ---------------------- 🔤 Strings ----------------------
  String textNotification = '';
  String warning = '';

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
            appBar: null,
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
                                      isCheckedPassword = !isCheckedPassword;
                                      setState(() {});
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
    textNotification = message;
    setState(() {});
  }

  Future<void> delay(Function action, {int milliseconds = 1000}) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
    action();
  }

  Future<void> signInWithGoogle() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    // แสดง Loading Dialog
    loadingDialog();

    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    // ผู้ใช้ยกเลิกการเข้าสู่ระบบ
    if (googleUser == null) {
      Get.back();
      setState(() {});
      return;
    }

    //เรียกเมธอด authentication จากออบเจกต์ googleUser เพื่อขอรับข้อมูลการตรวจสอบสิทธิ์ (tokens)
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);

    var responseGetUser = await http.post(
      Uri.parse("$url/user/api/get_user"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: getUserByEmailPostRequestToJson(
        GetUserByEmailPostRequest(
          email: googleUser.email,
        ),
      ),
    );

    GoogleLoginUserPostRequest jsonLoginGoogleUser = GoogleLoginUserPostRequest(
      email: googleUser.email,
      name: googleUser.displayName.toString(),
      profile: googleUser.photoUrl.toString(),
    );

    if (responseGetUser.statusCode == 200) {
      Get.back();
      showNotification('');

      GetUserByEmailPostResponst getUserByEmailPostResponst =
          getUserByEmailPostResponstFromJson(responseGetUser.body);

      //ถ้า admin ปิดการใช้งาน จะทำการยกเลิก GoogleSignInAccount ทันที
//----------------------------------------------------------------
      if (getUserByEmailPostResponst.isActive == '0') {
        showNotification('Your account has been disabled');
        googleUser = null;
        return;
      }
      //กรณีไม่ได้ยืนยัน otp
      if (getUserByEmailPostResponst.isVerify != 1) {
        showNotification('Your account must verify your email first');
        delay(() {
          //ส่งไปยืนยันเมล
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
                onPressed: () async {
                  Get.back();
                  // แสดง Loading Dialog
                  loadingDialog();
                  var responseOtp = await http.post(
                    Uri.parse("$url/otp/api/otp"),
                    headers: {
                      "Content-Type": "application/json; charset=utf-8"
                    },
                    body: sendOtpPostRequestToJson(
                      SendOtpPostRequest(
                        recipient: googleUser!.email,
                      ),
                    ),
                  );

                  if (responseOtp.statusCode == 200) {
                    Get.back();

                    showNotification('');
                    SendOtpPostResponst sendOTPResponse =
                        sendOtpPostResponstFromJson(responseOtp.body);

                    //ส่ง email, otp, ref ไปยืนยันและ verify เมลหน้าต่อไป
                    verifyOTP(
                      googleUser!.email,
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
                  googleUser = null;
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
//----------------------------------------------------------------
      //กรณีมี email และทำการเข้าระบบไปเลย
      // แสดง Loading Dialog
      loadingDialog();
      var responseLoginGoogle = await http.post(
        Uri.parse("$url/google/api/login_google"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: googleLoginUserPostRequestToJson(jsonLoginGoogleUser),
      );

      if (responseLoginGoogle.statusCode == 200) {
        Get.back();
        showNotification('');

        GoogleLoginUserPostResponse responseGoogleLogin =
            googleLoginUserPostResponseFromJson(responseLoginGoogle.body);
        if (responseGoogleLogin.success) {
          //เก็บ email, password user ไว้ใน storage ไว้ใช้ด้วย
          box.write('email', googleUser.email);
          if (getUserByEmailPostResponst.hashedPassword == '-') {
            box.write('password', "-");
          }
          //เข้า home ไปเรียบร้อบละ
          if (responseGoogleLogin.role == "admin") {
            Get.to(() => const NavbaradminPage());
          } else {
            Get.to(() => const NavbarPage());
          }
        }
      }
    } else {
      Get.back();
      showNotification('');
      //กรณีไม่มี email และทำการสมัครให้
      // แสดง Loading Dialog
      loadingDialog();
      var responseLoginGoogle = await http.post(
        Uri.parse("$url/google/api/login_google"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: googleLoginUserPostRequestToJson(jsonLoginGoogleUser),
      );

      if (responseLoginGoogle.statusCode == 201) {
        Get.back();
        showNotification('');

        GoogleLoginUserPostResponse responseLoginGoogleUser =
            googleLoginUserPostResponseFromJson(responseLoginGoogle.body);
        //สำเร็จและส่งยืนยัน otp ต่อ
        if (responseLoginGoogleUser.success) {
          //ส่ง OTP ไปที่ email
          // แสดง Loading Dialog
          loadingDialog();
          var responseOtp = await http.post(
            Uri.parse("$url/otp/api/otp"),
            headers: {"Content-Type": "application/json; charset=utf-8"},
            body: sendOtpPostRequestToJson(
              SendOtpPostRequest(
                recipient: googleUser.email,
              ),
            ),
          );

          if (responseOtp.statusCode == 200) {
            Get.back();
            showNotification('');

            SendOtpPostResponst sendOTPResponse =
                sendOtpPostResponstFromJson(responseOtp.body);
            //เก็บ password ไว้ใน storage ไว้ใช้ด้วย
            box.write('password', '-');
            //ส่ง email, otp, ref ไปยืนยันและ verify เมลหน้าต่อไป
            verifyOTP(
              googleUser.email,
              sendOTPResponse.otp,
              sendOTPResponse.ref,
            );
          }
        }
      } else {
        Get.back();
        showNotification('error!');
        googleUser = null;
        return;
      }
    }
  }

  bool isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
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
    //ถ้า email ว่าง
    if (emailCtl.text.isEmpty) {
      passwordCtl.text = '';
      isCheckedEmail = false;
      showNotification('Email address is required');
      return;
    }
    //ถ้า email format บ่ถูก
    if (!isValidEmail(emailCtl.text)) {
      passwordCtl.text = '';
      isCheckedEmail = false;
      showNotification('Invalid email address');
      return;
    }

    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];
    // แสดง Loading Dialog
    loadingDialog();
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
      Get.back();
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

      //ถ้า admin ปิดการใช้งาน
      if (responseGetUserByEmail.isActive == '0') {
        passwordCtl.text = '';
        isCheckedEmail = false;
        showNotification('Your account has been disabled');
        return;
      }
      //ถ้า ปิดบัญชี
      if (responseGetUserByEmail.isActive == '2') {
        passwordCtl.text = '';
        isCheckedEmail = false;
        showNotification('You have already deleted this account');
        return;
      }
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

      //เปิดให้ใส่รหัสผ่าน
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

      //อันนี้คือเข้ารหัส password BCrypt
      if (BCrypt.checkpw(
          passwordCtl.text, responseGetUserByEmail.hashedPassword)) {
        // แสดง Loading Dialog
        loadingDialog();
        var responseLogin = await http.post(
          Uri.parse("$url/signin_up/api/login"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: signInUserPostRequestToJson(
            SignInUserPostRequest(
              email: emailCtl.text,
              password: passwordCtl.text,
            ),
          ),
        );

        if (responseLogin.statusCode == 200) {
          Get.back();
          showNotification('');

          SignInUserPostResponst getUserByEmailResponse =
              signInUserPostResponstFromJson(responseLogin.body);

          if (getUserByEmailResponse.success) {
            //เก็บ email user ไว้ใน storage ไว้ใช้ด้วย
            box.write('email', emailCtl.text);
            box.write('password', passwordCtl.text);
            //แยกทางใครทางมัน
            if (getUserByEmailResponse.role == "admin") {
              Get.to(() => const NavbaradminPage());
            } else {
              Get.to(() => const NavbarPage());
            }
          }
        } else {
          //กรณีไม่ได้ยืนยัน otp
          if (responseGetUserByEmail.isVerify != 1) {
            Get.back();
            showNotification('Your account must verify your email first');
            delay(() {
              //ส่งไปยืนยันเมล
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
                    onPressed: () async {
                      Get.back();
                      // แสดง Loading Dialog
                      loadingDialog();
                      var responseOtp = await http.post(
                        Uri.parse("$url/otp/api/otp"),
                        headers: {
                          "Content-Type": "application/json; charset=utf-8"
                        },
                        body: sendOtpPostRequestToJson(
                          SendOtpPostRequest(
                            recipient: responseGetUserByEmail.email,
                          ),
                        ),
                      );

                      if (responseOtp.statusCode == 200) {
                        Get.back();
                        showNotification('');

                        SendOtpPostResponst sendOTPResponse =
                            sendOtpPostResponstFromJson(responseOtp.body);

                        //ส่ง email, otp, ref ไปยืนยันและ verify เมลหน้าต่อไป
                        verifyOTP(
                          responseGetUserByEmail.email,
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
            }, milliseconds: 500);
          }
        }
      } else {
        showNotification('Invalid password');
      }
    } else {
      passwordCtl.text = '';
      isCheckedEmail = false;
      showNotification('Unable to contact');
      Get.back();
    }
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
  }

  // ฟังก์ชันตรวจสอบ OTP
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

          GetUserByEmailPostResponst responseGetUserByEmail =
              getUserByEmailPostResponstFromJson(responseGetuser.body);

          //เก็บ email user ไว้ใน storage ไว้ใช้ด้วย
          box.write('email', email);
          //เข้าไปเรียบร้อบละ
          if (responseGetUserByEmail.role == "admin") {
            Get.to(() => const NavbaradminPage());
          } else {
            Get.to(() => const NavbarPage());
          }
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

  void goToRegisterPage() {
    Get.to(() => const RegisterPage());
  }
}
