import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/logoutUserPostRequest.dart';
import 'package:mydayplanner/models/response/logoutUserPostResponse.dart';
import 'package:mydayplanner/splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AdminhomePage extends StatefulWidget {
  const AdminhomePage({super.key});

  @override
  State<AdminhomePage> createState() => _AdminhomePageState();
}

class _AdminhomePageState extends State<AdminhomePage> {
  var box = GetStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn();

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
              padding: EdgeInsets.only(
                right: width * 0.05,
                left: width * 0.05,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: Get.textTheme.displaySmall!.fontSize,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(0, 122, 255, 1),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          logout();
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.01,
                            vertical: height * 0.01,
                          ),
                          child: SvgPicture.string(
                            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M16 13v-2H7V8l-5 4 5 4v-3z"></path><path d="M20 3h-9c-1.103 0-2 .897-2 2v4h2V5h9v14h-9v-4H9v4c0 1.103.897 2 2 2h9c1.103 0 2-.897 2-2V5c0-1.103-.897-2-2-2z"></path></svg>',
                            height: height * 0.03,
                            fit: BoxFit.contain,
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

  void logout() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    // แสดง Loading Dialog
    loadingDialog();
    var responseLogot = await http.post(
      Uri.parse("$url/auth/signout"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: logoutUserPostRequestToJson(
        LogoutUserPostRequest(
          email: box.read('email'),
        ),
      ),
    );
    if (responseLogot.statusCode == 200) {
      Get.back();

      LogoutUserPostResponse response =
          logoutUserPostResponseFromJson(responseLogot.body);
      await googleSignIn.signOut();
      // Sign out from Firebase if needed
      await FirebaseAuth.instance.signOut();
      if (response.email == box.read('email')) {
        box.remove('email');
        box.remove('password');
        Get.offAll(() => SplashPage());
      }
    } else {
      Get.back();
      Get.offAll(() => SplashPage());
    }
  }
}
