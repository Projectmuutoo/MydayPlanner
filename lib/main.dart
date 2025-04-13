import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mydayplanner/pages/splash.dart';
import 'package:mydayplanner/shared/firebase_options.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // สำหรับ debug
  );
  FirebaseAuth.instance.setLanguageCode("th");
  await dotenv.load(fileName: ".env");
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
    return GetMaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('th', 'TH'), // Thai
      ],
      title: 'MyDayPlanner',
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'baloo',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: SplashPage(),
    );
  }
}
