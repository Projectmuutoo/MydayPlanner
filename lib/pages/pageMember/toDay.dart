import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> with WidgetsBindingObserver {
  // 🧠 Data (Lists and Future)
  late Future<void> loadData;
  TextEditingController addTasknameCtl = TextEditingController();
  TextEditingController addDescriptionCtl = TextEditingController();
  List<TextEditingController> edittaskControllers = [];
  List<TextEditingController> editDescriptionControllers = [];
  List<FocusNode> editTasknameFocusNode = [];
  List<FocusNode> editDescriptionFocusNode = [];
  FocusNode addTasknameFocusNode = FocusNode();
  FocusNode addDescriptionFocusNode = FocusNode();
  bool isLoadings = true;
  bool showShimmer = true;
  bool isTyping = false;
  bool addToday = false;
  int itemCount = 1;
  List tasks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadData = loadDataAsync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in edittaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // แอปถูกย่อหน้าต่างหรือสลับไปแอปอื่น
      for (var controller in edittaskControllers) {
        _saveData(controller.text);
      }
    }
  }

  void _saveData(String value) {
    // ตัวอย่าง: บันทึกข้อความลงใน local storage, database หรือ Firestore
    log('บันทึกข้อความ: $value');
    // เช่น: await FirebaseFirestore.instance.collection('tasks').doc('yourDocId').update({'description': value});
  }

  Future<void> loadDataAsync() async {
    final String response = await rootBundle.loadString(
      'assets/text/today.json',
    );
    tasks = jsonDecode(response);
    edittaskControllers.clear();
    editDescriptionControllers.clear();
    for (var task in tasks) {
      edittaskControllers.add(TextEditingController(text: task['taskname']));
      editDescriptionControllers.add(
        TextEditingController(text: task['description']),
      );
      editTasknameFocusNode.add(FocusNode());
      editDescriptionFocusNode.add(FocusNode());
    }
    setState(() {
      isLoadings = false;
      showShimmer = false;
    });
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
            if (editTasknameFocusNode.any((focusNode) => focusNode.hasFocus)) {
              for (var focusNode in editTasknameFocusNode) {
                focusNode.unfocus();
              }
              setState(() {
                addToday = false;
              });
            }
            if (editDescriptionFocusNode.any(
              (focusNode) => focusNode.hasFocus,
            )) {
              for (var focusNode in editDescriptionFocusNode) {
                focusNode.unfocus();
              }
              setState(() {
                addToday = false;
              });
            }

            setState(() {
              addToday = !addToday;
            });
            addTasknameFocusNode.requestFocus();
          },
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  right: width * 0.05,
                  left: width * 0.05,
                  top: height * 0.01,
                  bottom:
                      addToday &&
                              !editTasknameFocusNode.any(
                                (focusNode) => focusNode.hasFocus,
                              ) &&
                              !editDescriptionFocusNode.any(
                                (focusNode) => focusNode.hasFocus,
                              )
                          ? MediaQuery.of(context).viewInsets.bottom +
                              height * 0.08
                          : height * 0.01,
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (editTasknameFocusNode.any(
                          (focusNode) => focusNode.hasFocus,
                        )) {
                          for (var focusNode in editTasknameFocusNode) {
                            focusNode.unfocus();
                          }
                          setState(() {
                            addToday = false;
                          });
                        }
                        if (editDescriptionFocusNode.any(
                          (focusNode) => focusNode.hasFocus,
                        )) {
                          for (var focusNode in editDescriptionFocusNode) {
                            focusNode.unfocus();
                          }
                          setState(() {
                            addToday = false;
                          });
                        }
                        setState(() {
                          addToday = false;
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Today',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.displaySmall!.fontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    if (editTasknameFocusNode.any(
                                      (focusNode) => focusNode.hasFocus,
                                    )) {
                                      for (var focusNode
                                          in editTasknameFocusNode) {
                                        focusNode.unfocus();
                                      }
                                      setState(() {
                                        addToday = false;
                                      });
                                    }
                                    if (editDescriptionFocusNode.any(
                                      (focusNode) => focusNode.hasFocus,
                                    )) {
                                      for (var focusNode
                                          in editDescriptionFocusNode) {
                                        focusNode.unfocus();
                                      }
                                      setState(() {
                                        addToday = false;
                                      });
                                    }
                                    setState(() {
                                      addToday = false;
                                    });
                                  },
                                  child: SvgPicture.string(
                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 12c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"></path></svg>',
                                    height: height * 0.035,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  getCurrentDayAndDate(),
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                        reverse:
                            addTasknameFocusNode.hasFocus ||
                                    addDescriptionFocusNode.hasFocus
                                ? addToday
                                : false,
                        child: Column(
                          children: [
                            ...tasks.asMap().entries.map((entry) {
                              int index = entry.key;
                              var task = entry.value;
                              return GestureDetector(
                                onTap: () {
                                  if (editTasknameFocusNode.any(
                                    (focusNode) => focusNode.hasFocus,
                                  )) {
                                    for (var focusNode
                                        in editTasknameFocusNode) {
                                      focusNode.unfocus();
                                    }
                                    setState(() {
                                      addToday = false;
                                    });
                                  }
                                  if (editDescriptionFocusNode.any(
                                    (focusNode) => focusNode.hasFocus,
                                  )) {
                                    for (var focusNode
                                        in editDescriptionFocusNode) {
                                      focusNode.unfocus();
                                    }
                                    setState(() {
                                      addToday = false;
                                    });
                                  }
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: () {},
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.005,
                                                vertical: height * 0.002,
                                              ),
                                              child: SvgPicture.string(
                                                '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-80q-83 0-156-31.5T197-197q-54-54-85.5-127T80-480q0-83 31.5-156T197-763q54-54 127-85.5T480-880q83 0 156 31.5T763-763q54 54 85.5 127T880-480q0 83-31.5 156T763-197q-54 54-127 85.5T480-80Zm0-80q134 0 227-93t93-227q0-134-93-227t-227-93q-134 0-227 93t-93 227q0 134 93 227t227 93Zm0-320Z"/></svg>',
                                                height: height * 0.04,
                                                fit: BoxFit.contain,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: width * 0.02),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                TextField(
                                                  controller:
                                                      edittaskControllers[index],
                                                  focusNode:
                                                      editTasknameFocusNode[index],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      task['taskname'] = value;
                                                    });
                                                  },
                                                  onTap: () {
                                                    setState(() {
                                                      addToday = true;
                                                    });
                                                  },
                                                  cursorColor: Color(
                                                    0xFF007AFF,
                                                  ),
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize:
                                                        Get
                                                            .textTheme
                                                            .titleLarge!
                                                            .fontSize,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: height * 0.005,
                                                ),
                                                TextField(
                                                  controller:
                                                      editDescriptionControllers[index],
                                                  focusNode:
                                                      editDescriptionFocusNode[index],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      task['description'] =
                                                          value;
                                                    });
                                                  },
                                                  onTap: () {
                                                    setState(() {
                                                      addToday = true;
                                                    });
                                                  },
                                                  cursorColor: Color(
                                                    0xFF007AFF,
                                                  ),
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize:
                                                        Get
                                                            .textTheme
                                                            .titleSmall!
                                                            .fontSize,
                                                    color: Colors.grey,
                                                  ),
                                                  minLines: 1,
                                                  maxLines: 5,
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: height * 0.01,
                                                  ),
                                                  child: Container(
                                                    width: width,
                                                    height: 0.5,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Column(
                                            //   children: [
                                            //     InkWell(
                                            //       onTap: () {},
                                            //       child: Column(
                                            //         crossAxisAlignment:
                                            //             CrossAxisAlignment
                                            //                 .start,
                                            //         children: [
                                            //           Text(
                                            //             task['taskname'] ?? '',
                                            //             style: TextStyle(
                                            //               fontSize:
                                            //                   Get
                                            //                       .textTheme
                                            //                       .titleLarge!
                                            //                       .fontSize,
                                            //               color: Colors.black,
                                            //             ),
                                            //             overflow:
                                            //                 TextOverflow
                                            //                     .ellipsis,
                                            //           ),
                                            //           SizedBox(
                                            //             height: height * 0.005,
                                            //           ),
                                            //           Text(
                                            //             task['description'] ??
                                            //                 '',
                                            //             style: TextStyle(
                                            //               fontSize:
                                            //                   Get
                                            //                       .textTheme
                                            //                       .titleSmall!
                                            //                       .fontSize,
                                            //               color: Colors.grey,
                                            //             ),
                                            //             maxLines: 6,
                                            //             overflow:
                                            //                 TextOverflow
                                            //                     .ellipsis,
                                            //           ),
                                            //         ],
                                            //       ),
                                            //     ),
                                            //     Padding(
                                            //       padding: EdgeInsets.symmetric(
                                            //         vertical: height * 0.01,
                                            //       ),
                                            //       child: Container(
                                            //         width: width,
                                            //         height: 0.5,
                                            //         color: Colors.grey,
                                            //       ),
                                            //     ),
                                            //   ],
                                            // ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            if (addToday &&
                                !editTasknameFocusNode.any(
                                  (focusNode) => focusNode.hasFocus,
                                ) &&
                                !editDescriptionFocusNode.any(
                                  (focusNode) => focusNode.hasFocus,
                                ))
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
                                            Get.textTheme.titleMedium!.fontSize,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: isTyping ? '' : 'Add title',
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
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: width * 0.02,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (addToday &&
                                !editTasknameFocusNode.any(
                                  (focusNode) => focusNode.hasFocus,
                                ) &&
                                !editDescriptionFocusNode.any(
                                  (focusNode) => focusNode.hasFocus,
                                ))
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
                                            Get.textTheme.titleMedium!.fontSize,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            isTyping ? '' : 'Add Description',
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
                                        contentPadding: EdgeInsets.symmetric(
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
                    ),
                    if (!addToday) SizedBox(height: height * 0.02),
                    if (!addToday)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                addToday = !addToday;
                              });
                              addTasknameFocusNode.requestFocus();
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String getCurrentDayAndDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE - d MMMM');
    return formatter.format(now);
  }
}
