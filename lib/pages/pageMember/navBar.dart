import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
import 'package:mydayplanner/pages/pageMember/allTasks.dart';
import 'package:mydayplanner/pages/pageMember/calendar.dart';
import 'package:mydayplanner/pages/pageMember/home.dart';
import 'package:mydayplanner/pages/pageMember/notification.dart';
import 'package:mydayplanner/pages/pageMember/toDay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  Timer? timer;
  Timer? timer2;
  Timer? _timer;
  Timer? _timer2;
  Timer? timerGroup;
  Timer? timerGroup2;
  int? expiresIn;

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
    startNotificationPrivate();
    timerGroup = Timer.periodic(Duration(seconds: 1), (timer) async {
      startNotificationListener();
    });
  }

  void startNotificationPrivate() {
    FirebaseFirestore.instance
        .collection('Notifications')
        .doc(box.read('userProfile')['email'])
        .collection('Tasks')
        .snapshots()
        .listen((snapshot) {
          timer?.cancel();
          timer = Timer.periodic(Duration(seconds: 1), (timer) {
            final now = DateTime.now();
            for (var doc in snapshot.docs) {
              final rawData = box.read('userDataAll');
              final tasksData = AllDataUserGetResponst.fromJson(rawData);
              final task = tasksData.tasks
                  .where((t) => t.taskId == doc['taskID'])
                  .toList();

              final dueDate = (doc['dueDate'] as Timestamp).toDate();
              final remindMeBefore = doc.data().containsKey('remindMeBefore')
                  ? (doc['remindMeBefore'] as Timestamp).toDate()
                  : null;
              final isSend = doc['isSend'];
              final isNotiRemind = doc.data().containsKey('isNotiRemind')
                  ? doc['isNotiRemind']
                  : false;
              final notificationID = doc['notificationID'].toString();
              final recurringPattern =
                  doc.data().containsKey('recurringPattern')
                  ? doc['recurringPattern'].toString().toLowerCase()
                  : 'onetime';

              if (remindMeBefore != null &&
                  remindMeBefore.isBefore(now) &&
                  !isNotiRemind) {
                if (selectedIndex != 4) {
                  Get.snackbar(
                    "It's almost time for your work.",
                    "You will be reminded before '${task.first.taskName}' starts.",
                    duration: Duration(seconds: 3),
                  );
                }
                FirebaseFirestore.instance
                    .collection('Notifications')
                    .doc(box.read('userProfile')['email'])
                    .collection('Tasks')
                    .doc(notificationID)
                    .update({
                      'isNotiRemind': true,
                      'isNotiRemindShow': true,
                      'dueDateOld': FieldValue.delete(),
                      'remindMeBeforeOld': FieldValue.delete(),
                      'updatedAt': Timestamp.now(),
                    });
              }
              if (dueDate.isBefore(now) && !isSend) {
                if (selectedIndex != 4) {
                  Get.snackbar(
                    task.first.taskName,
                    showDetailPrivateOrGroup(task.first).isEmpty
                        ? "Today, ${formatDateDisplay(doc['dueDate'])}"
                        : "${showDetailPrivateOrGroup(task.first)}, ${formatDateDisplay(doc['dueDate'])}",
                    titleText: task.first.priority.isEmpty
                        ? Text(
                            task.first.taskName,
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
                                  color: task.first.priority == '3'
                                      ? Colors.red
                                      : task.first.priority == '2'
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                task.first.taskName,
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.titleMedium!.fontSize!,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                            ],
                          ),
                    duration: Duration(seconds: 3),
                  );
                }
                _handleRecurringNotification(
                  notificationID: notificationID,
                  dueDate: dueDate,
                  remindMeBefore: remindMeBefore,
                  recurringPattern: recurringPattern,
                  userEmail: box.read('userProfile')['email'],
                  taskID: doc['taskID'],
                );
              }
            }
          });
        });
  }

  void startNotificationListener() async {
    final rawData = box.read('userDataAll');
    if (rawData == null) return;
    final tasksData = AllDataUserGetResponst.fromJson(rawData);
    final userEmail = box.read('userProfile')['email'];

    List<String> taskDetails = [];
    for (var boardgroup in tasksData.boardgroup) {
      final boardId = boardgroup.boardId.toString();

      for (var boardgroup in tasksData.boardgroup) {
        final boardId = boardgroup.boardId.toString();

        final result = await FirebaseFirestore.instance
            .collection('Boards')
            .doc(boardId)
            .collection('Tasks')
            .get();

        for (var docTasks in result.docs) {
          taskDetails.add(docTasks['taskID'].toString());
        }
      }

      for (var tasks in taskDetails) {
        final taskId = tasks.toString();

        FirebaseFirestore.instance
            .collection('BoardTasks')
            .doc(taskId)
            .collection('Notifications')
            .snapshots()
            .listen((notificationSnapshot) async {
              final now = DateTime.now();
              for (var doc in notificationSnapshot.docs) {
                final rawData = box.read('userDataAll');
                final tasksData = AllDataUserGetResponst.fromJson(rawData);

                final taskList = tasksData.tasks
                    .where((t) => t.taskId == doc['taskID'])
                    .toList();

                // ตรวจสอบว่าพบ task หรือไม่
                if (taskList.isEmpty) {
                  continue;
                }

                final task = taskList.first;
                final dueDate = (doc['dueDate'] as Timestamp).toDate();
                final remindMeBefore = doc.data().containsKey('remindMeBefore')
                    ? (doc['remindMeBefore'] as Timestamp).toDate()
                    : null;
                final isSend = doc['isSend'];
                final isNotiRemind = doc.data().containsKey('isNotiRemind')
                    ? doc['isNotiRemind']
                    : false;
                final notificationID = doc['notificationID'].toString();
                final recurringPattern =
                    doc.data().containsKey('recurringPattern')
                    ? doc['recurringPattern'].toString().toLowerCase()
                    : 'onetime';

                // เตือนก่อนถึงเวลา
                if (remindMeBefore != null &&
                    remindMeBefore.isBefore(now) &&
                    !isNotiRemind) {
                  // แสดง snackbar เฉพาะเมื่อไม่ได้อยู่ในหน้า notification
                  if (selectedIndex != 4) {
                    Get.snackbar(
                      "It's almost time for your work.",
                      "You will be reminded before '${task.taskName}' starts.",
                      duration: Duration(seconds: 3),
                    );
                  }

                  // อัปเดต notification status
                  var boardUsersSnapshot = await FirebaseFirestore.instance
                      .collection('Boards')
                      .doc(boardId)
                      .collection('BoardUsers')
                      .get();

                  for (var boardUsersDoc in boardUsersSnapshot.docs) {
                    FirebaseFirestore.instance
                        .collection('BoardTasks')
                        .doc(taskId)
                        .collection('Notifications')
                        .doc(notificationID)
                        .update({
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

                // ถึงเวลาแล้ว
                if (dueDate.isBefore(now) && !isSend) {
                  if (selectedIndex != 4) {
                    Get.snackbar(
                      task.taskName,
                      showDetailPrivateOrGroup(task).isEmpty
                          ? "Today, ${formatDateDisplay(doc['dueDate'])}"
                          : "${showDetailPrivateOrGroup(task)}, ${formatDateDisplay(doc['dueDate'])}",
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
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize!,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF007AFF),
                                  ),
                                ),
                              ],
                            ),
                      duration: Duration(seconds: 3),
                    );
                  }

                  _handleRecurringNotification2(
                    notificationID: notificationID,
                    dueDate: dueDate,
                    remindMeBefore: remindMeBefore,
                    recurringPattern: recurringPattern,
                    userEmail: userEmail,
                    taskID: int.parse(taskId),
                    boardID: boardId,
                  );
                }
              }
            });
      }
    }
  }

  void _handleRecurringNotification({
    required String notificationID,
    required DateTime dueDate,
    required DateTime? remindMeBefore,
    required String recurringPattern,
    required String userEmail,
    required int taskID,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(userEmail)
        .collection('Tasks')
        .doc(notificationID);

    DateTime? nextDueDate;
    DateTime? nextRemindMeBefore;

    if (recurringPattern == 'onetime') {
      // กรณี onetime - อัพเดทสถานะแล้วจบ
      await docRef.update({
        'isSend': true,
        'isShow': true,
        'dueDateOld': FieldValue.delete(),
        'remindMeBeforeOld': FieldValue.delete(),
        'updatedAt': Timestamp.now(),
      });
      nextDueDate = dueDate;
    } else {
      // กรณี recurring - คำนวณ dueDate ครั้งถัดไป
      nextDueDate = _calculateNextDueDate(dueDate, recurringPattern);
      nextRemindMeBefore = remindMeBefore != null
          ? _calculateNextRemindMeBefore(remindMeBefore, recurringPattern)
          : null;

      if (nextDueDate != null) {
        // อัพเดท notification สำหรับรอบถัดไป
        Map<String, dynamic> updateData = {
          'dueDate': Timestamp.fromDate(nextDueDate),
          'updatedAt': Timestamp.now(),
          'dueDateOld': dueDate,
          'remindMeBeforeOld': remindMeBefore,
          'isSend': false,
          'isShow': false,
          'isNotiRemind': false,
        };

        if (nextRemindMeBefore != null) {
          updateData['remindMeBefore'] = Timestamp.fromDate(nextRemindMeBefore);
        }

        await docRef.update(updateData);
      }
    }

    url = await loadAPIEndpoint();
    http.Response response;
    response = await http.put(
      Uri.parse("$url/notification/update/$taskID"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: jsonEncode({
        'due_date': nextDueDate?.toUtc().toIso8601String(),
        'recurring_pattern': recurringPattern,
        'is_send': recurringPattern == 'onetime' ? true : false,
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
          'is_send': recurringPattern == 'onetime' ? true : false,
        }),
      );
    }

    fetchDataOnResume();
  }

  void _handleRecurringNotification2({
    required String notificationID,
    required DateTime dueDate,
    required DateTime? remindMeBefore,
    required String recurringPattern,
    required String userEmail,
    required int taskID,
    required String boardID,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('BoardTasks')
        .doc(taskID.toString())
        .collection('Notifications')
        .doc(notificationID);

    DateTime? nextDueDate;
    DateTime? nextRemindMeBefore;

    if (recurringPattern == 'onetime') {
      // กรณี onetime - อัพเดทสถานะแล้วจบ
      var boardUsersSnapshot = await FirebaseFirestore.instance
          .collection('Boards')
          .doc(boardID)
          .collection('BoardUsers')
          .get();

      for (var boardUsersDoc in boardUsersSnapshot.docs) {
        await docRef.update({
          'isSend': true,
          'isShow': true,
          'dueDateOld': FieldValue.delete(),
          'updatedAt': Timestamp.now(),
          'remindMeBeforeOld': FieldValue.delete(),
          'userNotifications.${boardUsersDoc['UserID'].toString()}.isShow':
              true,
        });
      }
      nextDueDate = dueDate;
    } else {
      // กรณี recurring - คำนวณ dueDate ครั้งถัดไป
      nextDueDate = _calculateNextDueDate(dueDate, recurringPattern);
      nextRemindMeBefore = remindMeBefore != null
          ? _calculateNextRemindMeBefore(remindMeBefore, recurringPattern)
          : null;

      if (nextDueDate != null) {
        // อัพเดท notification สำหรับรอบถัดไป
        var boardUsersSnapshot = await FirebaseFirestore.instance
            .collection('Boards')
            .doc(boardID)
            .collection('BoardUsers')
            .get();

        for (var boardUsersDoc in boardUsersSnapshot.docs) {
          Map<String, dynamic> updateData = {
            'dueDate': Timestamp.fromDate(nextDueDate),
            'updatedAt': Timestamp.now(),
            'dueDateOld': dueDate,
            'remindMeBeforeOld': remindMeBefore,
            'isSend': false,
            'isShow': false,
            'isNotiRemind': false,
            'userNotifications.${boardUsersDoc['UserID'].toString()}.isShow':
                false,
            'userNotifications.${boardUsersDoc['UserID'].toString()}.isNotiRemindShow':
                false,
            'userNotifications.${boardUsersDoc['UserID'].toString()}.dueDateOld':
                dueDate,
            'userNotifications.${boardUsersDoc['UserID'].toString()}.remindMeBeforeOld':
                remindMeBefore,
          };

          if (nextRemindMeBefore != null) {
            updateData['remindMeBefore'] = Timestamp.fromDate(
              nextRemindMeBefore,
            );
          }

          await docRef.update(updateData);
        }
      }
    }

    url = await loadAPIEndpoint();
    http.Response response;
    response = await http.put(
      Uri.parse("$url/notification/update/$taskID"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: jsonEncode({
        'due_date': nextDueDate?.toUtc().toIso8601String(),
        'recurring_pattern': recurringPattern,
        'is_send': recurringPattern == 'onetime' ? true : false,
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
          'is_send': recurringPattern == 'onetime' ? true : false,
        }),
      );
    }

    fetchDataOnResume();
  }

  // ฟังก์ชันคำนวณ dueDate ครั้งถัดไป
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

  String formatDateDisplay(dynamic date) {
    final hour = date.toDate().hour.toString().padLeft(2, '0');
    final minute = date.toDate().minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String showDetailPrivateOrGroup(Task task) {
    final rawData = box.read('userDataAll');
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

  checkExpiresRefreshToken() async {
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

  checkInSystem() async {
    final userProfile = box.read('userProfile');
    final userLogin = box.read('userLogin');
    if (userProfile == null || userLogin == null) return;
    final localdeviceName = userLogin['deviceName'];

    _timer2 = Timer.periodic(Duration(seconds: 5), (_) async {
      final snapshot = await FirebaseFirestore.instance
          .collection('usersLogin')
          .doc(userProfile['email'])
          .get();
      if (snapshot.data() != null) {
        final serverdeviceName = snapshot['deviceName'].toString();

        if (localdeviceName != null) {
          if ((serverdeviceName != localdeviceName)) {
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
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    timer2?.cancel();
    _timer?.cancel();
    _timer2?.cancel();
    timerGroup?.cancel();
    timerGroup2?.cancel();
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
    var oldUserDataAllJson = box.read('userDataAll');
    if (oldUserDataAllJson == null) return;

    http.Response response;
    response = await http.get(
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
      final newDataJson = allDataUserGetResponstFromJson(response.body);

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
            icon: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><circle cx="18" cy="6" r="3"></circle><path d="M18 19H5V6h8c0-.712.153-1.387.422-2H5c-1.103 0-2 .897-2 2v13c0 1.103.897 2 2 2h13c1.103 0 2-.897 2-2v-8.422A4.962 4.962 0 0 1 18 11v8z"></path></svg>',
              width: width * 0.07,
              height: width * 0.07,
              fit: BoxFit.cover,
              color: Color(0xFF979595),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F7FF), Color(0xFFF2F2F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: pageOptions[selectedIndex],
      ),
    );
  }
}
