import 'dart:developer';

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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isLoading = false;
  var box = GetStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  void initState() {
    var re = box.getKeys();
    for (var i in re) {
      log(i);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: null,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: height * 0.05,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.01,
                        vertical: height * 0.01,
                      ),
                      child: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M21 11H6.414l5.293-5.293-1.414-1.414L2.586 12l7.707 7.707 1.414-1.414L6.414 13H21z"></path></svg>',
                        height: height * 0.03,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleLarge!.fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                    width: width * 0.05,
                  ),
                ],
              ),
              Container(
                width: width,
                height: height * 0.05,
                decoration: BoxDecoration(
                  color: Color(0xffD9D9D9),
                  borderRadius: BorderRadius.all(
                    Radius.circular(8),
                  ),
                ),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: width * 0.03),
                child: Row(
                  children: [
                    SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 16c2.206 0 4-1.794 4-4s-1.794-4-4-4-4 1.794-4 4 1.794 4 4 4zm0-6c1.084 0 2 .916 2 2s-.916 2-2 2-2-.916-2-2 .916-2 2-2z"></path><path d="m2.845 16.136 1 1.73c.531.917 1.809 1.261 2.73.73l.529-.306A8.1 8.1 0 0 0 9 19.402V20c0 1.103.897 2 2 2h2c1.103 0 2-.897 2-2v-.598a8.132 8.132 0 0 0 1.896-1.111l.529.306c.923.53 2.198.188 2.731-.731l.999-1.729a2.001 2.001 0 0 0-.731-2.732l-.505-.292a7.718 7.718 0 0 0 0-2.224l.505-.292a2.002 2.002 0 0 0 .731-2.732l-.999-1.729c-.531-.92-1.808-1.265-2.731-.732l-.529.306A8.1 8.1 0 0 0 15 4.598V4c0-1.103-.897-2-2-2h-2c-1.103 0-2 .897-2 2v.598a8.132 8.132 0 0 0-1.896 1.111l-.529-.306c-.924-.531-2.2-.187-2.731.732l-.999 1.729a2.001 2.001 0 0 0 .731 2.732l.505.292a7.683 7.683 0 0 0 0 2.223l-.505.292a2.003 2.003 0 0 0-.731 2.733zm3.326-2.758A5.703 5.703 0 0 1 6 12c0-.462.058-.926.17-1.378a.999.999 0 0 0-.47-1.108l-1.123-.65.998-1.729 1.145.662a.997.997 0 0 0 1.188-.142 6.071 6.071 0 0 1 2.384-1.399A1 1 0 0 0 11 5.3V4h2v1.3a1 1 0 0 0 .708.956 6.083 6.083 0 0 1 2.384 1.399.999.999 0 0 0 1.188.142l1.144-.661 1 1.729-1.124.649a1 1 0 0 0-.47 1.108c.112.452.17.916.17 1.378 0 .461-.058.925-.171 1.378a1 1 0 0 0 .471 1.108l1.123.649-.998 1.729-1.145-.661a.996.996 0 0 0-1.188.142 6.071 6.071 0 0 1-2.384 1.399A1 1 0 0 0 13 18.7l.002 1.3H11v-1.3a1 1 0 0 0-.708-.956 6.083 6.083 0 0 1-2.384-1.399.992.992 0 0 0-1.188-.141l-1.144.662-1-1.729 1.124-.651a1 1 0 0 0 .471-1.108z"></path></svg>',
                      height: height * 0.03,
                      fit: BoxFit.contain,
                      color: Colors.black,
                    ),
                    SizedBox(
                      width: width * 0.01,
                    ),
                    Text(
                      'My settings',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleLarge!.fontSize,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      width * 0.03,
                      height * 0.005,
                      0,
                      height * 0.005,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'First page',
                          style: TextStyle(
                            fontSize: Get.textTheme.titleLarge!.fontSize,
                            fontWeight: FontWeight.normal,
                            color: Color(0xff272727),
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            text: 'Choose the home page\n',
                            style: TextStyle(
                              fontSize: Get.textTheme.titleSmall!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: Color(0xff272727),
                            ),
                            children: [
                              TextSpan(
                                text: 'you want.',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize,
                                  fontWeight: FontWeight.normal,
                                  height: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'List',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleLarge!.fontSize,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: height * 0.02,
              ),
              Container(
                width: width,
                height: height * 0.05,
                decoration: BoxDecoration(
                  color: Color(0xffD9D9D9),
                  borderRadius: BorderRadius.all(
                    Radius.circular(8),
                  ),
                ),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: width * 0.03),
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleLarge!.fontSize,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  logout(context);
                },
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        width * 0.03,
                        height * 0.005,
                        0,
                        height * 0.005,
                      ),
                      child: Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: Get.textTheme.titleLarge!.fontSize,
                          fontWeight: FontWeight.normal,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
