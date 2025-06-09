import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mydayplanner/config/config.dart';
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
    log(box.read('userProfile')['email']);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    final boardId = context.watch<Appdata>().idBoard.idBoard;
    final boardName = context.watch<Appdata>().idBoard.boardName;
    final boardToken = context.watch<Appdata>().idBoard.boardToken;

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
                  boardId,
                  style: TextStyle(
                    fontSize: Get.textTheme.titleLarge!.fontSize,
                    fontFamily: 'mali',
                  ),
                ),
                SizedBox(height: height * 0.03),
                if (text.isNotEmpty)
                  SelectableText(
                    text,
                    style: TextStyle(
                      fontSize: Get.textTheme.titleLarge!.fontSize,
                      fontFamily: 'mali',
                      color: Colors.blue,
                    ),
                  ),
                if (text.isNotEmpty) SizedBox(height: height * 0.03),
                if (boardToken.isNotEmpty)
                  FilledButton(
                    onPressed: () async {
                      try {
                        // ตรวจสอบก่อนส่ง
                        if (!await canSendInvitation(
                          box.read('userProfile')['email'],
                          '123@gmail.com',
                          boardId,
                        )) {
                          Get.snackbar(
                            'Cannot Send',
                            'Invitation already sent or user already accepted',
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        // ส่งคำเชิญ
                        await FirebaseFirestore.instance
                            .collection('Notifications')
                            .doc('123@gmail.com')
                            .collection('InviteJoin')
                            .doc(
                              '${boardId}from-${box.read('userProfile')['email']}',
                            )
                            .set({
                              'Profile': box.read('userProfile')['profile'],
                              'BoardId': boardId,
                              'BoardName': boardName,
                              'InviterName': box.read('userProfile')['name'],
                              'Inviter': box.read('userProfile')['email'],
                              'Response': 'Waiting',
                              'Invitation time': DateTime.now(),
                            });
                      } catch (e) {
                        Get.snackbar(
                          'Error',
                          'Failed to send invitation: $e',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: Text(
                      'เตือนเชิญสมาชิก',
                      style: TextStyle(
                        fontSize: Get.textTheme.titleLarge!.fontSize,
                        fontFamily: 'mali',
                      ),
                    ),
                  ),
                if (boardToken.isNotEmpty)
                  FilledButton(
                    onPressed: () {
                      final inviteLink =
                          'myapp://mydayplanner-app/source?join=$boardToken';
                      setState(() {
                        text = inviteLink;
                      });
                    },
                    child: Text(
                      'สร้างลิ้ง',
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

  Future<bool> canSendInvitation(
    String inviterEmail,
    String inviteeEmail,
    String boardId,
  ) async {
    try {
      // ตรวจสอบว่ามีคำเชิญที่ยังรออยู่หรือถูก Accept แล้วหรือไม่
      final existingInvite =
          await FirebaseFirestore.instance
              .collection('Notifications')
              .doc(inviteeEmail)
              .collection('InviteJoin')
              .where('Inviter', isEqualTo: inviterEmail)
              .where('BoardId', isEqualTo: boardId)
              .get();

      if (existingInvite.docs.isEmpty) {
        return true; // ไม่มีคำเชิญ สามารถส่งได้
      }

      final inviteData = existingInvite.docs.first.data();
      final response = inviteData['Response'];

      // ถ้า Response เป็น Accept แล้ว ไม่สามารถส่งได้อีก
      if (response == 'Accept') {
        return false;
      }

      // ถ้า Response เป็น Waiting หรือ Decline ยังส่งได้
      return response == 'Decline' || response == 'Waiting';
    } catch (e) {
      print('Error checking invitation status: $e');
      return false;
    }
  }
}
