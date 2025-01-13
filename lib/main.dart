import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demomydayplanner/pages/login.dart';
import 'package:demomydayplanner/pages/pageAdmin/navBarAdmin.dart';
import 'package:demomydayplanner/pages/pageMember/navBar.dart';
import 'package:demomydayplanner/shared/firebase_options.dart';
import 'package:demomydayplanner/shared/appData.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await GetStorage.init();
  initializeDateFormatting().then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => Appdata(),
          )
        ],
        child: const MainApp(),
      ),
    );
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: getUserStatusStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildAppWithHome(
            Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              ),
            ),
          );
        } else if (snapshot.hasData) {
          final data = snapshot.data?.data();
          if (data != null) {
            if (data['active'] == 0) {
              return buildAppWithHome(LoginPage());
            }
            if (data['login'] == 1) {
              return buildAppWithHome(
                data['role'] == "admin" ? NavbaradminPage() : NavbarPage(),
              );
            }
          }
        }
        return buildAppWithHome(LoginPage());
      },
    );
  }

  GetMaterialApp buildAppWithHome(Widget home) {
    return GetMaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      // supportedLocales: const [
      //   Locale('en', 'US'), // English
      //   Locale('th', 'TH'), // Thai
      // ],
      title: 'MyDayPlanner',
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'baloo',
        scaffoldBackgroundColor: const Color(0xFFF3F3F3),
      ),
      home: home,
    );
  }
}

Stream<DocumentSnapshot<Map<String, dynamic>>>? getUserStatusStream() {
  final box = GetStorage();
  final email = box.read('email');
  if (email != null && email.isNotEmpty) {
    return FirebaseFirestore.instance
        .collection('usersLogin')
        .doc(email)
        .snapshots();
  }
  return null;
}
