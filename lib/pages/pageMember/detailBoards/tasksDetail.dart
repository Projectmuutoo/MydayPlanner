import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mydayplanner/config/config.dart';

class TasksdetailPage extends StatefulWidget {
  const TasksdetailPage({super.key});

  @override
  State<TasksdetailPage> createState() => _TasksdetailPageState();
}

class _TasksdetailPageState extends State<TasksdetailPage> {
  late Future<void> loadData;
  var box = GetStorage();
  String text = ''; // สำหรับแสดงลิงก์
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Text('data'),
              Text('data'),
              Text('data'),
              Text('data'),
              Text('data'),
            ],
          ),
        ),
      ),
    );
  }
}
