import 'dart:convert';
import 'dart:developer';

import 'package:demomydayplanner/config/config.dart';
import 'package:demomydayplanner/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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
  bool isTyping = false;
  bool isCheckedPassword = false;
  bool isCheckedConfirmPassword = false;
  bool isCaptchaVerified = false;
  bool isLoading = false;

  // Controller สำหรับเก็บค่า input
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  // สร้าง WebViewController
  late final WebViewController _controller;

  final String siteKey = dotenv.env['RECAPTCHA_SITE_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    // ลองเริ่มต้น reCAPTCHA client
    initCaptchaClient();

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

  @override
  void dispose() {
    // ปล่อยทรัพยากร controllers
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05,
              vertical: height * 0.03,
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
                      controller: nameController,
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
                      controller: emailController,
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
                      controller: passwordController,
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
                      controller: confirmPasswordController,
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
                    // แสดงสถานะ CAPTCHA
                    Container(
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
                          color: isCaptchaVerified ? Colors.green : Colors.grey,
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
                                fontSize: Get.textTheme.bodyMedium!.fontSize,
                                color: isCaptchaVerified
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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

  void initCaptchaClient() async {
    setState(() {
      isLoading = true;
    });
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void executeCaptcha() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await RecaptchaEnterprise.execute(RecaptchaAction.LOGIN());
      // log("CAPTCHA Token: $token");

      // ส่ง Token ไปตรวจสอบกับ Backend
      await verifyCaptchaOnServer(token);
    } catch (e) {
      log("Error executing reCAPTCHA: $e");
      // _showErrorDialog("Error executing reCAPTCHA: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> verifyCaptchaOnServer(String token) async {
    try {
      // ใช้ API endpoint ของคุณเพื่อยืนยัน reCAPTCHA token
      // หมายเหตุ: แนะนำให้ยืนยัน reCAPTCHA บน server ของคุณไม่ใช่จาก client โดยตรง
      var config = await Configuration.getConfig();
      var urls = config['apiEndpoint'];
      final url = Uri.parse('$urls/verify/verify-recaptcha');

      final response = await http.post(url,
          body: jsonEncode({'token': token, 'action': 'login'}),
          headers: {
            'Content-Type': 'application/json',
          });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['score'] > 0.5) {
          setState(() {
            isCaptchaVerified = true;
          });
          log("CAPTCHA Verified Successfully");
        } else {
          // _showErrorDialog(
          //     "CAPTCHA Verification Failed: ${data['error'] ?? 'Unknown error'}");
        }
      } else {
        // _showErrorDialog("Error verifying CAPTCHA: ${response.statusCode}");
      }
    } catch (e) {
      // _showErrorDialog("Error connecting to server: $e");
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

  void _verifyWebViewCaptcha(String token) async {
    try {
      await verifyCaptchaOnServer(token);
    } catch (e) {
      // _showErrorDialog("Error verifying CAPTCHA: $e");
    }
  }

  void register() async {
    // Validate form
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      // _showErrorDialog("Please fill in all fields");
      log("message");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      // _showErrorDialog("Passwords do not match");
      return;
    }

    if (!isCaptchaVerified) {
      // ถ้า native reCAPTCHA ไม่ทำงาน ให้ใช้ WebView fallback
      _showCaptchaWebView();
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // TODO: เพิ่มการเชื่อมต่อกับ API สำหรับการลงทะเบียน
      // ตัวอย่างสำหรับการเชื่อมต่อกับ API
      /*
      final response = await http.post(
        Uri.parse('https://yourapi.com/register'),
        body: jsonEncode({
          'name': nameController.text,
          'email': emailController.text,
          'password': passwordController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        Get.to(() => const LoginPage());
      } else {
        _showErrorDialog("Registration failed: ${jsonDecode(response.body)['message']}");
      }
      */

      // สำหรับตอนนี้แค่ไปหน้า login
      Get.to(() => const LoginPage());
    } catch (e) {
      // _showErrorDialog("Error during registration: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
}
