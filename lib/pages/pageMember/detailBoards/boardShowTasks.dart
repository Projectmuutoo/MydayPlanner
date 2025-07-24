import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/BoardTasksCreatePostRequest.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart'
    as model;
import 'package:mydayplanner/pages/pageMember/detailBoards/tasksDetail.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mydayplanner/splash.dart';
import 'package:rxdart/rxdart.dart' as rxdart;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class BoardshowtasksPage extends StatefulWidget {
  const BoardshowtasksPage({super.key});

  @override
  State<BoardshowtasksPage> createState() => _BoardshowtasksPageState();
}

class _BoardshowtasksPageState extends State<BoardshowtasksPage>
    with WidgetsBindingObserver {
  var box = GetStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final storage = FlutterSecureStorage();
  late String url;
  List<model.Task> tasks = [];
  final GlobalKey iconKey = GlobalKey();
  bool addTask = false;
  bool hideMenu = false;
  bool isTyping = false;
  List<String> selectedTaskIds = [];
  List<String> selectedIsArchived = [];
  Map<String, bool> creatingTasks = {};
  SortType currentSortType = SortType.dateEarliestFirst;
  OverlayEntry? mainMenuEntry;
  OverlayEntry? sortMenuEntry;
  bool isFinishing = false;
  Map<int, ScrollController> scrollControllers = {};
  final GlobalKey addFormKey = GlobalKey();
  bool isCreatingTask = false;
  Timer? _timer;
  bool isCustomReminderApplied = false;
  String? selectedReminder;
  DateTime? customReminderDateTime;
  int? selectedPriority;
  bool isKeyboardVisible = false;
  bool wasKeyboardOpen = false;
  int? selectedBeforeMinutes;
  Timer? debounceTimer;
  String? selectedRepeat;
  final TextEditingController addTasknameCtl = TextEditingController();
  final TextEditingController addDescriptionCtl = TextEditingController();
  final FocusNode addTasknameFocusNode = FocusNode();
  final FocusNode addDescriptionFocusNode = FocusNode();
  bool isShowMenuRemind = false;
  bool isShowMenuPriority = false;
  int currentViewIndex = 0;
  PageController pageController = PageController(
    viewportFraction: 0.92,
    initialPage: 0,
  );
  double currentPage = 0.0;
  bool isLoading = false;
  StreamSubscription? combinedSubscription;
  bool isBackHomepage = false;
  Map<int, model.Task> tempTasks = {};
  List<model.Task> firebaseTasks = [];
  Set<String> deletedTaskIds = {};

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final appData = Provider.of<Appdata>(context, listen: false);
    final pageCount = appData.boardDatas.boardToken.isEmpty ? 2 : 3;
    for (int i = 0; i < pageCount; i++) {
      scrollControllers[i] = ScrollController();
    }

    loadDataAsync();
    checkExpiresTokenBoard();
    setState(() {
      if (appData.boardDatas.boardToken.isNotEmpty) isLoading = true;
    });

    pageController.addListener(() {
      setState(() {
        currentPage = pageController.page ?? 0.0;
      });
    });

    addTasknameFocusNode.addListener(() {
      if (addTasknameFocusNode.hasFocus && addTask) {
        Future.delayed(Duration(milliseconds: 200), () {
          _scrollToAddForm();
        });
      }
    });

    addDescriptionFocusNode.addListener(() {
      if (addDescriptionFocusNode.hasFocus && addTask) {
        _scrollToAddForm();
      }
    });
  }

  Future<void> loadDataAsync() async {
    if (!mounted) return;

    final rawData = box.read('userDataAll');
    final tasksData = model.AllDataUserGetResponst.fromJson(rawData);
    final appData = Provider.of<Appdata>(context, listen: false);

    // ถ้ามี boardToken ให้แสดงข้อมูลจาก Firebase + temp tasks
    if (appData.boardDatas.boardToken.isNotEmpty) {
      combinedSubscription?.cancel();

      final tasksStream = FirebaseFirestore.instance
          .collection('Boards')
          .doc(appData.boardDatas.idBoard)
          .collection('Tasks')
          .snapshots();

      combinedSubscription = tasksStream.listen((tasksSnapshot) async {
        if (!mounted) return;

        List<Stream<QuerySnapshot>> notificationStreams = [];

        for (var doc in tasksSnapshot.docs) {
          final data = doc.data();
          final taskId = data['taskID'].toString();

          final notificationStream = FirebaseFirestore.instance
              .collection('BoardTasks')
              .doc(taskId)
              .collection('Notifications')
              .snapshots();

          notificationStreams.add(notificationStream);
        }

        // หากไม่มี Firebase tasks แต่มี temp tasks
        if (notificationStreams.isEmpty) {
          // รวม temp tasks เข้ากับ firebase tasks (ที่ว่างเปล่า)
          _updateDisplayTasks([]);
          return;
        }

        final combinedNotificationStream = rxdart.Rx.combineLatestList(
          notificationStreams,
        );

        combinedNotificationStream.listen((notificationSnapshots) async {
          if (!mounted) return;

          List<model.Task> updatedFirebaseTasks = [];

          for (int i = 0; i < tasksSnapshot.docs.length; i++) {
            final taskDoc = tasksSnapshot.docs[i];
            final taskData = taskDoc.data();

            List<model.Notification> notifications = [];
            if (i < notificationSnapshots.length) {
              final notificationSnapshot = notificationSnapshots[i];
              for (var notifDoc in notificationSnapshot.docs) {
                final notifData = notifDoc.data() as Map<String, dynamic>;
                notifications.add(
                  model.Notification(
                    createdAt: (notifData['createdAt'] as Timestamp)
                        .toDate()
                        .toIso8601String(),
                    dueDate: (notifData['dueDate'] as Timestamp)
                        .toDate()
                        .toIso8601String(),
                    isSend: notifData['isSend'] ?? false,
                    notificationId: notifData['notificationID'] ?? '',
                    recurringPattern: notifData['recurringPattern'] ?? '',
                    taskId: notifData['taskID'] ?? '',
                  ),
                );
              }
            }

            final task = model.Task(
              assigned: taskData['assigned'] ?? [],
              attachments: taskData['attachments'] ?? [],
              boardId: taskData['boardId'].toString(),
              checklists: taskData['checklists'] ?? [],
              createBy: int.parse(taskData['createBy'].toString()),
              createdAt: (taskData['createAt'] as Timestamp)
                  .toDate()
                  .toIso8601String(),
              description: taskData['description'] == null
                  ? ''
                  : taskData['description'].toString(),
              notifications: notifications,
              priority: taskData['priority'] == null
                  ? ''
                  : taskData['priority'].toString(),
              status: taskData['status'].toString(),
              taskId: int.parse(taskData['taskID'].toString()),
              taskName: taskData['taskName'].toString(),
            );
            updatedFirebaseTasks.add(task);
          }

          // อัพเดท firebase tasks และรวมกับ temp tasks
          _updateDisplayTasks(updatedFirebaseTasks);
        });
      });
      return;
    } else {
      // กรณี local storage
      List<model.Task> filteredTasks = tasksData.tasks
          .where(
            (task) => task.boardId.toString() == appData.boardDatas.idBoard,
          )
          .toList();

      filteredTasks = sortTasks(filteredTasks);
      appData.showMyTasks.setTasks(filteredTasks);
      setState(() {
        tasks = filteredTasks;
        isLoading = false;
      });
    }
  }

  void _updateDisplayTasks(List<model.Task> firebaseTasksList) {
    firebaseTasks = firebaseTasksList;

    // กรอง Firebase tasks ที่ไม่อยู่ใน deletedTaskIds
    List<model.Task> filteredFirebaseTasks = firebaseTasks
        .where((task) => !deletedTaskIds.contains(task.taskId.toString()))
        .toList();

    // รวม firebase tasks กับ temp tasks
    List<model.Task> combined = [...filteredFirebaseTasks];

    // เพิ่ม temp tasks ที่ยังไม่มีใน firebase และไม่ถูกลบ
    for (var tempTask in tempTasks.values) {
      if (!deletedTaskIds.contains(tempTask.taskId.toString())) {
        bool existsInFirebase = filteredFirebaseTasks.any(
          (task) => task.taskId == tempTask.taskId,
        );
        if (!existsInFirebase) {
          combined.add(tempTask);
        }
      }
    }

    // เรียงลำดับและอัพเดท UI
    combined = sortTasks(combined);

    final appData = Provider.of<Appdata>(context, listen: false);
    appData.showMyTasks.setTasks(combined);

    if (mounted) {
      setState(() {
        tasks = combined;
        isLoading = false;
      });
    }
  }

  @override
  void didChangeMetrics() {
    //ทั้งหมดคือดักจับ keyboard และการบันทึก task
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newKeyboardVisible = bottomInset > 0;

    if (newKeyboardVisible != isKeyboardVisible) {
      setState(() {
        isKeyboardVisible = newKeyboardVisible;
      });
      if (newKeyboardVisible) {
        wasKeyboardOpen = true;
      }
      if (!newKeyboardVisible && wasKeyboardOpen) {
        wasKeyboardOpen = false;

        setState(() {
          addTask = false;
        });
        _saveData(addTasknameCtl.text, addDescriptionCtl.text);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in scrollControllers.values) {
      controller.dispose();
    }
    scrollControllers.clear();
    addTasknameCtl.dispose();
    addDescriptionCtl.dispose();
    addTasknameFocusNode.dispose();
    addDescriptionFocusNode.dispose();
    pageController.dispose();
    _timer?.cancel();
    debounceTimer?.cancel();
    combinedSubscription?.cancel();
    mainMenuEntry?.remove();
    sortMenuEntry?.remove();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    //ทั้งหมดคือการบันทึก task ที่ user พิมไว้และกดออกแอป มันจะบันทึกให้
    if (state == AppLifecycleState.paused) {
      _saveData(addTasknameCtl.text, addDescriptionCtl.text);
      _timer = Timer.periodic(Duration(seconds: 3), (timer) {
        loadDataAsync();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        if (hideMenu) {
          setState(() {
            addTask = true;
          });
        }
        setState(() {
          addTask = !addTask;
        });
        Future.delayed(Duration(milliseconds: 200), () {
          addTasknameFocusNode.requestFocus();
        });
        _saveData(addTasknameCtl.text, addDescriptionCtl.text);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    addTask = false;
                  });
                  _saveData(addTasknameCtl.text, addDescriptionCtl.text);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: backToHomepage,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.02,
                                  vertical: height * 0.01,
                                ),
                                child: SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);"><path d="M21 11H6.414l5.293-5.293-1.414-1.414L2.586 12l7.707 7.707 1.414-1.414L6.414 13H21z"></path></svg>',
                                  height: height * 0.03,
                                  width: width * 0.03,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(width: width * 0.01),
                            !hideMenu
                                ? Expanded(
                                    child: Text(
                                      context
                                          .read<Appdata>()
                                          .boardDatas
                                          .boardName,
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleLarge!.fontSize!,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : Text(
                                    selectedTaskIds.isNotEmpty
                                        ? '${selectedTaskIds.length} Selected'
                                        : 'Select Task',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleLarge!.fontSize!,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                            SizedBox(width: width * 0.08),
                          ],
                        ),
                      ),
                      if (context
                          .read<Appdata>()
                          .boardDatas
                          .boardToken
                          .isNotEmpty)
                        Row(
                          children: [
                            InkWell(
                              onTap: () {},
                              child: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M5.5 15a3.51 3.51 0 0 0 2.36-.93l6.26 3.58a3.06 3.06 0 0 0-.12.85 3.53 3.53 0 1 0 1.14-2.57l-6.26-3.58a2.74 2.74 0 0 0 .12-.76l6.15-3.52A3.49 3.49 0 1 0 14 5.5a3.35 3.35 0 0 0 .12.85L8.43 9.6A3.5 3.5 0 1 0 5.5 15zm12 2a1.5 1.5 0 1 1-1.5 1.5 1.5 1.5 0 0 1 1.5-1.5zm0-13A1.5 1.5 0 1 1 16 5.5 1.5 1.5 0 0 1 17.5 4zm-12 6A1.5 1.5 0 1 1 4 11.5 1.5 1.5 0 0 1 5.5 10z"></path></svg>',
                                height: height * 0.03,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(width: width * 0.02),
                          ],
                        ),
                      Row(
                        children: [
                          if (!hideMenu)
                            InkWell(
                              key: iconKey,
                              onTap: () {
                                showPopupMenuOverlay(context);
                              },
                              child: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 12c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"></path></svg>',
                                height: height * 0.035,
                                fit: BoxFit.contain,
                              ),
                            ),
                          if (hideMenu || addTask)
                            TextButton(
                              onPressed: hideMenu
                                  ? () {
                                      final appData = Provider.of<Appdata>(
                                        context,
                                        listen: false,
                                      );
                                      setState(() {
                                        selectedTaskIds.clear();
                                        hideMenu = false;
                                      });
                                      if (appData
                                          .boardDatas
                                          .boardToken
                                          .isNotEmpty) {
                                        String currentStatus =
                                            getCurrentStatus();
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              pageController.jumpToPage(
                                                int.parse(currentStatus),
                                              );
                                            });
                                      }
                                    }
                                  : () {
                                      setState(() {
                                        addTask = false;
                                      });
                                      _saveData(
                                        addTasknameCtl.text,
                                        addDescriptionCtl.text,
                                      );
                                    },
                              child: Text(
                                "Save",
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.titleMedium!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              !hideMenu
                  ? SizedBox.shrink()
                  : selectedTaskIds.isNotEmpty ||
                        getCurrentPageTasks().isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.05,
                        bottom: height * 0.005,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            List<model.Task> currentTasks =
                                getCurrentPageTasks();
                            List<String> currentTaskIds = currentTasks
                                .map((task) => task.taskId.toString())
                                .toList();

                            if (selectedTaskIds.length ==
                                    currentTaskIds.length &&
                                selectedTaskIds.every(
                                  (id) => currentTaskIds.contains(id),
                                )) {
                              // ถ้าเลือกครบทุกตัวในหน้านี้แล้ว ให้ยกเลิกการเลือกทั้งหมด
                              selectedTaskIds.clear();
                            } else {
                              // ถ้ายังเลือกไม่ครบ ให้เลือกทั้งหมดในหน้านี้
                              selectedTaskIds = currentTaskIds;
                            }
                          });
                        },
                        child: Row(
                          children: [
                            SvgPicture.string(
                              () {
                                List<model.Task> currentTasks =
                                    getCurrentPageTasks();
                                List<String> currentTaskIds = currentTasks
                                    .map((task) => task.taskId.toString())
                                    .toList();

                                bool allSelected =
                                    selectedTaskIds.length ==
                                        currentTaskIds.length &&
                                    selectedTaskIds.every(
                                      (id) => currentTaskIds.contains(id),
                                    );

                                return allSelected
                                    ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>'
                                    : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>';
                              }(),
                              height: height * 0.04,
                              fit: BoxFit.contain,
                              color: () {
                                List<model.Task> currentTasks =
                                    getCurrentPageTasks();
                                List<String> currentTaskIds = currentTasks
                                    .map((task) => task.taskId.toString())
                                    .toList();

                                bool allSelected =
                                    selectedTaskIds.length ==
                                        currentTaskIds.length &&
                                    selectedTaskIds.every(
                                      (id) => currentTaskIds.contains(id),
                                    );

                                return allSelected
                                    ? Color(0xFF007AFF)
                                    : Colors.grey;
                              }(),
                            ),
                            SizedBox(width: width * 0.01),
                            Text(
                              'Select All',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize!,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    addTask = false;
                  });
                  _saveData(addTasknameCtl.text, addDescriptionCtl.text);
                },
                child: Container(
                  padding: EdgeInsets.only(
                    left: width * 0.05,
                    right: width * 0.05,
                    bottom: height * 0.005,
                  ),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          pageController.animateToPage(
                            0,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Transform.scale(
                          scale: currentPage <= 0.5 ? 1.0 : 0.8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.04,
                              vertical: height * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: currentPage <= 0.5
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "To Do",
                              style: TextStyle(
                                fontWeight: currentPage <= 0.5
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: currentPage <= 0.5
                                    ? Colors.blue
                                    : Colors.grey,
                                fontSize: Get.textTheme.titleMedium!.fontSize!,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (context
                          .read<Appdata>()
                          .boardDatas
                          .boardToken
                          .isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            pageController.animateToPage(
                              1,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Transform.scale(
                            scale: (currentPage > 0.5 && currentPage < 1.5)
                                ? 1.0
                                : 0.8,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.04,
                                vertical: height * 0.005,
                              ),
                              decoration: BoxDecoration(
                                color: (currentPage > 0.5 && currentPage < 1.5)
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "InProgress",
                                style: TextStyle(
                                  fontWeight:
                                      (currentPage > 0.5 && currentPage < 1.5)
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color:
                                      (currentPage > 0.5 && currentPage < 1.5)
                                      ? Colors.orange
                                      : Colors.grey,
                                  fontSize:
                                      Get.textTheme.titleMedium!.fontSize!,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Complete
                      GestureDetector(
                        onTap: () {
                          pageController.animateToPage(
                            context
                                    .read<Appdata>()
                                    .boardDatas
                                    .boardToken
                                    .isNotEmpty
                                ? 2
                                : 1,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Transform.scale(
                          scale:
                              context
                                  .read<Appdata>()
                                  .boardDatas
                                  .boardToken
                                  .isNotEmpty
                              ? (currentPage >= 1.5 ? 1.0 : 0.8)
                              : (currentPage >= 0.5 ? 1.0 : 0.8),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.04,
                              vertical: height * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  context
                                      .read<Appdata>()
                                      .boardDatas
                                      .boardToken
                                      .isNotEmpty
                                  ? (currentPage >= 1.5
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.transparent)
                                  : (currentPage >= 0.5
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.transparent),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Complete",
                              style: TextStyle(
                                fontWeight:
                                    context
                                        .read<Appdata>()
                                        .boardDatas
                                        .boardToken
                                        .isNotEmpty
                                    ? (currentPage >= 1.5
                                          ? FontWeight.bold
                                          : FontWeight.w500)
                                    : (currentPage >= 0.5
                                          ? FontWeight.bold
                                          : FontWeight.w500),
                                color:
                                    context
                                        .read<Appdata>()
                                        .boardDatas
                                        .boardToken
                                        .isNotEmpty
                                    ? (currentPage >= 1.5
                                          ? Colors.green
                                          : Colors.grey)
                                    : (currentPage >= 0.5
                                          ? Colors.green
                                          : Colors.grey),
                                fontSize: Get.textTheme.titleMedium!.fontSize!,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  onPageChanged: (index) {
                    setState(() {
                      currentViewIndex = index;
                      selectedTaskIds.clear();
                    });
                  },
                  itemCount:
                      context.read<Appdata>().boardDatas.boardToken.isEmpty
                      ? 2
                      : 3,
                  itemBuilder: (context, index) {
                    String status;
                    String emptyMessage;
                    if (context.read<Appdata>().boardDatas.boardToken.isEmpty) {
                      if (index == 0) {
                        status = '0'; // To Do
                        emptyMessage = 'No tasks for to do';
                      } else {
                        status = '2'; // Complete
                        emptyMessage = 'No completed tasks';
                      }
                    } else {
                      if (index == 0) {
                        status = '0'; // To Do
                        emptyMessage = 'No tasks for to do';
                      } else if (index == 1) {
                        status = '1'; // InProgress
                        emptyMessage = 'No tasks in progress';
                      } else {
                        status = '2'; // Complete
                        emptyMessage = 'No completed tasks';
                      }
                    }

                    List<model.Task> filteredTasks = tasks
                        .where((task) => task.status == status)
                        .toList();

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.01),
                      child: Container(
                        padding: EdgeInsets.only(top: height * 0.005),
                        decoration: BoxDecoration(
                          color: Color(0xFFF2F2F6),
                          borderRadius: addTask
                              ? BorderRadius.only(
                                  bottomLeft: Radius.circular(0),
                                  bottomRight: Radius.circular(0),
                                )
                              : BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.grey,
                                    ),
                                  )
                                : filteredTasks.isEmpty
                                ? Center(
                                    child: Text(
                                      emptyMessage,
                                      style: TextStyle(
                                        fontSize: Get
                                            .textTheme
                                            .titleMedium!
                                            .fontSize!,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: EdgeInsets.only(
                                      bottom: addTask
                                          ? height * 0.02
                                          : height * 0.1,
                                    ),
                                    child: SingleChildScrollView(
                                      controller: scrollControllers[index],
                                      child: Column(
                                        children: [
                                          ...filteredTasks.map((data) {
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                left: width * 0.03,
                                                right: width * 0.03,
                                                top: height * 0.005,
                                              ),
                                              child: Material(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  onTap: hideMenu
                                                      ? () {
                                                          if (selectedTaskIds
                                                              .contains(
                                                                data.taskId
                                                                    .toString(),
                                                              )) {
                                                            selectedTaskIds
                                                                .remove(
                                                                  data.taskId
                                                                      .toString(),
                                                                );
                                                          } else {
                                                            selectedTaskIds.add(
                                                              data.taskId
                                                                  .toString(),
                                                            );
                                                          }
                                                          setState(() {});
                                                        }
                                                      : null,
                                                  child: Dismissible(
                                                    key: ValueKey(data.taskId),
                                                    direction:
                                                        hideMenu ||
                                                            creatingTasks[data
                                                                    .taskId
                                                                    .toString()] ==
                                                                true
                                                        ? DismissDirection.none
                                                        : DismissDirection
                                                              .endToStart,
                                                    background: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      alignment:
                                                          Alignment.centerRight,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                width * 0.02,
                                                          ),
                                                      child: Icon(
                                                        Icons.delete,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    confirmDismiss: (direction) async {
                                                      return await showDialog<
                                                        bool
                                                      >(
                                                        context: context,
                                                        barrierDismissible:
                                                            false,
                                                        builder: (_) {
                                                          return AlertDialog(
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            contentPadding: EdgeInsets.symmetric(
                                                              horizontal:
                                                                  MediaQuery.of(
                                                                    context,
                                                                  ).size.width *
                                                                  0.04,
                                                              vertical:
                                                                  MediaQuery.of(
                                                                        context,
                                                                      )
                                                                      .size
                                                                      .height *
                                                                  0.02,
                                                            ),
                                                            content: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Image.asset(
                                                                  "assets/images/aleart/question.png",
                                                                  height:
                                                                      MediaQuery.of(
                                                                        context,
                                                                      ).size.height *
                                                                      0.1,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                ),
                                                                SizedBox(
                                                                  height:
                                                                      MediaQuery.of(
                                                                        context,
                                                                      ).size.height *
                                                                      0.02,
                                                                ),
                                                                Text(
                                                                  'Do you want to delete this task?',
                                                                  style: TextStyle(
                                                                    fontSize: Get
                                                                        .textTheme
                                                                        .titleMedium!
                                                                        .fontSize!,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                                SizedBox(
                                                                  height:
                                                                      MediaQuery.of(
                                                                        context,
                                                                      ).size.height *
                                                                      0.02,
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        true,
                                                                      ),
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor:
                                                                        Color(
                                                                          0xFF007AFF,
                                                                        ),
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                    ),
                                                                    fixedSize: Size(
                                                                      MediaQuery.of(
                                                                        context,
                                                                      ).size.width,
                                                                      MediaQuery.of(
                                                                            context,
                                                                          ).size.height *
                                                                          0.05,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    'Confirm',
                                                                    style: TextStyle(
                                                                      fontSize: Get
                                                                          .textTheme
                                                                          .titleMedium!
                                                                          .fontSize!,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        false,
                                                                      ),
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red[400],
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                    ),
                                                                    fixedSize: Size(
                                                                      MediaQuery.of(
                                                                        context,
                                                                      ).size.width,
                                                                      MediaQuery.of(
                                                                            context,
                                                                          ).size.height *
                                                                          0.05,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    'Cancel',
                                                                    style: TextStyle(
                                                                      fontSize: Get
                                                                          .textTheme
                                                                          .titleMedium!
                                                                          .fontSize!,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                    onDismissed: (direction) {
                                                      deleteTaskById(
                                                        data.taskId.toString(),
                                                        false,
                                                      );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical:
                                                                height * 0.005,
                                                            horizontal:
                                                                width * 0.01,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            selectedTaskIds
                                                                .contains(
                                                                  data.taskId
                                                                      .toString(),
                                                                )
                                                            ? Colors.black12
                                                            : data.status ==
                                                                      "2" &&
                                                                  hideMenu
                                                            ? Colors.grey[100]
                                                            : Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              GestureDetector(
                                                                onTap: !hideMenu
                                                                    ? () =>
                                                                          handleTaskTap(
                                                                            data,
                                                                          )
                                                                    : null,
                                                                child: !hideMenu
                                                                    ? SvgPicture.string(
                                                                        selectedIsArchived.contains(
                                                                              data.taskId.toString(),
                                                                            )
                                                                            ? '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-292q78.47 0 133.23-54.77Q668-401.53 668-480t-54.77-133.23Q558.47-668 480-668t-133.23 54.77Q292-558.47 292-480t54.77 133.23Q401.53-292 480-292Zm.13 204q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>'
                                                                            : data.status ==
                                                                                  "2"
                                                                            ? '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-292q78.47 0 133.23-54.77Q668-401.53 668-480t-54.77-133.23Q558.47-668 480-668t-133.23 54.77Q292-558.47 292-480t54.77 133.23Q401.53-292 480-292Zm.13 204q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>'
                                                                            : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                                                        height:
                                                                            height *
                                                                            0.04,
                                                                        fit: BoxFit
                                                                            .contain,
                                                                        color:
                                                                            creatingTasks[data.taskId.toString()] ==
                                                                                true
                                                                            ? Colors.grey[300]
                                                                            : selectedIsArchived.contains(
                                                                                data.taskId.toString(),
                                                                              )
                                                                            ? Color(
                                                                                0xFF007AFF,
                                                                              )
                                                                            : data.status ==
                                                                                  "2"
                                                                            ? Color(
                                                                                0xFF007AFF,
                                                                              )
                                                                            : Colors.grey,
                                                                      )
                                                                    : SvgPicture.string(
                                                                        selectedTaskIds.contains(
                                                                              data.taskId.toString(),
                                                                            )
                                                                            ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>'
                                                                            : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                                                        height:
                                                                            height *
                                                                            0.04,
                                                                        fit: BoxFit
                                                                            .contain,
                                                                        color:
                                                                            selectedTaskIds.contains(
                                                                              data.taskId.toString(),
                                                                            )
                                                                            ? Color(
                                                                                0xFF007AFF,
                                                                              )
                                                                            : Colors.grey,
                                                                      ),
                                                              ),
                                                              SizedBox(
                                                                width:
                                                                    width *
                                                                    0.01,
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsets.only(
                                                                        top:
                                                                            height *
                                                                            0.005,
                                                                        bottom:
                                                                            height *
                                                                            0.005,
                                                                        right:
                                                                            width *
                                                                            0.02,
                                                                      ),
                                                                      child: InkWell(
                                                                        onTap:
                                                                            !hideMenu
                                                                            ? creatingTasks[data.taskId.toString()] ==
                                                                                      true
                                                                                  ? null
                                                                                  : () {
                                                                                      if (!hideMenu) {
                                                                                        setState(
                                                                                          () {
                                                                                            hideMenu = false;
                                                                                            addTask = false;
                                                                                          },
                                                                                        );
                                                                                      }
                                                                                      Get.to(
                                                                                        () => TasksdetailPage(
                                                                                          taskId: data.taskId,
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                            : null,
                                                                        child: Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            Expanded(
                                                                              child: Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Row(
                                                                                    children: [
                                                                                      Expanded(
                                                                                        child: Text(
                                                                                          data.taskName,
                                                                                          style: TextStyle(
                                                                                            fontSize: Get.textTheme.titleMedium!.fontSize!,
                                                                                            color:
                                                                                                creatingTasks[data.taskId.toString()] ==
                                                                                                    true
                                                                                                ? Colors.grey
                                                                                                : selectedIsArchived.contains(
                                                                                                        data.taskId.toString(),
                                                                                                      ) ||
                                                                                                      data.status ==
                                                                                                          "2"
                                                                                                ? Colors.grey
                                                                                                : Colors.black,
                                                                                          ),
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                        ),
                                                                                      ),
                                                                                      data.priority.isEmpty
                                                                                          ? SizedBox.shrink()
                                                                                          : Padding(
                                                                                              padding: EdgeInsets.symmetric(
                                                                                                horizontal:
                                                                                                    width *
                                                                                                    0.01,
                                                                                              ),
                                                                                              child: Container(
                                                                                                width:
                                                                                                    width *
                                                                                                    0.03,
                                                                                                height:
                                                                                                    height *
                                                                                                    0.03,
                                                                                                decoration: BoxDecoration(
                                                                                                  shape: BoxShape.circle,
                                                                                                  color:
                                                                                                      data.priority ==
                                                                                                          '3'
                                                                                                      ? Colors.red
                                                                                                      : data.priority ==
                                                                                                            '2'
                                                                                                      ? Colors.orange
                                                                                                      : Colors.green,
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                    ],
                                                                                  ),
                                                                                  data.description.isEmpty
                                                                                      ? SizedBox.shrink()
                                                                                      : Text(
                                                                                          data.description,
                                                                                          style: TextStyle(
                                                                                            fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                            color: Colors.grey,
                                                                                          ),
                                                                                          maxLines: 2,
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                        ),
                                                                                  Row(
                                                                                    children: [
                                                                                      formatDateDisplay(
                                                                                            data.notifications,
                                                                                          ).isEmpty
                                                                                          ? SizedBox.shrink()
                                                                                          : Container(
                                                                                              decoration: BoxDecoration(
                                                                                                border: Border.all(
                                                                                                  width: 0.5,
                                                                                                  color: Colors.red,
                                                                                                ),
                                                                                                borderRadius: BorderRadius.circular(
                                                                                                  6,
                                                                                                ),
                                                                                              ),
                                                                                              padding: EdgeInsets.symmetric(
                                                                                                horizontal:
                                                                                                    width *
                                                                                                    0.01,
                                                                                              ),
                                                                                              child: Row(
                                                                                                children: [
                                                                                                  SvgPicture.string(
                                                                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M13 7h-2v6h6v-2h-4z"></path></svg>',
                                                                                                    width:
                                                                                                        width *
                                                                                                        0.04,
                                                                                                    fit: BoxFit.contain,
                                                                                                    color: Colors.red,
                                                                                                  ),
                                                                                                  Text(
                                                                                                    " Due ",
                                                                                                    style: TextStyle(
                                                                                                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                                      color: Colors.red,
                                                                                                    ),
                                                                                                  ),
                                                                                                  Text(
                                                                                                    formatDateDisplay(
                                                                                                      data.notifications,
                                                                                                    ),
                                                                                                    style: TextStyle(
                                                                                                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                                      color: Colors.red,
                                                                                                    ),
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            ),
                                                                                      FutureBuilder<
                                                                                        List<
                                                                                          String
                                                                                        >
                                                                                      >(
                                                                                        future: showTimeRemineMeBefore(
                                                                                          data.taskId,
                                                                                          notiTasks: data.notifications,
                                                                                        ),
                                                                                        builder:
                                                                                            (
                                                                                              context,
                                                                                              snapshot,
                                                                                            ) {
                                                                                              if (snapshot.hasData &&
                                                                                                  snapshot.data!.isNotEmpty) {
                                                                                                return Row(
                                                                                                  children: [
                                                                                                    Padding(
                                                                                                      padding: EdgeInsets.symmetric(
                                                                                                        horizontal:
                                                                                                            width *
                                                                                                            0.01,
                                                                                                      ),
                                                                                                      child: SvgPicture.string(
                                                                                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 4c-4.879 0-9 4.121-9 9s4.121 9 9 9 9-4.121 9-9-4.121-9-9-9zm0 16c-3.794 0-7-3.206-7-7s3.206-7 7-7 7 3.206 7 7-3.206 7-7 7z"></path><path d="M13 12V8h-2v6h6v-2zm4.284-8.293 1.412-1.416 3.01 3-1.413 1.417zm-10.586 0-2.99 2.999L2.29 5.294l2.99-3z"></path></svg>',
                                                                                                        width:
                                                                                                            width *
                                                                                                            0.04,
                                                                                                        fit: BoxFit.contain,
                                                                                                        color: Colors.red,
                                                                                                      ),
                                                                                                    ),
                                                                                                    ...snapshot.data!.map(
                                                                                                      (
                                                                                                        time,
                                                                                                      ) => Padding(
                                                                                                        padding: EdgeInsets.only(
                                                                                                          right:
                                                                                                              width *
                                                                                                              0.01,
                                                                                                        ),
                                                                                                        child: Text(
                                                                                                          time,
                                                                                                          style: TextStyle(
                                                                                                            fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                                            color: Colors.red,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ),
                                                                                                  ],
                                                                                                );
                                                                                              } else {
                                                                                                return SizedBox.shrink();
                                                                                              }
                                                                                            },
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
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),
                            if (!addTask && !hideMenu)
                              Positioned(
                                bottom: 20,
                                right: 20,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          addTask = !addTask;
                                        });
                                        if (addTask) {
                                          Future.delayed(
                                            Duration(milliseconds: 100),
                                            () {
                                              addTasknameFocusNode
                                                  .requestFocus();
                                            },
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.01,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              "New",
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .titleMedium!
                                                    .fontSize!,
                                                color: Color(0xFF007AFF),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: width * 0.01),
                                            SvgPicture.string(
                                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M13 7h-2v4H7v2h4v4h2v-4h4v-2h-4z"></path><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path></svg>',
                                              height: height * 0.04,
                                              fit: BoxFit.contain,
                                              color: Color(0xFF007AFF),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (hideMenu)
                              Positioned(
                                bottom: 20,
                                right: 0,
                                left: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: width * 0.12,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF2F2F6),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Material(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(18),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          onTap: selectedTaskIds.isNotEmpty
                                              ? () {
                                                  Get.defaultDialog(
                                                    title: '',
                                                    titlePadding:
                                                        EdgeInsets.zero,
                                                    backgroundColor:
                                                        Colors.white,
                                                    barrierDismissible: false,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal:
                                                              MediaQuery.of(
                                                                context,
                                                              ).size.width *
                                                              0.04,
                                                          vertical:
                                                              MediaQuery.of(
                                                                context,
                                                              ).size.height *
                                                              0.01,
                                                        ),
                                                    content: WillPopScope(
                                                      onWillPop: () async =>
                                                          false,
                                                      child: Column(
                                                        children: [
                                                          Image.asset(
                                                            "assets/images/aleart/question.png",
                                                            height:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.height *
                                                                0.1,
                                                            fit: BoxFit.contain,
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.height *
                                                                0.02,
                                                          ),
                                                          Text(
                                                            'Do you want to delete this board?',
                                                            style: TextStyle(
                                                              fontSize: Get
                                                                  .textTheme
                                                                  .titleMedium!
                                                                  .fontSize!,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors.red,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.height *
                                                                0.01,
                                                          ),
                                                          Text(
                                                            'Are you sure you want to delete this board and all its tasks.',
                                                            style: TextStyle(
                                                              fontSize: Get
                                                                  .textTheme
                                                                  .titleSmall!
                                                                  .fontSize!,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      Column(
                                                        children: [
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              Get.back();
                                                              setState(() {
                                                                hideMenu =
                                                                    false;
                                                              });
                                                              deleteTaskById(
                                                                selectedTaskIds,
                                                                true,
                                                              );
                                                              selectedTaskIds
                                                                  .clear();
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Color(
                                                                    0xFF007AFF,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              elevation: 1,
                                                              fixedSize: Size(
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width,
                                                                MediaQuery.of(
                                                                      context,
                                                                    ).size.height *
                                                                    0.05,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              'Confirm',
                                                              style: TextStyle(
                                                                fontSize: Get
                                                                    .textTheme
                                                                    .titleMedium!
                                                                    .fontSize!,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              Get.back();
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .red[400],
                                                              elevation: 0,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              fixedSize: Size(
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width,
                                                                MediaQuery.of(
                                                                      context,
                                                                    ).size.height *
                                                                    0.05,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              'Cancel',
                                                              style: TextStyle(
                                                                fontSize: Get
                                                                    .textTheme
                                                                    .titleMedium!
                                                                    .fontSize!,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                }
                                              : null,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.01,
                                              vertical: height * 0.005,
                                            ),
                                            child: SvgPicture.string(
                                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M5 20a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8h2V6h-4V4a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v2H3v2h2zM9 4h6v2H9zM8 8h9v12H7V8z"></path><path d="M9 10h2v8H9zm4 0h2v8h-2z"></path></svg>',
                                              width: width * 0.035,
                                              height: height * 0.035,
                                              fit: BoxFit.contain,
                                              color: selectedTaskIds.isNotEmpty
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (addTask)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      addTask = true;
                    });
                  },
                  child: Container(
                    color: Color(0xFFF2F2F6),
                    key: addFormKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: width * 0.04,
                                right: width * 0.018,
                              ),
                              child: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                height: height * 0.04,
                                fit: BoxFit.contain,
                                color: Colors.grey[400],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(
                                  top: height * 0.005,
                                  right: width * 0.05,
                                ),
                                width: width,
                                child: TextField(
                                  controller: addTasknameCtl,
                                  focusNode: addTasknameFocusNode,
                                  keyboardType: TextInputType.text,
                                  cursorColor: Color(0xFF007AFF),
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleSmall!.fontSize!,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: isTyping ? '' : 'Add Title',
                                    hintStyle: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize!,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey,
                                    ),
                                    constraints: BoxConstraints(
                                      maxHeight: height * 0.05,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: height * 0.01,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.only(
                                left: width * 0.145,
                                right: width * 0.05,
                              ),
                              width: width,
                              child: TextField(
                                controller: addDescriptionCtl,
                                focusNode: addDescriptionFocusNode,
                                keyboardType: TextInputType.text,
                                cursorColor: Color(0xFF007AFF),
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize!,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: isTyping ? '' : 'Add Description',
                                  hintStyle: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleSmall!.fontSize!,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey,
                                  ),
                                  constraints: BoxConstraints(
                                    maxHeight: height * 0.04,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: height * 0.005,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: width * 0.14,
                            right: width * 0.05,
                            bottom: height * 0.005,
                          ),
                          child: Row(
                            children: [
                              Text(
                                selectedReminder != null
                                    ? selectedReminder.toString()
                                    : 'Today',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize!,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (addTask) Divider(thickness: 1, height: 0),
              if (addTask)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      addTask = true;
                    });
                  },
                  child: Column(
                    children: [
                      if (isShowMenuRemind)
                        Container(
                          width: width,
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.02,
                            vertical: height * 0.01,
                          ),
                          color: Color(0xFFF2F2F6),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Wrap(
                              spacing: 6,
                              children: [
                                ...selectRemind().map((select) {
                                  bool isSelected = selectedReminder == select;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedReminder = isSelected
                                            ? null
                                            : select;
                                        customReminderDateTime = null;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.02,
                                        vertical: height * 0.005,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Color(0xFF007AFF)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        select,
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleSmall!
                                              .fontSize!,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      isCustomReminderApplied = true;
                                    });
                                    _showCustomDateTimePicker(context);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.02,
                                      vertical: height * 0.005,
                                    ),
                                    decoration: BoxDecoration(
                                      color: customReminderDateTime != null
                                          ? Color(0xFF007AFF)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      (selectedReminder != null &&
                                              selectedReminder!.startsWith(
                                                'Custom:',
                                              ) &&
                                              customReminderDateTime != null)
                                          ? showTimeCustom(
                                              customReminderDateTime!,
                                            )
                                          : 'Custom',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleSmall!.fontSize!,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            (selectedReminder != null &&
                                                selectedReminder!.startsWith(
                                                  'Custom:',
                                                ))
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (isShowMenuPriority)
                        Container(
                          width: width,
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.02,
                            vertical: height * 0.01,
                          ),
                          color: Color(0xFFF2F2F6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: selectPriority().map((select) {
                              bool isSelected = selectedPriority == select;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedPriority = isSelected
                                        ? null
                                        : select;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.02,
                                    vertical: height * 0.005,
                                  ),
                                  decoration: BoxDecoration(
                                    color: select == 1 && isSelected
                                        ? Colors.green
                                        : select == 2 && isSelected
                                        ? Colors.orange
                                        : select == 3 && isSelected
                                        ? Colors.red
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    select == 1
                                        ? 'Low'
                                        : select == 2
                                        ? 'Medium'
                                        : 'High',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize!,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      Divider(thickness: 1, height: 0),
                      Container(
                        color: Color(0xFFF2F2F6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      isShowMenuRemind = !isShowMenuRemind;
                                      isShowMenuPriority = false;
                                      _scrollToAddForm();
                                    });
                                  },
                                  child: SizedBox(
                                    width: width,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.02,
                                        vertical: height * 0.002,
                                      ),
                                      child: Column(
                                        children: [
                                          SvgPicture.string(
                                            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M8 15h3v3h2v-3h3v-2h-3v-3h-2v3H8z"></path><path d="M19 4h-2V2h-2v2H9V2H7v2H5c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h14c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2zm.002 16H5V8h14l.002 12z"></path></svg>',
                                            height: height * 0.03,
                                            fit: BoxFit.contain,
                                            color:
                                                selectedReminder != null ||
                                                    isShowMenuRemind
                                                ? Color(0xFF007AFF)
                                                : Colors.grey,
                                          ),
                                          Text(
                                            'Remind',
                                            style: TextStyle(
                                              fontSize: Get
                                                  .textTheme
                                                  .labelMedium!
                                                  .fontSize!,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      isShowMenuPriority = !isShowMenuPriority;
                                      isShowMenuRemind = false;
                                      _scrollToAddForm();
                                    });
                                  },
                                  child: SizedBox(
                                    width: width,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.02,
                                        vertical: height * 0.002,
                                      ),
                                      child: Column(
                                        children: [
                                          SvgPicture.string(
                                            '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-280q17 0 28.5-11.5T520-320q0-17-11.5-28.5T480-360q-17 0-28.5 11.5T440-320q0 17 11.5 28.5T480-280Zm-40-160h80v-240h-80v240ZM200-120q-33 0-56.5-23.5T120-200v-560q0-33 23.5-56.5T200-840h168q13-36 43.5-58t68.5-22q38 0 68.5 22t43.5 58h168q33 0 56.5 23.5T840-760v560q0 33-23.5 56.5T760-120H200Zm0-80h560v-560H200v560Zm280-590q13 0 21.5-8.5T510-820q0-13-8.5-21.5T480-850q-13 0-21.5 8.5T450-820q0 13 8.5 21.5T480-790ZM200-200v-560 560Z"/></svg>',
                                            height: height * 0.03,
                                            fit: BoxFit.contain,
                                            color: selectedPriority == 1
                                                ? Colors.green
                                                : selectedPriority == 2
                                                ? Colors.orange
                                                : selectedPriority == 3
                                                ? Colors.red
                                                : isShowMenuPriority
                                                ? Color(0xFF007AFF)
                                                : Colors.grey,
                                          ),
                                          Text(
                                            'Priority',
                                            style: TextStyle(
                                              fontSize: Get
                                                  .textTheme
                                                  .labelMedium!
                                                  .fontSize!,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  void backToHomepage() {
    if (addTasknameCtl.text.isNotEmpty || addDescriptionCtl.text.isNotEmpty) {
      setState(() {
        isBackHomepage = true;
      });
      addTasknameFocusNode.unfocus();
      addDescriptionFocusNode.unfocus();
      Future.delayed(Duration(milliseconds: 300), () {
        Get.defaultDialog(
          title: '',
          titlePadding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          barrierDismissible: false,
          contentPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.01,
          ),
          content: WillPopScope(
            onWillPop: () async => false,
            child: Column(
              children: [
                Image.asset(
                  "assets/images/aleart/question.png",
                  height: MediaQuery.of(context).size.height * 0.1,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  'Leave without saving?',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleLarge!.fontSize!,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Text(
                  'If you confirm, all unsaved changes will be lost.',
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
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height * 0.05,
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleMedium!.fontSize!,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      addTask = true;
                      isBackHomepage = false;
                    });
                    Future.delayed(Duration(milliseconds: 200), () {
                      addTasknameFocusNode.requestFocus();
                    });
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height * 0.05,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: Get.textTheme.titleMedium!.fontSize!,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      });
    } else {
      if (addTasknameFocusNode.hasFocus || addDescriptionFocusNode.hasFocus) {
        addTasknameFocusNode.unfocus();
        addDescriptionFocusNode.unfocus();
        Future.delayed(Duration(milliseconds: 300), () {
          Get.back();
        });
      } else {
        Get.back();
      }
    }
  }

  void checkExpiresTokenBoard() async {
    final appData = Provider.of<Appdata>(context, listen: false);
    url = await loadAPIEndpoint();
    final now = DateTime.now();
    final docSnapshot = await FirebaseFirestore.instance
        .collection('Boards')
        .doc(appData.boardDatas.idBoard)
        .get();
    final data = docSnapshot.data();
    if (data != null) {
      if ((data['ShareExpiresAt'] as Timestamp).toDate().isBefore(now)) {
        var response = await http.put(
          Uri.parse("$url/board/newtoken/${appData.boardDatas.idBoard}"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
        );

        if (response.statusCode == 403) {
          await loadNewRefreshToken();
          response = await http.put(
            Uri.parse("$url/board/newtoken/${appData.boardDatas.idBoard}"),
            headers: {
              "Content-Type": "application/json; charset=utf-8",
              "Authorization": "Bearer ${box.read('accessToken')}",
            },
          );
        }
      }
    }
  }

  String getCurrentStatus() {
    if (context.read<Appdata>().boardDatas.boardToken.isNotEmpty) {
      if (currentViewIndex == 0) {
        return '0'; // To Do
      } else if (currentViewIndex == 1) {
        return '1'; // InProgress
      } else {
        return '2'; // Complete
      }
    } else {
      if (currentViewIndex == 0) {
        return '0'; // To Do
      } else {
        return '2'; // Complete
      }
    }
  }

  List<model.Task> getCurrentPageTasks() {
    String currentStatus = getCurrentStatus();
    return tasks.where((task) => task.status == currentStatus).toList();
  }

  Future<List<String>> showTimeRemineMeBefore(
    int taskId, {
    required List<model.Notification> notiTasks,
  }) async {
    final appData = Provider.of<Appdata>(context, listen: false);
    final List<String> remindTimes = [];

    for (var notiTask in notiTasks) {
      DateTime? remindTimestamp;

      if (appData.boardDatas.boardToken.isNotEmpty) {
        // DocumentSnapshot
        final docSnapshot = await FirebaseFirestore.instance
            .collection('BoardTasks')
            .doc(taskId.toString())
            .collection('Notifications')
            .doc(notiTask.notificationId.toString())
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null && data['remindMeBefore'] != null) {
            remindTimestamp = (data['remindMeBefore'] as Timestamp).toDate();
          }
        }
      } else {
        // QuerySnapshot
        final querySnapshot = await FirebaseFirestore.instance
            .collection('Notifications')
            .doc(box.read('userProfile')['email'])
            .collection('Tasks')
            .where('taskID', isEqualTo: taskId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          if (data['remindMeBefore'] != null) {
            remindTimestamp = (data['remindMeBefore'] as Timestamp).toDate();
          }
        }
      }

      if (remindTimestamp != null && remindTimestamp.isAfter(DateTime.now())) {
        final timeString =
            "${remindTimestamp.hour.toString().padLeft(2, '0')}:${remindTimestamp.minute.toString().padLeft(2, '0')}";
        remindTimes.add(timeString);
      }
    }
    setState(() {});
    return remindTimes;
  }

  void handleTaskTap(model.Task data) async {
    final appData = Provider.of<Appdata>(context, listen: false);
    final taskId = data.taskId;
    setState(() => hideMenu = false);

    //กดเลือก task
    if (selectedIsArchived.contains(taskId.toString())) {
      selectedIsArchived.remove(taskId.toString());
    } else {
      selectedIsArchived.add(taskId.toString());
    }

    //หากกดเลือก task ที่เสร็จแล้ว
    if (data.status == "2") {
      if (appData.boardDatas.boardToken.isEmpty) {
        selectedIsArchived.clear();
        await showArchiveTask(taskId.toString());
      } else {
        FirebaseFirestore.instance
            .collection('Boards')
            .doc(appData.boardDatas.idBoard)
            .collection('Tasks')
            .doc(taskId.toString())
            .update({'status': '0'});
        showArchiveTask(taskId.toString());
        selectedIsArchived.clear();
      }
      return;
    }

    if (appData.boardDatas.boardToken.isEmpty) {
      debounceTimer?.cancel();
      //คือหากไม่ได้กดปุ่ม show complete มันจะหน่วงเวลานิดหน่อยเพื่อให้การตัดสินใจก่อน complete
      if (selectedIsArchived.isEmpty) return;

      debounceTimer = Timer(Duration(seconds: 1), () async {
        if (selectedIsArchived.isNotEmpty && !isFinishing) {
          isFinishing = true;
          await finishAllSelectedTasks();
          selectedIsArchived.clear();
          isFinishing = false;
        }
      });
    } else {
      FirebaseFirestore.instance
          .collection('Boards')
          .doc(appData.boardDatas.idBoard)
          .collection('Tasks')
          .doc(taskId.toString())
          .update({'status': '2'});
      await todayTasksFinish(taskId.toString());
      selectedIsArchived.clear();
    }
  }

  Future<void> todayTasksFinish(String id) async {
    if (!mounted) return;

    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = model.AllDataUserGetResponst.fromJson(userDataJson);

    // หาตำแหน่งของ task ที่มี id ตรงกับที่ส่งมา
    final index = existingData.tasks.indexWhere(
      (t) => t.taskId.toString() == id,
    );
    if (index == -1) return; // ออกจากฟังก์ชัน ถ้าไม่เจอ task

    // เปลี่ยนสถานะของ task เป็นเสร็จสิ้น
    existingData.tasks[index].status = '2';
    box.write('userDataAll', existingData.toJson());

    await loadDataAsync(); // ถ้าอยู่ในหน้า archived โหลดข้อมูลใหม่

    if (mounted) setState(() {});

    url = await loadAPIEndpoint();

    var response = await http.put(
      Uri.parse("$url/taskfinish/$id"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      response = await http.put(
        Uri.parse("$url/taskfinish/$id"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
    }
  }

  Future<void> finishAllSelectedTasks() async {
    if (selectedIsArchived.isEmpty) return;

    List<Future<void>> finishTasks = [];

    for (var taskId in selectedIsArchived) {
      finishTasks.add(todayTasksFinish(taskId));
    }
    await Future.wait(finishTasks);
    selectedIsArchived.clear();
    if (mounted) setState(() {});
  }

  Future<void> showArchiveTask(String id) async {
    if (!mounted) return;

    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = model.AllDataUserGetResponst.fromJson(userDataJson);

    final index = existingData.tasks.indexWhere(
      (t) => t.taskId.toString() == id,
    );
    if (index == -1) return;

    existingData.tasks[index].status = '0';
    box.write('userDataAll', existingData.toJson());

    await loadDataAsync();

    if (mounted) setState(() {});

    url = await loadAPIEndpoint();

    var response = await http.put(
      Uri.parse("$url/updatestatus/$id"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: jsonEncode({"status": "0"}),
    );

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      response = await http.put(
        Uri.parse("$url/updatestatus/$id"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: jsonEncode({"status": "0"}),
      );
    }
  }

  String getLabelFromIndex(int? index) {
    if (index == null) return 'Never';

    final options = getRemindMeBeforeOptions();
    if (index >= 0 && index < options.length) {
      return options[index]['label'];
    }
    return 'Never';
  }

  String showTimeCustom(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == today) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = (dateTime.year % 100).toString().padLeft(2, '0');
      return '$day/$month/$year';
    }
  }

  List<String> selectRemind() {
    return ['3 hours later', 'This evening', 'Tomorrow'];
  }

  List<int> selectPriority() {
    return [1, 2, 3];
  }

  void deleteTaskById(dynamic ids, bool select) async {
    if (!mounted) return;

    dynamic taskIdPayload;
    List<String> idList;
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = model.AllDataUserGetResponst.fromJson(userDataJson);
    final appData = Provider.of<Appdata>(context, listen: false);

    if (ids is String) {
      idList = [ids];
      taskIdPayload = ids;
    } else if (ids is List && ids.every((e) => e is String)) {
      idList = List<String>.from(ids);
      taskIdPayload = idList;
    } else {
      throw ArgumentError("Invalid ids parameter");
    }

    if (appData.boardDatas.boardToken.isEmpty) {
      // Local storage logic (เดิม)
      for (var id in idList) {
        appData.showMyTasks.removeTaskById(id);
        existingData.tasks.removeWhere((t) => t.taskId.toString() == id);
        tasks.removeWhere((t) => t.taskId.toString() == id);
      }
      box.write('userDataAll', existingData.toJson());
    } else {
      // 🔥 Firebase mode with Deleted State Management

      // 1. ✅ เพิ่ม IDs เข้าไปใน deletedTaskIds เพื่อป้องกัน Firebase Stream
      for (var id in idList) {
        deletedTaskIds.add(id);

        // ลบจาก tempTasks ถ้ามี
        final tempId = int.tryParse(id);
        if (tempId != null && tempTasks.containsKey(tempId)) {
          tempTasks.remove(tempId);
        }
      }

      // 2. 🚀 อัพเดท UI ทันที
      _updateDisplayTasks(firebaseTasks);

      // 3. 🔄 ลบจาก Firebase ใน background
      _deleteFromFirebaseInBackground(idList, select, taskIdPayload)
          .then((_) {
            // 4. อัพเดท local storage หลังจากลบ Firebase สำเร็จ
            for (var id in idList) {
              existingData.tasks.removeWhere((t) => t.taskId.toString() == id);
            }
            box.write('userDataAll', existingData.toJson());
          })
          .catchError((e) {
            // 5. ❌ หากลบ Firebase ไม่สำเร็จ -> rollback
            for (var id in idList) {
              deletedTaskIds.remove(id); // ลบออกจาก deleted set
            }
            if (mounted) {
              _updateDisplayTasks(firebaseTasks); // รีเฟรช UI

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ไม่สามารถลบ task ได้ กรุณาลองใหม่อีกครั้ง'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
    }

    // เรียก API ลบใน background
    final endpoint = select ? "deltask" : "deltask/$taskIdPayload";
    final requestBody = select ? {"task_id": taskIdPayload} : null;
    deleteWithRetry(endpoint, requestBody);
  }

  //ฟังก์ชันลบ
  Future<http.Response> deleteWithRetry(
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    url = await loadAPIEndpoint();

    final token = box.read('accessToken');
    Uri uri = Uri.parse("$url/$endpoint");

    Future<http.Response> sendRequest(String token) {
      return body == null
          ? http.delete(
              uri,
              headers: {
                "Content-Type": "application/json; charset=utf-8",
                "Authorization": "Bearer $token",
              },
            )
          : http.delete(
              uri,
              headers: {
                "Content-Type": "application/json; charset=utf-8",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode(body),
            );
    }

    var response = await sendRequest(token);

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      final newToken = box.read('accessToken');
      if (newToken != null) {
        response = await sendRequest(newToken);
      }
    }

    return response;
  }

  Future<void> _deleteFromFirebaseInBackground(
    List<String> idList,
    bool select,
    dynamic taskIdPayload,
  ) async {
    if (select) {
      for (var id in idList) {
        await _deleteSingleTaskFromFirebase(id);
      }
    } else {
      await _deleteSingleTaskFromFirebase(taskIdPayload.toString());
    }

    // ✅ หลังจากลบจาก Firebase สำเร็จ ให้ลบออกจาก deletedTaskIds
    // เพื่อให้ Firebase stream ทำงานปกติ
    Future.delayed(Duration(seconds: 2), () {
      for (var id in idList) {
        deletedTaskIds.remove(id);
      }
    });
  }

  Future<void> _deleteSingleTaskFromFirebase(String taskId) async {
    final appData = Provider.of<Appdata>(context, listen: false);
    // ลบจาก Boards collection
    await FirebaseFirestore.instance
        .collection('Boards')
        .doc(appData.boardDatas.idBoard)
        .collection('Tasks')
        .doc(taskId)
        .delete();

    // ลบจาก BoardTasks collection รวม notifications
    final taskDocRef = FirebaseFirestore.instance
        .collection('BoardTasks')
        .doc(taskId);

    final notificationsSnapshot = await taskDocRef
        .collection('Notifications')
        .get();

    // ลบ notifications ทั้งหมด
    final deleteNotificationsFutures = notificationsSnapshot.docs.map(
      (doc) => doc.reference.delete(),
    );
    await Future.wait(deleteNotificationsFutures);
    await loadDataAsync();
    // ลบ BoardTasks document
    await taskDocRef.delete();
  }

  List<Map<String, dynamic>> getRemindMeBeforeOptions() {
    return [
      {'label': 'Never', 'minutes': 0},
      {'label': '5 min', 'minutes': 5},
      {'label': '10 min', 'minutes': 10},
      {'label': '15 min', 'minutes': 15},
      {'label': '30 min', 'minutes': 30},
      {'label': '1 hour', 'minutes': 60},
      {'label': '2 hours', 'minutes': 120},
      {'label': '1 day', 'minutes': 1440},
      {'label': '2 days', 'minutes': 2880},
      {'label': '1 week', 'minutes': 10080},
    ];
  }

  List<String> getRepeatOptions() {
    return ['Onetime', 'Daily', 'Weekly', 'Monthly', 'Yearly'];
  }

  int getMinutesFromIndex(int? index) {
    if (index == null || index == 0) return 0; // Never

    final options = getRemindMeBeforeOptions();
    if (index >= 0 && index < options.length) {
      return options[index]['minutes'];
    }
    return 0;
  }

  bool isValidNotificationTime(DateTime dueDate, int? selectedBeforeMinutes) {
    if (selectedBeforeMinutes == null || selectedBeforeMinutes == 0) {
      return true; // Never หรือ ไม่ได้เลือก = ใช้ dueDate
    }

    final minutesBefore = getMinutesFromIndex(selectedBeforeMinutes);
    if (minutesBefore <= 0) return true;

    final calculatedNotificationTime = dueDate.subtract(
      Duration(minutes: minutesBefore),
    );
    return calculatedNotificationTime.isAfter(DateTime.now());
  }

  // ฟังก์ชันคำนวณเวลาแจ้งเตือนที่ถูกต้อง
  DateTime calculateNotificationTime(
    DateTime dueDate,
    int? selectedBeforeMinutes,
  ) {
    if (selectedBeforeMinutes == null || selectedBeforeMinutes == 0) {
      return dueDate;
    }

    final minutesBefore = getMinutesFromIndex(selectedBeforeMinutes);
    if (minutesBefore <= 0) return dueDate;

    final calculatedNotificationTime = dueDate.subtract(
      Duration(minutes: minutesBefore),
    );

    // หากเวลาแจ้งเตือนอยู่ในอดีต ให้ใช้ dueDate
    if (calculatedNotificationTime.isBefore(DateTime.now())) {
      return dueDate;
    }

    return calculatedNotificationTime;
  }

  DateTime convertReminderToDateTime(String reminder) {
    final now = DateTime.now();

    switch (reminder) {
      case '3 hours later':
        return now.add(Duration(hours: 3));
      case 'This evening':
        return DateTime(now.year, now.month, now.day, 18, 0);
      case 'Tomorrow':
        return now.add(Duration(days: 1));
      default:
        return now;
    }
  }

  Future<void> _saveData(String value, String description) async {
    if (!mounted) return;
    final userProfile = box.read('userProfile');
    final userId = userProfile['userid'];
    final userEmail = userProfile['email'];
    final appData = Provider.of<Appdata>(context, listen: false);
    if (userId == null || userEmail == null) return;

    //ตัวแปรควบคุมหากการ custom data&time หากมีการพิม taskName หรือ description ไว้แล้ว
    //มันจะยังไม่บันทึกจนกว่าออกจาก custom data&time และมากดปุ่ม save
    if (isCustomReminderApplied || isBackHomepage) return;

    final trimmedTitle = value.trim();
    final trimmedDescription = description.trim();
    if (trimmedTitle.isEmpty && trimmedDescription.isEmpty) return;

    //เก็บตามเงื่อนไขที่รับ remind มา
    DateTime dueDate;
    if (selectedReminder != null && selectedReminder!.isNotEmpty) {
      if (selectedReminder!.startsWith('Custom:')) {
        dueDate = customReminderDateTime!;
      } else {
        dueDate = convertReminderToDateTime(selectedReminder!);
      }
    } else {
      dueDate = DateTime.now();
    }

    //หาก title เป็นว่างและ description ไม่ว่างจะบันทึก title => Untitled
    final titleToSave = trimmedTitle.isEmpty ? "Untitled" : trimmedTitle;
    final descriptionToSave = trimmedDescription;
    final tempId = DateTime.now().millisecondsSinceEpoch;

    if (appData.boardDatas.boardToken.isEmpty) {
      // Local storage logic (เดิม)
      final tempTask = model.Task(
        taskName: titleToSave,
        description: descriptionToSave,
        createdAt: DateTime.now().toIso8601String(),
        priority: selectedPriority == null ? '' : selectedPriority.toString(),
        status: '0',
        attachments: [],
        checklists: [],
        createBy: userId,
        taskId: tempId,
        assigned: [],
        boardId: appData.boardDatas.idBoard.toString(),
        notifications: [
          model.Notification(
            createdAt: DateTime.now().toIso8601String(),
            dueDate: dueDate.toUtc().toIso8601String(),
            isSend: dueDate.isAfter(DateTime.now()) ? false : true,
            notificationId: tempId,
            recurringPattern: (selectedRepeat ?? 'Onetime').toLowerCase(),
            taskId: tempId,
          ),
        ],
      );

      appData.showMyTasks.addTask(tempTask);
      if (mounted) {
        setState(() {
          addTask = false;
          creatingTasks[tempId.toString()] = true;
          isCreatingTask = true;
          addTasknameCtl.clear();
          addDescriptionCtl.clear();
        });
      }

      await _updateLocalStorage(tempTask);
      await loadDataAsync();

      final success = await _createTaskAPI(
        titleToSave,
        descriptionToSave,
        userEmail,
        dueDate,
      );

      if (success['success']) {
        final realTaskId = success['taskId'];
        final notificationID = success['notificationID'];
        await _replaceWithRealTask(
          tempId.toString(),
          notificationID,
          realTaskId,
          tempTask,
          userId,
          dueDate,
        );
      } else {
        await _removeTempTask(tempId.toString());
      }
      if (mounted) {
        setState(() {
          creatingTasks.remove(tempId.toString());
          isCreatingTask = creatingTasks.isNotEmpty;
          customReminderDateTime = null;
          selectedReminder = null;
          selectedPriority = null;
          isShowMenuPriority = false;
          isShowMenuRemind = false;
          isCustomReminderApplied = false;
          selectedBeforeMinutes = null;
          selectedRepeat = 'Onetime';
        });
      }
    } else {
      // 🔥 Firebase mode - Optimistic Update
      final tempTask = model.Task(
        taskName: titleToSave,
        description: descriptionToSave,
        createdAt: DateTime.now().toIso8601String(),
        priority: selectedPriority == null ? '' : selectedPriority.toString(),
        status: '0',
        attachments: [],
        checklists: [],
        createBy: userId,
        taskId: tempId,
        assigned: [],
        boardId: appData.boardDatas.idBoard.toString(),
        notifications: [
          model.Notification(
            createdAt: DateTime.now().toIso8601String(),
            dueDate: dueDate.toUtc().toIso8601String(),
            isSend: dueDate.isAfter(DateTime.now()) ? false : true,
            notificationId: tempId,
            recurringPattern: (selectedRepeat ?? 'Onetime').toLowerCase(),
            taskId: tempId,
          ),
        ],
      );

      // 1. 🚀 แสดง temp task ในทันทีให้ผู้ใช้เห็น (Optimistic Update)
      tempTasks[tempId] = tempTask;

      // 2. ตั้งค่า creating state ก่อน update display
      if (mounted) {
        setState(() {
          addTask = false;
          creatingTasks[tempId.toString()] = true; // ✅ ตั้งค่าให้แสดง loading
          isCreatingTask = true;
          addTasknameCtl.clear();
          addDescriptionCtl.clear();
        });
      }

      await _updateLocalStorage(tempTask);
      await loadDataAsync();
      // 3. อัพเดท display หลังจากตั้งค่า creating state แล้ว
      _updateDisplayTasks(firebaseTasks);

      // 4. 🔄 สร้าง real task ใน background
      _createRealTaskInBackground(
        tempId,
        titleToSave,
        descriptionToSave,
        userEmail,
        dueDate,
        userId,
        tempTask,
        appData,
      );
    }
  }

  Future<void> _createRealTaskInBackground(
    int tempId,
    String titleToSave,
    String descriptionToSave,
    String userEmail,
    DateTime dueDate,
    int userId,
    model.Task tempTask,
    dynamic appData,
  ) async {
    // เรียก API สร้าง real task
    final success = await _createTaskAPI(
      titleToSave,
      descriptionToSave,
      userEmail,
      dueDate,
    );

    if (success['success']) {
      final realTaskId = success['taskId'];
      final notificationID = success['notificationID'];

      await _replaceWithRealTaskFirebase(
        tempId,
        realTaskId,
        notificationID,
        tempTask,
        dueDate,
        appData,
      );
    }
  }

  Future<void> _replaceWithRealTaskFirebase(
    int tempId,
    int realTaskId,
    int notificationID,
    model.Task tempTask,
    DateTime dueDate,
    dynamic appData,
  ) async {
    // 1. ลบ temp task ทันที เพื่อป้องกัน duplicate
    if (mounted && tempTasks.containsKey(tempId)) {
      _updateDisplayTasks(firebaseTasks); // รีเฟรช UI ทันที
      tempTasks.remove(tempId);
    }

    final realTask = model.Task(
      taskName: tempTask.taskName,
      description: tempTask.description,
      createdAt: DateTime.now().toIso8601String(),
      priority: tempTask.priority,
      status: '0',
      attachments: [],
      checklists: [],
      createBy: tempTask.createBy,
      taskId: realTaskId,
      assigned: [],
      boardId: appData.boardDatas.idBoard.toString(),
      notifications: [
        model.Notification(
          createdAt: DateTime.now().toIso8601String(),
          dueDate: dueDate.toUtc().toIso8601String(),
          isSend: dueDate.isAfter(DateTime.now()) ? false : true,
          notificationId: notificationID,
          recurringPattern: (selectedRepeat ?? 'Onetime').toLowerCase(),
          taskId: realTaskId,
        ),
      ],
    );

    // 2. สร้าง Firebase document ด้วย real ID
    await FirebaseFirestore.instance
        .collection('Boards')
        .doc(appData.boardDatas.idBoard)
        .collection('Tasks')
        .doc(realTaskId.toString())
        .set({
          'boardID': int.parse(appData.boardDatas.idBoard),
          'createAt': Timestamp.now(),
          'createBy': tempTask.createBy,
          'description': tempTask.description,
          'priority': tempTask.priority,
          'status': tempTask.status,
          'taskID': realTaskId,
          'taskName': tempTask.taskName,
          'updatedAt': Timestamp.now(),
        });

    // 3. รอให้ Firebase document ถูกสร้าง
    await _waitForDocumentCreation(realTaskId, notificationID, true);

    // 4. ตั้งค่า notifications เบื้องหลัง
    await _setupTaskNotifications(realTaskId, notificationID, dueDate, appData);
    await _updateLocalStorage(realTask, tempIdToRemove: tempId.toString());

    // 5. ✅ ลบ creating state เมื่อทำเสร็จแล้ว
    if (mounted) {
      setState(() {
        creatingTasks.remove(tempId.toString());
        isCreatingTask = creatingTasks.isNotEmpty;
        customReminderDateTime = null;
        selectedReminder = null;
        selectedPriority = null;
        isShowMenuPriority = false;
        isShowMenuRemind = false;
        isCustomReminderApplied = false;
        selectedBeforeMinutes = null;
        selectedRepeat = 'Onetime';
      });
    }
  }

  Future<void> _setupTaskNotifications(
    int realTaskId,
    int notificationID,
    DateTime dueDate,
    dynamic appData,
  ) async {
    // อัปเดต isShow
    await FirebaseFirestore.instance
        .collection('BoardTasks')
        .doc(realTaskId.toString())
        .collection('Notifications')
        .doc(notificationID.toString())
        .update({
          'isShow': dueDate.isAfter(DateTime.now())
              ? false
              : FieldValue.delete(),
        });

    // ตั้งค่า reminder notification
    if (isValidNotificationTime(dueDate, selectedBeforeMinutes)) {
      DateTime notificationDateTime = calculateNotificationTime(
        dueDate,
        selectedBeforeMinutes,
      );
      await FirebaseFirestore.instance
          .collection('BoardTasks')
          .doc(realTaskId.toString())
          .collection('Notifications')
          .doc(notificationID.toString())
          .update({
            'isNotiRemind': false,
            'remindMeBefore': selectedBeforeMinutes == null
                ? FieldValue.delete()
                : notificationDateTime,
          });
    }

    // ตั้งค่า user notifications
    var boardUsersSnapshot = await FirebaseFirestore.instance
        .collection('Boards')
        .doc(appData.boardDatas.idBoard)
        .collection('BoardUsers')
        .get();

    for (var boardUsersDoc in boardUsersSnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('BoardTasks')
          .doc(realTaskId.toString())
          .collection('Notifications')
          .doc(notificationID.toString())
          .update({
            'userNotifications.${boardUsersDoc['UserID']}': {
              'isShow': false,
              'isNotiRemindShow': false,
            },
          });
    }
  }

  Future<Map<String, dynamic>> _createTaskAPI(
    String title,
    String description,
    String email,
    DateTime dueDate,
  ) async {
    url = await loadAPIEndpoint();
    final appData = Provider.of<Appdata>(context, listen: false);

    var responseCreate = await http.post(
      Uri.parse("$url/task"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: boardTasksCreatePostRequestToJson(
        BoardTasksCreatePostRequest(
          boardId: int.parse(appData.boardDatas.idBoard),
          taskName: title,
          description: description,
          status: '0',
          priority: selectedPriority == null ? '' : selectedPriority.toString(),
          reminder: Reminder(
            dueDate: dueDate.toUtc().toIso8601String(),
            recurringPattern: (selectedRepeat ?? 'Onetime').toLowerCase(),
          ),
        ),
      ),
    );

    if (responseCreate.statusCode == 403) {
      await loadNewRefreshToken();
      responseCreate = await http.post(
        Uri.parse("$url/task"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: boardTasksCreatePostRequestToJson(
          BoardTasksCreatePostRequest(
            boardId: int.parse(appData.boardDatas.idBoard),
            taskName: title,
            description: description,
            status: '0',
            priority: selectedPriority == null
                ? ''
                : selectedPriority.toString(),
            reminder: Reminder(
              dueDate: dueDate.toUtc().toIso8601String(),
              recurringPattern: (selectedRepeat ?? 'Onetime').toLowerCase(),
            ),
          ),
        ),
      );
    }

    if (responseCreate.statusCode == 201) {
      final responseData = jsonDecode(responseCreate.body);
      return {
        'success': true,
        'taskId': responseData['taskID'],
        'notificationID': responseData['notificationID'],
      };
    } else {
      return {
        'success': false,
        'error': 'Server error: ${responseCreate.statusCode}',
      };
    }
  }

  Future<void> _replaceWithRealTask(
    String tempId,
    int notificationID,
    int realId,
    model.Task tempTask,
    int userId,
    DateTime dueDate,
  ) async {
    if (!mounted) return;

    final appData = Provider.of<Appdata>(context, listen: false);
    // model แสดง task จริงหาก taskId,notificationID ได้รับจาก api
    final realTask = model.Task(
      taskName: tempTask.taskName,
      description: tempTask.description,
      createdAt: DateTime.now().toIso8601String(),
      priority: tempTask.priority,
      status: '0',
      attachments: [],
      checklists: [],
      createBy: userId,
      taskId: realId,
      assigned: [],
      boardId: appData.boardDatas.idBoard.toString(),
      notifications: [
        model.Notification(
          createdAt: DateTime.now().toIso8601String(),
          dueDate: dueDate.toUtc().toIso8601String(),
          isSend: dueDate.isAfter(DateTime.now()) ? false : true,
          notificationId: notificationID,
          recurringPattern: (selectedRepeat ?? 'Onetime').toLowerCase(),
          taskId: realId,
        ),
      ],
    );

    await _waitForDocumentCreation(realId, notificationID, false);

    FirebaseFirestore.instance
        .collection('Notifications')
        .doc(box.read('userProfile')['email'])
        .collection('Tasks')
        .doc(notificationID.toString())
        .update({
          'isShow': dueDate.isAfter(DateTime.now())
              ? false
              : FieldValue.delete(),
        });

    if (isValidNotificationTime(dueDate, selectedBeforeMinutes)) {
      DateTime notificationDateTime = calculateNotificationTime(
        dueDate,
        selectedBeforeMinutes,
      );
      FirebaseFirestore.instance
          .collection('Notifications')
          .doc(box.read('userProfile')['email'])
          .collection('Tasks')
          .doc(notificationID.toString())
          .update({
            'isNotiRemind': false,
            'remindMeBefore': selectedBeforeMinutes == null
                ? FieldValue.delete()
                : notificationDateTime,
          });
    }

    appData.showMyTasks.removeTaskById(tempId);
    appData.showMyTasks.addTask(realTask);

    await _updateLocalStorage(realTask, tempIdToRemove: tempId);
    await loadDataAsync();

    if (mounted) {
      setState(() {
        creatingTasks.remove(tempId);
        isCreatingTask = creatingTasks.isNotEmpty;
      });
    }
  }

  // ฟังก์ชันรอให้ document ถูกสร้างก่อน
  Future<void> _waitForDocumentCreation(
    int realId,
    int notificationID,
    bool isGroup,
  ) async {
    int maxRetries = 10; // จำกัดจำนวนครั้งที่ลอง
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        DocumentSnapshot doc;
        if (isGroup) {
          doc = await FirebaseFirestore.instance
              .collection('BoardTasks')
              .doc(realId.toString())
              .collection('Notifications')
              .doc(notificationID.toString())
              .get();
        } else {
          doc = await FirebaseFirestore.instance
              .collection('Notifications')
              .doc(box.read('userProfile')['email'])
              .collection('Tasks')
              .doc(notificationID.toString())
              .get();
        }

        if (doc.exists) {
          // Document ถูกสร้างแล้ว สามารถทำงานต่อได้
          return;
        }

        // หาก document ยังไม่ถูกสร้าง รอ 500ms แล้วลองใหม่
        retryCount++;
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        // หากเกิดข้อผิดพลาด รอ 500ms แล้วลองใหม่
        retryCount++;
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
  }

  Future<void> _removeTempTask(String tempId) async {
    if (!mounted) return;

    final appData = Provider.of<Appdata>(context, listen: false);
    appData.showMyTasks.removeTaskById(tempId);

    if (mounted) {
      setState(() {
        creatingTasks.remove(tempId);
        isCreatingTask = creatingTasks.isNotEmpty;
      });

      await loadDataAsync();
    }

    final userDataJson = box.read('userDataAll');
    if (userDataJson != null) {
      final existingData = model.AllDataUserGetResponst.fromJson(userDataJson);
      existingData.tasks.removeWhere((t) => t.taskId.toString() == tempId);
      box.write('userDataAll', existingData.toJson());
    }
  }

  Future<void> _updateLocalStorage(
    model.Task task, {
    String? tempIdToRemove,
  }) async {
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    final existingData = model.AllDataUserGetResponst.fromJson(userDataJson);

    if (tempIdToRemove != null) {
      existingData.tasks.removeWhere(
        (t) => t.taskId.toString() == tempIdToRemove,
      );
    }

    existingData.tasks.add(task);
    box.write('userDataAll', existingData.toJson());
  }

  List<model.Task> sortTasks(List<model.Task> tasks, [SortType? newSortType]) {
    if (newSortType != null) {
      currentSortType = newSortType;
    }

    const priorityMap = {'3': 3, '2': 2, '1': 1};

    List<model.Task> sortedTasks = List.from(tasks);

    sortedTasks.sort((a, b) {
      //จัดรียง list ให้ถูกต้องก่อน
      bool aIsCreating = creatingTasks.containsKey(a.taskId.toString());
      bool bIsCreating = creatingTasks.containsKey(b.taskId.toString());

      int statusOrderA = a.status == '0' ? 0 : 1;
      int statusOrderB = b.status == '0' ? 0 : 1;

      if (statusOrderA != statusOrderB) {
        return statusOrderA.compareTo(statusOrderB);
      }

      //จัดเรียงให้อันที่ไม่ complete อยู่บน อัน complete อยู่ล่าง
      if (statusOrderA == 0) {
        if (aIsCreating && !bIsCreating) {
          return 1;
        } else if (!aIsCreating && bIsCreating) {
          return -1;
        }
      }

      switch (currentSortType) {
        case SortType.dateEarliestFirst:
          try {
            final dateA = DateTime.parse(a.createdAt);
            final dateB = DateTime.parse(b.createdAt);
            return dateA.compareTo(dateB);
          } catch (e) {
            return a.createdAt.compareTo(b.createdAt);
          }
        case SortType.dateLatestFirst:
          try {
            final dateA = DateTime.parse(a.createdAt);
            final dateB = DateTime.parse(b.createdAt);
            return dateB.compareTo(dateA);
          } catch (e) {
            return b.createdAt.compareTo(a.createdAt);
          }
        case SortType.titleAZ:
          return a.taskName.toLowerCase().compareTo(b.taskName.toLowerCase());
        case SortType.titleZA:
          return b.taskName.toLowerCase().compareTo(a.taskName.toLowerCase());
        case SortType.priorityHighToLow:
          final aPriority = priorityMap[a.priority] ?? 0;
          final bPriority = priorityMap[b.priority] ?? 0;
          return bPriority.compareTo(aPriority);
        case SortType.priorityLowToHigh:
          final aPriority = priorityMap[a.priority] ?? 0;
          final bPriority = priorityMap[b.priority] ?? 0;
          return aPriority.compareTo(bPriority);
      }
    });

    return sortedTasks;
  }

  //ฟังก์ชันเลื่อนแสดง task ที่ถูกทับ
  void _scrollToAddForm() {
    if (!mounted) return;

    final currentController = scrollControllers[currentViewIndex];
    if (currentController == null) return;

    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted && currentController.hasClients) {
        currentController.animateTo(
          currentController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted && currentController.hasClients) {
        currentController.animateTo(
          currentController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );

        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted && addFormKey.currentContext != null) {
            Scrollable.ensureVisible(
              addFormKey.currentContext!,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: 1.0,
            );
          }
        });
      }
    });
  }

  String formatDateDisplay(List<model.Notification> notifications) {
    if (notifications.isEmpty) return '';

    final now = DateTime.now();
    final dueDate = DateTime.parse(notifications.first.dueDate).toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    if (dueDateDay.isAtSameMomentAs(today)) {
      if (dueDate.isAfter(now)) {
        final hour = dueDate.hour.toString().padLeft(2, '0');
        final minute = dueDate.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }
      return '';
    }

    if (dueDateDay.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    }
    if (dueDateDay.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    }

    if (dueDateDay.isBefore(yesterday)) {
      final day = dueDate.day.toString().padLeft(2, '0');
      final month = dueDate.month.toString().padLeft(2, '0');
      final year = (dueDate.year % 100).toString().padLeft(2, '0');
      final hour = dueDate.hour.toString().padLeft(2, '0');
      final minute = dueDate.minute.toString().padLeft(2, '0');
      return '$day/$month/$year, $hour:$minute';
    }
    if (dueDateDay.isAfter(yesterday)) {
      final hour = dueDate.hour.toString().padLeft(2, '0');
      final minute = dueDate.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return '';
  }

  //ฟังก์ชันแสดง ui popup menu
  Widget buildPopupItem(
    BuildContext context, {
    required String title,
    Widget? trailing,
    Widget? trailing2,
    required VoidCallback onTap,
  }) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            title == 'Sort By' ||
                title == 'Select Task' ||
                title == 'Show Completed' ||
                title == 'Hide Completed'
            ? EdgeInsets.symmetric(horizontal: width * 0.02)
            : EdgeInsets.symmetric(horizontal: width * 0.04),
        width: width * 0.5,
        height: height * 0.05,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Get.textTheme.titleSmall!.fontSize!,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (trailing2 != null) trailing2,
                if (trailing2 != null)
                  Text(
                    currentSortType == SortType.dateEarliestFirst ||
                            currentSortType == SortType.dateLatestFirst
                        ? 'Due Date'
                        : currentSortType == SortType.titleAZ ||
                              currentSortType == SortType.titleZA
                        ? 'Title'
                        : 'Priority',
                    style: TextStyle(
                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void hideSortMenu() {
    sortMenuEntry?.remove();
    sortMenuEntry = null;
  }

  void hideMainMenu() {
    mainMenuEntry?.remove();
    mainMenuEntry = null;
  }

  void hideMenus() {
    hideSortMenu();
    hideMainMenu();
  }

  //ฟังก์ชันแสดง popup menu สามจุด
  void showPopupMenuOverlay(BuildContext context) {
    final RenderBox renderBox =
        iconKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    var height = MediaQuery.of(context).size.height;
    final appData = Provider.of<Appdata>(context, listen: false);

    mainMenuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: hideMenus,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left:
                offset.dx +
                size.width -
                (MediaQuery.of(context).size.width * 0.5),
            top: offset.dy + size.height,
            child: Material(
              elevation: 1,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildPopupItem(
                    context,
                    title: 'Select Task',
                    trailing: SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>',
                      height: height * 0.025,
                      fit: BoxFit.contain,
                    ),
                    onTap: () {
                      hideMenus();
                      setState(() {
                        addTask = false;
                        hideMenu = true;
                      });
                      if (appData.boardDatas.boardToken.isNotEmpty) {
                        String currentStatus = getCurrentStatus();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          pageController.jumpToPage(int.parse(currentStatus));
                        });
                      }
                    },
                  ),
                  buildPopupItem(
                    context,
                    title: 'Sort By',
                    trailing: SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M7 20h2V8h3L8 4 4 8h3zm13-4h-3V4h-2v12h-3l4 4z"></path></svg>',
                      height: height * 0.025,
                      fit: BoxFit.contain,
                    ),
                    trailing2: SvgPicture.string(
                      sortMenuEntry == null
                          ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>'
                          : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M16.293 9.293 12 13.586 7.707 9.293l-1.414 1.414L12 16.414l5.707-5.707z"></path></svg>',
                      height: height * 0.025,
                      fit: BoxFit.contain,
                    ),
                    onTap: () => showSortByOverlay(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(mainMenuEntry!);
  }

  //ฟังก์ชันแสดง popup menu Sort By
  void showSortByOverlay(BuildContext context) {
    if (sortMenuEntry != null) {
      hideSortMenu();
      return;
    }

    final RenderBox renderBox =
        iconKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    sortMenuEntry = OverlayEntry(
      builder: (context) => Positioned(
        left:
            offset.dx + size.width - (MediaQuery.of(context).size.width * 0.5),
        top:
            offset.dy +
            size.height +
            (MediaQuery.of(context).size.height * 0.1),
        child: Material(
          elevation: 1,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildPopupItem(
                context,
                title: 'Due Date',
                trailing:
                    currentSortType == SortType.dateEarliestFirst ||
                        currentSortType == SortType.dateLatestFirst
                    ? Text(
                        '${currentSortType == SortType.dateEarliestFirst ? 'Earliest' : 'Latest'} First',
                        style: TextStyle(
                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      )
                    : null,
                onTap: () {
                  final newSort = currentSortType == SortType.dateEarliestFirst
                      ? SortType.dateLatestFirst
                      : SortType.dateEarliestFirst;
                  sortTasks(tasks, newSort);
                  hideSortMenu();
                  loadDataAsync();
                },
              ),
              buildPopupItem(
                context,
                title: 'Title',
                trailing:
                    currentSortType == SortType.titleAZ ||
                        currentSortType == SortType.titleZA
                    ? Text(
                        currentSortType == SortType.titleAZ
                            ? 'Ascending'
                            : 'Descending',
                        style: TextStyle(
                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      )
                    : null,
                onTap: () {
                  final newSort = currentSortType == SortType.titleAZ
                      ? SortType.titleZA
                      : SortType.titleAZ;
                  sortTasks(tasks, newSort);
                  hideSortMenu();
                  loadDataAsync();
                },
              ),
              buildPopupItem(
                context,
                title: 'Priority',
                trailing:
                    currentSortType == SortType.priorityHighToLow ||
                        currentSortType == SortType.priorityLowToHigh
                    ? Text(
                        '${currentSortType == SortType.priorityHighToLow ? 'Highest' : 'Lowest'} First',
                        style: TextStyle(
                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      )
                    : null,
                onTap: () {
                  final newSort = currentSortType == SortType.priorityHighToLow
                      ? SortType.priorityLowToHigh
                      : SortType.priorityHighToLow;
                  sortTasks(tasks, newSort);
                  hideSortMenu();
                  loadDataAsync();
                },
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(sortMenuEntry!);
  }

  void _showSelectRemindMeBefore(
    BuildContext context,
    StateSetter parentSetState,
  ) {
    if (selectedBeforeMinutes == null) {
      setState(() {
        selectedBeforeMinutes = 0;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState1) {
            double height = MediaQuery.of(context).size.height;
            double width = MediaQuery.of(context).size.width;
            final options = getRemindMeBeforeOptions();

            return Padding(
              padding: EdgeInsets.only(
                top: height * 0.01,
                left: width * 0.05,
                right: width * 0.05,
              ),
              child: SizedBox(
                height: height * 0.4,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          child: Text(
                            "Back",
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize!,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          "Remind me before",
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize!,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: width * 0.15),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        mainAxisSpacing: height * 0.01,
                        crossAxisSpacing: width * 0.01,
                        childAspectRatio: 2.5,
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.02,
                          vertical: height * 0.01,
                        ),
                        physics: NeverScrollableScrollPhysics(),
                        children: options.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final data = entry.value;

                          return InkWell(
                            onTap: () {
                              setState1(() {
                                selectedBeforeMinutes = idx;
                              });

                              setState(() {
                                selectedBeforeMinutes = idx;
                              });

                              parentSetState(() {
                                selectedBeforeMinutes = idx;
                              });

                              Get.back();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    (selectedBeforeMinutes != null &&
                                        idx == selectedBeforeMinutes)
                                    ? Color(0xFF007AFF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                data['label'],
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      (selectedBeforeMinutes != null &&
                                          idx == selectedBeforeMinutes)
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (selectedBeforeMinutes == 0) {
        setState(() {
          selectedBeforeMinutes = null;
        });
        parentSetState(() {
          selectedBeforeMinutes = null;
        });
      } else {
        setState(() {});
        parentSetState(() {});
      }
    });
  }

  void _showCustomDateTimePicker(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime tempSelectedDate = now;
    TimeOfDay tempSelectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState1) {
            double height = MediaQuery.of(context).size.height;
            double width = MediaQuery.of(context).size.width;

            return WillPopScope(
              onWillPop: () async => false,
              child: SizedBox(
                height: height * 0.94,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: height * 0.01,
                    left: width * 0.05,
                    right: width * 0.05,
                  ),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Get.back();
                                  setState(() {
                                    addTask = true;
                                    selectedBeforeMinutes = null;
                                    selectedReminder = null;
                                    customReminderDateTime = null;
                                    isShowMenuRemind = false;
                                    isCustomReminderApplied = false;
                                  });
                                  addTasknameFocusNode.requestFocus();
                                  Future.delayed(
                                    Duration(microseconds: 300),
                                    () {
                                      _scrollToAddForm();
                                    },
                                  );
                                },
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize!,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              Text(
                                "Custom Date & Time",
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.titleMedium!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  final selectedDateTime = DateTime(
                                    tempSelectedDate.year,
                                    tempSelectedDate.month,
                                    tempSelectedDate.day,
                                    tempSelectedTime.hour,
                                    tempSelectedTime.minute,
                                  );

                                  setState(() {
                                    selectedReminder =
                                        'Custom: ${DateFormat('MMM dd, yyyy HH:mm').format(selectedDateTime)}';
                                    customReminderDateTime = selectedDateTime;
                                    isCustomReminderApplied = false;
                                    isShowMenuRemind = true;
                                    addTask = true;
                                  });
                                  addTasknameFocusNode.requestFocus();
                                  Future.delayed(
                                    Duration(microseconds: 300),
                                    () {
                                      _scrollToAddForm();
                                    },
                                  );
                                  Get.back();
                                },
                                child: Text(
                                  'Apply',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize!,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4790EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Date:",
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize!,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Color(0xFF4790EB),
                                  ),
                                  textTheme: TextTheme(
                                    bodySmall: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  height: height * 0.35,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Material(
                                      color: Colors.black12,
                                      child: CalendarDatePicker(
                                        initialDate: tempSelectedDate,
                                        firstDate: DateTime.now().subtract(
                                          Duration(days: 365),
                                        ),
                                        lastDate: DateTime.now().add(
                                          Duration(days: 365 * 5),
                                        ),
                                        onDateChanged: (date) {
                                          setState1(() {
                                            tempSelectedDate = date;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              Row(
                                children: [
                                  Text(
                                    "Time:",
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize!,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: height * 0.16,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.time,
                                  initialDateTime: DateTime(
                                    tempSelectedDate.year,
                                    tempSelectedDate.month,
                                    tempSelectedDate.day,
                                    tempSelectedTime.hour,
                                    tempSelectedTime.minute,
                                  ),
                                  use24hFormat: true,
                                  onDateTimeChanged: (DateTime dateTime) {
                                    setState1(() {
                                      tempSelectedTime = TimeOfDay.fromDateTime(
                                        dateTime,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          InkWell(
                            onTap: () {
                              _showSelectRemindMeBefore(context, setState1);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.02,
                                vertical: height * 0.005,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 4c-4.879 0-9 4.121-9 9s4.121 9 9 9 9-4.121 9-9-4.121-9-9-9zm0 16c-3.794 0-7-3.206-7-7s3.206-7 7-7 7 3.206 7 7-3.206 7-7 7z"></path><path d="M13 12V8h-2v6h6v-2zm4.284-8.293 1.412-1.416 3.01 3-1.413 1.417zm-10.586 0-2.99 2.999L2.29 5.294l2.99-3z"></path></svg>',
                                        color: selectedBeforeMinutes != null
                                            ? Color(0xFF007AFF)
                                            : Colors.black,
                                      ),
                                      SizedBox(width: width * 0.01),
                                      Text(
                                        "Remind me before",
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        getLabelFromIndex(
                                          selectedBeforeMinutes,
                                        ),
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black45,
                                        ),
                                      ),
                                      SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                        width: width * 0.03,
                                        height: height * 0.03,
                                        fit: BoxFit.contain,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          InkWell(
                            onTap: () {
                              _showSelectRepeat(context, setState1);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.02,
                                vertical: height * 0.005,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M19 7a1 1 0 0 0-1-1h-8v2h7v5h-3l3.969 5L22 13h-3V7zM5 17a1 1 0 0 0 1 1h8v-2H7v-5h3L6 6l-4 5h3v6z"></path></svg>',
                                        color: Colors.black,
                                      ),
                                      SizedBox(width: width * 0.01),
                                      Text(
                                        "Repeat",
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        selectedRepeat ?? 'Onetime',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black45,
                                        ),
                                      ),
                                      SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                        width: width * 0.03,
                                        height: height * 0.03,
                                        fit: BoxFit.contain,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSelectRepeat(BuildContext context, StateSetter parentSetState) {
    if (selectedRepeat == null) {
      setState(() {
        selectedRepeat = 'Onetime';
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState1) {
            double height = MediaQuery.of(context).size.height;
            double width = MediaQuery.of(context).size.width;
            final options = getRepeatOptions();

            return Padding(
              padding: EdgeInsets.only(
                top: height * 0.01,
                left: width * 0.05,
                right: width * 0.05,
              ),
              child: SizedBox(
                height: height * 0.4,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          child: Text(
                            "Back",
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize!,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          "Repeat",
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize!,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: width * 0.15),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 1,
                        mainAxisSpacing: height * 0.005,
                        crossAxisSpacing: width * 0.01,
                        childAspectRatio: 8.5,
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.02,
                          vertical: height * 0.01,
                        ),
                        physics: NeverScrollableScrollPhysics(),
                        children: options.map((data) {
                          return InkWell(
                            onTap: () {
                              setState1(() {
                                selectedRepeat = data;
                              });

                              setState(() {
                                selectedRepeat = data;
                              });

                              parentSetState(() {
                                selectedRepeat = data;
                              });

                              Get.back();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.only(left: width * 0.02),
                              decoration: BoxDecoration(
                                color:
                                    (selectedRepeat != null &&
                                        data == selectedRepeat)
                                    ? Color(0xFF007AFF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                data,
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      (selectedRepeat != null &&
                                          data == selectedRepeat)
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (selectedRepeat == 'Onetime') {
        setState(() {
          selectedRepeat = 'Onetime';
        });
        parentSetState(() {
          selectedRepeat = 'Onetime';
        });
      } else {
        setState(() {});
        parentSetState(() {});
      }
    });
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
                fontSize: Get.textTheme.titleMedium!.fontSize!,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
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
      final newDataJson = model.allDataUserGetResponstFromJson(response.body);

      box.write('userDataAll', newDataJson.toJson());
    }
  }
}

enum SortType {
  dateEarliestFirst,
  dateLatestFirst,
  titleAZ,
  titleZA,
  priorityHighToLow,
  priorityLowToHigh,
}
