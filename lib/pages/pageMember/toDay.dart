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
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/todayTasksCreatePostRequest.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
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
  late Future<void> loadData;
  late String url;

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

  // 🔢 Integer Variables
  int itemCount = 1;

  // 🕒 Timer
  Timer? _timer;
  Timer? debounceTimer;

  // 📋 Lists
  List<Todaytask> tasks = [];
  List<Todaytask> filteredTasks = [];
  List<String> selectedTaskIds = [];
  List<String> selectedIsArchived = [];
  Map<String, bool> creatingTasks = {};

  SortType currentSortType = SortType.dateEarliestFirst;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  void resetVariables() {
    setState(() {
      hideMenu = false;
      selectedTaskIds.clear();
      selectedIsArchived.clear();
    });
    loadDataAsync();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    loadData = loadDataAsync();

    addTasknameFocusNode.addListener(() {
      if (addTasknameFocusNode.hasFocus && addToday) {
        _scrollToAddForm();
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
    final rawData = box.read('userDataAll');
    final tasksData = AllDataUserGetResponst.fromJson(rawData);
    final appData = Provider.of<Appdata>(context, listen: false);

    filteredTasks =
        showArchived
            ? List.from(tasksData.todaytasks)
            : tasksData.todaytasks
                .where((task) => task.archived == false)
                .toList();

    appData.showMyTasks.setTasks(filteredTasks);

    if (!mounted) return;
    setState(() {
      tasks = filteredTasks;
    });
  }

  @override
  void didChangeMetrics() {
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

    return FutureBuilder(
      future: loadData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Future.delayed(Duration.zero, () {
            if (!mounted) return;
            setState(() {
              itemCount = tasks.isEmpty ? 1 : tasks.length;
            });
          });
        }

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
            addTasknameFocusNode.requestFocus();
            _saveData(addTasknameCtl.text, addDescriptionCtl.text);
          },
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  right: width * 0.05,
                  left: width * 0.05,
                  bottom:
                      addToday
                          ? MediaQuery.of(context).viewInsets.bottom +
                              height * 0.06
                          : height * 0.005,
                ),
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
                                            Get
                                                .textTheme
                                                .headlineMedium!
                                                .fontSize! *
                                            MediaQuery.of(
                                              context,
                                            ).textScaleFactor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                    : Text(
                                      selectedTaskIds.isNotEmpty
                                          ? '${selectedTaskIds.length} Selected'
                                          : 'Select Task',
                                      style: TextStyle(
                                        fontSize:
                                            Get
                                                .textTheme
                                                .headlineMedium!
                                                .fontSize! *
                                            MediaQuery.of(
                                              context,
                                            ).textScaleFactor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                !hideMenu
                                    ? InkWell(
                                      key: iconKey,
                                      onTap: () {
                                        showPopupMenuOverlay(context);
                                        setState(() {
                                          addToday = false;
                                        });
                                        _saveData(
                                          addTasknameCtl.text,
                                          addDescriptionCtl.text,
                                        );
                                      },
                                      child: SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 12c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"></path></svg>',
                                        height: height * 0.035,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                    : InkWell(
                                      onTap: () {
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
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.01,
                                          vertical: height * 0.005,
                                        ),
                                        child: Text(
                                          "Save",
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
                                            color: Color(0xFF007AFF),
                                          ),
                                        ),
                                      ),
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
                                            Get
                                                .textTheme
                                                .titleMedium!
                                                .fontSize! *
                                            MediaQuery.of(
                                              context,
                                            ).textScaleFactor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                    : selectedTaskIds.isNotEmpty ||
                                        tasks.isNotEmpty
                                    ? InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (selectedTaskIds.length ==
                                              tasks.length) {
                                            selectedTaskIds.clear();
                                          } else {
                                            selectedTaskIds =
                                                tasks
                                                    .map((task) => task.taskId)
                                                    .toList();
                                          }
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          SvgPicture.string(
                                            selectedTaskIds.length ==
                                                    tasks.length
                                                ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>'
                                                : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                            height: height * 0.04,
                                            fit: BoxFit.contain,
                                            color:
                                                selectedTaskIds.length ==
                                                        tasks.length
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
                                      : '${tasks.length} tasks, ${tasks.where((t) => t.archived).length} Completed',
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
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          children: [
                            if (tasks.isEmpty && !addToday)
                              Container(
                                width: width,
                                height: height * 0.6,
                                alignment: Alignment.center,
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
                              ),
                            if (tasks.isNotEmpty)
                              ...sortTasks(tasks).map((data) {
                                return InkWell(
                                  onTap:
                                      hideMenu
                                          ? () {
                                            if (selectedTaskIds.contains(
                                              data.taskId,
                                            )) {
                                              selectedTaskIds.remove(
                                                data.taskId,
                                              );
                                            } else {
                                              selectedTaskIds.add(data.taskId);
                                            }
                                          }
                                          : null,
                                  child: Container(
                                    color: Colors.transparent,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Dismissible(
                                          key: ValueKey(data.taskId),
                                          direction:
                                              hideMenu ||
                                                      creatingTasks[data
                                                              .taskId] ==
                                                          true
                                                  ? DismissDirection.none
                                                  : DismissDirection.endToStart,
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.02,
                                            ),
                                            color: Colors.red,
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
                                                (t) => t.taskId == data.taskId,
                                              );
                                            });
                                            deleteTaskById(data.taskId, false);
                                          },
                                          child: Row(
                                            crossAxisAlignment:
                                                !hideMenu
                                                    ? CrossAxisAlignment.start
                                                    : CrossAxisAlignment.center,
                                            children: [
                                              GestureDetector(
                                                onTap:
                                                    !hideMenu
                                                        ? () =>
                                                            handleTaskTap(data)
                                                        : null,
                                                child:
                                                    !hideMenu
                                                        ? SvgPicture.string(
                                                          selectedIsArchived
                                                                  .contains(
                                                                    data.taskId,
                                                                  )
                                                              ? '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-292q78.47 0 133.23-54.77Q668-401.53 668-480t-54.77-133.23Q558.47-668 480-668t-133.23 54.77Q292-558.47 292-480t54.77 133.23Q401.53-292 480-292Zm.13 204q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>'
                                                              : data.archived
                                                              ? '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-292q78.47 0 133.23-54.77Q668-401.53 668-480t-54.77-133.23Q558.47-668 480-668t-133.23 54.77Q292-558.47 292-480t54.77 133.23Q401.53-292 480-292Zm.13 204q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>'
                                                              : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                                          height: height * 0.04,
                                                          fit: BoxFit.contain,
                                                          color:
                                                              creatingTasks[data
                                                                          .taskId] ==
                                                                      true
                                                                  ? Colors
                                                                      .grey[300]
                                                                  : selectedIsArchived
                                                                      .contains(
                                                                        data.taskId,
                                                                      )
                                                                  ? Color(
                                                                    0xFF007AFF,
                                                                  )
                                                                  : data
                                                                      .archived
                                                                  ? Color(
                                                                    0xFF007AFF,
                                                                  )
                                                                  : Colors.grey,
                                                        )
                                                        : SvgPicture.string(
                                                          selectedTaskIds
                                                                  .contains(
                                                                    data.taskId,
                                                                  )
                                                              ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>'
                                                              : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                                          height: height * 0.04,
                                                          fit: BoxFit.contain,
                                                          color:
                                                              selectedTaskIds
                                                                      .contains(
                                                                        data.taskId,
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
                                                                height * 0.005,
                                                          ),
                                                      child: InkWell(
                                                        onTap:
                                                            !hideMenu
                                                                ? creatingTasks[data
                                                                            .taskId] ==
                                                                        true
                                                                    ? () {
                                                                      log(
                                                                        "สร้างยังไม่เสร็จ",
                                                                      );
                                                                    }
                                                                    : () {
                                                                      if (!hideMenu) {
                                                                        setState(() {
                                                                          hideMenu =
                                                                              false;
                                                                          addToday =
                                                                              false;
                                                                        });
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
                                                                    CrossAxisAlignment
                                                                        .start,
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
                                                                                creatingTasks[data.taskId] ==
                                                                                        true
                                                                                    ? Colors.grey
                                                                                    : selectedIsArchived.contains(
                                                                                          data.taskId,
                                                                                        ) ||
                                                                                        data.archived
                                                                                    ? Colors.grey
                                                                                    : Colors.black,
                                                                          ),
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  data
                                                                          .description
                                                                          .isEmpty
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
                                                                  formatDateDisplay(
                                                                        data.createdAt,
                                                                      ).isEmpty
                                                                      ? SizedBox.shrink()
                                                                      : Text(
                                                                        formatDateDisplay(
                                                                          data.createdAt,
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
                                                            data
                                                                    .priority
                                                                    .isEmpty
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
                                                                          BoxShape
                                                                              .circle,
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
                                                      ),
                                                    ),
                                                    Container(
                                                      width: width,
                                                      height: 0.5,
                                                      color: Colors.grey,
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
                                );
                              }),
                            if (addToday)
                              Container(
                                key: addFormKey,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          width: width * 0.8,
                                          child: TextField(
                                            controller: addTasknameCtl,
                                            focusNode: addTasknameFocusNode,
                                            keyboardType: TextInputType.text,
                                            cursorColor: Color(0xFF007AFF),
                                            style: TextStyle(
                                              fontSize:
                                                  Get
                                                      .textTheme
                                                      .titleSmall!
                                                      .fontSize! *
                                                  MediaQuery.of(
                                                    context,
                                                  ).textScaleFactor,
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  isTyping ? '' : 'Add title',
                                              hintStyle: TextStyle(
                                                fontSize:
                                                    Get
                                                        .textTheme
                                                        .titleSmall!
                                                        .fontSize! *
                                                    MediaQuery.of(
                                                      context,
                                                    ).textScaleFactor,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.grey,
                                              ),
                                              constraints: BoxConstraints(
                                                maxHeight: height * 0.04,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: width * 0.02,
                                                  ),
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          width: width * 0.8,
                                          child: TextField(
                                            controller: addDescriptionCtl,
                                            focusNode: addDescriptionFocusNode,
                                            keyboardType: TextInputType.text,
                                            cursorColor: Color(0xFF007AFF),
                                            style: TextStyle(
                                              fontSize:
                                                  Get
                                                      .textTheme
                                                      .titleSmall!
                                                      .fontSize! *
                                                  MediaQuery.of(
                                                    context,
                                                  ).textScaleFactor,
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  isTyping
                                                      ? ''
                                                      : 'Add Description',
                                              hintStyle: TextStyle(
                                                fontSize:
                                                    Get
                                                        .textTheme
                                                        .titleSmall!
                                                        .fontSize! *
                                                    MediaQuery.of(
                                                      context,
                                                    ).textScaleFactor,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.grey,
                                              ),
                                              constraints: BoxConstraints(
                                                maxHeight: height * 0.04,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: width * 0.02,
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
                        ),
                      ),
                    ),
                    if (!addToday || !hideMenu) SizedBox(height: height * 0.02),
                    if (!addToday && !hideMenu)
                      Row(
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
                                          MediaQuery.of(
                                            context,
                                          ).textScaleFactor,
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
                    if (hideMenu)
                      Row(
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void handleTaskTap(Todaytask data) async {
    final taskId = data.taskId;
    setState(() => hideMenu = false);

    if (data.archived) {
      await showArchiveTask(taskId);
      return;
    }

    if (selectedIsArchived.contains(taskId)) {
      selectedIsArchived.remove(taskId);
    } else {
      selectedIsArchived.add(taskId);
    }

    if (showArchived && !data.archived) {
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

  List<Todaytask> sortTasks(List<Todaytask> tasks, [SortType? newSortType]) {
    Map<String, dynamic> currentData = Map<String, dynamic>.from(
      box.read('showDisplays2') ?? {},
    );

    late SortType sortType;

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

    tasks.sort((a, b) {
      if (showArchived && a.archived != b.archived) {
        return a.archived ? 1 : -1;
      }

      switch (sortType) {
        case SortType.dateEarliestFirst:
          return a.createdAt.compareTo(b.createdAt);
        case SortType.dateLatestFirst:
          return b.createdAt.compareTo(a.createdAt);
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

    return tasks;
  }

  Future<void> finishAllSelectedTasks() async {
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

    var existingData = AllDataUserGetResponst.fromJson(userDataJson);
    final appData = Provider.of<Appdata>(context, listen: false);

    final index = existingData.todaytasks.indexWhere((t) => t.taskId == id);
    if (index == -1) return;

    existingData.todaytasks[index].archived = true;
    box.write('userDataAll', existingData.toJson());

    if (!showArchived) {
      appData.showMyTasks.removeTaskById(id);
      tasks.removeWhere((t) => t.taskId == id);
    } else {
      tasks = List.from(existingData.todaytasks);
      tasks.sort((a, b) {
        if (a.archived != b.archived) {
          return a.archived ? 1 : -1;
        }
        final dateA = DateTime.parse(a.createdAt);
        final dateB = DateTime.parse(b.createdAt);
        return dateA.compareTo(dateB);
      });

      appData.showMyTasks.setTasks(tasks);
    }

    if (mounted) setState(() {});

    url = await loadAPIEndpoint();
    var response = await http.put(
      Uri.parse("$url/todaytasks/finish"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: jsonEncode({"task_id": id}),
    );

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      response = await http.put(
        Uri.parse("$url/todaytasks/finish"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: jsonEncode({"task_id": id}),
      );
    }
  }

  Future<void> showArchiveTask(String id) async {
    if (!mounted) return;

    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = AllDataUserGetResponst.fromJson(userDataJson);
    final appData = Provider.of<Appdata>(context, listen: false);

    final index = existingData.todaytasks.indexWhere((t) => t.taskId == id);
    if (index == -1) return;

    existingData.todaytasks[index].archived = false;
    box.write('userDataAll', existingData.toJson());

    if (!showArchived) {
      tasks = existingData.todaytasks.where((t) => !t.archived).toList();
      appData.showMyTasks.setTasks(tasks);
    } else {
      tasks = List.from(existingData.todaytasks);
      tasks.sort((a, b) {
        if (a.archived != b.archived) {
          return a.archived ? 1 : -1;
        }
        final dateA = DateTime.parse(a.createdAt);
        final dateB = DateTime.parse(b.createdAt);
        return dateA.compareTo(dateB);
      });

      appData.showMyTasks.setTasks(tasks);
    }

    if (mounted) setState(() {});

    await FirebaseFirestore.instance
        .collection('TodayTasks')
        .doc(box.read('userProfile')['email'])
        .collection('tasks')
        .doc(id)
        .update({'Archived': false});
  }

  void deleteTaskById(dynamic ids, bool select) async {
    if (!mounted) return;

    dynamic taskIdPayload;
    List<String> idList;
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = AllDataUserGetResponst.fromJson(userDataJson);
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
      existingData.todaytasks.removeWhere((t) => t.taskId == id);
      tasks.removeWhere((t) => t.taskId == id);
    }
    box.write('userDataAll', existingData.toJson());

    if (mounted) setState(() {});

    final endpoint = select ? "todaytasks/deltoday" : "todaytasks/delidtoday";
    await deleteWithRetry(endpoint, {"task_id": taskIdPayload});
  }

  Future<http.Response> deleteWithRetry(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    url = await loadAPIEndpoint();
    final token = box.read('accessToken');
    var response = await http.delete(
      Uri.parse("$url/$endpoint"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      final newToken = box.read('accessToken');
      response = await http.delete(
        Uri.parse("$url/$endpoint"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer $newToken",
        },
        body: jsonEncode(body),
      );
    }

    return response;
  }

  Future<void> _saveData(String value, String description) async {
    if (!mounted) return;

    final trimmedTitle = value.trim();
    final trimmedDescription = description.trim();

    if (trimmedTitle.isEmpty && trimmedDescription.isEmpty) return;

    final titleToSave = trimmedTitle.isEmpty ? "Untitled" : trimmedTitle;
    final descriptionToSave = trimmedDescription;

    final userProfile = readMapSafely(box, 'userProfile');
    if (userProfile == null) {
      return;
    }

    final userId = userProfile['userid'];
    final userEmail = userProfile['email']?.toString();

    if (userId == null || userEmail == null) {
      return;
    }

    url = await loadAPIEndpoint();

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempTask = Todaytask(
      taskName: titleToSave,
      description: descriptionToSave,
      archived: false,
      createdAt: DateTime.now().toIso8601String(),
      priority: '',
      status: '0',
      attachments: [],
      checklists: [],
      createdBy: userId,
      taskId: tempId,
    );

    if (mounted) {
      final appData = Provider.of<Appdata>(context, listen: false);
      appData.showMyTasks.addTask(tempTask);

      setState(() {
        addToday = false;
        creatingTasks[tempId] = true;
        isCreatingTask = true;
        tasks =
            showArchived
                ? List.from(appData.showMyTasks.tasks)
                : List.from(
                  appData.showMyTasks.tasks
                      .where((task) => task.archived == false)
                      .toList(),
                );

        addTasknameCtl.clear();
        addDescriptionCtl.clear();
      });
    }
    await _updateLocalStorage(tempTask, isTemp: true);

    final success = await _createTaskAPI(
      titleToSave,
      descriptionToSave,
      userEmail,
    );
    if (success['success']) {
      final realTaskId = success['taskId'];
      await _replaceWithRealTask(tempId, realTaskId, tempTask, userId);
    } else {
      await _removeTempTask(tempId);
    }

    if (mounted) {
      setState(() {
        creatingTasks.remove(tempId);
        isCreatingTask = creatingTasks.isNotEmpty;
      });
    }
  }

  Future<Map<String, dynamic>> _createTaskAPI(
    String title,
    String description,
    String email,
  ) async {
    var responseCreate = await http.post(
      Uri.parse("$url/todaytasks/create"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${readStringSafely(box, 'accessToken')}",
      },
      body: todayTasksCreatePostRequestToJson(
        TodayTasksCreatePostRequest(
          email: email,
          taskName: title,
          description: description,
          status: '0',
          priority: '',
        ),
      ),
    );

    if (responseCreate.statusCode == 403) {
      await loadNewRefreshToken();
      responseCreate = await http.post(
        Uri.parse("$url/todaytasks/create"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${readStringSafely(box, 'accessToken')}",
        },
        body: todayTasksCreatePostRequestToJson(
          TodayTasksCreatePostRequest(
            email: email,
            taskName: title,
            description: description,
            status: '0',
            priority: '',
          ),
        ),
      );
    }

    if (responseCreate.statusCode == 200) {
      final responseData = jsonDecode(responseCreate.body);
      return {'success': true, 'taskId': responseData['taskID']};
    } else {
      return {
        'success': false,
        'error': 'Server error: ${responseCreate.statusCode}',
      };
    }
  }

  Future<void> _replaceWithRealTask(
    String tempId,
    String realId,
    Todaytask tempTask,
    int userId,
  ) async {
    if (!mounted) return;

    final realTask = Todaytask(
      taskName: tempTask.taskName,
      description: tempTask.description,
      archived: false,
      createdAt: DateTime.now().toIso8601String(),
      priority: tempTask.priority,
      status: '0',
      attachments: [],
      checklists: [],
      createdBy: userId,
      taskId: realId,
    );

    final appData = Provider.of<Appdata>(context, listen: false);
    appData.showMyTasks.removeTaskById(tempId);
    appData.showMyTasks.addTask(realTask);

    if (mounted) {
      creatingTasks.remove(tempId);
      isCreatingTask = creatingTasks.isNotEmpty;
      setState(() {
        tasks =
            showArchived
                ? List.from(appData.showMyTasks.tasks)
                : List.from(
                  appData.showMyTasks.tasks
                      .where((task) => task.archived == false)
                      .toList(),
                );
      });
    }

    await _updateLocalStorage(realTask, isTemp: false, tempIdToRemove: tempId);
  }

  Future<void> _removeTempTask(String tempId) async {
    if (!mounted) return;

    final appData = Provider.of<Appdata>(context, listen: false);
    appData.showMyTasks.removeTaskById(tempId);

    if (mounted) {
      setState(() {
        creatingTasks.remove(tempId);
        isCreatingTask = creatingTasks.isNotEmpty;
        tasks =
            showArchived
                ? List.from(appData.showMyTasks.tasks)
                : List.from(
                  appData.showMyTasks.tasks
                      .where((task) => task.archived == false)
                      .toList(),
                );
      });
    }

    final existingData = AllDataUserGetResponst.fromJson(
      box.read('userDataAll'),
    );
    existingData.todaytasks.removeWhere((t) => t.taskId == tempId);
    box.write('userDataAll', existingData.toJson());
  }

  Future<void> _updateLocalStorage(
    Todaytask task, {
    bool isTemp = false,
    String? tempIdToRemove,
  }) async {
    final existingData = AllDataUserGetResponst.fromJson(
      box.read('userDataAll'),
    );

    if (tempIdToRemove != null) {
      existingData.todaytasks.removeWhere((t) => t.taskId == tempIdToRemove);
    }

    existingData.todaytasks.add(task);
    box.write('userDataAll', existingData.toJson());
  }

  Map<String, dynamic>? readMapSafely(GetStorage box, String key) {
    try {
      final data = box.read(key);
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String readStringSafely(
    GetStorage box,
    String key, [
    String defaultValue = '',
  ]) {
    try {
      final data = box.read(key);
      return data?.toString() ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  void _scrollToAddForm() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (addFormKey.currentContext != null) {
        Scrollable.ensureVisible(
          addFormKey.currentContext!,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: 1.0,
        );
      }
    });
  }

  String formatDateDisplay(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString).toLocal();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(inputDate).inDays;

    if (difference == 0) {
      return '';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${inputDate.day.toString().padLeft(2, '0')}/${inputDate.month.toString().padLeft(2, '0')}/${(inputDate.year % 100).toString().padLeft(2, '0')}';
    }
  }

  String getCurrentDayAndDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE - d MMMM');
    return formatter.format(now);
  }

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
                          setState(() => hideMenu = true);
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
