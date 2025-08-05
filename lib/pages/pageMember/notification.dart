import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
import 'package:mydayplanner/pages/pageMember/detailBoards/tasksDetail.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:rxdart/rxdart.dart' as rxdart;
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
  var box = GetStorage();
  final Set<String> _animatedIds = <String>{};
  final Set<String> _animatedIds2 = <String>{};
  final Set<String> _animatedIds3 = <String>{};
  final Set<String> _animatedIds4 = <String>{};
  late String url;
  Timer? timer;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
                    'Notifications',
                    style: TextStyle(
                      fontSize: Get.textTheme.headlineMedium!.fontSize!,
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
                            fontSize: Get.textTheme.titleMedium!.fontSize!,
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
                      return Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize!,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    final notifications = snapshot.data!;
                    final userUid = box
                        .read('userProfile')['userid']
                        .toString();

                    final validDisplayableNotifications = notifications.where((
                      doc,
                    ) {
                      final data = doc.data() as Map<String, dynamic>;

                      if (data.containsKey('InviterName') &&
                          data['Response'] == 'Waiting') {
                        return true;
                      }
                      if (data.containsKey('ResponderName') &&
                          data['Response'] == 'Accept') {
                        return true;
                      }

                      if (data.containsKey('taskID') &&
                          !data.containsKey('userNotifications')) {
                        return (data['isShow'] == true) ||
                            (data['dueDateOld'] != null) ||
                            (data['isNotiRemindShow'] == true) ||
                            (data['remindMeBeforeOld'] != null);
                      }

                      if (data.containsKey('userNotifications')) {
                        final userNotifications = data['userNotifications'];
                        if (userNotifications != null &&
                            userNotifications is Map<String, dynamic> &&
                            userNotifications.containsKey(userUid)) {
                          final userSettings = userNotifications[userUid];
                          if (userSettings != null &&
                              userSettings is Map<String, dynamic>) {
                            return (userSettings['isShow'] == true) ||
                                (userSettings['dueDateOld'] != null) ||
                                (userSettings['isNotiRemindShow'] == true) ||
                                (userSettings['remindMeBeforeOld'] != null);
                          }
                        }
                      }

                      if (data.containsKey('AssignBy')) {
                        return true;
                      }

                      return false;
                    }).toList();

                    if (validDisplayableNotifications.isEmpty) {
                      return Center(
                        child: Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize!,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: validDisplayableNotifications.length,
                      itemBuilder: (context, index) {
                        final doc = validDisplayableNotifications[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final isInvite =
                            data.containsKey('InviterName') &&
                            data['Response'] == 'Waiting';
                        final isResponse =
                            data.containsKey('ResponderName') &&
                            data['Response'] == 'Accept';

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
                                        ClipOval(
                                          child: data['Profile'] == 'none-url'
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
                                                        decoration:
                                                            BoxDecoration(
                                                              color: Colors
                                                                  .black12,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                      ),
                                                      Positioned(
                                                        left: 0,
                                                        right: 0,
                                                        bottom: 0,
                                                        child: SvgPicture.string(
                                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                          height:
                                                              height * 0.035,
                                                          fit: BoxFit.contain,
                                                          color: Color(
                                                            0xFF979595,
                                                          ),
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
                                                      fontSize: Get
                                                          .textTheme
                                                          .titleSmall!
                                                          .fontSize!,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isInvite
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
                                                          fontSize: Get
                                                              .textTheme
                                                              .labelMedium!
                                                              .fontSize!,
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
                                                        fontSize: Get
                                                            .textTheme
                                                            .labelMedium!
                                                            .fontSize!,
                                                        color: Colors.black,
                                                      ),
                                                  children: [
                                                    TextSpan(
                                                      text: isInvite
                                                          ? '@${data['InviterName']} '
                                                          : '@${data['ResponderName']} ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: isInvite
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
                                                      onPressed: () =>
                                                          _handleAccept(
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
                                                          fontSize: Get
                                                              .textTheme
                                                              .labelMedium!
                                                              .fontSize!,
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
                                                      onPressed: () =>
                                                          _handleDecline(
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
                                                          fontSize: Get
                                                              .textTheme
                                                              .labelMedium!
                                                              .fontSize!,
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
                        } else if (data.containsKey('AssignBy')) {
                          final isFirstTime = !_animatedIds4.contains(doc.id);
                          if (isFirstTime) {
                            _animatedIds4.add(doc.id);
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

                                    await _deleteNotification(
                                      doc.id,
                                      'AddAssigness',
                                    );
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
                                        ClipOval(
                                          child: Container(
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
                                                Align(
                                                  child: Icon(
                                                    Icons.person_add_rounded,
                                                    size: 24,
                                                    color: Color(0xFF979595),
                                                  ),
                                                ),
                                              ],
                                            ),
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
                                                    'There is a new assignment',
                                                    style: TextStyle(
                                                      fontSize: Get
                                                          .textTheme
                                                          .titleSmall!
                                                          .fontSize!,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isInvite
                                                          ? Colors.black
                                                          : Colors.green,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        timeAgo(
                                                          data['updatedAt']
                                                              .toDate()
                                                              .toIso8601String(),
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: Get
                                                              .textTheme
                                                              .labelMedium!
                                                              .fontSize!,
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
                                                        fontSize: Get
                                                            .textTheme
                                                            .labelMedium!
                                                            .fontSize!,
                                                        color: Colors.black,
                                                      ),
                                                  children: [
                                                    TextSpan(
                                                      text: 'You ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${data['nameUser']}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          ' have been assigned a task.',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                maxLines: 4,
                                                overflow: TextOverflow.ellipsis,
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

                        final rawData = box.read('userDataAll');
                        final tasksData = AllDataUserGetResponst.fromJson(
                          rawData,
                        );
                        final task = tasksData.tasks
                            .where((t) => t.taskId == data['taskID'])
                            .toList();

                        if (task.isEmpty) return SizedBox.shrink();

                        final isTaskNotification =
                            data.containsKey('taskID') &&
                            !data.containsKey('userNotifications');

                        if (isTaskNotification) {
                          final isFirstTime = !_animatedIds2.contains(doc.id);
                          if (isFirstTime) {
                            _animatedIds2.add(doc.id);
                          }
                          List<Widget> notificationWidgets = [];

                          if ((data['isShow'] == true) ||
                              (data['dueDateOld'] != null)) {
                            notificationWidgets.add(
                              _buildTaskNotification(
                                context: context,
                                doc: doc,
                                task: task.first,
                                data: data,
                                isFirstTime: isFirstTime,
                                notificationType: 'show',
                              ),
                            );
                          }

                          if ((data['isNotiRemindShow'] == true) ||
                              (data['remindMeBeforeOld'] != null)) {
                            notificationWidgets.add(
                              _buildTaskNotification(
                                context: context,
                                doc: doc,
                                task: task.first,
                                data: data,
                                isFirstTime: isFirstTime,
                                notificationType: 'remind',
                              ),
                            );
                          }
                          if (notificationWidgets.isNotEmpty) {
                            return Column(children: notificationWidgets);
                          }
                        } else if (data.containsKey('userNotifications')) {
                          final userNotifications = data['userNotifications'];

                          if (userNotifications != null &&
                              userNotifications is Map<String, dynamic> &&
                              userNotifications.containsKey(userUid)) {
                            final userSettings = userNotifications[userUid];
                            if (userSettings != null &&
                                userSettings is Map<String, dynamic>) {
                              final isFirstTime = !_animatedIds3.contains(
                                doc.id,
                              );
                              if (isFirstTime) {
                                _animatedIds3.add(doc.id);
                              }
                              List<Widget> notificationWidgets = [];

                              if ((userSettings['isShow'] == true) ||
                                  (userSettings['dueDateOld'] != null)) {
                                notificationWidgets.add(
                                  _buildGroupTaskNotification(
                                    context: context,
                                    doc: doc,
                                    task: task.first,
                                    data: data,
                                    userSettings: userSettings,
                                    isFirstTime: isFirstTime,
                                    notificationType: 'show',
                                  ),
                                );
                              }

                              if ((userSettings['isNotiRemindShow'] == true) ||
                                  (userSettings['remindMeBeforeOld'] != null)) {
                                notificationWidgets.add(
                                  _buildGroupTaskNotification(
                                    context: context,
                                    doc: doc,
                                    task: task.first,
                                    data: data,
                                    userSettings: userSettings,
                                    isFirstTime: isFirstTime,
                                    notificationType: 'remind',
                                  ),
                                );
                              }
                              if (notificationWidgets.isNotEmpty) {
                                return Column(children: notificationWidgets);
                              } else {
                                return Text('data');
                              }
                            }
                          }
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

  Widget _buildTaskNotification({
    required BuildContext context,
    required QueryDocumentSnapshot doc,
    required Task task,
    required Map data,
    required bool isFirstTime,
    required String notificationType,
    bool isGroupTask = false,
  }) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(bottom: height * 0.01),
      child: TweenAnimationBuilder(
        key: ValueKey('${doc.id}_$notificationType'),
        tween: Tween<double>(begin: isFirstTime ? 0.0 : 1.0, end: 1.0),
        duration: Duration(milliseconds: isFirstTime ? 400 : 0),
        curve: Curves.easeOutCirc,
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * -30),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.8 + (value * 0.2), child: child),
            ),
          );
        },
        child: Material(
          color: isGroupTask ? Color(0xFFE6F3FF) : Color(0xFFFFF2E6),
          borderRadius: BorderRadius.circular(8),
          child: Dismissible(
            key: ValueKey('${doc.id}_$notificationType'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: width * 0.02),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.red,
              ),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async => true,
            onDismissed: (direction) async {
              await _dismissNotification(
                doc,
                data,
                notificationType,
                isGroupTask,
              );
            },
            child: _buildNotificationContent(
              context: context,
              doc: doc,
              task: task,
              data: data,
              notificationType: notificationType,
              isGroupTask: isGroupTask,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupTaskNotification({
    required BuildContext context,
    required QueryDocumentSnapshot doc,
    required Task task,
    required Map data,
    required Map<String, dynamic> userSettings,
    required bool isFirstTime,
    required String notificationType,
  }) {
    // สร้าง merged data object
    final mergedData = Map<String, dynamic>.from(data);
    mergedData['isShow'] = userSettings['isShow'];
    mergedData['isNotiRemindShow'] = userSettings['isNotiRemindShow'];

    return _buildTaskNotification(
      context: context,
      doc: doc,
      task: task,
      data: mergedData,
      isFirstTime: isFirstTime,
      notificationType: notificationType,
      isGroupTask: true,
    );
  }

  Future<void> _dismissNotification(
    QueryDocumentSnapshot doc,
    Map data,
    String notificationType,
    bool isGroupTask,
  ) async {
    final userID = box.read('userProfile')['userid'].toString();
    final userEmail = box.read('userProfile')['email'];

    if (isGroupTask) {
      // สำหรับ group task notifications
      final taskId = data['taskID'].toString();

      if (notificationType == 'show') {
        await FirebaseFirestore.instance
            .collection('BoardTasks')
            .doc(taskId)
            .collection('Notifications')
            .doc(doc.id)
            .update({
              'userNotifications.$userID.isShow': false,
              'userNotifications.$userID.dueDateOld': FieldValue.delete(),
            });
      } else if (notificationType == 'remind') {
        await FirebaseFirestore.instance
            .collection('BoardTasks')
            .doc(taskId)
            .collection('Notifications')
            .doc(doc.id)
            .update({
              'userNotifications.$userID.isNotiRemindShow': false,
              'userNotifications.$userID.remindMeBeforeOld':
                  FieldValue.delete(),
            });
      }
    } else {
      // สำหรับ personal task notifications
      if (notificationType == 'show') {
        await FirebaseFirestore.instance
            .collection('Notifications')
            .doc(userEmail)
            .collection('Tasks')
            .doc(doc.id)
            .update({
              'isShow': FieldValue.delete(),
              'dueDateOld': FieldValue.delete(),
            });
      } else if (notificationType == 'remind') {
        await FirebaseFirestore.instance
            .collection('Notifications')
            .doc(userEmail)
            .collection('Tasks')
            .doc(doc.id)
            .update({
              'isNotiRemindShow': FieldValue.delete(),
              'remindMeBeforeOld': FieldValue.delete(),
            });
      }
    }
  }

  Widget _buildNotificationContent({
    required BuildContext context,
    required QueryDocumentSnapshot doc,
    required Task task,
    required Map data,
    required String notificationType,
    bool isGroupTask = false,
  }) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Material(
      color: Color(0xFFF2F2F6),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          Get.to(() => TasksdetailPage(taskId: task.taskId));
          _dismissNotification(doc, data, notificationType, isGroupTask);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.only(
            top: height * 0.01,
            bottom: height * 0.01,
            left: width * 0.02,
            right: width * 0.03,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: height * 0.05,
                height: height * 0.05,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isGroupTask ? Colors.blue.shade400 : Colors.black26,
                ),
                child: Align(
                  child: SvgPicture.string(
                    _getIconSvg(notificationType, isGroupTask),
                    width: width * 0.034,
                    height: height * 0.034,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: width * 0.02),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _getNotificationTitle(
                              notificationType,
                              task,
                              isGroupTask,
                            ),
                            style: TextStyle(
                              fontSize: Get.textTheme.titleSmall!.fontSize!,
                              fontWeight: FontWeight.w600,
                              color: isGroupTask
                                  ? Color(0xFF007AFF)
                                  : Color(0xFF007AFF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: width * 0.05),
                        Text(
                          timeAgo(
                            notificationType == 'show'
                                ? (data['dueDateOld'] ?? data['dueDate'])
                                      .toDate()
                                      .toIso8601String()
                                : (data['remindMeBeforeOld'] ??
                                          data['beforeDueDate'])
                                      .toDate()
                                      .toIso8601String(),
                          ),
                          style: TextStyle(
                            fontSize: Get.textTheme.labelMedium!.fontSize!,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _getNotificationSubtitle(
                        notificationType,
                        task,
                        data,
                        isGroupTask,
                      ),
                      style: TextStyle(
                        fontSize: Get.textTheme.labelMedium!.fontSize!,
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
    );
  }

  String _getIconSvg(String notificationType, [bool isGroupTask = false]) {
    if (notificationType == 'show') {
      return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M13 7h-2v5.414l3.293 3.293 1.414-1.414L13 11.586z"></path></svg>';
    } else {
      return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 4c-4.879 0-9 4.121-9 9s4.121 9 9 9 9-4.121 9-9-4.121-9-9-9zm0 16c-3.794 0-7-3.206-7-7s3.206-7 7-7 7 3.206 7 7-3.206 7-7 7z"></path><path d="M13 12V8h-2v6h6v-2zm4.284-8.293 1.412-1.416 3.01 3-1.413 1.417zm-10.586 0-2.99 2.999L2.29 5.294l2.99-3z"></path></svg>';
    }
  }

  String _getNotificationTitle(
    String notificationType,
    Task task, [
    bool isGroupTask = false,
  ]) {
    if (notificationType == 'show') {
      return task.taskName;
    } else {
      return "It's almost time for your work.";
    }
  }

  String _getNotificationSubtitle(
    String notificationType,
    Task task,
    Map data, [
    bool isGroupTask = false,
  ]) {
    if (notificationType == 'show') {
      final detail = showDetailPrivateOrGroup(task);
      if (detail.isEmpty) {
        return "Today, ${formatDateDisplay(data['dueDate'])}";
      } else {
        return "$detail, ${formatDateDisplay(data['dueDate'])}";
      }
    } else {
      return "You will be reminded before '${task.taskName}' starts.";
    }
  }

  String formatDateDisplay(dynamic date) {
    final hour = date.toDate().hour.toString().padLeft(2, '0');
    final minute = date.toDate().minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String showDetailPrivateOrGroup(Task task) {
    final rawData = box.read('userDataAll');
    if (rawData == null) return '';
    final data = AllDataUserGetResponst.fromJson(rawData);

    bool isPrivate = (data.board).any(
      (b) => b.boardId.toString() == task.boardId.toString(),
    );
    bool isGroup = (data.boardgroup).any(
      (b) => b.boardId.toString() == task.boardId.toString(),
    );
    if (isPrivate) return 'Private';
    if (isGroup) return 'Group';

    return '';
  }

  Future<void> _handleAccept(String docId, Map data) async {
    final batch = FirebaseFirestore.instance.batch();
    Get.snackbar('Joining...', '');

    // 1. ส่งการแจ้งเตือนให้คนที่เชิญ
    var boardUsersSnapshot = await FirebaseFirestore.instance
        .collection('Boards')
        .doc(data['BoardId'])
        .collection('BoardUsers')
        .get();

    for (var boardUsersDoc in boardUsersSnapshot.docs) {
      final responseDoc = FirebaseFirestore.instance
          .collection('Notifications')
          .doc(boardUsersDoc['Email'])
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
        'notiCount': false,
        'updatedAt': Timestamp.now(),
      });
    }
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
      await AppDataLoadNewRefreshToken().loadNewRefreshToken();
      await http.post(
        Uri.parse("$url/board/addboard/${data['BoardId']}"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
    }
    var response2 = await http.get(
      Uri.parse("$url/user/data"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );
    if (response2.statusCode == 403) {
      await AppDataLoadNewRefreshToken().loadNewRefreshToken();
      response = await http.get(
        Uri.parse("$url/user/data"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
    }
    if (response2.statusCode == 200) {
      final newDataJson = allDataUserGetResponstFromJson(response2.body);
      box.write('userDataAll', newDataJson.toJson());
      Get.snackbar('Successfully join the board.', '');
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
    final rawData = box.read('userDataAll');
    final tasksData = AllDataUserGetResponst.fromJson(rawData);
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
        final snapshot2 = await baseCollection
            .collection(collectionType2)
            .get();
        for (var doc in snapshot2.docs) {
          await doc.reference.delete();
        }
      }
      if (collectionType3 != null) {
        final snapshot3 = await baseCollection
            .collection(collectionType3)
            .get();
        for (var doc in snapshot3.docs) {
          await doc.reference.update({
            'isShow': FieldValue.delete(),
            'dueDateOld': FieldValue.delete(),
            'isNotiRemindShow': FieldValue.delete(),
            'remindMeBeforeOld': FieldValue.delete(),
          });
        }

        for (var boardgroup in tasksData.boardgroup) {
          final boardId = boardgroup.boardId.toString();

          var tasksSnapshot = await FirebaseFirestore.instance
              .collection('Boards')
              .doc(boardId)
              .collection('Tasks')
              .get();

          for (var tasksDoc in tasksSnapshot.docs) {
            final notiCollectionRef = FirebaseFirestore.instance
                .collection('BoardTasks')
                .doc(tasksDoc['taskID'].toString())
                .collection('Notifications');

            final notiDocsSnapshot = await notiCollectionRef.get();
            for (var notiDoc in notiDocsSnapshot.docs) {
              await notiDoc.reference.update({
                'userNotifications.${box.read('userProfile')['userid'].toString()}.isShow':
                    false,
                'userNotifications.${box.read('userProfile')['userid'].toString()}.isNotiRemindShow':
                    false,
                'userNotifications.${box.read('userProfile')['userid'].toString()}.dueDateOld':
                    FieldValue.delete(),
                'userNotifications.${box.read('userProfile')['userid'].toString()}.remindMeBeforeOld':
                    FieldValue.delete(),
              });
            }
          }
        }
      }
    } else {
      await baseCollection.collection(collectionType).doc(docId).delete();
    }
  }

  Stream<List<QueryDocumentSnapshot>> getAllCombinedNotifications() {
    final rawData = box.read('userDataAll');
    final tasksData = AllDataUserGetResponst.fromJson(rawData);
    final userEmail = box.read('userProfile')['email'];

    final inviteStream = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(userEmail)
        .collection('InviteJoin')
        .snapshots()
        .map((snapshot) => snapshot.docs);

    final responseStream = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(userEmail)
        .collection('InviteResponse')
        .snapshots()
        .map((snapshot) => snapshot.docs);

    final taskStream = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(userEmail)
        .collection('Tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs);

    final addAssignessStream = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(userEmail)
        .collection('AddAssigness')
        .snapshots()
        .map((snapshot) => snapshot.docs);

    List<Stream<List<QueryDocumentSnapshot>>> taskGroupStreams = [];

    for (var task in tasksData.tasks) {
      final taskId = task.taskId.toString();

      final taskNotificationStream = FirebaseFirestore.instance
          .collection('BoardTasks')
          .doc(taskId)
          .collection('Notifications')
          .snapshots()
          .map((snapshot) => snapshot.docs);

      taskGroupStreams.add(taskNotificationStream);
    }

    // Combine all streams
    if (taskGroupStreams.isEmpty) {
      return rxdart.Rx.combineLatest4<
        List<QueryDocumentSnapshot>,
        List<QueryDocumentSnapshot>,
        List<QueryDocumentSnapshot>,
        List<QueryDocumentSnapshot>,
        List<QueryDocumentSnapshot>
      >(inviteStream, responseStream, taskStream, addAssignessStream, (
        invites,
        responses,
        tasks,
        addAssignessStream,
      ) {
        final all = [...invites, ...responses, ...tasks, ...addAssignessStream];
        _sortNotifications(all);
        return all;
      });
    } else {
      final allTaskGroupStreams = rxdart.Rx.combineLatestList(
        taskGroupStreams,
      ).map((listOfLists) => listOfLists.expand((list) => list).toList());

      return rxdart.Rx.combineLatest5<
        List<QueryDocumentSnapshot>,
        List<QueryDocumentSnapshot>,
        List<QueryDocumentSnapshot>,
        List<QueryDocumentSnapshot>,
        List<QueryDocumentSnapshot>,
        List<QueryDocumentSnapshot>
      >(
        inviteStream,
        responseStream,
        taskStream,
        addAssignessStream,
        allTaskGroupStreams,
        (invites, responses, tasks, addAssignessStream, taskGroups) {
          final all = [
            ...invites,
            ...responses,
            ...tasks,
            ...addAssignessStream,
            ...taskGroups,
          ];
          _sortNotifications(all);
          return all;
        },
      );
    }
  }

  void _sortNotifications(List<QueryDocumentSnapshot> notifications) {
    notifications.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      final aTime = aData['updatedAt'];
      final bTime = bData['updatedAt'];

      return (bTime as Timestamp).compareTo(aTime as Timestamp);
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
}
