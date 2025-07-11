import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/todayTasksCreatePostRequest.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart'
    as model;
import 'package:mydayplanner/shared/appData.dart';
import 'package:mydayplanner/splash.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => TodayPageState();
}

class TodayPageState extends State<TodayPage> with WidgetsBindingObserver {
  // 📦 Storage
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FlutterSecureStorage storage = FlutterSecureStorage();
  var box = GetStorage();

  // 🧠 Late Variables
  late String url;
  String? selectedReminder;
  DateTime? customReminderDateTime;

  OverlayEntry? mainMenuEntry;
  OverlayEntry? sortMenuEntry;

  // 📋 Global Keys
  final GlobalKey addFormKey = GlobalKey();
  final GlobalKey iconKey = GlobalKey();

  // 📥 Text Editing Controllers
  final TextEditingController addTasknameCtl = TextEditingController();
  final TextEditingController addDescriptionCtl = TextEditingController();

  // 🧠 Focus Nodes
  final FocusNode addTasknameFocusNode = FocusNode();
  final FocusNode addDescriptionFocusNode = FocusNode();

  // 🧾 Scroll Controller
  final ScrollController scrollController = ScrollController();

  // 🔘 Boolean Variables
  bool isTyping = false;
  bool addToday = false;
  bool hideMenu = false;
  bool isKeyboardVisible = false;
  bool wasKeyboardOpen = false;
  bool showArchived = false;
  bool isFinishing = false;
  bool isCreatingTask = false;
  bool isShowMenuRemind = false;
  bool isShowMenuPriority = false;
  bool isCustomReminderApplied = false;

  // 🔢 Integer Variables
  int itemCount = 1;
  int? selectedPriority;
  int? selectedBeforeMinutes;
  String? selectedRepeat;

  // 🕒 Timer
  Timer? _timer;
  Timer? timer2;
  Timer? debounceTimer;

  // 📋 Lists
  List<model.Task> tasks = [];
  List<String> selectedTaskIds = [];
  List<String> selectedIsArchived = [];
  Map<String, bool> creatingTasks = {};

