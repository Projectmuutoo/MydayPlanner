import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart'
    as model;
import 'package:mydayplanner/pages/pageMember/allTasks.dart';
import 'package:mydayplanner/pages/pageMember/calendar.dart';
import 'package:mydayplanner/pages/pageMember/home.dart';
import 'package:mydayplanner/pages/pageMember/notification.dart';
import 'package:mydayplanner/pages/pageMember/toDay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxdart/rxdart.dart' as rxdart;
import 'package:get/get.dart';
import 'package:mydayplanner/splash.dart';
import 'package:http/http.dart' as http;

mixin RealtimeUserStatusMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  final box = GetStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final storage = FlutterSecureStorage();
  late String url;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  void startRealtimeMonitoring() {
    final userProfile = box.read('userProfile');
    if (userProfile != null && userProfile['email'] != null) {
      _statusSubscription = FirebaseFirestore.instance
          .collection('usersLogin')
          .doc(userProfile['email'])
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && snapshot['active'] == '0') {
              Future.delayed(Duration.zero, () async {
                if (mounted) {
                  Get.snackbar(
                    '⚠️ Warning',
                    'You have been blocked!',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red.shade600,
                    colorText: Colors.white,
                    duration: Duration(seconds: 3),
                  );
                  logout();
                  Get.offAll(
                    () => SplashPage(),
                    arguments: {'fromLogout': true},
                  );
                }
              });
            }
            if (snapshot['active'] == '1') {
              box.write('userLogin', {
                'keepActiveUser': snapshot['active'] == '0' ? '0' : '1',
                'keepRoleUser': snapshot['role'],
              });
            }
          });
    }
  }

  void logout() async {
    url = await loadAPIEndpoint();

    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();

    var responseLogout = await http.post(
      Uri.parse("$url/auth/signout"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );

    if (responseLogout.statusCode == 403) {
      await loadNewRefreshToken();
      await http.post(
        Uri.parse("$url/auth/signout"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
    }
  }

  Future<void> loadNewRefreshToken() async {
    if (!mounted) return;
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
    } else if (loadtoketnew.statusCode == 403 ||
        loadtoketnew.statusCode == 401) {
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
                  fontSize: Get.textTheme.headlineSmall!.fontSize!,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              Text(
                'The system has expired. Please log in again.',
                style: TextStyle(
                  fontSize: Get.textTheme.titleSmall!.fontSize!,
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
              Get.offAll(() => SplashPage());
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
                fontSize: Get.textTheme.titleMedium!.fontSize!,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}

class NavbarPage extends StatefulWidget {
  const NavbarPage({super.key});

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage>
    with RealtimeUserStatusMixin<NavbarPage>, WidgetsBindingObserver {
  int selectedIndex = 2;
  final GlobalKey<HomePageState> homeKey = GlobalKey<HomePageState>();
  final GlobalKey<TodayPageState> todayKey = GlobalKey<TodayPageState>();
  final GlobalKey<CalendarPageState> calendarKey =
      GlobalKey<CalendarPageState>();
  final GlobalKey<AlltasksPageState> allTaskKey =
      GlobalKey<AlltasksPageState>();
  late final List<Widget> pageOptions;
  DateTime? createdAtDate;
  Timer? _timer;
  Timer? _timer2;
  int? expiresIn;
  List<model.Task> tasks = [];
  int showNoticounts = 0;
  List<QueryDocumentSnapshot> all = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    pageOptions = [
      TodayPage(),
      AlltasksPage(),
      HomePage(),
      CalendarPage(),
      NotificationPage(),
    ];
    checkExpiresRefreshToken();
    checkInSystem();
    startRealtimeMonitoring();
  }

  void showNotificationsCount() async {
    final rawData = box.read('userDataAll');
    final tasksData = model.AllDataUserGetResponst.fromJson(rawData);
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

    if (taskGroupStreams.isEmpty) {
      all = await rxdart.Rx.combineLatest3(
        inviteStream,
        responseStream,
        taskStream,
        (invites, responses, tasks) => [...invites, ...responses, ...tasks],
      ).first;
    } else {
      final allTaskGroupStreams = rxdart.Rx.combineLatestList(
        taskGroupStreams,
      ).map((listOfLists) => listOfLists.expand((list) => list).toList());

      all = await rxdart.Rx.combineLatest4(
        inviteStream,
        responseStream,
        taskStream,
        allTaskGroupStreams,
        (invites, responses, tasks, taskGroups) => [
          ...invites,
          ...responses,
          ...tasks,
          ...taskGroups,
        ],
      ).first;
    }

    _updateNotificationField(all, null);
  }

  Future<void> _updateNotificationField(
    List<QueryDocumentSnapshot> docs,
    int? index,
  ) async {
    int count = 0;

    for (final doc in docs) {
      final docRef = doc.reference;
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        if (index != null && index == 4) {
          await docRef.update({'notiCount': true});
        }
        if (data['notiCount'] != null && !data['notiCount']) {
          count++;
        }
      }
    }

    if (mounted) {
      setState(() {
        showNoticounts = count;
      });
    }
  }

  Future<List> showTimeRemineMeBefore(model.Task task) async {
    final rawData = box.read('userDataAll');
    final userProfile = box.read('userProfile');
    final userEmail = userProfile['email'];
    if (rawData == null || userEmail == null) return [];
    final data = model.AllDataUserGetResponst.fromJson(rawData);
    final List<String> remindTimes = [];
    bool tokenFMC = true;

    var result = await FirebaseFirestore.instance
        .collection('usersLogin')
        .doc(userEmail)
        .get();
    final dataResult = result.data();
    if (dataResult != null) {
      tokenFMC = dataResult['FMCToken'].toString() != 'off';
    }

    for (var notiTask in task.notifications) {
      DateTime? remindTimestamp;

      bool isGroup = (data.boardgroup).any(
        (b) => b.boardId.toString() == task.boardId.toString(),
      );
      if (isGroup) {
        // DocumentSnapshot
        final docSnapshot = await FirebaseFirestore.instance
            .collection('BoardTasks')
            .doc(task.taskId.toString())
            .collection('Notifications')
            .doc(notiTask.notificationId.toString())
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null) {
            if (data['remindMeBefore'] != null) {
              remindTimestamp = (data['remindMeBefore'] as Timestamp).toDate();
            }
            if (data['remindMeBefore'] != null &&
                (data['remindMeBefore'] as Timestamp).toDate().isBefore(
                  DateTime.now(),
                ) &&
                !data['isNotiRemind']) {
              // แสดง snackbar เฉพาะเมื่อไม่ได้อยู่ในหน้า notification
              if (!tokenFMC && selectedIndex != 4) {
                Get.snackbar(
                  "It's almost time for your work.",
                  "You will be reminded before '${task.taskName}' starts.",
                  duration: Duration(seconds: 3),
                );
              }

              // อัปเดต notification status
              var boardUsersSnapshot = await FirebaseFirestore.instance
                  .collection('Boards')
                  .doc(task.boardId.toString())
                  .collection('BoardUsers')
                  .get();

              for (var boardUsersDoc in boardUsersSnapshot.docs) {
                FirebaseFirestore.instance
                    .collection('BoardTasks')
                    .doc(task.taskId.toString())
                    .collection('Notifications')
                    .doc(notiTask.notificationId.toString())
                    .update({
                      'notiCount': false,
                      'isNotiRemind': true,
                      'isNotiRemindShow': true,
                      'dueDateOld': FieldValue.delete(),
                      'remindMeBeforeOld': FieldValue.delete(),
                      'updatedAt': Timestamp.now(),
                      'userNotifications.${boardUsersDoc['UserID'].toString()}.isShow':
                          false,
                      'userNotifications.${boardUsersDoc['UserID'].toString()}.isNotiRemindShow':
                          true,
                    });
              }
            }

            if (data['dueDate'] != null &&
                (data['dueDate'] as Timestamp).toDate().isBefore(
                  DateTime.now(),
                ) &&
                !data['isSend']) {
              if (!tokenFMC && selectedIndex != 4) {
                Get.snackbar(
                  task.taskName,
                  showDetailPrivateOrGroup(task).isEmpty
                      ? "Today, ${formatDateDisplay((data['dueDate'] as Timestamp).toDate())}"
                      : "${showDetailPrivateOrGroup(task)}, ${formatDateDisplay((data['dueDate'] as Timestamp).toDate())}",
                  titleText: task.priority.isEmpty
                      ? Text(
                          task.taskName,
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize!,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF007AFF),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: task.priority == '3'
                                    ? Colors.red
                                    : task.priority == '2'
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              task.taskName,
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize!,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                          ],
                        ),
                  duration: Duration(seconds: 3),
                );
              }

              handleRecurringNotification(
                notificationID: notiTask.notificationId.toString(),
                dueDate: (data['dueDate'] as Timestamp).toDate(),
                remindMeBefore: data['remindMeBefore'] != null
                    ? (data['remindMeBefore'] as Timestamp).toDate()
                    : null,
                recurringPattern: data['recurringPattern'].toString(),
                userEmail: box.read('userProfile')['email'],
                taskID: data['taskID'],
                boardID: task.boardId.toString(),
                isGroup: true,
              );
            }
          }
        }
      } else {
        // QuerySnapshot
        final querySnapshot = await FirebaseFirestore.instance
            .collection('Notifications')
            .doc(box.read('userProfile')['email'])
            .collection('Tasks')
            .where('taskID', isEqualTo: task.taskId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          if (data['remindMeBefore'] != null) {
            remindTimestamp = (data['remindMeBefore'] as Timestamp).toDate();
          }
          if (data['remindMeBefore'] != null &&
              (data['remindMeBefore'] as Timestamp).toDate().isBefore(
                DateTime.now(),
              ) &&
              !data['isNotiRemind']) {
            if (!tokenFMC && selectedIndex != 4) {
              Get.snackbar(
                "It's almost time for your work.",
                "You will be reminded before '${task.taskName}' starts.",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.blue.shade600,
                colorText: Colors.white,
                duration: Duration(seconds: 3),
                isDismissible: true,
              );
            }
            await FirebaseFirestore.instance
                .collection('Notifications')
                .doc(box.read('userProfile')['email'])
                .collection('Tasks')
                .doc(notiTask.notificationId.toString())
                .update({
                  'notiCount': false,
                  'isNotiRemind': true,
                  'isNotiRemindShow': true,
                  'dueDateOld': FieldValue.delete(),
                  'remindMeBeforeOld': FieldValue.delete(),
                  'updatedAt': Timestamp.now(),
                });
          }

          if (data['dueDate'] != null &&
              (data['dueDate'] as Timestamp).toDate().isBefore(
                DateTime.now(),
              ) &&
              !data['isSend']) {
            if (!tokenFMC && selectedIndex != 4) {
              Get.snackbar(
                task.taskName,
                showDetailPrivateOrGroup(task).isEmpty
                    ? "Today, ${formatDateDisplay((data['dueDate'] as Timestamp).toDate())}"
                    : "${showDetailPrivateOrGroup(task)}, ${formatDateDisplay((data['dueDate'] as Timestamp).toDate())}",
                titleText: task.priority.isEmpty
                    ? Text(
                        task.taskName,
                        style: TextStyle(
                          fontSize: Get.textTheme.titleMedium!.fontSize!,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF007AFF),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: task.priority == '3'
                                  ? Colors.red
                                  : task.priority == '2'
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            task.taskName,
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize!,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                        ],
                      ),
                duration: Duration(seconds: 3),
              );
            }

            handleRecurringNotification(
              notificationID: notiTask.notificationId.toString(),
              dueDate: (data['dueDate'] as Timestamp).toDate(),
              remindMeBefore: data['remindMeBefore'] != null
                  ? (data['remindMeBefore'] as Timestamp).toDate()
                  : null,
              recurringPattern: data['recurringPattern'].toString(),
              userEmail: box.read('userProfile')['email'],
              taskID: data['taskID'],
            );
          }
        }
      }

      if (remindTimestamp != null && remindTimestamp.isAfter(DateTime.now())) {
        final timeString =
            "${remindTimestamp.hour.toString().padLeft(2, '0')}:${remindTimestamp.minute.toString().padLeft(2, '0')}";
        remindTimes.add(timeString);
      }
    }

    return remindTimes;
  }

  Future<void> handleRecurringNotification({
    required String notificationID,
    required DateTime dueDate,
    required DateTime? remindMeBefore,
    required String recurringPattern,
    required String userEmail,
    required int taskID,
    String? boardID,
    bool isGroup = false,
  }) async {
    final firestore = FirebaseFirestore.instance;
    DocumentReference docRef;

    if (isGroup && boardID != null) {
      docRef = firestore
          .collection('BoardTasks')
          .doc(taskID.toString())
          .collection('Notifications')
          .doc(notificationID);
    } else {
      docRef = firestore
          .collection('Notifications')
          .doc(userEmail)
          .collection('Tasks')
          .doc(notificationID);
    }

    DateTime? nextDueDate;
    DateTime? nextRemindMeBefore;

    if (recurringPattern == 'onetime') {
      Map<String, dynamic> updateData = {
        'isSend': true,
        'isShow': true,
        'dueDateOld': FieldValue.delete(),
        'remindMeBeforeOld': FieldValue.delete(),
        'updatedAt': Timestamp.now(),
        'notiCount': false,
      };

      if (isGroup && boardID != null) {
        var boardUsersSnapshot = await firestore
            .collection('Boards')
            .doc(boardID)
            .collection('BoardUsers')
            .get();

        for (var boardUsersDoc in boardUsersSnapshot.docs) {
          updateData['userNotifications.${boardUsersDoc['UserID'].toString()}.isShow'] =
              true;
        }
      }

      await docRef.update(updateData);
      nextDueDate = dueDate;
    } else {
      nextDueDate = _calculateNextDueDate(dueDate, recurringPattern);
      nextRemindMeBefore = remindMeBefore != null
          ? _calculateNextRemindMeBefore(remindMeBefore, recurringPattern)
          : null;

      if (nextDueDate != null) {
        Map<String, dynamic> updateData = {
          'dueDate': Timestamp.fromDate(nextDueDate),
          'updatedAt': Timestamp.now(),
          'dueDateOld': dueDate,
          'remindMeBeforeOld': remindMeBefore,
          'isSend': false,
          'isShow': false,
          'isNotiRemind': false,
          'notiCount': false,
        };

        if (nextRemindMeBefore != null) {
          updateData['remindMeBefore'] = Timestamp.fromDate(nextRemindMeBefore);
        }

        if (isGroup && boardID != null) {
          var boardUsersSnapshot = await firestore
              .collection('Boards')
              .doc(boardID)
              .collection('BoardUsers')
              .get();

          for (var boardUsersDoc in boardUsersSnapshot.docs) {
            updateData['userNotifications.${boardUsersDoc['UserID'].toString()}.isShow'] =
                false;
            updateData['userNotifications.${boardUsersDoc['UserID'].toString()}.isNotiRemindShow'] =
                false;
            updateData['userNotifications.${boardUsersDoc['UserID'].toString()}.dueDateOld'] =
                dueDate;
            updateData['userNotifications.${boardUsersDoc['UserID'].toString()}.remindMeBeforeOld'] =
                remindMeBefore;
          }
        }

        await docRef.update(updateData);
      }
    }

    final url = await loadAPIEndpoint();
    http.Response response = await http.put(
      Uri.parse("$url/notification/update/$taskID"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: jsonEncode({
        'due_date': nextDueDate?.toUtc().toIso8601String(),
        'recurring_pattern': recurringPattern,
        'is_send': dueDate.isAfter(DateTime.now()) ? false : true,
      }),
    );

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      response = await http.put(
        Uri.parse("$url/notification/update/$taskID"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: jsonEncode({
          'due_date': nextDueDate?.toUtc().toIso8601String(),
          'recurring_pattern': recurringPattern,
          'is_send': dueDate.isAfter(DateTime.now()) ? false : true,
        }),
      );
    }

    if (isGroup) {
      fetchDataOnResume();
    }
  }

  DateTime? _calculateNextDueDate(DateTime currentDueDate, String pattern) {
    switch (pattern) {
      case 'daily':
        return currentDueDate.add(Duration(days: 1));
      case 'weekly':
        return currentDueDate.add(Duration(days: 7));
      case 'monthly':
        return DateTime(
          currentDueDate.year,
          currentDueDate.month + 1,
          currentDueDate.day,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
        );
      case 'yearly':
        return DateTime(
          currentDueDate.year + 1,
          currentDueDate.month,
          currentDueDate.day,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
        );
      default:
        return null;
    }
  }

  // ฟังก์ชันคำนวณ remindMeBefore ครั้งถัดไป
  DateTime? _calculateNextRemindMeBefore(
    DateTime currentRemindMeBefore,
    String pattern,
  ) {
    switch (pattern) {
      case 'daily':
        return currentRemindMeBefore.add(Duration(days: 1));
      case 'weekly':
        return currentRemindMeBefore.add(Duration(days: 7));
      case 'monthly':
        return DateTime(
          currentRemindMeBefore.year,
          currentRemindMeBefore.month + 1,
          currentRemindMeBefore.day,
          currentRemindMeBefore.hour,
          currentRemindMeBefore.minute,
          currentRemindMeBefore.second,
        );
      case 'yearly':
        return DateTime(
          currentRemindMeBefore.year + 1,
          currentRemindMeBefore.month,
          currentRemindMeBefore.day,
          currentRemindMeBefore.hour,
          currentRemindMeBefore.minute,
          currentRemindMeBefore.second,
        );
      default:
        return null;
    }
  }

  String formatDateDisplay(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String showDetailPrivateOrGroup(model.Task task) {
    final rawData = box.read('userDataAll');
    final data = model.AllDataUserGetResponst.fromJson(rawData);

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

  void checkExpiresRefreshToken() async {
    final userProfile = box.read('userProfile');
    if (userProfile == null) return;

    final userId = userProfile['userid'];
    await FirebaseFirestore.instance
        .collection('refreshTokens')
        .doc(userId.toString())
        .get()
        .then((snapshot) {
          if (snapshot.exists) {
            var createdAt = snapshot['CreatedAt'];
            expiresIn = snapshot['ExpiresIn'];
            createdAtDate = DateTime.fromMillisecondsSinceEpoch(
              createdAt * 1000,
            );
          }
        });

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (createdAtDate == null) return;

      DateTime expiryDate = createdAtDate!.add(Duration(seconds: expiresIn!));
      DateTime now = DateTime.now();

      if (now.isAfter(expiryDate)) {
        //1. หยุด Timer
        _timer?.cancel();

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
                  'Warning!!',
                  style: TextStyle(
                    fontSize: Get.textTheme.headlineSmall!.fontSize,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF007AFF),
                  ),
                ),
                Text(
                  'The system has expired. Please log in again.',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleMedium!.fontSize,
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
                await box.remove('userProfile');
                await box.remove('userLogin');
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
                  fontSize: Get.textTheme.titleLarge!.fontSize,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      }
    });
  }

  Future<String> getDeviceName() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      final model = androidInfo.model;
      final id = androidInfo.id;
      return '${model}_$id';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      final model = iosInfo.modelName;
      final id = iosInfo.identifierForVendor!;
      return '${model}_$id';
    } else {
      return 'Unknown_${Random().nextInt(100000000)}';
    }
  }

  void checkInSystem() async {
    final userProfile = box.read('userProfile');
    final userLogin = box.read('userLogin');
    if (userProfile == null || userLogin == null) return;
    String deviceName = await getDeviceName();

    _timer2 = Timer.periodic(Duration(seconds: 1), (_) async {
      final userDataAll = box.read('userDataAll');
      if (userDataAll == null) return;
      final rawData = model.AllDataUserGetResponst.fromJson(userDataAll);

      // for (var tasks in rawData.tasks) {
      //   showTimeRemineMeBefore(tasks);
      // }
      showNotificationsCount();

      final snapshot = await FirebaseFirestore.instance
          .collection('usersLogin')
          .doc(userProfile['email'])
          .get();
      final data = snapshot.data();
      if (data != null) {
        final serverdeviceName = data['deviceName'].toString();
        if ((serverdeviceName != deviceName)) {
          _timer2?.cancel();

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
                    'Warning!!',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleLarge!.fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'Detected login from another device.',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleMedium!.fontSize,
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
                  await box.remove('userProfile');
                  await box.remove('userLogin');
                  await googleSignIn.signOut();
                  await FirebaseAuth.instance.signOut();
                  await storage.deleteAll();
                  Get.offAll(
                    () => SplashPage(),
                    arguments: {'fromLogout': true},
                  );
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
                    fontSize: Get.textTheme.titleMedium!.fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer2?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await fetchDataOnResume();
    }
  }

  Future<void> fetchDataOnResume() async {
    url = await loadAPIEndpoint();
    http.Response response = await http.get(
      Uri.parse("$url/user/data"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      response = await http.get(
        Uri.parse("$url/user/data"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
    }
    if (response.statusCode == 200) {
      final newDataJson = model.allDataUserGetResponstFromJson(response.body);
      box.write('userDataAll', newDataJson.toJson());
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m7 17.013 4.413-.015 9.632-9.54c.378-.378.586-.88.586-1.414s-.208-1.036-.586-1.414l-1.586-1.586c-.756-.756-2.075-.752-2.825-.003L7 12.583v4.43zM18.045 4.458l1.589 1.583-1.597 1.582-1.586-1.585 1.594-1.58zM9 13.417l6.03-5.973 1.586 1.586-6.029 5.971L9 15.006v-1.589z"></path><path d="M5 21h14c1.103 0 2-.897 2-2v-8.668l-2 2V19H8.158c-.026 0-.053.01-.079.01-.033 0-.066-.009-.1-.01H5V5h6.847l2-2H5c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2z"></path></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF979595),
            ),
            activeIcon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m18.988 2.012 3 3L19.701 7.3l-3-3zM8 16h3l7.287-7.287-3-3L8 13z"></path><path d="M19 19H8.158c-.026 0-.053.01-.079.01-.033 0-.066-.009-.1-.01H5V5h6.847l2-2H5c-1.103 0-2 .896-2 2v14c0 1.104.897 2 2 2h14a2 2 0 0 0 2-2v-8.668l-2 2V19z"></path></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF007AFF),
            ),
            label: 'To day',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="m438-240 226-226-58-58-169 169-84-84-57 57 142 142ZM240-80q-33 0-56.5-23.5T160-160v-640q0-33 23.5-56.5T240-880h320l240 240v480q0 33-23.5 56.5T720-80H240Zm280-520v-200H240v640h480v-440H520ZM240-800v200-200 640-640Z"/></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF979595),
            ),
            activeIcon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="m438-240 226-226-58-58-169 169-84-84-57 57 142 142ZM240-80q-33 0-56.5-23.5T160-160v-640q0-33 23.5-56.5T240-880h320l240 240v480q0 33-23.5 56.5T720-80H240Zm280-520h200L520-800v200Z"/></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF007AFF),
            ),
            label: 'All Tasks',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <path d="M3.99999 10L12 3L20 10L20 20H15V16C15 15.2044 14.6839 14.4413 14.1213 13.8787C13.5587 13.3161 12.7956 13 12 13C11.2043 13 10.4413 13.3161 9.87868 13.8787C9.31607 14.4413 9 15.2043 9 16V20H4L3.99999 10Z" stroke="#000000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path> </g></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF979595),
            ),
            activeIcon: SvgPicture.string(
              '<svg viewBox="-1.6 -1.6 19.20 19.20" fill="none" xmlns="http://www.w3.org/2000/svg"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <path d="M1 6V15H6V11C6 9.89543 6.89543 9 8 9C9.10457 9 10 9.89543 10 11V15H15V6L8 0L1 6Z" fill="#000000"></path> </g></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF007AFF),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M7 11h2v2H7zm0 4h2v2H7zm4-4h2v2h-2zm0 4h2v2h-2zm4-4h2v2h-2zm0 4h2v2h-2z"></path><path d="M5 22h14c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2h-2V2h-2v2H9V2H7v2H5c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2zM19 8l.001 12H5V8h14z"></path></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF979595),
            ),
            activeIcon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M21 20V6c0-1.103-.897-2-2-2h-2V2h-2v2H9V2H7v2H5c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h14c1.103 0 2-.897 2-2zM9 18H7v-2h2v2zm0-4H7v-2h2v2zm4 4h-2v-2h2v2zm0-4h-2v-2h2v2zm4 4h-2v-2h2v2zm0-4h-2v-2h2v2zm2-5H5V7h14v2z"></path></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF007AFF),
            ),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              alignment: Alignment.topRight,
              children: [
                SvgPicture.string(
                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><circle cx="18" cy="6" r="3"></circle><path d="M18 19H5V6h8c0-.712.153-1.387.422-2H5c-1.103 0-2 .897-2 2v13c0 1.103.897 2 2 2h13c1.103 0 2-.897 2-2v-8.422A4.962 4.962 0 0 1 18 11v8z"></path></svg>',
                  width: width * 0.07,
                  height: width * 0.07,
                  fit: BoxFit.cover,
                  color: Color(0xFF979595),
                ),
                if (showNoticounts != 0)
                  Positioned(
                    top: -3,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        showNoticounts > 99 ? '99+' : showNoticounts.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><circle cx="18" cy="6" r="3"></circle><path d="M13 6c0-.712.153-1.387.422-2H6c-1.103 0-2 .897-2 2v12c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2v-7.422A4.962 4.962 0 0 1 18 11a5 5 0 0 1-5-5z"></path></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF007AFF),
            ),
            label: 'Notification',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: (index) {
          if (index == 4) {
            _updateNotificationField(all, index);
          }
          setState(() {
            selectedIndex = index;
          });
        },
        selectedLabelStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.03,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.03,
        ),
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF007AFF),
        unselectedItemColor: Color(0xFF979595),
        type: BottomNavigationBarType.fixed,
      ),
      body: pageOptions[selectedIndex],
    );
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize(BuildContext context) {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/logo');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          if (payload == 'test') {
            Get.to(() => TodayPage());
          } else {
            Get.to(() => TodayPage());
          }
        }
      },
    );
  }

  static void showNotification({
    required String title,
    required String body,
    String payload = 'default_payload',
  }) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'default_channel',
          'Default',
          channelDescription: 'Default channel for app notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          icon: '@drawable/logo',
          color: Color(0xFF3B82F6),
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
