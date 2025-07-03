import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
import 'package:mydayplanner/splash.dart';
import 'package:rxdart/rxdart.dart' as rxdart;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // 📦 Storage
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FlutterSecureStorage storage = FlutterSecureStorage();
  var box = GetStorage();
  final Set<String> _animatedIds = <String>{};
  final Set<String> _animatedIds2 = <String>{};
  late String url;
  Timer? timer;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notification',
                    style: TextStyle(
                      fontSize:
                          Get.textTheme.headlineMedium!.fontSize! *
                          MediaQuery.of(context).textScaleFactor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        _deleteNotification(
                          null,
                          'InviteJoin',
                          collectionType2: 'InviteResponse',
                          collectionType3: 'Tasks',
                          all: true,
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03,
                          vertical: height * 0.005,
                        ),
                        child: Text(
                          "Clear",
                          style: TextStyle(
                            fontSize:
                                Get.textTheme.titleMedium!.fontSize! *
                                MediaQuery.of(context).textScaleFactor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder<List<QueryDocumentSnapshot>>(
                  stream: getAllCombinedNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize:
                                Get.textTheme.titleSmall!.fontSize! *
                                MediaQuery.of(context).textScaleFactor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    final notifications = snapshot.data!;
                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final doc = notifications[index];
                        final data = doc.data() as Map;

                        final isInvite =
                            data.containsKey('InviterName') &&
                            data['Response'] == 'Waiting';
                        final isResponse =
                            data.containsKey('ResponderName') &&
                            data['Response'] == 'Accept';
                        final isTaskNotification = data.containsKey('taskID');

                        if (isInvite || isResponse) {
                          final isFirstTime = !_animatedIds.contains(doc.id);
                          if (isFirstTime) {
                            _animatedIds.add(doc.id);
                          }
                          return Padding(
                            padding: EdgeInsets.only(bottom: height * 0.01),
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(
                                begin: isFirstTime ? 0.0 : 1.0,
                                end: 1.0,
                              ),
                              duration: Duration(
                                milliseconds: isFirstTime ? 400 : 0,
                              ),
                              curve: Curves.easeOutCirc,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, (1 - value) * -30),
                                  child: Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: Transform.scale(
                                      scale: 0.8 + (value * 0.2),
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: Material(
                                color: Color(0xFFF2F2F6),
                                borderRadius: BorderRadius.circular(8),
                                child: Dismissible(
                                  key: ValueKey(doc.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.02,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.red,
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return true;
                                  },
                                  onDismissed: (direction) async {
                                    setState(() {
                                      notifications.removeAt(index);
                                    });
                                    if (isInvite) {
                                      await _deleteNotification(
                                        doc.id,
                                        'InviteJoin',
                                      );
                                    } else {
                                      await _deleteNotification(
                                        doc.id,
                                        'InviteResponse',
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(
                                      top: height * 0.01,
                                      bottom: height * 0.01,
                                      left: width * 0.02,
                                      right: width * 0.03,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF2F2F6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        data['Profile'] == 'none-url'
                                            ? Container(
                                              width: height * 0.05,
                                              height: height * 0.05,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                              ),
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    height: height * 0.1,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black12,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    bottom: 0,
                                                    child: SvgPicture.string(
                                                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                      height: height * 0.035,
                                                      fit: BoxFit.contain,
                                                      color: Color(0xFF979595),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            : Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black12,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Image.network(
                                                data['Profile'],
                                                width: height * 0.05,
                                                height: height * 0.05,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                        SizedBox(width: width * 0.02),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    isInvite
                                                        ? 'Invite to join'
                                                        : 'Already joined the board',
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .titleSmall!
                                                              .fontSize! *
                                                          MediaQuery.of(
                                                            context,
                                                          ).textScaleFactor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          isInvite
                                                              ? Colors.black
                                                              : Colors.green,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        isInvite
                                                            ? timeAgo(
                                                              data['Invitation time']
                                                                  .toDate()
                                                                  .toIso8601String(),
                                                            )
                                                            : timeAgo(
                                                              data['Response time']
                                                                  .toDate()
                                                                  .toIso8601String(),
                                                            ),
                                                        style: TextStyle(
                                                          fontSize:
                                                              Get
                                                                  .textTheme
                                                                  .labelMedium!
                                                                  .fontSize! *
                                                              MediaQuery.of(
                                                                context,
                                                              ).textScaleFactor,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              RichText(
                                                text: TextSpan(
                                                  style: Get
                                                      .textTheme
                                                      .labelMedium!
                                                      .copyWith(
                                                        fontSize:
                                                            Get
                                                                .textTheme
                                                                .labelMedium!
                                                                .fontSize! *
                                                            MediaQuery.of(
                                                              context,
                                                            ).textScaleFactor,
                                                        color: Colors.black,
                                                      ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          isInvite
                                                              ? '@${data['InviterName']} '
                                                              : '@${data['ResponderName']} ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          isInvite
                                                              ? 'invited you to '
                                                              : 'accepted your invitation to ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${data['BoardName']} board',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                maxLines: 4,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (isInvite)
                                                Row(
                                                  children: [
                                                    ElevatedButton(
                                                      onPressed:
                                                          () => _handleAccept(
                                                            doc.id,
                                                            data,
                                                          ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Color(
                                                          0xFF007AFF,
                                                        ),
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Accept',
                                                        style: TextStyle(
                                                          fontSize:
                                                              Get
                                                                  .textTheme
                                                                  .labelMedium!
                                                                  .fontSize! *
                                                              MediaQuery.of(
                                                                context,
                                                              ).textScaleFactor,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: width * 0.02,
                                                    ),
                                                    ElevatedButton(
                                                      onPressed:
                                                          () => _handleDecline(
                                                            doc.id,
                                                            data,
                                                          ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.white,
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          side: BorderSide(
                                                            color:
                                                                Colors.black26,
                                                            width: 1,
                                                          ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Decline',
                                                        style: TextStyle(
                                                          fontSize:
                                                              Get
                                                                  .textTheme
                                                                  .labelMedium!
                                                                  .fontSize! *
                                                              MediaQuery.of(
                                                                context,
                                                              ).textScaleFactor,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else if (isTaskNotification) {
                          final rawData = box.read('userDataAll');
                          final tasksData = AllDataUserGetResponst.fromJson(
                            rawData,
                          );
                          final task =
                              tasksData.tasks
                                  .where((t) => t.taskId == data['taskID'])
                                  .toList();
                          if (task.isEmpty) return SizedBox.shrink();

                          final isFirstTime = !_animatedIds2.contains(doc.id);
                          if (isFirstTime) {
                            _animatedIds2.add(doc.id);
                          }

                          return Padding(
                            padding: EdgeInsets.only(bottom: height * 0.01),
                            child: TweenAnimationBuilder(
                              key: ValueKey(doc.id),
                              tween: Tween<double>(
                                begin: isFirstTime ? 0.0 : 1.0,
                                end: 1.0,
                              ),
                              duration: Duration(
                                milliseconds: isFirstTime ? 400 : 0,
                              ),
                              curve: Curves.easeOutCirc,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, (1 - value) * -30),
                                  child: Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: Transform.scale(
                                      scale: 0.8 + (value * 0.2),
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: Material(
                                color: Color(0xFFFFF2E6),
                                borderRadius: BorderRadius.circular(8),
                                child: Dismissible(
                                  key: ValueKey(doc.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.02,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.red,
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async => true,
                                  onDismissed: (direction) async {
                                    await FirebaseFirestore.instance
                                        .collection('Notifications')
                                        .doc(box.read('userProfile')['email'])
                                        .collection('Tasks')
                                        .doc(doc.id)
                                        .update({
                                          'isShow': FieldValue.delete(),
                                        });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(
                                      top: height * 0.01,
                                      bottom: height * 0.01,
                                      left: width * 0.02,
                                      right: width * 0.03,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF2F2F6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: height * 0.05,
                                          height: height * 0.05,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black12,
                                          ),
                                          child: Icon(
                                            Icons.schedule,
                                            color: Colors.white,
                                            size: height * 0.03,
                                          ),
                                        ),
                                        SizedBox(width: width * 0.02),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      task.first.taskName,
                                                      style: TextStyle(
                                                        fontSize:
                                                            Get
                                                                .textTheme
                                                                .titleSmall!
                                                                .fontSize! *
                                                            MediaQuery.of(
                                                              context,
                                                            ).textScaleFactor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFF007AFF,
                                                        ),
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(width: width * 0.05),
                                                  Text(
                                                    timeAgo(
                                                      data['dueDate']
                                                          .toDate()
                                                          .toIso8601String(),
                                                    ),
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .labelMedium!
                                                              .fontSize! *
                                                          MediaQuery.of(
                                                            context,
                                                          ).textScaleFactor,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              showDetailPrivateOrGroup(
                                                    task.first,
                                                  ).isEmpty
                                                  ? Text(
                                                    "Today, ${formatDateDisplay(data['dueDate'])}",
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .labelMedium!
                                                              .fontSize! *
                                                          MediaQuery.of(
                                                            context,
                                                          ).textScaleFactor,
                                                      color: Colors.black,
                                                    ),
                                                  )
                                                  : Text(
                                                    "${showDetailPrivateOrGroup(task.first)}, ${formatDateDisplay(data['dueDate'])}",
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .labelMedium!
                                                              .fontSize! *
                                                          MediaQuery.of(
                                                            context,
                                                          ).textScaleFactor,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatDateDisplay(dynamic date) {
    final hour = date.toDate().hour.toString().padLeft(2, '0');
    final minute = date.toDate().minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String showDetailPrivateOrGroup(Task task) {
    final rawData = box.read('userDataAll');
    final data = AllDataUserGetResponst.fromJson(rawData);

    bool isPrivate = (data.board).any((b) => b.boardId == task.boardId);
    bool isGroup = (data.boardgroup).any((b) => b.boardId == task.boardId);
    if (isPrivate) return 'Private';
    if (isGroup) return 'Group';

    return '';
  }

  Future<void> _handleAccept(String docId, Map data) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. ส่งการแจ้งเตือนให้คนที่เชิญ
    final responseDoc = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(data['Inviter'])
        .collection('InviteResponse')
        .doc('${data['BoardId']}from-${box.read('userProfile')['email']}');

    batch.set(responseDoc, {
      'Profile': box.read('userProfile')['profile'],
      'BoardId': data['BoardId'],
      'BoardName': data['BoardName'],
      'Response': 'Accept',
      'ResponderName': box.read('userProfile')['name'],
      'Responder': box.read('userProfile')['email'],
      'Response time': DateTime.now(),
    });

    // 2. อัพเดท Response ใน InviteJoin เป็น Accept
    final inviteDoc = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(box.read('userProfile')['email'])
        .collection('InviteJoin')
        .doc(docId);

    batch.update(inviteDoc, {'Response': 'Accept'});

    await batch.commit();

    url = await loadAPIEndpoint();
    var response = await http.post(
      Uri.parse("$url/board/addboard/${data['BoardId']}"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );
    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      await http.post(
        Uri.parse("$url/board/addboard/${data['BoardId']}"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
    }
    final responseAll = await http.get(
      Uri.parse("$url/user/data"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );
    if (responseAll.statusCode == 200) {
      final response2 = allDataUserGetResponstFromJson(responseAll.body);
      box.write('userDataAll', response2.toJson());
    }
  }

  Future<void> _handleDecline(String docId, Map data) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. ส่งการแจ้งเตือนให้คนที่เชิญ
    final responseDoc = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(data['Inviter'])
        .collection('InviteResponse')
        .doc('${data['BoardId']}from-${box.read('userProfile')['email']}');

    batch.set(responseDoc, {
      'Profile': box.read('userProfile')['profile'],
      'BoardId': data['BoardId'],
      'BoardName': data['BoardName'],
      'Response': 'Decline',
      'ResponderName': box.read('userProfile')['name'],
      'Responder': box.read('userProfile')['email'],
      'Response time': DateTime.now(),
    });

    // 2. อัพเดท Response ใน InviteJoin เป็น Decline
    final inviteDoc = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(box.read('userProfile')['email'])
        .collection('InviteJoin')
        .doc(docId);

    batch.update(inviteDoc, {'Response': 'Decline'});

    await batch.commit();
  }

  Future<void> _deleteNotification(
    String? docId,
    String collectionType, {
    String? collectionType2,
    String? collectionType3,
    bool all = false,
  }) async {
    final userEmail = box.read('userProfile')['email'];
    final baseCollection = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(userEmail);

    if (all) {
      final snapshot1 = await baseCollection.collection(collectionType).get();
      for (var doc in snapshot1.docs) {
        await doc.reference.delete();
      }
      if (collectionType2 != null) {
        final snapshot2 =
            await baseCollection.collection(collectionType2).get();
        for (var doc in snapshot2.docs) {
          await doc.reference.delete();
        }
      }
      if (collectionType3 != null) {
        final snapshot3 =
            await baseCollection.collection(collectionType3).get();
        for (var doc in snapshot3.docs) {
          await doc.reference.update({'isShow': FieldValue.delete()});
        }
      }
    } else {
      await baseCollection.collection(collectionType).doc(docId).delete();
    }
  }

  Stream<List<QueryDocumentSnapshot>> getAllCombinedNotifications() {
    final inviteStream = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(box.read('userProfile')['email'])
        .collection('InviteJoin')
        .orderBy('Invitation time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);

    final responseStream = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(box.read('userProfile')['email'])
        .collection('InviteResponse')
        .orderBy('Response time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);

    final taskStream = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(box.read('userProfile')['email'])
        .collection('Tasks')
        .where('isShow', isEqualTo: true)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
    return rxdart.Rx.combineLatest3<
      List<QueryDocumentSnapshot>,
      List<QueryDocumentSnapshot>,
      List<QueryDocumentSnapshot>,
      List<QueryDocumentSnapshot>
    >(inviteStream, responseStream, taskStream, (invites, responses, tasks) {
      final all = [...invites, ...responses, ...tasks];
      all.sort((a, b) {
        final aData = a.data() as Map;
        final bData = b.data() as Map;

        final aTime =
            aData['Invitation time'] ??
            aData['Response time'] ??
            aData['dueDate'];
        final bTime =
            bData['Invitation time'] ??
            bData['Response time'] ??
            bData['dueDate'];

        return (bTime as Timestamp).compareTo(aTime as Timestamp);
      });
      return all;
    });
  }

  String formatToDayAndTime(DateTime dateTime) {
    final formatter = DateFormat('EEEE h:mma');
    return formatter.format(dateTime);
  }

  String timeAgo(String timestamp) {
    final DateTime postTimeUtc = DateTime.parse(timestamp);
    final DateTime postTimeLocal = postTimeUtc.toLocal();
    final DateTime nowLocal = DateTime.now();

    final Duration difference = nowLocal.difference(postTimeLocal);
    String formattedTime = DateFormat('HH:mm').format(postTimeLocal);

    if (difference.inSeconds < 10) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      bool isSameDay =
          postTimeLocal.year == nowLocal.year &&
          postTimeLocal.month == nowLocal.month &&
          postTimeLocal.day == nowLocal.day;

      if (isSameDay) {
        return '${difference.inHours}h ago';
      } else {
        return 'Yesterday, $formattedTime';
      }
    } else if (difference.inDays < 7) {
      DateTime yesterday = nowLocal.subtract(Duration(days: 1));
      bool isYesterday =
          postTimeLocal.year == yesterday.year &&
          postTimeLocal.month == yesterday.month &&
          postTimeLocal.day == yesterday.day;

      if (isYesterday) {
        return 'Yesterday, $formattedTime';
      } else {
        return '${difference.inDays}d ago, $formattedTime';
      }
    } else {
      return DateFormat('d MMM yyyy, HH:mm').format(postTimeLocal);
    }
  }

  Future<void> loadNewRefreshToken() async {
    url = await loadAPIEndpoint();
    var value = await storage.read(key: 'refreshToken');
    var loadtoketnew = await http.post(
      Uri.parse("$url/auth/newaccesstoken"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer $value",
      },
    );
    if (loadtoketnew.statusCode == 200) {
      var reponse = jsonDecode(loadtoketnew.body);
      box.write('accessToken', reponse['accessToken']);
    } else if (loadtoketnew.statusCode == 403) {
      Get.defaultDialog(
        title: '',
        titlePadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        barrierDismissible: false,
        contentPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        content: WillPopScope(
          onWillPop: () async => false,
          child: Column(
            children: [
              Image.asset(
                "assets/images/aleart/warning.png",
                height: MediaQuery.of(context).size.height * 0.1,
                fit: BoxFit.contain,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Text(
                'Waring!!',
                style: TextStyle(
                  fontSize:
                      Get.textTheme.headlineSmall!.fontSize! *
                      MediaQuery.of(context).textScaleFactor,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              Text(
                'The system has expired. Please log in again.',
                style: TextStyle(
                  fontSize:
                      Get.textTheme.titleSmall!.fontSize! *
                      MediaQuery.of(context).textScaleFactor,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final currentUserProfile = box.read('userProfile');
              if (currentUserProfile != null && currentUserProfile is Map) {
                await FirebaseFirestore.instance
                    .collection('usersLogin')
                    .doc(currentUserProfile['email'])
                    .update({'deviceName': FieldValue.delete()});
              }
              box.remove('userDataAll');
              box.remove('userLogin');
              box.remove('userProfile');
              box.remove('accessToken');
              await googleSignIn.signOut();
              await FirebaseAuth.instance.signOut();
              await storage.deleteAll();
              Get.offAll(() => SplashPage(), arguments: {'fromLogout': true});
            },
            style: ElevatedButton.styleFrom(
              fixedSize: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height * 0.05,
              ),
              backgroundColor: Color(0xFF007AFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
            child: Text(
              'Login',
              style: TextStyle(
                fontSize:
                    Get.textTheme.titleMedium!.fontSize! *
                    MediaQuery.of(context).textScaleFactor,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
  }
}
