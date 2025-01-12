import 'package:demomydayplanner/config/config.dart';
import 'package:demomydayplanner/models/request/logoutUserPostRequest.dart';
import 'package:demomydayplanner/models/response/logoutUserPostResponse.dart';
import 'package:demomydayplanner/pages/login.dart';
import 'package:demomydayplanner/shared/appData.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class AdminhomePage extends StatefulWidget {
  const AdminhomePage({super.key});

  @override
  State<AdminhomePage> createState() => _AdminhomePageState();
}

class _AdminhomePageState extends State<AdminhomePage> {
  bool isLoading = false;
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
        appBar: null,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05,
              vertical: height * 0.05,
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
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        logout(context);
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
    );
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

  void logout(BuildContext context) async {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    Get.defaultDialog(
      title: "",
      barrierDismissible: true,
      titlePadding: EdgeInsets.zero,
      backgroundColor: Color(0xff494949),
      contentPadding: EdgeInsets.symmetric(
        horizontal: width * 0.02,
        vertical: height * 0.02,
      ),
      content: Column(
        children: [
          Text(
            'Log out account',
            style: TextStyle(
              fontSize: Get.textTheme.headlineSmall!.fontSize,
              color: Colors.white,
            ),
          ),
          SizedBox(
            height: height * 0.02,
          )
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            // แสดง Loading Dialog
            loadingDialog();
            var responseLogot = await http.post(
              Uri.parse("$url/signin_up/api/logout"),
              headers: {"Content-Type": "application/json; charset=utf-8"},
              body: logoutUserPostRequestToJson(
                LogoutUserPostRequest(
                  email: box.read('email'),
                ),
              ),
            );
            if (responseLogot.statusCode == 200) {
              Get.back();
              setState(() {
                isLoading = false;
              });
              LogoutUserPostResponse response =
                  logoutUserPostResponseFromJson(responseLogot.body);
              await googleSignIn.signOut();
              // Sign out from Firebase if needed
              await FirebaseAuth.instance.signOut();
              if (response.success) {
                Get.to(() => LoginPage());
              }
            }
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
            'Log out',
            style: TextStyle(
              fontSize: Get.textTheme.titleMedium!.fontSize,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
