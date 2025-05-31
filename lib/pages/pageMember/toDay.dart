import 'dart:convert';
import 'dart:developer';
import 'dart:math' show Random;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> with WidgetsBindingObserver {
  // 🧠 Data (Lists and Future)
  late Future<void> loadData;
  var box = GetStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final storage = FlutterSecureStorage();
  TextEditingController addTasknameCtl = TextEditingController();
  TextEditingController addDescriptionCtl = TextEditingController();
  FocusNode addTasknameFocusNode = FocusNode();
  FocusNode addDescriptionFocusNode = FocusNode();
  ScrollController scrollController = ScrollController();
  GlobalKey addFormKey = GlobalKey();
  bool isTyping = false;
  bool addToday = false;
  bool hideMenu = false;
  bool isKeyboardVisible = false;
  bool wasKeyboardOpen = false;
  int itemCount = 1;
  GlobalKey iconKey = GlobalKey();
  List<Todaytask> tasks = [];
  List<String> selectedTaskIds = [];
  late String url;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
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
    final rawData = box.read('userDataAll');
    final tasksData = AllDataUserGetResponst.fromJson(rawData);

    final appData = Provider.of<Appdata>(context, listen: false);
    appData.showMyTasks.setTasks(tasksData.todaytasks);

    setState(() {
      tasks = appData.showMyTasks.tasks;
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
    addTasknameCtl.dispose();
    addDescriptionCtl.dispose();
    scrollController.dispose();
    addTasknameFocusNode.dispose();
    addDescriptionFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // แอปถูกย่อหน้าต่างหรือสลับไปแอปอื่น
      _saveData(addTasknameCtl.text, addDescriptionCtl.text);
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
                  top: height * 0.01,
                  bottom:
                      addToday
                          ? MediaQuery.of(context).viewInsets.bottom +
                              height * 0.06
                          : height * 0.01,
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
                                                .displaySmall!
                                                .fontSize,
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
                                                .displaySmall!
                                                .fontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                !hideMenu
                                    ? InkWell(
                                      key: iconKey,
                                      onTap: () {
                                        showPopupMenu(context);
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
                                                    .titleLarge!
                                                    .fontSize,
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
                                            Get.textTheme.titleLarge!.fontSize,
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
                                                      .titleLarge!
                                                      .fontSize,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : SizedBox.shrink(),
                                Text(
                                  '${tasks.length} tasks',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize,
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
                                        Get.textTheme.titleLarge!.fontSize,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (tasks.isNotEmpty)
                              ...tasks.map((data) {
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
                                              hideMenu
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
                                                        ? () {
                                                          if (!hideMenu) {
                                                            setState(() {
                                                              hideMenu = false;
                                                            });
                                                          }
                                                        }
                                                        : null,
                                                child:
                                                    !hideMenu
                                                        ? SvgPicture.string(
                                                          '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                                          height: height * 0.04,
                                                          fit: BoxFit.contain,
                                                          color: Colors.grey,
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
                                              SizedBox(width: width * 0.02),
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
                                                                ? () {
                                                                  if (!hideMenu) {
                                                                    setState(() {
                                                                      hideMenu =
                                                                          false;
                                                                      addToday =
                                                                          false;
                                                                    });
                                                                  }
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
                                                                                Get.textTheme.titleLarge!.fontSize,
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Text(
                                                                    data.description,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          Get
                                                                              .textTheme
                                                                              .titleSmall!
                                                                              .fontSize,
                                                                      color:
                                                                          Colors
                                                                              .grey,
                                                                    ),
                                                                    maxLines: 6,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ],
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
                                                      .titleMedium!
                                                      .fontSize,
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  isTyping ? '' : 'Add title',
                                              hintStyle: TextStyle(
                                                fontSize:
                                                    Get
                                                        .textTheme
                                                        .titleMedium!
                                                        .fontSize,
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
                                                      .titleMedium!
                                                      .fontSize,
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
                                                        .titleMedium!
                                                        .fontSize,
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
                                          Get.textTheme.titleLarge!.fontSize,
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
                          InkWell(
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
                                width: width * 0.032,
                                height: height * 0.032,
                                fit: BoxFit.contain,
                                color:
                                    selectedTaskIds.isNotEmpty
                                        ? Colors.red
                                        : Colors.grey,
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

  void deleteTaskById(dynamic ids, bool select) async {
    if (!mounted) return;

    List<String> idList;
    var existingData = AllDataUserGetResponst.fromJson(box.read('userDataAll'));
    final appData = Provider.of<Appdata>(context, listen: false);

    if (ids is String) {
      idList = [ids];
    } else if (ids is List<String>) {
      idList = ids;
    } else {
      throw ArgumentError();
    }

    for (var id in idList) {
      appData.showMyTasks.removeTaskById(id);
      existingData.todaytasks.removeWhere((t) => t.taskId == id);
      tasks.removeWhere((t) => t.taskId == id);
    }
    box.write('userDataAll', existingData.toJson());
    if (mounted) {
      setState(() {});
    }

    if (select) {
      var response = await http.delete(
        Uri.parse("$url/todaytasks/deltoday"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: jsonEncode({"task_id": idList}),
      );
      if (response.statusCode == 403) {
        await loadNewRefreshToken();
        response = await http.delete(
          Uri.parse("$url/todaytasks/deltoday"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
          body: jsonEncode({"task_id": idList}),
        );
      }
      log(response.statusCode.toString());
      if (response.statusCode == 200) {}
    } else {}
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
        tasks = List.from(appData.showMyTasks.tasks);
        addTasknameCtl.clear();
        addDescriptionCtl.clear();
        addToday = false;
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
      setState(() {
        tasks = List.from(appData.showMyTasks.tasks);
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
        tasks = List.from(appData.showMyTasks.tasks);
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
          duration: Duration(milliseconds: 0),
          curve: Curves.easeInOut,
          alignment: 1.0,
        );
      }
    });
  }

  String getCurrentDayAndDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE - d MMMM');
    return formatter.format(now);
  }

  void showPopupMenu(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;

    final RenderBox renderBox =
        iconKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        width - offset.dx - size.width,
        0,
      ),
      elevation: 1,
      items: [
        PopupMenuItem(
          value: 'select',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>',
                height: height * 0.025,
                fit: BoxFit.contain,
              ),
              SizedBox(width: width * 0.02),
              Text(
                'Select Task',
                style: TextStyle(
                  fontSize: Get.textTheme.titleLarge!.fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      menuPadding: EdgeInsets.zero,
    ).then((value) {
      if (value == 'select') {
        setState(() {
          hideMenu = true;
        });
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
  }
}
