import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AlltasksPage extends StatefulWidget {
  const AlltasksPage({super.key});

  @override
  State<AlltasksPage> createState() => _AlltasksPageState();
}

class _AlltasksPageState extends State<AlltasksPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Alltasks',
              style: TextStyle(
                fontSize: Get.textTheme.displayMedium!.fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
