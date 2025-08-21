import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:mydayplanner/splash.dart';
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    final payloadData = {
      'timestamp': message.data['timestamp'],
      'boardid': message.data['boardid'],
      'taskid': message.data['taskid'],
      'type': message.data['type'],
    };

    NotificationService.showNotification(
      title: title,
      body: body,
      payload: message.data['payload'] ?? jsonEncode(payloadData),
      type: message.data['type'] ?? '',
    );
  });
  FirebaseAuth.instance.setLanguageCode('th');
  await dotenv.load(fileName: ".env");
  await GetStorage.init();
  initializeDateFormatting().then((_) {
    runApp(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (context) => Appdata())],
        child: MainApp(),
      ),
    );
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.initialize(navigatorKey.currentContext!);
    });
    return ScreenUtilInit(
      designSize: Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height,
      ),
      minTextAdapt: true,
      builder: (_, child) {
        return GetMaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: [Locale('en', 'US'), Locale('th', 'TH')],
          title: 'MyDayPlanner',
          theme: ThemeData(
            useMaterial3: false,
            fontFamily: 'baloo',
            scaffoldBackgroundColor: Colors.white,
          ),
          home: const SplashPage(),
        );
      },
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final title = message.notification?.title ?? '';
  final body = message.notification?.body ?? '';
  final payloadData = {
    'timestamp': message.data['timestamp'],
    'boardid': message.data['boardid'],
    'taskid': message.data['taskid'],
    'type': message.data['type'] ?? '',
  };

  NotificationService.showNotification(
    title: title,
    body: body,
    payload: message.data['payload'] ?? jsonEncode(payloadData),
    type: message.data['type'],
  );
}
