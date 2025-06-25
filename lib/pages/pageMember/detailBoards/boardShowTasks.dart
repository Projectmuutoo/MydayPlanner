import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/pages/pageMember/detailBoards/tasksDetail.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

class BoradprivatePage extends StatefulWidget {
  const BoradprivatePage({super.key});

  @override
  State<BoradprivatePage> createState() => _BoradprivatePageState();
}

class _BoradprivatePageState extends State<BoradprivatePage> {
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
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
                FilledButton(
                  onPressed: () {
                    Get.to(() => TasksdetailPage());
                  },
                  child: Text(
                    'ไป',
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
