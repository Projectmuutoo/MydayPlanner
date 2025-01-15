import 'dart:convert';

import 'package:demomydayplanner/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isTyping = false;
  bool isCheckedPassword = false;
  bool isCheckedConfirmPassword = false;
//   late final WebViewController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(NavigationDelegate(
//         onPageFinished: (String url) async {
//           // Inject JavaScript after the page loads
//           await _controller.runJavaScript('''
//           function callback(token) {
//             window.captchaToken.postMessage(token);
//           }
//         ''');
//         },
//       ))
//       ..addJavaScriptChannel(
//         'captchaToken',
//         onMessageReceived: (JavaScriptMessage message) {
//           final token = message.message;
//           verifyCaptcha(token);
//         },
//       )
//       ..loadRequest(Uri.dataFromString(_getCaptchaHTML(),
//           mimeType: 'text/html', encoding: Encoding.getByName('utf-8')));
//   }

//   String _getCaptchaHTML() {
//     const siteKey = "6LcCdrcqAAAAANQwZUDTgZrQtwNk3DG_jeIsmLNF"; // Your site key
//     return '''
//     <html>
//   <head>
//     <title>reCAPTCHA</title>
//     <script src="https://www.google.com/recaptcha/api.js" async defer>
// </script>
//   </head>
//   <body style='background-color: aqua;'>
//     <div style='height: 60px;'></div>
//     <form action="?" method="POST">
//       <div class="g-recaptcha"
//         data-sitekey="6LcCdrcqAAAAANQwZUDTgZrQtwNk3DG_jeIsmLNF"
//         data-callback="captchaCallback"></div>

//     </form>
//     <script>
//       function captchaCallback(response){
//         //console.log(response);
//         alert(response);
//         if(typeof Captcha!=="undefined"){
//           Captcha.postMessage(response);
//         }
//       }
//     </script>
//   </body>
// </html>
//   ''';
//   }

//   Future<void> verifyCaptcha(String token) async {
//     const secretKey =
//         "AIzaSyAu9PKmAA8rsdcMxxqyo_W31t361WVkEEc"; // Your secret key
//     final url = Uri.parse(
//         'https://recaptchaenterprise.googleapis.com/v1/projects/mydayplanner-1735045952562/assessments?key=$secretKey');

//     final response = await http.post(url,
//         body: jsonEncode({
//           "event": {
//             "token": token,
//             "expectedAction": "USER_ACTION",
//             "siteKey": "6LeR1aQqAAAAAEJvvUUB7X_mLDSLqyF_mUEvF99I"
//           }
//         }),
//         headers: {
//           'Content-Type': 'application/json',
//         });

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['success']) {
//         print("CAPTCHA Verified Successfully");
//       } else {
//         print("CAPTCHA Verification Failed: ${data['error-codes']}");
//       }
//     } else {
//       print("Error verifying CAPTCHA: ${response.statusCode}");
//     }
//   }

  @override
  Widget build(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
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
                        Image.asset(
                          "assets/images/LogoApp.png",
                          height: height * 0.06,
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
                              fontSize: Get.textTheme.titleLarge!.fontSize,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      keyboardType: TextInputType.text,
                      cursorColor: Colors.black,
                      style: TextStyle(
                        fontSize: Get.textTheme.titleLarge!.fontSize,
                      ),
                      decoration: InputDecoration(
                        hintText: isTyping ? '' : 'Enter your name',
                        hintStyle: TextStyle(
                          fontSize: Get.textTheme.titleLarge!.fontSize,
                          fontWeight: FontWeight.normal,
                          color: const Color.fromRGBO(0, 0, 0, 0.3),
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
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      cursorColor: Colors.black,
                      style: TextStyle(
                        fontSize: Get.textTheme.titleLarge!.fontSize,
                      ),
                      decoration: InputDecoration(
                        hintText: isTyping ? '' : 'Enter your email address',
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
                    TextField(
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
                    TextField(
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: !isCheckedConfirmPassword,
                      cursorColor: Colors.black,
                      style: TextStyle(
                        fontSize: Get.textTheme.titleLarge!.fontSize,
                      ),
                      decoration: InputDecoration(
                        hintText: isTyping ? '' : 'Enter your confirm password',
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
                    SizedBox(
                      height: height * 0.02,
                    ),
                    // SizedBox(
                    //   height: width * 0.2,
                    //   child: WebViewWidget(controller: _controller),
                    // ),
                    SizedBox(
                      height: height * 0.02,
                    ),
                    ElevatedButton(
                      onPressed: () {},
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
                          color: const Color(0xffAF4C31),
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

  void backToLoginPage() {
    Get.back();
  }

  void goToLogin() {
    Get.to(() => const LoginPage());
  }
}
