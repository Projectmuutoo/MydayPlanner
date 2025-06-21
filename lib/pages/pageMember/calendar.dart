import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  var box = GetStorage();
  List<UnifiedTask> tasks = [];

  @override
  void initState() {
    super.initState();

    loadDataAsync();
  }

  Future<void> loadDataAsync() async {
    if (!mounted) return;

    final rawData = box.read('userDataAll');
    final tasksData = AllDataUserGetResponst.fromJson(rawData);
    final appData = Provider.of<Appdata>(context, listen: false);

    List<UnifiedTask> filter = [];

    // จาก Task
    // filter.addAll(
    //   tasksData.tasks.map(
    //     (task) => UnifiedTask(
    //       taskId: task.taskId.toString(), // เป็น int จึงต้องแปลง
    //       taskName: task.taskName,
    //       description: task.description!,
    //       priority: task.priority!,
    //       status: task.status,
    //       createdAt: task.createdAt,
    //     ),
    //   ),
    // );

    appData.showMyTasksCalendar.setTasks(filter);

    if (!mounted) return;
    setState(() {
      tasks = appData.showMyTasksCalendar.tasks;
    });
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
            Column(
              children:
                  tasks.map((value) {
                    return Column(
                      children: [Text(value.taskName), Text(value.taskId)],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
