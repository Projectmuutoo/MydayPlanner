import 'dart:developer';

import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

class BoradlistsPage extends StatefulWidget {
  const BoradlistsPage({super.key});

  @override
  State<BoradlistsPage> createState() => _BoradlistsPageState();
}

class _BoradlistsPageState extends State<BoradlistsPage> {
  late Future<void> loadData;
  var box = GetStorage();
  String text = '';
  late String url;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    loadData = loadDataAsync();
  }

  Future<void> loadDataAsync() async {
    url = await loadAPIEndpoint();
    log(box.read('userProfile')['email']);
  }

  @override
  Widget build(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  box.read('userProfile')['email'],
                  style: TextStyle(
                    fontSize: Get.textTheme.titleLarge!.fontSize,
                    fontFamily: 'mali',
                  ),
                ),
                SizedBox(height: height * 0.03),
                Text(
                  context.watch<Appdata>().idBoard.idBoard,
                  style: TextStyle(
                    fontSize: Get.textTheme.titleLarge!.fontSize,
                    fontFamily: 'mali',
                  ),
                ),
                SizedBox(height: height * 0.03),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: Get.textTheme.titleLarge!.fontSize,
                      fontFamily: 'mali',
                    ),
                  ),
                if (text.isNotEmpty) SizedBox(height: height * 0.03),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      text.isEmpty ? text = 'อุอิ' : text = '';
                    });
                  },
                  child: Text(
                    'ปุ่ม',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleLarge!.fontSize,
                      fontFamily: 'mali',
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: Text(
                    'กลับ',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleLarge!.fontSize,
                      fontFamily: 'mali',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
