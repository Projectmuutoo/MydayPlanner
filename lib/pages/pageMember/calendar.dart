import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  var box = GetStorage();

  @override
  void initState() {
    super.initState();

    loadDataAsync();
  }

  Future<void> loadDataAsync() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Calendar',
              style: TextStyle(fontSize: Get.textTheme.displayMedium!.fontSize),
            ),
          ],
        ),
      ),
    );
  }
}
