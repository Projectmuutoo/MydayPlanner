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
    log(context.read<Appdata>().idBoard.idBoard);
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
          padding: EdgeInsets.only(
            right: width * 0.05,
            left: width * 0.05,
            top: height * 0.01,
          ),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.read<Appdata>().idBoard.idBoard,
                  style: TextStyle(
                    fontSize: Get.textTheme.titleLarge!.fontSize,
                    fontFamily: 'mali',
                  ),
                ),
                FilledButton(
                  onPressed: () {},
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