  SortType currentSortType = SortType.dateEarliestFirst;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    loadDataAsync();
    timer2 = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) loadDataAsync();
    });

    addTasknameFocusNode.addListener(() {
      if (addTasknameFocusNode.hasFocus && addToday) {
        Future.delayed(Duration(milliseconds: 200), () {
          _scrollToAddForm();
        });
      }
    });

    addDescriptionFocusNode.addListener(() {
      if (addDescriptionFocusNode.hasFocus && addToday) {
        _scrollToAddForm();
      }
    });
  }

  Future<void> loadDataAsync() async {
    if (!mounted) return;

    final rawData = box.read('userDataAll'); //อ่านจาก storage
    //แปลง model
    final tasksData = model.AllDataUserGetResponst.fromJson(rawData);
    //เรียก provider
    final appData = Provider.of<Appdata>(context, listen: false);

    //เก็บ filtertask ไว้ก่อน
    List<model.Task> filteredTasks =
        tasksData.tasks
            .where((task) => task.boardId == "Today") //เลือกเอาเฉพาะ today
            .where(
              (task) =>
                  showArchived //เลือกแสดงเอาเฉพาะ complete || ไม่ complete
                      ? (task.status == '0' || task.status == '2')
                      : task.status == '0',
            )
            .where((task) {
              //เก็บมาแสดงเฉพาะวันนี้เท่านั้น
              final now = DateTime.now();
              final todayStart =
                  DateTime(now.year, now.month, now.day).toLocal();
              final todayEnd = todayStart.add(const Duration(days: 1));
              final dueDate =
                  DateTime.parse(task.notifications.first.dueDate).toLocal();

              return dueDate.isBefore(todayEnd) && todayEnd.isAfter(todayStart);
            })
            .toList();

    filteredTasks = sortTasks(filteredTasks); //เอา filtertask ที่ได้ไป sort
    appData.showMyTasks.setTasks(filteredTasks); //บันทึกลง provider

    setState(() {
      tasks = filteredTasks; //แสดง ui
    });
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
          addToday = false;
        });
        _saveData(addTasknameCtl.text, addDescriptionCtl.text);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    addTasknameCtl.dispose();
    addDescriptionCtl.dispose();
    scrollController.dispose();
    addTasknameFocusNode.dispose();
    addDescriptionFocusNode.dispose();
    _timer?.cancel();
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
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        if (hideMenu) {
          setState(() {
            addToday = true;
          });
        }
        setState(() {
          addToday = !addToday;
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
                    addToday = false;
                  });
                  _saveData(addTasknameCtl.text, addDescriptionCtl.text);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          !hideMenu
                              ? Text(
                                'Today',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.headlineMedium!.fontSize! *
                                      MediaQuery.of(context).textScaleFactor,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                              : Text(
                                selectedTaskIds.isNotEmpty
                                    ? '${selectedTaskIds.length} Selected'
                                    : 'Select Task',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.headlineMedium!.fontSize! *
                                      MediaQuery.of(context).textScaleFactor,
                                  fontWeight: FontWeight.w500,
                                ),
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
                              if (hideMenu || addToday)
                                TextButton(
                                  onPressed:
                                      hideMenu
                                          ? () {
                                            setState(() {
                                              selectedTaskIds.clear();
                                              hideMenu = false;
                                            });

                                            if (showArchived) {
                                              setState(() {
                                                showArchived = true;
                                              });
                                              loadDataAsync();
                                            }
                                          }
                                          : () {
                                            setState(() {
                                              addToday = false;
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
                                          Get.textTheme.titleMedium!.fontSize! *
                                          MediaQuery.of(
                                            context,
                                          ).textScaleFactor,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF007AFF),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          !hideMenu
                              ? Text(
                                getCurrentDayAndDate(),
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.titleMedium!.fontSize! *
                                      MediaQuery.of(context).textScaleFactor,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                              : selectedTaskIds.isNotEmpty || tasks.isNotEmpty
                              ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (selectedTaskIds.length ==
                                        tasks.length) {
                                      selectedTaskIds.clear();
                                    } else {
                                      selectedTaskIds =
                                          tasks
                                              .map(
                                                (task) =>
                                                    task.taskId.toString(),
                                              )
                                              .toList();
                                    }
                                  });
                                },
                                child: Row(
                                  children: [
                                    SvgPicture.string(
                                      selectedTaskIds.length == tasks.length
                                          ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>'
                                          : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                      height: height * 0.04,
                                      fit: BoxFit.contain,
                                      color:
                                          selectedTaskIds.length == tasks.length
                                              ? Color(0xFF007AFF)
                                              : Colors.grey,
                                    ),
                                    SizedBox(width: width * 0.01),
                                    Text(
                                      'Select All',
                                      style: TextStyle(
                                        fontSize:
                                            Get
                                                .textTheme
                                                .titleMedium!
                                                .fontSize! *
                                            MediaQuery.of(
                                              context,
                                            ).textScaleFactor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : SizedBox.shrink(),
                          Text(
                            !showArchived
                                ? '${tasks.length} tasks'
                                : '${tasks.length} tasks, ${tasks.where((t) => t.boardId == "Today").where((task) => task.status == "2").length} Completed',
                            style: TextStyle(
                              fontSize:
                                  Get.textTheme.titleSmall!.fontSize! *
                                  MediaQuery.of(context).textScaleFactor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: height * 0.01),
              Expanded(
                child: Container(
                  color: Color(0xFFF2F2F6),
                  child:
                      tasks.isEmpty
                          ? Center(
                            child: Text(
                              'No tasks for today',
                              style: TextStyle(
                                fontSize:
                                    Get.textTheme.titleMedium!.fontSize! *
                                    MediaQuery.of(context).textScaleFactor,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                          : SingleChildScrollView(
                            controller: scrollController,
                            child: Column(
                              children: [
                                ...sortTasks(tasks).map((data) {
                                  return TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: Duration(milliseconds: 400),
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
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: width * 0.03,
                                        right: width * 0.03,
                                        top: height * 0.005,
                                      ),
                                      child: Material(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          onTap:
                                              hideMenu
                                                  ? () {
                                                    if (selectedTaskIds
                                                        .contains(
                                                          data.taskId
                                                              .toString(),
                                                        )) {
                                                      selectedTaskIds.remove(
                                                        data.taskId.toString(),
                                                      );
                                                    } else {
                                                      selectedTaskIds.add(
                                                        data.taskId.toString(),
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
                                                    BorderRadius.circular(8),
                                              ),
                                              alignment: Alignment.centerRight,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.02,
                                              ),
                                              child: Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                            ),
                                            confirmDismiss: (direction) async {
                                              return true;
                                            },
                                            onDismissed: (direction) {
                                              setState(() {
                                                tasks.removeWhere(
                                                  (t) =>
                                                      t.taskId == data.taskId,
                                                );
                                              });
                                              deleteTaskById(
                                                data.taskId.toString(),
                                                false,
                                              );
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.01,
                                                vertical: height * 0.002,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    selectedTaskIds.contains(
                                                          data.taskId
                                                              .toString(),
                                                        )
                                                        ? Colors.black12
                                                        : data.status == "2" &&
                                                            hideMenu
                                                        ? Colors.grey[100]
                                                        : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        !hideMenu
                                                            ? CrossAxisAlignment
                                                                .start
                                                            : CrossAxisAlignment
                                                                .center,
                                                    children: [
                                                      GestureDetector(
                                                        onTap:
                                                            !hideMenu
                                                                ? () =>
                                                                    handleTaskTap(
                                                                      data,
                                                                    )
                                                                : null,
                                                        child:
                                                            !hideMenu
                                                                ? SvgPicture.string(
                                                                  selectedIsArchived.contains(
                                                                        data.taskId
                                                                            .toString(),
                                                                      )
                                                                      ? '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-292q78.47 0 133.23-54.77Q668-401.53 668-480t-54.77-133.23Q558.47-668 480-668t-133.23 54.77Q292-558.47 292-480t54.77 133.23Q401.53-292 480-292Zm.13 204q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>'
                                                                      : data.status ==
                                                                          "2"
                                                                      ? '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-292q78.47 0 133.23-54.77Q668-401.53 668-480t-54.77-133.23Q558.47-668 480-668t-133.23 54.77Q292-558.47 292-480t54.77 133.23Q401.53-292 480-292Zm.13 204q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>'
                                                                      : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                                                  height:
                                                                      height *
                                                                      0.04,
                                                                  fit:
                                                                      BoxFit
                                                                          .contain,
                                                                  color:
                                                                      creatingTasks[data.taskId.toString()] ==
                                                                              true
                                                                          ? Colors
                                                                              .grey[300]
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
                                                                        data.taskId
                                                                            .toString(),
                                                                      )
                                                                      ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>'
                                                                      : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                                                  height:
                                                                      height *
                                                                      0.04,
                                                                  fit:
                                                                      BoxFit
                                                                          .contain,
                                                                  color:
                                                                      selectedTaskIds.contains(
                                                                            data.taskId.toString(),
                                                                          )
                                                                          ? Color(
                                                                            0xFF007AFF,
                                                                          )
                                                                          : Colors
                                                                              .grey,
                                                                ),
                                                      ),
                                                      SizedBox(
                                                        width: width * 0.01,
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        height *
                                                                        0.005,
                                                                  ),
                                                              child: InkWell(
                                                                onTap:
                                                                    !hideMenu
                                                                        ? creatingTasks[data.taskId.toString()] ==
                                                                                true
                                                                            ? () {
                                                                              log(
                                                                                "สร้างยังไม่เสร็จ",
                                                                              );
                                                                            }
                                                                            : () {
                                                                              if (!hideMenu) {
                                                                                setState(
                                                                                  () {
                                                                                    hideMenu =
                                                                                        false;
                                                                                    addToday =
                                                                                        false;
                                                                                  },
                                                                                );
                                                                              }
                                                                              log(
                                                                                "เรียบร้อยกับยูเซอร์น่าโง่",
                                                                              );
                                                                            }
                                                                        : null,
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Expanded(
                                                                      child: Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              Expanded(
                                                                                child: Text(
                                                                                  data.taskName,
                                                                                  style: TextStyle(
                                                                                    fontSize:
                                                                                        Get.textTheme.titleMedium!.fontSize! *
                                                                                        MediaQuery.of(
                                                                                          context,
                                                                                        ).textScaleFactor,
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
                                                                                  overflow:
                                                                                      TextOverflow.ellipsis,
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
                                                                                        shape:
                                                                                            BoxShape.circle,
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
                                                                                  fontSize:
                                                                                      Get.textTheme.labelMedium!.fontSize! *
                                                                                      MediaQuery.of(
                                                                                        context,
                                                                                      ).textScaleFactor,
                                                                                  color:
                                                                                      Colors.grey,
                                                                                ),
                                                                                maxLines:
                                                                                    6,
                                                                                overflow:
                                                                                    TextOverflow.ellipsis,
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
                                                                                        width:
                                                                                            0.5,
                                                                                        color:
                                                                                            Colors.red,
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
                                                                                          fit:
                                                                                              BoxFit.contain,
                                                                                          color:
                                                                                              Colors.red,
                                                                                        ),
                                                                                        Text(
                                                                                          " Due ",
                                                                                          style: TextStyle(
                                                                                            fontSize:
                                                                                                Get.textTheme.labelMedium!.fontSize! *
                                                                                                MediaQuery.of(
                                                                                                  context,
                                                                                                ).textScaleFactor,
                                                                                            color:
                                                                                                Colors.red,
                                                                                          ),
                                                                                        ),
                                                                                        Text(
                                                                                          formatDateDisplay(
                                                                                            data.notifications,
                                                                                          ),
                                                                                          style: TextStyle(
                                                                                            fontSize:
                                                                                                Get.textTheme.labelMedium!.fontSize! *
                                                                                                MediaQuery.of(
                                                                                                  context,
                                                                                                ).textScaleFactor,
                                                                                            color:
                                                                                                Colors.red,
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                              FutureBuilder<
                                                                                String
                                                                              >(
                                                                                future: showTimeRemineMeBefore(
                                                                                  data.taskId,
                                                                                ),
                                                                                builder: (
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
                                                                                            fit:
                                                                                                BoxFit.contain,
                                                                                            color:
                                                                                                Colors.red,
                                                                                          ),
                                                                                        ),
                                                                                        Text(
                                                                                          snapshot.data!,
                                                                                          style: TextStyle(
                                                                                            fontSize:
                                                                                                Get.textTheme.labelMedium!.fontSize! *
                                                                                                MediaQuery.of(
                                                                                                  context,
                                                                                                ).textScaleFactor,
                                                                                            color:
                                                                                                Colors.red,
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
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                ),
              ),
              if (addToday)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      addToday = true;
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
                                        Get.textTheme.titleSmall!.fontSize! *
                                        MediaQuery.of(context).textScaleFactor,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: isTyping ? '' : 'Add title',
                                    hintStyle: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize! *
                                          MediaQuery.of(
                                            context,
                                          ).textScaleFactor,
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
                                  fontSize:
                                      Get.textTheme.titleSmall!.fontSize! *
                                      MediaQuery.of(context).textScaleFactor,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: isTyping ? '' : 'Add Description',
                                  hintStyle: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleSmall!.fontSize! *
                                        MediaQuery.of(context).textScaleFactor,
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
                                  fontSize:
                                      Get.textTheme.titleSmall!.fontSize! *
                                      MediaQuery.of(context).textScaleFactor,
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
              if (addToday) Divider(thickness: 1, height: 0),
              if (addToday)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      addToday = true;
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
                                        selectedReminder =
                                            isSelected ? null : select;
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
                                        color:
                                            isSelected
                                                ? Color(0xFF007AFF)
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        select,
                                        style: TextStyle(
                                          fontSize:
                                              Get
                                                  .textTheme
                                                  .titleSmall!
                                                  .fontSize! *
                                              MediaQuery.of(
                                                context,
                                              ).textScaleFactor,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              isSelected
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
                                      color:
                                          customReminderDateTime != null
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
                                            Get
                                                .textTheme
                                                .titleSmall!
                                                .fontSize! *
                                            MediaQuery.of(
                                              context,
                                            ).textScaleFactor,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            (selectedReminder != null &&
                                                    selectedReminder!
                                                        .startsWith('Custom:'))
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
                            children:
                                selectPriority().map((select) {
                                  bool isSelected = selectedPriority == select;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedPriority =
                                            isSelected ? null : select;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.02,
                                        vertical: height * 0.005,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            select == 1 && isSelected
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
                                              Get
                                                  .textTheme
                                                  .titleSmall!
                                                  .fontSize! *
                                              MediaQuery.of(
                                                context,
                                              ).textScaleFactor,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              isSelected
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
                                              fontSize:
                                                  Get
                                                      .textTheme
                                                      .labelMedium!
                                                      .fontSize! *
                                                  MediaQuery.of(
                                                    context,
                                                  ).textScaleFactor,
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
                                            color:
                                                selectedPriority == 1
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
                                              fontSize:
                                                  Get
                                                      .textTheme
                                                      .labelMedium!
                                                      .fontSize! *
                                                  MediaQuery.of(
                                                    context,
                                                  ).textScaleFactor,
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
              if (!addToday && !hideMenu)
                Container(
                  color: Color(0xFFF2F2F6),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: height * 0.02,
                      right: width * 0.05,
                      bottom: height * 0.02,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              addToday = !addToday;
                            });
                            if (addToday) {
                              Future.delayed(Duration(milliseconds: 100), () {
                                addTasknameFocusNode.requestFocus();
                              });
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
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize! *
                                        MediaQuery.of(context).textScaleFactor,
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
                ),
              if (hideMenu)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: height * 0.01),
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
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap:
                                selectedTaskIds.isNotEmpty
                                    ? () async {
                                      setState(() {
                                        hideMenu = false;
                                      });
                                      deleteTaskById(selectedTaskIds, true);
                                      selectedTaskIds.clear();
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
                                color:
                                    selectedTaskIds.isNotEmpty
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
      ),
    );
  }

  Future<String> showTimeRemineMeBefore(int taskId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('Notifications')
            .doc(box.read('userProfile')['email'])
            .collection('Tasks')
            .where('taskID', isEqualTo: taskId)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final remindTimestamp = (data['remindMeBefore'] as Timestamp).toDate();

      if (remindTimestamp.isAfter(DateTime.now())) {
        return "${remindTimestamp.hour.toString().padLeft(2, '0')}:${remindTimestamp.minute.toString().padLeft(2, '0')}";
      }
    }
    return '';
  }

  //แสดง custom remind
  void _showCustomDateTimePicker(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime tempSelectedDate = now;
    TimeOfDay tempSelectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState1) {
            double height = MediaQuery.of(context).size.height;
            double width = MediaQuery.of(context).size.width;

            return Padding(
              padding: EdgeInsets.only(
                top: height * 0.01,
                left: width * 0.05,
                right: width * 0.05,
              ),
              child: SizedBox(
                height: height * 0.94,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Get.back();
                              setState(() {
                                addToday = true;
                                selectedBeforeMinutes = null;
                                selectedReminder = null;
                                customReminderDateTime = null;
                                isShowMenuRemind = false;
                                isCustomReminderApplied = false;
                              });
                              addTasknameFocusNode.requestFocus();
                              Future.delayed(Duration(microseconds: 300), () {
                                _scrollToAddForm();
                              });
                            },
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize:
                                    Get.textTheme.titleMedium!.fontSize! *
                                    MediaQuery.of(context).textScaleFactor,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          Text(
                            "Custom Date & Time",
                            style: TextStyle(
                              fontSize:
                                  Get.textTheme.titleMedium!.fontSize! *
                                  MediaQuery.of(context).textScaleFactor,
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
                                addToday = true;
                              });
                              addTasknameFocusNode.requestFocus();
                              Future.delayed(Duration(microseconds: 300), () {
                                _scrollToAddForm();
                              });
                              Get.back();
                            },
                            child: Text(
                              'Apply',
                              style: TextStyle(
                                fontSize:
                                    Get.textTheme.titleMedium!.fontSize! *
                                    MediaQuery.of(context).textScaleFactor,
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
                                      Get.textTheme.titleMedium!.fontSize! *
                                      MediaQuery.of(context).textScaleFactor,
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
                                      Get.textTheme.titleMedium!.fontSize! *
                                      MediaQuery.of(context).textScaleFactor,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.string(
                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 4c-4.879 0-9 4.121-9 9s4.121 9 9 9 9-4.121 9-9-4.121-9-9-9zm0 16c-3.794 0-7-3.206-7-7s3.206-7 7-7 7 3.206 7 7-3.206 7-7 7z"></path><path d="M13 12V8h-2v6h6v-2zm4.284-8.293 1.412-1.416 3.01 3-1.413 1.417zm-10.586 0-2.99 2.999L2.29 5.294l2.99-3z"></path></svg>',
                                    color:
                                        selectedBeforeMinutes != null
                                            ? Color(0xFF007AFF)
                                            : Colors.black,
                                  ),
                                  SizedBox(width: width * 0.01),
                                  Text(
                                    "Remind me before",
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize! *
                                          MediaQuery.of(
                                            context,
                                          ).textScaleFactor,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    getLabelFromIndex(selectedBeforeMinutes),
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize! *
                                          MediaQuery.of(
                                            context,
                                          ).textScaleFactor,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize! *
                                          MediaQuery.of(
                                            context,
                                          ).textScaleFactor,
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
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize! *
                                          MediaQuery.of(
                                            context,
                                          ).textScaleFactor,
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
            );
          },
        );
      },
    );
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
                              fontSize:
                                  Get.textTheme.titleMedium!.fontSize! *
                                  MediaQuery.of(context).textScaleFactor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          "Remind me before",
                          style: TextStyle(
                            fontSize:
                                Get.textTheme.titleMedium!.fontSize! *
                                MediaQuery.of(context).textScaleFactor,
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
                        children:
                            options.asMap().entries.map((entry) {
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
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize! *
                                          MediaQuery.of(
                                            context,
                                          ).textScaleFactor,
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
                              fontSize:
                                  Get.textTheme.titleMedium!.fontSize! *
                                  MediaQuery.of(context).textScaleFactor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          "Repeat",
                          style: TextStyle(
                            fontSize:
                                Get.textTheme.titleMedium!.fontSize! *
                                MediaQuery.of(context).textScaleFactor,
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
                        children:
                            options.map((data) {
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
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize! *
                                          MediaQuery.of(
                                            context,
                                          ).textScaleFactor,
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

  // ฟังก์ชันตรวจสอบว่าเวลาแจ้งเตือนสมเหตุสมผลหรือไม่
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

  int getMinutesFromIndex(int? index) {
    if (index == null || index == 0) return 0; // Never

    final options = getRemindMeBeforeOptions();
    if (index >= 0 && index < options.length) {
      return options[index]['minutes'];
    }
    return 0;
  }

  // ฟังก์ชันสำหรับแปลง selectedBeforeMinutes เป็น label
  String getLabelFromIndex(int? index) {
    if (index == null) return 'Never';

    final options = getRemindMeBeforeOptions();
    if (index >= 0 && index < options.length) {
      return options[index]['label'];
    }
    return 'Never';
  }

  //เลือก remind
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

  List<String> selectRemind() {
    return ['3 hours later', 'This evening', 'Tomorrow'];
  }

  List<int> selectPriority() {
    return [1, 2, 3];
  }

  //การกด หรือ เลือกเพื่อเก็บ task
  void handleTaskTap(model.Task data) async {
    final taskId = data.taskId;
    setState(() => hideMenu = false);

    //หากกดเลือก task ที่เสร็จแล้ว
    if (data.status == "2") {
      await showArchiveTask(taskId.toString());
      return;
    }

    //กดเลือก task
    if (selectedIsArchived.contains(taskId.toString())) {
      selectedIsArchived.remove(taskId.toString());
    } else {
      selectedIsArchived.add(taskId.toString());
    }

    //หากกดแสดง complete แล้วกด complete task มันจะเก็บแบบรวดเร็ว
    if (showArchived && data.boardId != "Today") {
      await finishAllSelectedTasks();
      selectedIsArchived.clear();
      return;
    }

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
  }

  //sort task ตามชื่อจัดเรียงตาม SortType ที่กด
  List<model.Task> sortTasks(List<model.Task> tasks, [SortType? newSortType]) {
    Map<String, dynamic> currentData = Map<String, dynamic>.from(
      box.read('showDisplays2') ?? {},
    );

    late SortType sortType;
    //เก็บลง stoarge user ไว้ด้วยและนำมาใช้ทีหลัง
    if (newSortType != null) {
      sortType = newSortType;
      currentData['Sort by'] = sortType.name;
      box.write('showDisplays2', currentData);
    } else if (currentData['Sort by'] is String) {
      final saved = currentData['Sort by'] as String;
      sortType = SortType.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => SortType.dateEarliestFirst,
      );
    } else {
      sortType = SortType.dateEarliestFirst;
      currentData['Sort by'] = sortType.name;
      box.write('showDisplays2', currentData);
    }

    currentSortType = sortType;

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

      switch (sortType) {
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

  //method นี้ไว้วนหา idtask ก่อนไปเก็บ
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

  //complete today
  Future<void> todayTasksFinish(String id) async {
    if (!mounted) return;

    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = model.AllDataUserGetResponst.fromJson(userDataJson);
    final appData = Provider.of<Appdata>(context, listen: false);

    // หาตำแหน่งของ task ที่มี id ตรงกับที่ส่งมา
    final index = existingData.tasks.indexWhere(
      (t) => t.taskId.toString() == id,
    );
    if (index == -1) return; // ออกจากฟังก์ชัน ถ้าไม่เจอ task

    // เปลี่ยนสถานะของ task เป็นเสร็จสิ้น
    existingData.tasks[index].status = '2';
    box.write('userDataAll', existingData.toJson());

    if (!showArchived) {
      // ถ้าไม่ได้อยู่ในหน้า archived ให้ลบ task ออกจาก list ที่แสดงอยู่
      appData.showMyTasks.removeTaskById(id);
      tasks.removeWhere((t) => t.taskId.toString() == id);
    } else {
      await loadDataAsync(); // ถ้าอยู่ในหน้า archived โหลดข้อมูลใหม่
    }

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

  //แสดง task ที่เสร็จคล้ายๆ method todayTasksFinish
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

  //ลบ task ที่เลือก
  void deleteTaskById(dynamic ids, bool select) async {
    if (!mounted) return;

    dynamic taskIdPayload;
    List<String> idList;
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = model.AllDataUserGetResponst.fromJson(userDataJson);
    final appData = Provider.of<Appdata>(context, listen: false);

    // ตรวจสอบว่า ids เป็น String เดี่ยว หรือ List<String>
    if (ids is String) {
      idList = [ids]; // กรณีลบตัวเดียว
      taskIdPayload = ids;
    } else if (ids is List && ids.every((e) => e is String)) {
      idList = List<String>.from(ids); // กรณีลบหลายตัว
      taskIdPayload = idList;
    } else {
      throw ArgumentError("Invalid ids parameter");
    }

    // ลบ task ออกจาก list
    for (var id in idList) {
      appData.showMyTasks.removeTaskById(id);
      existingData.tasks.removeWhere((t) => t.taskId.toString() == id);
      tasks.removeWhere((t) => t.taskId.toString() == id);
    }
    box.write('userDataAll', existingData.toJson());

    if (mounted) setState(() {});

    // สร้าง endpoint และ body สำหรับเรียก API ลบ task
    final endpoint = select ? "deltask" : "deltask/$taskIdPayload";
    final requestBody = select ? {"task_id": taskIdPayload} : null;
    //ฟังก์ชันลบ
    await deleteWithRetry(endpoint, requestBody);
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

  // บันทึก task
  Future<void> _saveData(String value, String description) async {
    if (!mounted) return;
    final userProfile = box.read('userProfile');
    final userId = userProfile['userid'];
    final userEmail = userProfile['email'];
    if (userId == null || userEmail == null) return;

    //ตัวแปรควบคุมหากการ custom data&time หากมีการพิม taskName หรือ description ไว้แล้ว
    //มันจะยังไม่บันทึกจนกว่าออกจาก custom data&time และมากดปุ่ม save
    if (isCustomReminderApplied) return;

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

    //ทำ model การแสดง today temp ไว้แสดง
    final tempId = DateTime.now().millisecondsSinceEpoch;
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
      boardId: "Today",
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

    if (mounted) {
      final appData = Provider.of<Appdata>(context, listen: false);
      appData.showMyTasks.addTask(tempTask);

      setState(() {
        addToday = false;
        creatingTasks[tempId.toString()] = true;
        isCreatingTask = true;
        addTasknameCtl.clear();
        addDescriptionCtl.clear();
      });
    }

    //ฟังก์ชันอัพเดทลง storage
    await _updateLocalStorage(tempTask, isTemp: true);

    //เรียก api สร้าง task
    final success = await _createTaskAPI(
      titleToSave,
      descriptionToSave,
      userEmail,
      dueDate,
    );

    if (success['success']) {
      final realTaskId = success['taskId'];
      final notificationID = success['notificationID'];
      //ฟังก์ชัน replace เฉพาะ task จริงที่ได้รับ taskId,notificationID จาก api
      await _replaceWithRealTask(
        tempId.toString(),
        notificationID,
        realTaskId,
        tempTask,
        userId,
        dueDate,
      );
    } else {
      //หากเกิดข้อผิดพลาดให้ลบ TempTask ออก
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
  }

  Future<Map<String, dynamic>> _createTaskAPI(
    String title,
    String description,
    String email,
    DateTime dueDate,
  ) async {
    url = await loadAPIEndpoint();

    var responseCreate = await http.post(
      Uri.parse("$url/todaytasks/create"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: todayTasksCreatePostRequestToJson(
        TodayTasksCreatePostRequest(
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
        Uri.parse("$url/todaytasks/create"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: todayTasksCreatePostRequestToJson(
          TodayTasksCreatePostRequest(
            taskName: title,
            description: description,
            status: '0',
            priority:
                selectedPriority == null ? '' : selectedPriority.toString(),
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
      boardId: "Today",
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
    FirebaseFirestore.instance
        .collection('Notifications')
        .doc(box.read('userProfile')['email'])
        .collection('Tasks')
        .doc(notificationID.toString())
        .update({
          'isShow':
              dueDate.isAfter(DateTime.now()) ? false : FieldValue.delete(),
        });
    if (isValidNotificationTime(dueDate, selectedBeforeMinutes)) {
      DateTime notificationDateTime = calculateNotificationTime(
        dueDate,
        selectedBeforeMinutes,
      );
      if (selectedBeforeMinutes == null || selectedBeforeMinutes == 0) return;
      FirebaseFirestore.instance
          .collection('Notifications')
          .doc(box.read('userProfile')['email'])
          .collection('Tasks')
          .doc(notificationID.toString())
          .update({
            'isNotiRemind': false,
            'remindMeBefore': notificationDateTime,
          });
    }

    final appData = Provider.of<Appdata>(context, listen: false);
    appData.showMyTasks.removeTaskById(tempId);
    appData.showMyTasks.addTask(realTask);

    await _updateLocalStorage(realTask, isTemp: false, tempIdToRemove: tempId);
    await loadDataAsync();
    if (mounted) {
      creatingTasks.remove(tempId);
      isCreatingTask = creatingTasks.isNotEmpty;
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
    bool isTemp = false,
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

  //ฟังก์ชันเลื่อนแสดง task ที่ถูกทับ
  void _scrollToAddForm() {
    if (!mounted) return;

    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted && scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted && scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
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

  //ฟังก์ชันแสดงวันเวลาใต้แต่ละ task
  String formatDateDisplay(List<model.Notification> notifications) {
    if (notifications.isEmpty) return '';

    final now = DateTime.now();
    final dueDate = DateTime.parse(notifications.first.dueDate).toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final yesterday = today.subtract(const Duration(days: 1));

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

    if (dueDateDay.isBefore(yesterday)) {
      final day = dueDate.day.toString().padLeft(2, '0');
      final month = dueDate.month.toString().padLeft(2, '0');
      final year = (dueDate.year % 100).toString().padLeft(2, '0');
      return '$day/$month/$year';
    }

    return '';
  }

  String getCurrentDayAndDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d MMMM');
    return formatter.format(now);
  }

  //ฟังก์ชันแสดง custom date&time หากกด apply
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
                    fontSize:
                        Get.textTheme.titleSmall!.fontSize! *
                        MediaQuery.of(context).textScaleFactor,
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
                      fontSize:
                          Get.textTheme.labelMedium!.fontSize! *
                          MediaQuery.of(context).textScaleFactor,
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

    mainMenuEntry = OverlayEntry(
      builder:
          (context) => Stack(
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
                            addToday = false;
                            hideMenu = true;
                          });
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
                      buildPopupItem(
                        context,
                        title: '${showArchived ? 'Hide' : 'Show'} Completed',
                        trailing: SvgPicture.string(
                          showArchived
                              ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 19c.946 0 1.81-.103 2.598-.281l-1.757-1.757c-.273.021-.55.038-.841.038-5.351 0-7.424-3.846-7.926-5a8.642 8.642 0 0 1 1.508-2.297L4.184 8.305c-1.538 1.667-2.121 3.346-2.132 3.379a.994.994 0 0 0 0 .633C2.073 12.383 4.367 19 12 19zm0-14c-1.837 0-3.346.396-4.604.981L3.707 2.293 2.293 3.707l18 18 1.414-1.414-3.319-3.319c2.614-1.951 3.547-4.615 3.561-4.657a.994.994 0 0 0 0-.633C21.927 11.617 19.633 5 12 5zm4.972 10.558-2.28-2.28c.19-.39.308-.819.308-1.278 0-1.641-1.359-3-3-3-.459 0-.888.118-1.277.309L8.915 7.501A9.26 9.26 0 0 1 12 7c5.351 0 7.424 3.846 7.926 5-.302.692-1.166 2.342-2.954 3.558z"></path></svg>'
                              : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 9a3.02 3.02 0 0 0-3 3c0 1.642 1.358 3 3 3 1.641 0 3-1.358 3-3 0-1.641-1.359-3-3-3z"></path><path d="M12 5c-7.633 0-9.927 6.617-9.948 6.684L1.946 12l.105.316C2.073 12.383 4.367 19 12 19s9.927-6.617 9.948-6.684l.106-.316-.105-.316C21.927 11.617 19.633 5 12 5zm0 12c-5.351 0-7.424-3.846-7.926-5C4.578 10.842 6.652 7 12 7c5.351 0 7.424 3.846 7.926 5-.504 1.158-2.578 5-7.926 5z"></path></svg>',
                          height: height * 0.025,
                          fit: BoxFit.contain,
                        ),
                        onTap: () {
                          setState(() => showArchived = !showArchived);
                          hideMenus();
                          loadDataAsync();
                          _scrollToAddForm();
                        },
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
      builder:
          (context) => Positioned(
            left:
                offset.dx +
                size.width -
                (MediaQuery.of(context).size.width * 0.5),
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
                                fontSize:
                                    Get.textTheme.labelMedium!.fontSize! *
                                    MediaQuery.of(context).textScaleFactor,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            )
                            : null,
                    onTap: () {
                      final newSort =
                          currentSortType == SortType.dateEarliestFirst
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
                                fontSize:
                                    Get.textTheme.labelMedium!.fontSize! *
                                    MediaQuery.of(context).textScaleFactor,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            )
                            : null,
                    onTap: () {
                      final newSort =
                          currentSortType == SortType.titleAZ
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
                                fontSize:
                                    Get.textTheme.labelMedium!.fontSize! *
                                    MediaQuery.of(context).textScaleFactor,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            )
                            : null,
                    onTap: () {
                      final newSort =
                          currentSortType == SortType.priorityHighToLow
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

enum SortType {
  dateEarliestFirst,
  dateLatestFirst,
  titleAZ,
  titleZA,
  priorityHighToLow,
  priorityLowToHigh,
}
