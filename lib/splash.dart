import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
import 'package:mydayplanner/pages/login.dart';
import 'package:mydayplanner/pages/pageAdmin/navBarAdmin.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final box = GetStorage();
  StreamSubscription<DocumentSnapshot>? _subscription;
  bool _isFromLogout = false;
  final storage = FlutterSecureStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  bool _isNavigating = false;
  late String url;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();

    final arguments = Get.arguments;
    _isFromLogout = arguments?['fromLogout'] == true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _initializeApp() {
    final appData = Provider.of<Appdata>(context, listen: false);
    final userProfile = box.read('userProfile');

    if (_isFromLogout) {
      box.write('userLogin', {'keepActiveUser': '', 'keepRoleUser': ''});
    }

    if (userProfile == null || userProfile['email'] == null) {
      goToPage();
      return;
    }

    var existingUserLogin = box.read('userLogin');
    if (existingUserLogin != null &&
        existingUserLogin['keepActiveUser'] != null &&
        existingUserLogin['keepActiveUser'] != '' &&
        existingUserLogin['keepRoleUser'] != null &&
        existingUserLogin['keepRoleUser'] != '') {
      goToPage();
      return;
    }

    if (!_isFromLogout) {
      _startFirebaseListenerWithTimeout(appData, userProfile);
    } else {
      goToPage();
    }
  }

  void _startFirebaseListenerWithTimeout(Appdata appData, userProfile) {
    bool hasNavigated = false;

    Timer timeoutTimer = Timer(Duration(seconds: 5), () {
      if (!hasNavigated && mounted) {
        hasNavigated = true;
        _subscription?.cancel();
        goToPage();
      }
    });

    _subscription = FirebaseFirestore.instance
        .collection('usersLogin')
        .doc(userProfile['email'])
        .snapshots()
        .listen(
          (snapshot) {
            if (_isNavigating || hasNavigated) return;

            timeoutTimer.cancel();
            hasNavigated = true;

            if (snapshot.exists && ['0', '1'].contains(snapshot['active'])) {
              box.write('userLogin', {
                'keepActiveUser': snapshot['active'] == '0' ? '0' : '1',
                'keepRoleUser': snapshot['role'],
              });
            } else {
              Future.delayed(Duration.zero, () {
                if (mounted) {
                  goToPage();
                }
              });
            }
          },
          onError: (error) {
            timeoutTimer.cancel();
            if (!hasNavigated && mounted) {
              hasNavigated = true;
              goToPage();
            }
          },
        );
  }

  void goToPage() async {
    if (_isNavigating) return;
    _isNavigating = true;

    var userLogin = box.read('userLogin');
    if (userLogin == null) {
      Get.offAll(() => LoginPage());
      return;
    }
    var keepActiveUser = userLogin['keepActiveUser'];
    var keepRoleUser = userLogin['keepRoleUser'];

    Future.delayed(Duration(seconds: 1), () async {
      if (keepRoleUser == "admin" && keepActiveUser == '1') {
        Get.offAll(() => NavbaradminPage());
      } else if (keepRoleUser == "user" && keepActiveUser == '1') {
        fetchDataOnResume();
        Get.offAll(() => NavbarPage());
      } else {
        Get.offAll(() => LoginPage());
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> fetchDataOnResume() async {
    url = await loadAPIEndpoint();
    var oldUserProfile = box.read('userProfile');
    var oldUserDataAllJson = box.read('userDataAll');
    if (oldUserProfile == null || oldUserDataAllJson == null) {
      return;
    }

    var oldUserDataAll = AllDataUserGetResponst.fromJson(oldUserDataAllJson);
    final response = await http.get(
      Uri.parse("$url/user/data"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );

    if (response.statusCode == 200) {
      final newDataJson = allDataUserGetResponstFromJson(response.body);

      if (!deepEquals(oldUserDataAll, newDataJson)) {
        box.write('userDataAll', newDataJson.toJson());
      }
    }
    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      return fetchDataOnResume();
    }
  }

  bool deepEquals(AllDataUserGetResponst a, AllDataUserGetResponst b) {
    return jsonEncode(a.toJson()) == jsonEncode(b.toJson());
  }

  Future<void> loadNewRefreshToken() async {
    url = await loadAPIEndpoint();
    var value = await storage.read(key: 'refreshToken');
    var loadtoketnew = await http.post(
      Uri.parse("$url/auth/newaccesstoken"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer $value",
      },
    );

    if (loadtoketnew.statusCode == 200) {
      var reponse = jsonDecode(loadtoketnew.body);
      box.write('accessToken', reponse['accessToken']);
    } else if (loadtoketnew.statusCode == 403 ||
        loadtoketnew.statusCode == 401) {
      final currentUserProfile = box.read('userProfile');
      if (currentUserProfile != null && currentUserProfile is Map) {
        await FirebaseFirestore.instance
            .collection('usersLogin')
            .doc(currentUserProfile['email'])
            .update({'deviceName': FieldValue.delete()});
      }
      box.remove('userDataAll');
      box.remove('userLogin');
      box.remove('userProfile');
      box.remove('accessToken');
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      await storage.deleteAll();
      Get.offAll(() => SplashPage(), arguments: {'fromLogout': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFF2F2F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/LogoApp.png', width: 100, height: 100),
          ],
        ),
      ),
    );
  }
}
