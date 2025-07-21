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
import 'package:http/http.dart' as http;
import 'package:mydayplanner/pages/pageMember/detailBoards/tasksDetail.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:mydayplanner/splash.dart';
import 'package:provider/provider.dart';

class AlltasksPage extends StatefulWidget {
  const AlltasksPage({super.key});

  @override
  State<AlltasksPage> createState() => AlltasksPageState();
}

class AlltasksPageState extends State<AlltasksPage>
    with WidgetsBindingObserver {
  // 📦 Storage
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FlutterSecureStorage storage = FlutterSecureStorage();
  var box = GetStorage();
  final GlobalKey iconKey = GlobalKey();
  final ScrollController scrollController = ScrollController();
  late String url;

  Map<String, TextEditingController> addTasknameCtlMap = {};
  Map<String, TextEditingController> addDescriptionCtlMap = {};
  Map<String, FocusNode> addTasknameFocusNodeMap = {};
  Map<String, FocusNode> addDescriptionFocusNodeMap = {};
  String? focusedCategory;

  OverlayEntry? mainMenuEntry;
  String? selectedReminder;
  DateTime? customReminderDateTime;
  bool showArchived = false;
  Map<String, GlobalKey> addFormKeyMap = {};
  bool hideMenu = false;
  bool isShowMenuRemind = false;
  bool isFinishing = false;
  bool isKeyboardVisible = false;
  bool wasKeyboardOpen = false;
  bool addTask = false;
  bool isTyping = false;
  bool isCustomReminderApplied = false;
  List<String> selectedTaskIds = [];
  bool isCreatingTask = false;
  bool isShowMenuPriority = false;
  List<String> selectedIsArchived = [];
  int? selectedPriority;
  List<model.Task> tasks = [];
  int? selectedBeforeMinutes;
  String? selectedRepeat;
  Timer? debounceTimer;
  StreamSubscription<DocumentSnapshot>? boardSubscription;
  Timer? timer;
  bool isFirstSnapshot = true;
  Map<String, bool> creatingTasks = {};

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    loadDataAsync();
    timer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) loadDataAsync();
    });

    for (final category in getAllCategories()) {
      addTasknameCtlMap.putIfAbsent(category, () => TextEditingController());
      addDescriptionCtlMap.putIfAbsent(category, () => TextEditingController());
      addTasknameFocusNodeMap.putIfAbsent(category, () => FocusNode());
      addDescriptionFocusNodeMap.putIfAbsent(category, () => FocusNode());
      addFormKeyMap.putIfAbsent(category, () => GlobalKey());
      addTasknameFocusNodeMap[category]!.addListener(() {
        if (addTasknameFocusNodeMap[category]!.hasFocus && addTask) {
          _scrollToForm(category);
        }
      });
    }
  }

  Future<void> loadDataAsync() async {
    if (!mounted) return;

    final rawData = box.read('userDataAll');
    final tasksData = model.AllDataUserGetResponst.fromJson(rawData);
    final appData = Provider.of<Appdata>(context, listen: false);

    List<model.Task> filteredTasks = tasksData.tasks
        .where(
          (task) => (showArchived
              ? ['0', '1', '2'].contains(task.status)
              : task.status != '2'),
        )
        .toList();

    appData.showMyTasks.setTasks(filteredTasks);

    setState(() {
      tasks = filteredTasks;
    });
  }

  @override
  void didChangeMetrics() async {
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
        if (focusedCategory != null) {
          await _handleTaskSubmit(focusedCategory!);
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scrollController.dispose();
    mainMenuEntry?.remove();
    mainMenuEntry = null;
    debounceTimer?.cancel();
    timer?.cancel();
    boardSubscription?.cancel();
    for (var controller in addTasknameCtlMap.values) {
      controller.dispose();
    }
    addTasknameCtlMap.clear();
    for (var controller in addDescriptionCtlMap.values) {
      controller.dispose();
    }
    addDescriptionCtlMap.clear();
    for (var node in addTasknameFocusNodeMap.values) {
      node.dispose();
    }
    addTasknameFocusNodeMap.clear();
    for (var node in addDescriptionFocusNodeMap.values) {
      node.dispose();
    }
    addDescriptionFocusNodeMap.clear();
    addFormKeyMap.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      if (focusedCategory != null) {
        await _handleTaskSubmit(focusedCategory!);
      }
      loadDataAsync();
    }
  }

  @override
  Widget build(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    Map<String, List<model.Task>> groupedTasks = groupTasksByDate();
    List<String> allCategories = getAllCategories();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              color: Colors.transparent,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      !hideMenu
                          ? Text(
                              'All tasks',
                              style: TextStyle(
                                fontSize:
                                    Get.textTheme.headlineMedium!.fontSize!,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : Text(
                              selectedTaskIds.isNotEmpty
                                  ? '${selectedTaskIds.length} Selected'
                                  : 'Select Task',
                              style: TextStyle(
                                fontSize:
                                    Get.textTheme.headlineMedium!.fontSize!,
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
                          if (hideMenu || addTask)
                            TextButton(
                              onPressed: hideMenu
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
                                  : () async {
                                      if (focusedCategory != null) {
                                        addTasknameFocusNodeMap[focusedCategory]
                                            ?.unfocus();
                                        addDescriptionFocusNodeMap[focusedCategory]
                                            ?.unfocus();
                                        await _handleTaskSubmit(
                                          focusedCategory!,
                                        );
                                      }
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      !hideMenu
                          ? SizedBox.shrink()
                          : selectedTaskIds.isNotEmpty || tasks.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selectedTaskIds.length == tasks.length) {
                                    selectedTaskIds.clear();
                                  } else {
                                    selectedTaskIds = tasks
                                        .map((task) => task.taskId.toString())
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
                                          Get.textTheme.titleMedium!.fontSize!,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: height * 0.005),
                controller: scrollController,
                child: Column(
                  children: [
                    Column(
                      children: allCategories.map((category) {
                        List<model.Task> categoryTasks =
                            groupedTasks[category] ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (category != 'Past Due' &&
                                categoryTasks.isNotEmpty)
                              Padding(
                                padding: hideMenu
                                    ? EdgeInsets.symmetric(
                                        vertical: height * 0.01,
                                      )
                                    : EdgeInsets.only(top: height * 0.005),
                                child: Container(
                                  height: 2,
                                  color: Colors.white,
                                ),
                              ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap:
                                    category != 'Past Due' &&
                                        category != 'Coming soon' &&
                                        !hideMenu
                                    ? creatingTasks.isEmpty
                                          ? () async {
                                              if (focusedCategory != null &&
                                                  focusedCategory != category) {
                                                await _handleTaskSubmit(
                                                  focusedCategory!,
                                                );
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                      addTasknameFocusNodeMap[category]
                                                          ?.requestFocus();
                                                    });
                                              } else {
                                                addTasknameFocusNodeMap[category]
                                                    ?.requestFocus();
                                              }
                                              setState(() {
                                                addTask = true;
                                                focusedCategory = category;
                                                selectedReminder = null;
                                                customReminderDateTime = null;
                                              });
                                            }
                                          : null
                                    : null,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.03,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: categoryTasks.isNotEmpty
                                              ? Get
                                                    .textTheme
                                                    .titleLarge!
                                                    .fontSize!
                                              : Get
                                                    .textTheme
                                                    .titleMedium!
                                                    .fontSize!,
                                          fontWeight: FontWeight.w500,
                                          color: categoryTasks.isNotEmpty
                                              ? Colors.black
                                              : Colors.black45,
                                        ),
                                      ),
                                      if (category != 'Past Due' &&
                                          category != 'Coming soon' &&
                                          !hideMenu)
                                        SvgPicture.string(
                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M19 11h-6V5h-2v6H5v2h6v6h2v-6h6z"></path></svg>',
                                          width: width * 0.05,
                                          fit: BoxFit.contain,
                                          color: Colors.black45,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ...categoryTasks.map((data) {
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
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: hideMenu
                                          ? () {
                                              if (selectedTaskIds.contains(
                                                data.taskId.toString(),
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
                                                creatingTasks[data.taskId
                                                        .toString()] ==
                                                    true
                                            ? DismissDirection.none
                                            : DismissDirection.endToStart,
                                        background: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                          return await showDialog<bool>(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
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
                                                          0.02,
                                                    ),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
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
                                                      'Do you want to delete this task?',
                                                      style: TextStyle(
                                                        fontSize: Get
                                                            .textTheme
                                                            .titleMedium!
                                                            .fontSize!,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.red,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
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
                                                          ).pop(true),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Color(
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
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(false),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red[400],
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
                                                          color: Colors.white,
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
                                          setState(() {
                                            tasks.removeWhere(
                                              (t) => t.taskId == data.taskId,
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
                                                  data.taskId.toString(),
                                                )
                                                ? Colors.black12
                                                : data.status == "2" && hideMenu
                                                ? Colors.grey[100]
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                crossAxisAlignment: !hideMenu
                                                    ? CrossAxisAlignment.start
                                                    : CrossAxisAlignment.center,
                                                children: [
                                                  GestureDetector(
                                                    onTap: !hideMenu
                                                        ? () => handleTaskTap(
                                                            data,
                                                          )
                                                        : null,
                                                    child: !hideMenu
                                                        ? SvgPicture.string(
                                                            selectedIsArchived
                                                                    .contains(
                                                                      data.taskId
                                                                          .toString(),
                                                                    )
                                                                ? '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-292q78.47 0 133.23-54.77Q668-401.53 668-480t-54.77-133.23Q558.47-668 480-668t-133.23 54.77Q292-558.47 292-480t54.77 133.23Q401.53-292 480-292Zm.13 204q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>'
                                                                : data.status ==
                                                                      "2"
                                                                ? '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-292q78.47 0 133.23-54.77Q668-401.53 668-480t-54.77-133.23Q558.47-668 480-668t-133.23 54.77Q292-558.47 292-480t54.77 133.23Q401.53-292 480-292Zm.13 204q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>'
                                                                : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                                            height:
                                                                height * 0.04,
                                                            fit: BoxFit.contain,
                                                            color:
                                                                creatingTasks[data
                                                                        .taskId
                                                                        .toString()] ==
                                                                    true
                                                                ? Colors
                                                                      .grey[300]
                                                                : selectedIsArchived
                                                                      .contains(
                                                                        data.taskId
                                                                            .toString(),
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
                                                                height * 0.04,
                                                            fit: BoxFit.contain,
                                                            color:
                                                                selectedTaskIds
                                                                    .contains(
                                                                      data.taskId
                                                                          .toString(),
                                                                    )
                                                                ? Color(
                                                                    0xFF007AFF,
                                                                  )
                                                                : Colors.grey,
                                                          ),
                                                  ),
                                                  SizedBox(width: width * 0.01),
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
                                                            onTap: !hideMenu
                                                                ? creatingTasks[data
                                                                              .taskId
                                                                              .toString()] ==
                                                                          true
                                                                      ? () {
                                                                          log(
                                                                            "สร้างยังไม่เสร็จ",
                                                                          );
                                                                        }
                                                                      : () async {
                                                                          if (!hideMenu) {
                                                                            setState(() {
                                                                              hideMenu = false;
                                                                              addTask = false;
                                                                            });
                                                                          }
                                                                          log(
                                                                            "เรียบร้อย",
                                                                          );
                                                                          if (focusedCategory !=
                                                                              null) {
                                                                            addTasknameFocusNodeMap[focusedCategory]!.unfocus();
                                                                            addDescriptionFocusNodeMap[focusedCategory]!.unfocus();
                                                                            await _handleTaskSubmit(
                                                                              focusedCategory!,
                                                                            );
                                                                          }
                                                                          Get.to(
                                                                            () =>
                                                                                TasksdetailPage(),
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
                                                                      Row(
                                                                        children: [
                                                                          Expanded(
                                                                            child: Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                data.description.isEmpty
                                                                                    ? SizedBox.shrink()
                                                                                    : Text(
                                                                                        data.description,
                                                                                        style: TextStyle(
                                                                                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                          color: Colors.grey,
                                                                                        ),
                                                                                        maxLines: 6,
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                      ),
                                                                                showDetailPrivateOrGroup(
                                                                                      data,
                                                                                    ).isEmpty
                                                                                    ? SizedBox.shrink()
                                                                                    : Text(
                                                                                        showDetailPrivateOrGroup(
                                                                                          data,
                                                                                        ),
                                                                                        style: TextStyle(
                                                                                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                          color: Color(
                                                                                            0xFF007AFF,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                Row(
                                                                                  children: [
                                                                                    formatDateDisplay(
                                                                                          data.notifications,
                                                                                          category,
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
                                                                                              mainAxisSize: MainAxisSize.min,
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
                                                                                                    category,
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
                            }).toList(),
                            if (!hideMenu &&
                                category != 'Past Due' &&
                                category != 'Coming soon' &&
                                (categoryTasks.isNotEmpty ||
                                    focusedCategory == category))
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: height * 0.01,
                                ),
                                key: addFormKeyMap[category],
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
                                            color: Colors.black12,
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
                                              controller:
                                                  addTasknameCtlMap[category],
                                              focusNode:
                                                  addTasknameFocusNodeMap[category],
                                              keyboardType: TextInputType.text,
                                              cursorColor: Color(0xFF007AFF),
                                              enabled: creatingTasks.isEmpty
                                                  ? true
                                                  : false,
                                              onTap: () async {
                                                if (focusedCategory != null &&
                                                    focusedCategory !=
                                                        category) {
                                                  await _handleTaskSubmit(
                                                    focusedCategory!,
                                                  );
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback((
                                                        _,
                                                      ) {
                                                        addTasknameFocusNodeMap[category]
                                                            ?.requestFocus();
                                                      });
                                                }
                                                setState(() {
                                                  addTask = true;
                                                  focusedCategory = category;
                                                  selectedReminder = null;
                                                  customReminderDateTime = null;
                                                });
                                              },
                                              onEditingComplete: () async {
                                                if (focusedCategory != null) {
                                                  addTasknameFocusNodeMap[focusedCategory]!
                                                      .unfocus();
                                                  addDescriptionFocusNodeMap[focusedCategory]!
                                                      .unfocus();
                                                  await _handleTaskSubmit(
                                                    focusedCategory!,
                                                  );
                                                }
                                              },
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .titleSmall!
                                                    .fontSize!,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                constraints: BoxConstraints(
                                                  maxHeight: height * 0.05,
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: height * 0.01,
                                                    ),
                                                border: InputBorder.none,
                                                hintText: '',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: Get
                                                      .textTheme
                                                      .titleSmall!
                                                      .fontSize!,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (focusedCategory == category)
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.only(
                                              left: width * 0.145,
                                              right: width * 0.05,
                                            ),
                                            width: width,
                                            child: TextField(
                                              controller:
                                                  addDescriptionCtlMap[category],
                                              focusNode:
                                                  addDescriptionFocusNodeMap[category],
                                              keyboardType: TextInputType.text,
                                              cursorColor: Color(0xFF007AFF),
                                              maxLines: 6,
                                              minLines: 1,
                                              onEditingComplete: () async {
                                                if (focusedCategory != null) {
                                                  addTasknameFocusNodeMap[focusedCategory]!
                                                      .unfocus();
                                                  addDescriptionFocusNodeMap[focusedCategory]!
                                                      .unfocus();
                                                  await _handleTaskSubmit(
                                                    focusedCategory!,
                                                  );
                                                }
                                              },
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .titleSmall!
                                                    .fontSize!,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                hintText: isTyping
                                                    ? ''
                                                    : 'Add Description',
                                                hintStyle: TextStyle(
                                                  fontSize: Get
                                                      .textTheme
                                                      .titleSmall!
                                                      .fontSize!,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.grey,
                                                ),
                                                constraints: BoxConstraints(
                                                  maxHeight: height * 0.18,
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: height * 0.01,
                                                    ),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
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
                                  selectedPriority = isSelected ? null : select;
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
                                    _scrollToForm(
                                      focusedCategory ??
                                          getAllCategories().first,
                                    );
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
                                    _scrollToForm(
                                      focusedCategory ??
                                          getAllCategories().first,
                                    );
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
                          onTap: selectedTaskIds.isNotEmpty
                              ? () {
                                  Get.defaultDialog(
                                    title: '',
                                    titlePadding: EdgeInsets.zero,
                                    backgroundColor: Colors.white,
                                    barrierDismissible: false,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                          0.04,
                                      vertical:
                                          MediaQuery.of(context).size.height *
                                          0.01,
                                    ),
                                    content: WillPopScope(
                                      onWillPop: () async => false,
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
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red,
                                            ),
                                            textAlign: TextAlign.center,
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
                                              setState(() {
                                                hideMenu = false;
                                              });
                                              deleteTaskById(
                                                selectedTaskIds,
                                                true,
                                              );
                                              selectedTaskIds.clear();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(
                                                0xFF007AFF,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Get.back();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red[400],
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                                color: Colors.white,
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

    return remindTimes;
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

  Future<void> _handleTaskSubmit(String category) async {
    if (!mounted) return;
    final taskName = addTasknameCtlMap[category]!.text;
    final description = addDescriptionCtlMap[category]!.text;

    setState(() {
      focusedCategory = null;
    });
    await _saveData(category, taskName, description);
    if (taskName.isNotEmpty || description.isNotEmpty) _scrollToForm(category);
  }

  Future<void> _saveData(
    String category,
    String value,
    String description,
  ) async {
    if (!mounted) return;
    final userProfile = box.read('userProfile');
    final userId = userProfile['userid'];
    final userEmail = userProfile['email'];
    if (userId == null || userEmail == null) return;

    if (selectedReminder == null) {
      if (category == 'Today') {
        customReminderDateTime = null;
        selectedReminder = null;
      } else if (category == 'Tomorrow') {
        customReminderDateTime = null;
        selectedReminder = 'Tomorrow';
      } else if (category != 'Past Due' && category != 'Coming soon') {
        DateTime? selectedDateTime = parseDateFromCategory(category);
        if (selectedDateTime != null) {
          selectedReminder =
              'Custom: ${DateFormat('MMM dd, yyyy HH:mm').format(selectedDateTime)}';
          customReminderDateTime = selectedDateTime;
        }
      }
    }

    if (isCustomReminderApplied) return;

    final trimmedTitle = value.trim();
    final trimmedDescription = description.trim();
    if (trimmedTitle.isEmpty && trimmedDescription.isEmpty) return;

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

    final titleToSave = trimmedTitle.isEmpty ? "Untitled" : trimmedTitle;
    final descriptionToSave = trimmedDescription;

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
        addTask = false;
        creatingTasks[tempId.toString()] = true;
        isCreatingTask = true;
        addTasknameCtlMap[category]?.clear();
        addDescriptionCtlMap[category]?.clear();
        addTasknameFocusNodeMap[category]?.unfocus();
        addDescriptionFocusNodeMap[category]?.unfocus();
      });
    }

    await _updateLocalStorage(tempTask, isTemp: true);

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
    await _waitForDocumentCreation(realId, notificationID);
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

  Future<void> _waitForDocumentCreation(int realId, int notificationID) async {
    int maxRetries = 10; // จำกัดจำนวนครั้งที่ลอง
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        DocumentSnapshot doc;

        doc = await FirebaseFirestore.instance
            .collection('Notifications')
            .doc(box.read('userProfile')['email'])
            .collection('Tasks')
            .doc(notificationID.toString())
            .get();

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

  Map<String, List<model.Task>> groupTasksByDate() {
    Map<String, List<model.Task>> groupedTasks = {};
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(Duration(days: 1));

    for (var task in tasks) {
      String category = getTaskCategory(task, today, tomorrow);
      if (groupedTasks[category] == null) {
        groupedTasks[category] = [];
      }
      groupedTasks[category]!.add(task);
    }

    return groupedTasks;
  }

  // ฟังก์ชันกำหนดหมวดหมู่ของ task
  String getTaskCategory(model.Task task, DateTime today, DateTime tomorrow) {
    if (task.notifications.isEmpty) {
      return 'No Due Date';
    }

    // หาวันที่ใกล้ที่สุด
    DateTime? nearestDueDate;
    for (var notification in task.notifications) {
      if (notification.dueDate.isNotEmpty) {
        try {
          DateTime dueDate = DateTime.parse(notification.dueDate).toLocal();
          DateTime dueDateOnly = DateTime(
            dueDate.year,
            dueDate.month,
            dueDate.day,
          );

          if (nearestDueDate == null || dueDateOnly.isBefore(nearestDueDate)) {
            nearestDueDate = dueDateOnly;
          }
        } catch (e) {
          continue;
        }
      }
    }

    if (nearestDueDate == null) {
      return 'No Due Date';
    }
    // จัดหมวดหมู่
    if (nearestDueDate.isBefore(today)) {
      return 'Past Due';
    } else if (nearestDueDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (nearestDueDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else if (nearestDueDate.isBefore(today.add(Duration(days: 7)))) {
      // สำหรับวันที่ 2-6 วันข้างหน้า ใช้รูปแบบ "Day DD MMM"
      return formatFutureDate(nearestDueDate);
    } else {
      // สำหรับวันที่เกิน 7 วันข้างหน้า จัดเป็น "Coming soon"
      return 'Coming soon';
    }
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

  int getMinutesFromIndex(int? index) {
    if (index == null || index == 0) return 0; // Never

    final options = getRemindMeBeforeOptions();
    if (index >= 0 && index < options.length) {
      return options[index]['minutes'];
    }
    return 0;
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

  // ฟังก์ชันสำหรับแปลง selectedBeforeMinutes เป็น label
  String getLabelFromIndex(int? index) {
    if (index == null) return 'Never';

    final options = getRemindMeBeforeOptions();
    if (index >= 0 && index < options.length) {
      return options[index]['label'];
    }
    return 'Never';
  }

  // ฟังก์ชันจัดรูปแบบวันที่ในอนาคต
  String formatFutureDate(DateTime date) {
    List<String> dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    List<String> monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    String dayName = dayNames[date.weekday - 1];
    String monthName = monthNames[date.month - 1];

    return '$dayName, ${date.day} $monthName';
  }

  List<String> getAllCategories() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    List<String> categories = ['Past Due', 'Today', 'Tomorrow'];

    // เพิ่มวันที่ 2-6 วันข้างหน้า
    for (int i = 2; i <= 6; i++) {
      DateTime futureDate = today.add(Duration(days: i));
      categories.add(formatFutureDate(futureDate));
    }

    // เพิ่ม "Coming soon" ไว้สุดท้าย
    categories.add('Coming soon');

    return categories;
  }

  DateTime? parseDateFromCategory(String category) {
    try {
      List<String> parts = category.split(' ');
      if (parts.length != 3) return null;

      int day = int.parse(parts[1]);
      String monthAbbr = parts[2];

      List<String> monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      int month = monthNames.indexOf(monthAbbr) + 1;
      if (month == 0) return null;

      DateTime now = DateTime.now();

      DateTime date = DateTime(now.year, month, day, now.hour, now.minute);

      return date;
    } catch (e) {
      return null;
    }
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

  String formatDateDisplay(
    List<model.Notification> notifications,
    String category,
  ) {
    if (notifications.isEmpty) return '';

    final now = DateTime.now();
    final dueDate = DateTime.parse(notifications.first.dueDate).toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (category == 'Coming soon') {
      final day = dueDate.day.toString().padLeft(2, '0');
      final month = dueDate.month.toString().padLeft(2, '0');
      final year = (dueDate.year % 100).toString().padLeft(2, '0');
      final hour = dueDate.hour.toString().padLeft(2, '0');
      final minute = dueDate.minute.toString().padLeft(2, '0');
      return '$day/$month/$year, $hour:$minute';
    }

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

  void handleTaskTap(model.Task data) async {
    if (!mounted) return;
    final taskId = data.taskId;
    setState(() => hideMenu = false);

    if (data.status == "2") {
      await showArchiveTask(taskId.toString());
      selectedIsArchived.clear();
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (selectedIsArchived.contains(taskId.toString())) {
      selectedIsArchived.remove(taskId.toString());
    } else {
      selectedIsArchived.add(taskId.toString());
    }

    if (showArchived) {
      await finishAllSelectedTasks();
      selectedIsArchived.clear();
      return;
    }

    debounceTimer?.cancel();

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

  Future<void> todayTasksFinish(String id) async {
    if (!mounted) return;

    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = model.AllDataUserGetResponst.fromJson(userDataJson);
    final appData = Provider.of<Appdata>(context, listen: false);

    final index = existingData.tasks.indexWhere(
      (t) => t.taskId.toString() == id,
    );
    if (index == -1) return;

    existingData.tasks[index].status = '2';
    box.write('userDataAll', existingData.toJson());

    if (!showArchived) {
      appData.showMyTasks.removeTaskById(id);
      tasks.removeWhere((t) => t.taskId.toString() == id);
    } else {
      await loadDataAsync();
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

    for (var id in idList) {
      appData.showMyTasks.removeTaskById(id);
      existingData.tasks.removeWhere((t) => t.taskId.toString() == id);
      tasks.removeWhere((t) => t.taskId.toString() == id);
    }
    box.write('userDataAll', existingData.toJson());

    if (mounted) setState(() {});

    final endpoint = select ? "deltask" : "deltask/$taskIdPayload";
    final requestBody = select ? {"task_id": taskIdPayload} : null;
    await deleteWithRetry(endpoint, requestBody);
  }

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

  void _scrollToForm(String category) {
    if (!mounted) return;
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted && addFormKeyMap[category]?.currentContext != null) {
            Scrollable.ensureVisible(
              addFormKeyMap[category]!.currentContext!,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: 1.0,
            );
          }
        });
      }
    });
  }

  void hideMainMenu() {
    mainMenuEntry?.remove();
    mainMenuEntry = null;
  }

  void hideMenus() {
    hideMainMenu();
  }

  void showPopupMenuOverlay(BuildContext context) {
    final RenderBox renderBox =
        iconKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    var height = MediaQuery.of(context).size.height;

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
                        addTasknameFocusNodeMap[focusedCategory]?.unfocus();
                        addDescriptionFocusNodeMap[focusedCategory]?.unfocus();
                        focusedCategory = null;
                      });

                      Future.delayed(Duration(milliseconds: 300), () {
                        setState(() {
                          hideMenu = true;
                        });
                      });
                    },
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

  Widget buildPopupItem(
    BuildContext context, {
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: width * 0.04),
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
              ],
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  //แสดง custom remind
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
                                  Future.delayed(
                                    Duration(microseconds: 300),
                                    () {
                                      _scrollToForm(getAllCategories().first);
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
                                  Future.delayed(
                                    Duration(microseconds: 300),
                                    () {
                                      _scrollToForm(getAllCategories().first);
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
                        childAspectRatio: 9.5,
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
}
