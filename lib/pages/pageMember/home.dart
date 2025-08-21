import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/createBoardListsPostRequest.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
import 'package:mydayplanner/pages/pageMember/detailBoards/tasksDetail.dart';
import 'package:mydayplanner/pages/pageMember/menu/menuReport.dart';
import 'package:mydayplanner/pages/pageMember/detailBoards/boardShowTasks.dart';
import 'package:mydayplanner/pages/pageMember/menu/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mydayplanner/shared/appData.dart';
import 'package:mydayplanner/splash.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // 📦 Storage
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  var box = GetStorage();

  // 🔑 Global Keys
  final GlobalKey iconKey = GlobalKey();

  // 🧠 Late Variables
  late String url;
  OverlayEntry? menuEntryShowMenuBoard;
  // 📊 Integer Variables
  int? loadingBoardId;

  // 🔤 String Variables
  String emailUser = '';
  String name = '';
  String userProfile = '';
  String? focusedBoardId;
  String? randomMessage;
  String loadingText = '.';

  // 🔢 Double Variables
  double progressValue = 0.0;
  double slider = 160;
  double sliderTop = 100;

  // 🔘 Boolean Variables
  bool displayFormat = false;
  bool isTyping = false;
  bool hideSearchMyBoards = false;
  bool isDeleteBoard = false;
  bool isSelectBoard = false;
  bool _hasFetchedData = false;

  // 🕒 Timers
  Timer? progressTimer;
  Timer? _timer;
  Timer? timer2;

  // 📥 Text Editing Controllers
  TextEditingController boardCtl = TextEditingController();
  TextEditingController searchCtl = TextEditingController();

  // 🧠 Focus Nodes
  FocusNode searchFocusNode = FocusNode();
  FocusNode boardFocusNode = FocusNode();

  // 🔤 Font Weights
  FontWeight privateFontWeight = FontWeight.w600;
  FontWeight groupFontWeight = FontWeight.w500;

  // 🗺️ Map
  Map<String, GlobalKey> boardInfoKeysGrid = {};
  Map<String, GlobalKey> boardInfoKeysList = {};

  // 📋 Lists
  List boards = [];
  List<Task> tasks = [];
  List<String> selectedPrivateBoards = [];
  List<String> selectedGroupBoards = [];

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    // var re = box.getKeys();
    // for (var i in re) {
    //   log(i);
    // }

    showDisplays();
    loadMessages();
    loadDataAsync();
    timer2 = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) loadDataAsync();
    });

    searchFocusNode.addListener(() {
      if (!searchFocusNode.hasFocus && searchCtl.text.isEmpty) {
        setState(() {
          hideSearchMyBoards = false;
        });
      }
    });
  }

  Future<void> loadDataAsync() async {
    loadDisplays();
    await checkExpiresRefreshToken();
  }

  @override
  void dispose() {
    progressTimer?.cancel();
    _timer?.cancel();
    timer2?.cancel();
    boardCtl.dispose();
    searchCtl.dispose();
    searchFocusNode.dispose();
    boardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final isPrivateMode = privateFontWeight == FontWeight.w600;
    final currentBoards = boards;
    final currentSelected = isPrivateMode
        ? selectedPrivateBoards
        : selectedGroupBoards;

    return GestureDetector(
      onTap: () {
        if (searchFocusNode.hasFocus || hideSearchMyBoards) {
          searchFocusNode.unfocus();
          setState(() {
            hideSearchMyBoards = false;
            searchCtl.clear();
          });
        }
        if (boardCtl.text.isNotEmpty) {
          setState(() {
            boardCtl.clear();
          });
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: Stack(
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        !hideSearchMyBoards
                            ? Row(
                                children: [
                                  ClipOval(
                                    child: userProfile == 'none-url'
                                        ? Container(
                                            width: height * 0.06,
                                            height: height * 0.06,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFF2F2F6),
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              color: Color(0xFF979595),
                                              size: height * 0.04,
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: () {
                                              final appData =
                                                  Provider.of<Appdata>(
                                                    context,
                                                    listen: false,
                                                  );
                                              final profileUrl = appData
                                                  .changeMyProfileProvider
                                                  .profile;

                                              if (profileUrl.isNotEmpty) {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => Dialog(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        Get.back();
                                                      },
                                                      child: Image.network(
                                                        profileUrl,
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black12,
                                              ),
                                              child: Image.network(
                                                context
                                                    .watch<Appdata>()
                                                    .changeMyProfileProvider
                                                    .profile,
                                                width: height * 0.06,
                                                height: height * 0.06,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                  ),
                                  SizedBox(width: width * 0.015),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hello, ${context.watch<Appdata>().changeMyProfileProvider.name}',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .labelMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        randomMessage.toString(),
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .labelMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : AnimatedContainer(
                                duration: Duration.zero,
                                width: width * 0.8,
                                child: TextField(
                                  controller: searchCtl,
                                  focusNode: searchFocusNode,
                                  keyboardType: TextInputType.text,
                                  cursorColor: Color(0xFF3B82F6),
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleSmall!.fontSize!,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: isTyping ? '' : 'Search',
                                    hintStyle: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize!,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey[600],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.grey[600],
                                    ),
                                    suffixIcon: searchCtl.text.isNotEmpty
                                        ? IconButton(
                                            onPressed: () {
                                              searchCtl.clear();
                                            },
                                            icon: Icon(
                                              Icons.clear,
                                              color: Colors.grey[600],
                                            ),
                                          )
                                        : null,
                                    constraints: BoxConstraints(
                                      maxHeight: height * 0.05,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: width * 0.02,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Color(0xFFE2E8F0),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Color(0xFF3B82F6),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        currentSelected.isEmpty && !isSelectBoard
                            ? Row(
                                children: [
                                  !hideSearchMyBoards
                                      ? GestureDetector(
                                          onTap: () {
                                            searchMyBoards();
                                            setState(() {
                                              selectedPrivateBoards.clear();
                                              selectedGroupBoards.clear();
                                            });
                                          },
                                          child: Icon(
                                            Icons.search,
                                            size: height * 0.035,
                                            color: Colors.black87,
                                          ),
                                        )
                                      : SizedBox.shrink(),
                                  GestureDetector(
                                    key: iconKey,
                                    onTap: () {
                                      !hideSearchMyBoards
                                          ? showPopupMenu(context)
                                          : setState(() {
                                              hideSearchMyBoards = false;
                                              selectedPrivateBoards.clear();
                                              selectedGroupBoards.clear();
                                              if (searchCtl.text.isNotEmpty) {
                                                searchCtl.clear();
                                              }
                                            });
                                    },
                                    child: Icon(
                                      !hideSearchMyBoards
                                          ? Icons.more_vert
                                          : Icons.close,
                                      size: height * 0.035,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: width * 0.02,
                                    ),
                                    child: Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: currentSelected.isNotEmpty
                                            ? getDialogDeleteBoardBySelected
                                            : null,
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.delete,
                                            size: height * 0.035,
                                            color: currentSelected.isNotEmpty
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        isSelectBoard = false;
                                        selectedPrivateBoards.clear();
                                        selectedGroupBoards.clear();
                                      });
                                    },
                                    child: Text(
                                      "Save",
                                      style: TextStyle(
                                        fontSize: Get
                                            .textTheme
                                            .titleMedium!
                                            .fontSize!,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF007AFF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                    if (searchCtl.text.isEmpty)
                      Expanded(
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                SizedBox(height: height * 0.01),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFEFF6FF),
                                        Color(0xFFF2F2F6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.03,
                                      vertical: height * 0.01,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Today',
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .titleLarge!
                                                    .fontSize!,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.03,
                                                vertical: height * 0.005,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(
                                                      0xFF3B82F6,
                                                    ).withOpacity(0.8),
                                                    Color(
                                                      0xFF1D4ED8,
                                                    ).withOpacity(0.8),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Text(
                                                'is coming!!',
                                                style: TextStyle(
                                                  fontSize: Get
                                                      .textTheme
                                                      .titleSmall!
                                                      .fontSize!,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: height * 0.005),
                                        if (getUpcomingTasks(tasks).isEmpty)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: height * 0.02,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .check_circle_outline_rounded,
                                                  color: Color(0xFF10B981),
                                                  size: 20,
                                                ),
                                                SizedBox(width: width * 0.01),
                                                Text(
                                                  "No tasks for today",
                                                  style: TextStyle(
                                                    fontSize: Get
                                                        .textTheme
                                                        .titleSmall!
                                                        .fontSize!,
                                                    color: Color(0xFF10B981),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ...getUpcomingTasks(tasks).map((task) {
                                          return TweenAnimationBuilder(
                                            tween: Tween<double>(
                                              begin: 0.0,
                                              end: 1.0,
                                            ),
                                            duration: Duration(
                                              milliseconds: 400,
                                            ),
                                            curve: Curves.easeOutCirc,
                                            builder: (context, value, child) {
                                              return Transform.translate(
                                                offset: Offset(
                                                  0,
                                                  (1 - value) * -30,
                                                ),
                                                child: Opacity(
                                                  opacity: value.clamp(
                                                    0.0,
                                                    1.0,
                                                  ),
                                                  child: Transform.scale(
                                                    scale: 0.8 + (value * 0.2),
                                                    child: child,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: GestureDetector(
                                              onTap: () async {
                                                final result =
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            TasksdetailPage(
                                                              taskId:
                                                                  task.taskId,
                                                            ),
                                                      ),
                                                    );
                                                if (result == 'refresh') {
                                                  loadDataAsync();
                                                }
                                              },
                                              child: Container(
                                                margin: EdgeInsets.symmetric(
                                                  vertical: height * 0.002,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.03,
                                                  vertical: height * 0.01,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Color(
                                                      0xFF3B82F6,
                                                    ).withOpacity(0.1),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.05),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 4,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            task.priority == '1'
                                                            ? Colors.green
                                                            : task.priority ==
                                                                  '2'
                                                            ? Colors.orange
                                                            : task.priority ==
                                                                  '3'
                                                            ? Colors.red
                                                            : Color(0xFF3B82F6),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              2,
                                                            ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: width * 0.03,
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            task.taskName,
                                                            style: TextStyle(
                                                              fontSize: Get
                                                                  .textTheme
                                                                  .labelMedium!
                                                                  .fontSize!,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Color(
                                                                0xFF1E293B,
                                                              ),
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                height * 0.005,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Container(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                      2,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: Color(
                                                                    0xFF3B82F6,
                                                                  ).withOpacity(0.1),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        4,
                                                                      ),
                                                                ),
                                                                child: Icon(
                                                                  Icons
                                                                      .schedule,
                                                                  color: Color(
                                                                    0xFF3B82F6,
                                                                  ),
                                                                  size: 14,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width:
                                                                    width *
                                                                    0.01,
                                                              ),
                                                              Text(
                                                                timeUntilDetailed(
                                                                  task
                                                                      .notifications
                                                                      .first
                                                                      .dueDate,
                                                                ),
                                                                style: TextStyle(
                                                                  fontSize: Get
                                                                      .textTheme
                                                                      .labelSmall!
                                                                      .fontSize!,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Color(
                                                                    0xFF64748B,
                                                                  ),
                                                                ),
                                                              ),
                                                              FutureBuilder<
                                                                String
                                                              >(
                                                                future:
                                                                    showTimeRemineMeBefore(
                                                                      task.taskId,
                                                                    ),
                                                                builder:
                                                                    (
                                                                      context,
                                                                      snapshot,
                                                                    ) {
                                                                      if (snapshot
                                                                              .hasData &&
                                                                          snapshot
                                                                              .data!
                                                                              .isNotEmpty) {
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
                                                                                    0.035,
                                                                                fit: BoxFit.contain,
                                                                                color: Colors.red,
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              snapshot.data!,
                                                                              style: TextStyle(
                                                                                fontSize: Get.textTheme.labelSmall!.fontSize!,
                                                                                color: Colors.red,
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
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                        8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Color(
                                                          0xFF3B82F6,
                                                        ).withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.arrow_forward_ios,
                                                        color: Color(
                                                          0xFF3B82F6,
                                                        ),
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: height * 0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        if (isSelectBoard)
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (currentSelected.length ==
                                                    currentBoards
                                                        .where(
                                                          (b) =>
                                                              b.createdBy
                                                                  .toString() ==
                                                              box
                                                                  .read(
                                                                    'userProfile',
                                                                  )['userid']
                                                                  .toString(),
                                                        )
                                                        .toList()
                                                        .length) {
                                                  isPrivateMode
                                                      ? selectedPrivateBoards
                                                            .clear()
                                                      : selectedGroupBoards
                                                            .clear();
                                                } else {
                                                  final newIds = currentBoards
                                                      .where(
                                                        (b) =>
                                                            b.createdBy
                                                                .toString() ==
                                                            box
                                                                .read(
                                                                  'userProfile',
                                                                )['userid']
                                                                .toString(),
                                                      )
                                                      .map(
                                                        (board) => board.boardId
                                                            .toString(),
                                                      )
                                                      .toList();
                                                  if (isPrivateMode) {
                                                    selectedPrivateBoards =
                                                        newIds;
                                                  } else {
                                                    selectedGroupBoards =
                                                        newIds;
                                                  }
                                                }
                                              });
                                            },
                                            child: Icon(
                                              currentSelected.length ==
                                                      currentBoards
                                                          .where(
                                                            (b) =>
                                                                b.createdBy
                                                                    .toString() ==
                                                                box
                                                                    .read(
                                                                      'userProfile',
                                                                    )['userid']
                                                                    .toString(),
                                                          )
                                                          .toList()
                                                          .length
                                                  ? Icons.check_circle_rounded
                                                  : Icons
                                                        .radio_button_unchecked,
                                              size: height * 0.04,
                                              color:
                                                  currentSelected.length ==
                                                      currentBoards
                                                          .where(
                                                            (b) =>
                                                                b.createdBy
                                                                    .toString() ==
                                                                box
                                                                    .read(
                                                                      'userProfile',
                                                                    )['userid']
                                                                    .toString(),
                                                          )
                                                          .toList()
                                                          .length
                                                  ? Color(0xFF007AFF)
                                                  : Colors.grey,
                                            ),
                                          ),
                                        Text(
                                          isSelectBoard
                                              ? currentSelected.isNotEmpty
                                                    ? ' ${currentSelected.length} Selected'
                                                    : ' Select Board'
                                              : 'My Boards',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .titleLarge!
                                                .fontSize!,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              toggleDisplayFormat(true),
                                          child: Icon(
                                            !displayFormat
                                                ? Icons
                                                      .format_list_bulleted_sharp
                                                : Icons.view_list_rounded,
                                            size: height * 0.032,
                                            color: displayFormat
                                                ? Colors.black
                                                : Color(0xFF979595),
                                          ),
                                        ),
                                        SizedBox(width: width * 0.01),
                                        GestureDetector(
                                          onTap: () =>
                                              toggleDisplayFormat(false),
                                          child: Icon(
                                            displayFormat
                                                ? Icons.grid_view
                                                : Icons.grid_view_rounded,
                                            size: height * 0.03,
                                            color: !displayFormat
                                                ? Colors.black
                                                : Color(0xFF979595),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                privateFontWeight ==
                                                    FontWeight.w600
                                                ? Colors.white
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow:
                                                privateFontWeight ==
                                                    FontWeight.w600
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 1,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            onTap: () {
                                              var boardData =
                                                  AllDataUserGetResponst.fromJson(
                                                    box.read('userDataAll'),
                                                  );
                                              final appData =
                                                  Provider.of<Appdata>(
                                                    context,
                                                    listen: false,
                                                  );
                                              appData.showMyBoards.setBoards(
                                                boardData,
                                              );
                                              var createdBoards = appData
                                                  .showMyBoards
                                                  .createdBoards;
                                              setState(() {
                                                boards = createdBoards;
                                                privateFontWeight =
                                                    FontWeight.w600;
                                                groupFontWeight =
                                                    FontWeight.w500;
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: height * 0.01,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.lock_rounded,
                                                    size: 16,
                                                    color:
                                                        privateFontWeight ==
                                                            FontWeight.w600
                                                        ? Color(0xFF3B82F6)
                                                        : Color(0xFF64748B),
                                                  ),
                                                  SizedBox(width: width * 0.02),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Private ',
                                                        style: TextStyle(
                                                          fontSize: Get
                                                              .textTheme
                                                              .titleMedium!
                                                              .fontSize!,
                                                          fontWeight:
                                                              privateFontWeight,
                                                          color:
                                                              privateFontWeight ==
                                                                  FontWeight
                                                                      .w600
                                                              ? Color(
                                                                  0xFF3B82F6,
                                                                )
                                                              : Color(
                                                                  0xFF64748B,
                                                                ),
                                                        ),
                                                      ),
                                                      findNumberOfAllTask(
                                                                true,
                                                              ) ==
                                                              '0'
                                                          ? SizedBox.shrink()
                                                          : Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        width *
                                                                        0.02,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Color(
                                                                  0xFF3B82F6,
                                                                ).withOpacity(0.1),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: Text(
                                                                findNumberOfAllTask(
                                                                  true,
                                                                ),
                                                                style: TextStyle(
                                                                  fontSize: Get
                                                                      .textTheme
                                                                      .titleSmall!
                                                                      .fontSize!,
                                                                  fontWeight:
                                                                      privateFontWeight,
                                                                  color:
                                                                      privateFontWeight ==
                                                                          FontWeight
                                                                              .w600
                                                                      ? Color(
                                                                          0xFF3B82F6,
                                                                        )
                                                                      : Color(
                                                                          0xFF64748B,
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
                                      ),
                                      SizedBox(width: width * 0.01),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                groupFontWeight ==
                                                    FontWeight.w600
                                                ? Colors.white
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow:
                                                groupFontWeight ==
                                                    FontWeight.w600
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 1,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            onTap: () {
                                              var boardData =
                                                  AllDataUserGetResponst.fromJson(
                                                    box.read('userDataAll'),
                                                  );
                                              final appData =
                                                  Provider.of<Appdata>(
                                                    context,
                                                    listen: false,
                                                  );
                                              appData.showMyBoards.setBoards(
                                                boardData,
                                              );
                                              var memberBoards = appData
                                                  .showMyBoards
                                                  .memberBoards;
                                              setState(() {
                                                boards = memberBoards;
                                                privateFontWeight =
                                                    FontWeight.w500;
                                                groupFontWeight =
                                                    FontWeight.w600;
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: height * 0.01,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.groups_2_outlined,
                                                    size: 18,
                                                    color:
                                                        groupFontWeight ==
                                                            FontWeight.w600
                                                        ? Color(0xFF3B82F6)
                                                        : Color(0xFF64748B),
                                                  ),
                                                  SizedBox(width: width * 0.02),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Groups ',
                                                        style: TextStyle(
                                                          fontSize: Get
                                                              .textTheme
                                                              .titleMedium!
                                                              .fontSize!,
                                                          fontWeight:
                                                              groupFontWeight,
                                                          color:
                                                              groupFontWeight ==
                                                                  FontWeight
                                                                      .w600
                                                              ? Color(
                                                                  0xFF3B82F6,
                                                                )
                                                              : Color(
                                                                  0xFF64748B,
                                                                ),
                                                        ),
                                                      ),
                                                      findNumberOfAllTask(
                                                                false,
                                                              ) ==
                                                              '0'
                                                          ? SizedBox.shrink()
                                                          : Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        width *
                                                                        0.02,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Color(
                                                                  0xFF3B82F6,
                                                                ).withOpacity(0.1),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: Text(
                                                                findNumberOfAllTask(
                                                                  false,
                                                                ),
                                                                style: TextStyle(
                                                                  fontSize: Get
                                                                      .textTheme
                                                                      .titleSmall!
                                                                      .fontSize!,
                                                                  fontWeight:
                                                                      groupFontWeight,
                                                                  color:
                                                                      groupFontWeight ==
                                                                          FontWeight
                                                                              .w600
                                                                      ? Color(
                                                                          0xFF3B82F6,
                                                                        )
                                                                      : Color(
                                                                          0xFF64748B,
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
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: height * 0.005),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      if (focusedBoardId != null)
                                        Positioned.fill(
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 6,
                                              sigmaY: 6,
                                            ),
                                            child: Container(
                                              color: Colors.black.withOpacity(
                                                0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      SingleChildScrollView(
                                        physics:
                                            AlwaysScrollableScrollPhysics(),
                                        child: Column(
                                          children: [
                                            AnimatedCrossFade(
                                              firstChild: GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.01,
                                                  vertical: height * 0.005,
                                                ),
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2,
                                                      crossAxisSpacing:
                                                          width * 0.03,
                                                      mainAxisSpacing:
                                                          width * 0.025,
                                                      childAspectRatio:
                                                          (width * 0.4) /
                                                          (height * 0.15),
                                                    ),
                                                itemCount: boards.length + 1,
                                                itemBuilder: (context, index) {
                                                  if (index == boards.length) {
                                                    return InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      onTap:
                                                          loadingBoardId == null
                                                          ? (isSelectBoard
                                                                ? null
                                                                : createNewBoard)
                                                          : null,
                                                      child: Stack(
                                                        children: [
                                                          DottedBorder(
                                                            options: RoundedRectDottedBorderOptions(
                                                              radius:
                                                                  Radius.circular(
                                                                    12,
                                                                  ),
                                                              color:
                                                                  isSelectBoard ||
                                                                      focusedBoardId !=
                                                                          null
                                                                  ? Colors
                                                                        .transparent
                                                                  : Colors
                                                                        .black12,
                                                              dashPattern: [
                                                                1,
                                                                2,
                                                              ],
                                                              strokeWidth: 1.5,
                                                            ),
                                                            child: Container(
                                                              width: width,
                                                              decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                color:
                                                                    isSelectBoard
                                                                    ? Colors
                                                                          .black12
                                                                    : null,
                                                              ),
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Icon(
                                                                  Icons.add,
                                                                  size:
                                                                      height *
                                                                      0.025,
                                                                  color: Colors
                                                                      .black38,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          if (focusedBoardId !=
                                                              null)
                                                            Positioned.fill(
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                child: BackdropFilter(
                                                                  filter:
                                                                      ImageFilter.blur(
                                                                        sigmaX:
                                                                            6,
                                                                        sigmaY:
                                                                            6,
                                                                      ),
                                                                  child: Container(
                                                                    color: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                          0.1,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                                  final board = boards[index];
                                                  final String keyId =
                                                      '${board.boardName}_$index';
                                                  final bool loadWaitNewBoard =
                                                      loadingBoardId ==
                                                      board.boardId;

                                                  if (!boardInfoKeysGrid
                                                      .containsKey(keyId)) {
                                                    boardInfoKeysGrid[keyId] =
                                                        GlobalKey();
                                                  }

                                                  final bool isSelected =
                                                      focusedBoardId == keyId;

                                                  return TweenAnimationBuilder(
                                                    tween: Tween<double>(
                                                      begin: 0.0,
                                                      end: 1.0,
                                                    ),
                                                    duration: Duration(
                                                      milliseconds: 400,
                                                    ),
                                                    curve: Curves.easeOutCirc,
                                                    builder: (context, value, child) {
                                                      return Transform.translate(
                                                        offset: Offset(
                                                          0,
                                                          (1 - value) * -30,
                                                        ),
                                                        child: Opacity(
                                                          opacity: value.clamp(
                                                            0.0,
                                                            1.0,
                                                          ),
                                                          child:
                                                              Transform.scale(
                                                                scale:
                                                                    isSelected
                                                                    ? 1.03
                                                                    : 1.0,
                                                                child: child,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    child: SizedBox(
                                                      key:
                                                          boardInfoKeysGrid[keyId],
                                                      child: AnimatedContainer(
                                                        duration: Duration(
                                                          milliseconds: 200,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              loadWaitNewBoard
                                                              ? Color(
                                                                  0xFFF2F2F6,
                                                                )
                                                              : isSelectBoard &&
                                                                    board.createdBy
                                                                            .toString() !=
                                                                        box
                                                                            .read(
                                                                              'userProfile',
                                                                            )['userid']
                                                                            .toString()
                                                              ? Color(
                                                                  0xFFF2F5F8,
                                                                )
                                                              : isSelected
                                                              ? Color(
                                                                  0xFFE6F0FF,
                                                                )
                                                              : currentSelected
                                                                    .contains(
                                                                      board
                                                                          .boardId
                                                                          .toString(),
                                                                    )
                                                              ? Color(
                                                                  0xFF3B82F6,
                                                                ).withOpacity(
                                                                  0.15,
                                                                )
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? Color(
                                                                    0xFF2563EB,
                                                                  )
                                                                : currentSelected
                                                                      .contains(
                                                                        board
                                                                            .boardId
                                                                            .toString(),
                                                                      )
                                                                ? Color(
                                                                    0xFF3B82F6,
                                                                  )
                                                                : Color(
                                                                    0xFFE2E8F0,
                                                                  ),
                                                            width: isSelected
                                                                ? 2
                                                                : 1,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: isSelected
                                                                  ? Color(
                                                                      0xFF3B82F6,
                                                                    ).withOpacity(
                                                                      0.3,
                                                                    )
                                                                  : Colors.black
                                                                        .withOpacity(
                                                                          0.02,
                                                                        ),
                                                              blurRadius: 2,
                                                              offset: Offset(
                                                                0,
                                                                isSelected
                                                                    ? 0
                                                                    : 2,
                                                              ),
                                                              spreadRadius:
                                                                  isSelected
                                                                  ? 1
                                                                  : 0,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            onTap:
                                                                !loadWaitNewBoard
                                                                ? isSelectBoard &&
                                                                          board.createdBy.toString() ==
                                                                              box.read('userProfile')['userid'].toString()
                                                                      ? () {
                                                                          setState(() {
                                                                            if (currentSelected.contains(
                                                                              board.boardId.toString(),
                                                                            )) {
                                                                              currentSelected.remove(
                                                                                board.boardId.toString(),
                                                                              );
                                                                            } else {
                                                                              currentSelected.add(
                                                                                board.boardId.toString(),
                                                                              );
                                                                            }
                                                                          });
                                                                        }
                                                                      : !isSelectBoard ||
                                                                            board.createdBy
                                                                                    .toString() ==
                                                                                box
                                                                                    .read(
                                                                                      'userProfile',
                                                                                    )['userid']
                                                                                    .toString()
                                                                      ? () {
                                                                          goToMyTask(
                                                                            board.boardId.toString(),
                                                                            board.boardName,
                                                                            tokenBoard:
                                                                                groupFontWeight ==
                                                                                    FontWeight.w600
                                                                                ? board.token
                                                                                : null,
                                                                          );
                                                                        }
                                                                      : null
                                                                : null,
                                                            onLongPress:
                                                                isSelectBoard
                                                                ? null
                                                                : () {
                                                                    final String
                                                                    keyId =
                                                                        '${board.boardName}_$index';
                                                                    setState(() {
                                                                      focusedBoardId =
                                                                          focusedBoardId ==
                                                                              keyId
                                                                          ? null
                                                                          : keyId;
                                                                    });
                                                                    showInfoMenuBoard(
                                                                      context,
                                                                      board,
                                                                      keyId:
                                                                          keyId,
                                                                      grid:
                                                                          true,
                                                                      shareToken:
                                                                          groupFontWeight ==
                                                                              FontWeight.w600
                                                                          ? board.token
                                                                          : null,
                                                                    );
                                                                  },
                                                            child: Stack(
                                                              children: [
                                                                Container(
                                                                  width: double
                                                                      .infinity,
                                                                  height: double
                                                                      .infinity,
                                                                  padding: EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        width *
                                                                        0.02,
                                                                  ),
                                                                  child: Center(
                                                                    child: Text(
                                                                      board
                                                                          .boardName,
                                                                      style: TextStyle(
                                                                        fontSize: Get
                                                                            .textTheme
                                                                            .titleSmall!
                                                                            .fontSize!,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        color:
                                                                            loadWaitNewBoard
                                                                            ? Color.fromRGBO(
                                                                                151,
                                                                                149,
                                                                                149,
                                                                                progressValue,
                                                                              )
                                                                            : isSelected
                                                                            ? Color(
                                                                                0xFF1E40AF,
                                                                              )
                                                                            : Colors.black,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      maxLines:
                                                                          3,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (isSelectBoard &&
                                                                    board.createdBy
                                                                            .toString() ==
                                                                        box
                                                                            .read(
                                                                              'userProfile',
                                                                            )['userid']
                                                                            .toString())
                                                                  Positioned(
                                                                    left: 4,
                                                                    top: 4,
                                                                    child: Icon(
                                                                      currentSelected.contains(
                                                                            board.boardId.toString(),
                                                                          )
                                                                          ? Icons.check_circle_rounded
                                                                          : Icons.radio_button_unchecked,
                                                                      size:
                                                                          height *
                                                                          0.03,
                                                                      color:
                                                                          currentSelected.contains(
                                                                            board.boardId.toString(),
                                                                          )
                                                                          ? Color(
                                                                              0xFF2563EB,
                                                                            )
                                                                          : Colors.grey,
                                                                    ),
                                                                  ),
                                                                if (groupFontWeight ==
                                                                    FontWeight
                                                                        .w600)
                                                                  if (board
                                                                          .createdBy
                                                                          .toString() !=
                                                                      box
                                                                          .read(
                                                                            'userProfile',
                                                                          )['userid']
                                                                          .toString())
                                                                    Positioned(
                                                                      right: 6,
                                                                      top: 4,
                                                                      child: ClipOval(
                                                                        child:
                                                                            board.createdByUser.profile ==
                                                                                'none-url'
                                                                            ? Container(
                                                                                width:
                                                                                    height *
                                                                                    0.035,
                                                                                height:
                                                                                    height *
                                                                                    0.035,
                                                                                decoration: BoxDecoration(
                                                                                  shape: BoxShape.circle,
                                                                                  color: Color(
                                                                                    0xFFF2F2F6,
                                                                                  ),
                                                                                ),
                                                                                child: Icon(
                                                                                  Icons.person,
                                                                                  size:
                                                                                      height *
                                                                                      0.025,
                                                                                  color: Color(
                                                                                    0xFF979595,
                                                                                  ),
                                                                                ),
                                                                              )
                                                                            : Container(
                                                                                decoration: BoxDecoration(
                                                                                  shape: BoxShape.circle,
                                                                                  color: Colors.black12,
                                                                                ),
                                                                                child: Image.network(
                                                                                  board.createdByUser.profile,
                                                                                  width:
                                                                                      height *
                                                                                      0.035,
                                                                                  height:
                                                                                      height *
                                                                                      0.035,
                                                                                  fit: BoxFit.cover,
                                                                                ),
                                                                              ),
                                                                      ),
                                                                    ),
                                                                Positioned(
                                                                  bottom: 4,
                                                                  left: 6,
                                                                  child: Row(
                                                                    children: [
                                                                      Container(
                                                                        padding:
                                                                            EdgeInsets.all(
                                                                              2,
                                                                            ),
                                                                        decoration: BoxDecoration(
                                                                          color: Color(
                                                                            0xFF3B82F6,
                                                                          ).withOpacity(0.1),
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                4,
                                                                              ),
                                                                        ),
                                                                        child: Icon(
                                                                          Icons
                                                                              .checklist_rounded,
                                                                          size:
                                                                              16,
                                                                          color: Color(
                                                                            0xFF4A89DC,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      FutureBuilder<
                                                                        String
                                                                      >(
                                                                        future: AppDataShareShowEditInfo.findNumberOFTasks(
                                                                          board,
                                                                          groupFontWeight,
                                                                        ),
                                                                        builder:
                                                                            (
                                                                              context,
                                                                              snapshot,
                                                                            ) {
                                                                              if (snapshot.hasData &&
                                                                                  snapshot.data!.isNotEmpty) {
                                                                                return Text(
                                                                                  ' ${snapshot.data} tasks ',
                                                                                  style: TextStyle(
                                                                                    fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                    fontWeight: FontWeight.w500,
                                                                                    color: Colors.black45,
                                                                                  ),
                                                                                );
                                                                              } else {
                                                                                return Padding(
                                                                                  padding: EdgeInsets.only(
                                                                                    left:
                                                                                        width *
                                                                                        0.01,
                                                                                  ),
                                                                                  child: Text(
                                                                                    'Loading...',
                                                                                    style: TextStyle(
                                                                                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                      fontWeight: FontWeight.w500,
                                                                                      color: Colors.black45,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              }
                                                                            },
                                                                      ),
                                                                      if (groupFontWeight ==
                                                                          FontWeight
                                                                              .w600)
                                                                        FutureBuilder<
                                                                          String
                                                                        >(
                                                                          future: showMembersCount(
                                                                            board,
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
                                                                                      Icon(
                                                                                        Icons.circle,
                                                                                        size: 4,
                                                                                        color: Colors.black45,
                                                                                      ),
                                                                                      Text(
                                                                                        ' ${snapshot.data!} members',
                                                                                        style: TextStyle(
                                                                                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                          fontWeight: FontWeight.w500,
                                                                                          color: Colors.black45,
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
                                                                ),
                                                                if (focusedBoardId !=
                                                                        null &&
                                                                    !isSelected)
                                                                  Positioned.fill(
                                                                    child: ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                      child: BackdropFilter(
                                                                        filter: ImageFilter.blur(
                                                                          sigmaX:
                                                                              6,
                                                                          sigmaY:
                                                                              6,
                                                                        ),
                                                                        child: Container(
                                                                          color: Colors.black.withOpacity(
                                                                            0.1,
                                                                          ),
                                                                        ),
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
                                              ),
                                              secondChild: ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.015,
                                                  vertical: height * 0.005,
                                                ),
                                                itemCount: boards.length + 1,
                                                itemBuilder: (context, index) {
                                                  if (index == boards.length) {
                                                    return InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      onTap:
                                                          loadingBoardId == null
                                                          ? (isSelectBoard
                                                                ? null
                                                                : createNewBoard)
                                                          : null,
                                                      child: Stack(
                                                        children: [
                                                          DottedBorder(
                                                            options: RoundedRectDottedBorderOptions(
                                                              radius:
                                                                  Radius.circular(
                                                                    12,
                                                                  ),
                                                              color:
                                                                  isSelectBoard ||
                                                                      focusedBoardId !=
                                                                          null
                                                                  ? Colors
                                                                        .transparent
                                                                  : Colors
                                                                        .black12,
                                                              dashPattern: [
                                                                1,
                                                                2,
                                                              ],
                                                              strokeWidth: 1.5,
                                                            ),
                                                            child: Container(
                                                              width: width,
                                                              height:
                                                                  height * 0.07,
                                                              decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                color:
                                                                    isSelectBoard
                                                                    ? Colors
                                                                          .black12
                                                                    : null,
                                                              ),
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Icon(
                                                                  Icons.add,
                                                                  size:
                                                                      height *
                                                                      0.025,
                                                                  color: Colors
                                                                      .black38,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          if (focusedBoardId !=
                                                              null)
                                                            Positioned.fill(
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                child: BackdropFilter(
                                                                  filter:
                                                                      ImageFilter.blur(
                                                                        sigmaX:
                                                                            6,
                                                                        sigmaY:
                                                                            6,
                                                                      ),
                                                                  child: Container(
                                                                    color: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                          0.1,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                                  final board = boards[index];
                                                  final String keyId =
                                                      '${board.boardName}_$index';
                                                  final bool loadWaitNewBoard =
                                                      loadingBoardId ==
                                                      board.boardId;
                                                  if (!boardInfoKeysList
                                                      .containsKey(keyId)) {
                                                    boardInfoKeysList[keyId] =
                                                        GlobalKey();
                                                  }
                                                  final bool isSelected =
                                                      focusedBoardId == keyId;

                                                  return TweenAnimationBuilder(
                                                    tween: Tween<double>(
                                                      begin: 0.0,
                                                      end: 1.0,
                                                    ),
                                                    duration: Duration(
                                                      milliseconds: 400,
                                                    ),
                                                    curve: Curves.easeOutCirc,
                                                    builder: (context, value, child) {
                                                      return Transform.translate(
                                                        offset: Offset(
                                                          0,
                                                          (1 - value) * -30,
                                                        ),
                                                        child: Opacity(
                                                          opacity: value.clamp(
                                                            0.0,
                                                            1.0,
                                                          ),
                                                          child:
                                                              Transform.scale(
                                                                scale:
                                                                    isSelected
                                                                    ? 1.03
                                                                    : 1.0,
                                                                child: child,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    child: Padding(
                                                      key:
                                                          boardInfoKeysList[keyId],
                                                      padding: EdgeInsets.only(
                                                        bottom: height * 0.01,
                                                      ),
                                                      child: AnimatedContainer(
                                                        duration: Duration(
                                                          milliseconds: 200,
                                                        ),
                                                        width: width,
                                                        height: height * 0.076,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              loadWaitNewBoard
                                                              ? Color(
                                                                  0xFFF2F2F6,
                                                                )
                                                              : isSelectBoard &&
                                                                    board.createdBy
                                                                            .toString() !=
                                                                        box
                                                                            .read(
                                                                              'userProfile',
                                                                            )['userid']
                                                                            .toString()
                                                              ? Color(
                                                                  0xFFF2F5F8,
                                                                )
                                                              : isSelected
                                                              ? Color(
                                                                  0xFFE6F0FF,
                                                                )
                                                              : currentSelected
                                                                    .contains(
                                                                      board
                                                                          .boardId
                                                                          .toString(),
                                                                    )
                                                              ? Color(
                                                                  0xFF3B82F6,
                                                                ).withOpacity(
                                                                  0.15,
                                                                )
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? Color(
                                                                    0xFF2563EB,
                                                                  )
                                                                : currentSelected
                                                                      .contains(
                                                                        board
                                                                            .boardId
                                                                            .toString(),
                                                                      )
                                                                ? Color(
                                                                    0xFF3B82F6,
                                                                  )
                                                                : Color(
                                                                    0xFFE2E8F0,
                                                                  ),
                                                            width: isSelected
                                                                ? 2
                                                                : 1,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: isSelected
                                                                  ? Color(
                                                                      0xFF3B82F6,
                                                                    ).withOpacity(
                                                                      0.3,
                                                                    )
                                                                  : Colors.black
                                                                        .withOpacity(
                                                                          0.02,
                                                                        ),
                                                              blurRadius: 2,
                                                              offset: Offset(
                                                                0,
                                                                isSelected
                                                                    ? 0
                                                                    : 2,
                                                              ),
                                                              spreadRadius:
                                                                  isSelected
                                                                  ? 1
                                                                  : 0,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            onTap:
                                                                !loadWaitNewBoard
                                                                ? isSelectBoard &&
                                                                          board.createdBy.toString() ==
                                                                              box.read('userProfile')['userid'].toString()
                                                                      ? () {
                                                                          setState(() {
                                                                            if (currentSelected.contains(
                                                                              board.boardId.toString(),
                                                                            )) {
                                                                              currentSelected.remove(
                                                                                board.boardId.toString(),
                                                                              );
                                                                            } else {
                                                                              currentSelected.add(
                                                                                board.boardId.toString(),
                                                                              );
                                                                            }
                                                                          });
                                                                        }
                                                                      : !isSelectBoard ||
                                                                            board.createdBy
                                                                                    .toString() ==
                                                                                box
                                                                                    .read(
                                                                                      'userProfile',
                                                                                    )['userid']
                                                                                    .toString()
                                                                      ? () {
                                                                          goToMyTask(
                                                                            board.boardId.toString(),
                                                                            board.boardName,
                                                                            tokenBoard:
                                                                                groupFontWeight ==
                                                                                    FontWeight.w600
                                                                                ? board.token
                                                                                : null,
                                                                          );
                                                                        }
                                                                      : null
                                                                : null,
                                                            onLongPress:
                                                                currentSelected
                                                                    .isNotEmpty
                                                                ? null
                                                                : () {
                                                                    final String
                                                                    keyId =
                                                                        '${board.boardName}_$index';
                                                                    setState(() {
                                                                      focusedBoardId =
                                                                          focusedBoardId ==
                                                                              keyId
                                                                          ? null
                                                                          : keyId;
                                                                    });
                                                                    showInfoMenuBoard(
                                                                      context,
                                                                      board,
                                                                      keyId:
                                                                          keyId,
                                                                      grid:
                                                                          false,
                                                                      shareToken:
                                                                          groupFontWeight ==
                                                                              FontWeight.w600
                                                                          ? board.token
                                                                          : null,
                                                                    );
                                                                  },
                                                            child: Stack(
                                                              children: [
                                                                Center(
                                                                  child: Padding(
                                                                    padding: EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          width *
                                                                          0.02,
                                                                    ),
                                                                    child: Text(
                                                                      board
                                                                          .boardName,
                                                                      style: TextStyle(
                                                                        fontSize: Get
                                                                            .textTheme
                                                                            .labelMedium!
                                                                            .fontSize!,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        color:
                                                                            loadWaitNewBoard
                                                                            ? Color.fromRGBO(
                                                                                151,
                                                                                149,
                                                                                149,
                                                                                progressValue,
                                                                              )
                                                                            : isSelected
                                                                            ? Color(
                                                                                0xFF1E40AF,
                                                                              )
                                                                            : Colors.black,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (isSelectBoard &&
                                                                    board.createdBy
                                                                            .toString() ==
                                                                        box
                                                                            .read(
                                                                              'userProfile',
                                                                            )['userid']
                                                                            .toString())
                                                                  Positioned(
                                                                    left: 3,
                                                                    top: 3,
                                                                    child: Icon(
                                                                      currentSelected.contains(
                                                                            board.boardId.toString(),
                                                                          )
                                                                          ? Icons.check_circle_rounded
                                                                          : Icons.radio_button_unchecked,
                                                                      size:
                                                                          height *
                                                                          0.025,
                                                                      color:
                                                                          currentSelected.contains(
                                                                            board.boardId.toString(),
                                                                          )
                                                                          ? Color(
                                                                              0xFF2563EB,
                                                                            )
                                                                          : Colors.grey,
                                                                    ),
                                                                  ),
                                                                if (groupFontWeight ==
                                                                    FontWeight
                                                                        .w600)
                                                                  if (board
                                                                          .createdBy
                                                                          .toString() !=
                                                                      box
                                                                          .read(
                                                                            'userProfile',
                                                                          )['userid']
                                                                          .toString())
                                                                    Positioned(
                                                                      right: 4,
                                                                      top: 3,
                                                                      child: ClipOval(
                                                                        child:
                                                                            board.createdByUser.profile ==
                                                                                'none-url'
                                                                            ? Container(
                                                                                width:
                                                                                    height *
                                                                                    0.028,
                                                                                height:
                                                                                    height *
                                                                                    0.028,
                                                                                decoration: BoxDecoration(
                                                                                  shape: BoxShape.circle,
                                                                                  color: Color(
                                                                                    0xFFF2F2F6,
                                                                                  ),
                                                                                ),
                                                                                child: Icon(
                                                                                  Icons.person,
                                                                                  size:
                                                                                      height *
                                                                                      0.025,
                                                                                  color: Color(
                                                                                    0xFF979595,
                                                                                  ),
                                                                                ),
                                                                              )
                                                                            : Container(
                                                                                decoration: BoxDecoration(
                                                                                  shape: BoxShape.circle,
                                                                                  color: Colors.black12,
                                                                                ),
                                                                                child: Image.network(
                                                                                  board.createdByUser.profile,
                                                                                  width:
                                                                                      height *
                                                                                      0.028,
                                                                                  height:
                                                                                      height *
                                                                                      0.028,
                                                                                  fit: BoxFit.cover,
                                                                                ),
                                                                              ),
                                                                      ),
                                                                    ),
                                                                Positioned(
                                                                  bottom: 4,
                                                                  left: 6,
                                                                  child: Row(
                                                                    children: [
                                                                      Container(
                                                                        padding:
                                                                            EdgeInsets.all(
                                                                              2,
                                                                            ),
                                                                        decoration: BoxDecoration(
                                                                          color: Color(
                                                                            0xFF3B82F6,
                                                                          ).withOpacity(0.1),
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                4,
                                                                              ),
                                                                        ),
                                                                        child: Icon(
                                                                          Icons
                                                                              .checklist_rounded,
                                                                          size:
                                                                              10,
                                                                          color: Color(
                                                                            0xFF4A89DC,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      FutureBuilder<
                                                                        String
                                                                      >(
                                                                        future: AppDataShareShowEditInfo.findNumberOFTasks(
                                                                          board,
                                                                          groupFontWeight,
                                                                        ),
                                                                        builder:
                                                                            (
                                                                              context,
                                                                              snapshot,
                                                                            ) {
                                                                              if (snapshot.hasData &&
                                                                                  snapshot.data!.isNotEmpty) {
                                                                                return Text(
                                                                                  ' ${snapshot.data} tasks ',
                                                                                  style: TextStyle(
                                                                                    fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                    fontWeight: FontWeight.w500,
                                                                                    color: Colors.black45,
                                                                                  ),
                                                                                );
                                                                              } else {
                                                                                return Padding(
                                                                                  padding: EdgeInsets.only(
                                                                                    left:
                                                                                        width *
                                                                                        0.01,
                                                                                  ),
                                                                                  child: Text(
                                                                                    'Loading...',
                                                                                    style: TextStyle(
                                                                                      fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                      fontWeight: FontWeight.w500,
                                                                                      color: Colors.black45,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              }
                                                                            },
                                                                      ),
                                                                      if (groupFontWeight ==
                                                                          FontWeight
                                                                              .w600)
                                                                        FutureBuilder<
                                                                          String
                                                                        >(
                                                                          future: showMembersCount(
                                                                            board,
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
                                                                                      Icon(
                                                                                        Icons.circle,
                                                                                        size: 4,
                                                                                        color: Colors.black45,
                                                                                      ),
                                                                                      Text(
                                                                                        ' ${snapshot.data!} members',
                                                                                        style: TextStyle(
                                                                                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                          fontWeight: FontWeight.w500,
                                                                                          color: Colors.black45,
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
                                                                ),
                                                                if (focusedBoardId !=
                                                                        null &&
                                                                    !isSelected)
                                                                  Positioned.fill(
                                                                    child: ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                      child: BackdropFilter(
                                                                        filter: ImageFilter.blur(
                                                                          sigmaX:
                                                                              6,
                                                                          sigmaY:
                                                                              6,
                                                                        ),
                                                                        child: Container(
                                                                          color: Colors.black.withOpacity(
                                                                            0.1,
                                                                          ),
                                                                        ),
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
                                              ),
                                              crossFadeState: displayFormat
                                                  ? CrossFadeState.showSecond
                                                  : CrossFadeState.showFirst,
                                              duration: Duration(
                                                milliseconds: 300,
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
                            if (hideSearchMyBoards)
                              Positioned.fill(
                                child: ClipRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 3,
                                      sigmaY: 3,
                                    ),
                                    child: Container(
                                      color: Colors.black.withOpacity(0),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (searchCtl.text.isNotEmpty)
                      SizedBox(height: height * 0.01),
                    if (searchCtl.text.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Lists",
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.titleMedium!.fontSize!,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (showSearchResultCreatedBoards(
                            searchCtl.text,
                          ).isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: height * 0.01,
                              ),
                              child: Text(
                                "No results found",
                                style: TextStyle(
                                  fontSize: Get.textTheme.bodyMedium!.fontSize!,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          else
                            ...showSearchResultCreatedBoards(
                              searchCtl.text,
                            ).map(
                              (data) => Column(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        goToMyTask(
                                          data.boardId.toString(),
                                          data.boardName,
                                          tokenBoard: null,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.02,
                                          vertical: height * 0.01,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                data.boardName,
                                                style: TextStyle(
                                                  fontSize: Get
                                                      .textTheme
                                                      .titleMedium!
                                                      .fontSize!,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: height * 0.001,
                                    ),
                                    child: Container(
                                      width: width,
                                      height: 0.5,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: height * 0.01),
                          Row(
                            children: [
                              Text(
                                "Groups",
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.titleMedium!.fontSize!,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (showSearchResultMemberBoards(
                            searchCtl.text,
                          ).isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: height * 0.01,
                              ),
                              child: Text(
                                "No results found",
                                style: TextStyle(
                                  fontSize: Get.textTheme.bodyMedium!.fontSize!,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          else
                            ...showSearchResultMemberBoards(searchCtl.text).map(
                              (data) => Column(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        goToMyTask(
                                          data.boardId.toString(),
                                          data.boardName,
                                          tokenBoard: data.token,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.02,
                                          vertical: height * 0.01,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                data.boardName,
                                                style: TextStyle(
                                                  fontSize: Get
                                                      .textTheme
                                                      .titleMedium!
                                                      .fontSize!,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: height * 0.001,
                                    ),
                                    child: Container(
                                      width: width,
                                      height: 0.5,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void checkBoardGroupActive() async {
    final rawData = box.read('userDataAll');
    final userProfile = box.read('userProfile');
    if (rawData == null || userProfile == null) {
      _timer?.cancel();
      return;
    }

    final userEmail = userProfile['email'];
    final rawDataResult = AllDataUserGetResponst.fromJson(rawData);

    final localBoardIds = rawDataResult.boardgroup
        .map((b) => b.boardId.toString())
        .toSet();

    for (var i in rawDataResult.boardgroup) {
      final result = await FirebaseFirestore.instance
          .collection('Boards')
          .doc(i.boardId.toString())
          .collection('BoardUsers')
          .get();

      final firebaseBoardIds = result.docs
          .map((doc) => doc['BoardID'].toString())
          .toSet();

      final missingBoardIds = localBoardIds.difference(firebaseBoardIds);
      final emailNotFound = !result.docs.any(
        (doc) =>
            (doc.data()['Email']?.toString().toLowerCase() ?? '') ==
            userEmail.toString().toLowerCase(),
      );

      if ((missingBoardIds.isNotEmpty || emailNotFound) && !_hasFetchedData) {
        _hasFetchedData = true;

        final url = await loadAPIEndpoint();
        var response = await http.get(
          Uri.parse("$url/user/data"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
        );

        if (response.statusCode == 403) {
          final rawData = box.read('userDataAll');
          final userProfile = box.read('userProfile');
          if (rawData == null || userProfile == null) {
            _timer?.cancel();
            return;
          }
          await AppDataLoadNewRefreshToken().loadNewRefreshToken();
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

        _hasFetchedData = false;
      }
    }
  }

  Future<String> showTimeRemineMeBefore(int taskId) async {
    final userEmail = box.read('userProfile')['email'];
    if (userEmail == null) return '';
    final snapshot = await FirebaseFirestore.instance
        .collection('Notifications')
        .doc(userEmail.toString())
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

  Future<String> showMembersCount(dynamic boards) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('Boards')
        .doc(boards.boardId.toString())
        .collection('BoardUsers')
        .get();

    return docSnapshot.docs.length.toString();
  }

  String findNumberOfAllTask(bool value) {
    final boardDataRaw = box.read('userDataAll');
    if (boardDataRaw == null) return '';
    final boardData = AllDataUserGetResponst.fromJson(boardDataRaw);
    String number = value
        ? boardData.board.length.toString()
        : boardData.boardgroup.length.toString();
    return number;
  }

  void getDialogDeleteBoardBySelected() {
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
              'Do you want to delete this board?',
              style: TextStyle(
                fontSize: Get.textTheme.titleMedium!.fontSize!,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              'Are you sure you want to delete this board and all its tasks.',
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
                final allSelectedBoards = [
                  ...selectedPrivateBoards,
                  ...selectedGroupBoards,
                ];

                setState(() {
                  selectedPrivateBoards.clear();
                  selectedGroupBoards.clear();
                });

                deleteBoardBySelected(allSelectedBoards);
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
  }

  void deleteBoardBySelected(List<String> allSelectedBoards) async {
    final appData = Provider.of<Appdata>(context, listen: false);
    var existingData = AllDataUserGetResponst.fromJson(box.read('userDataAll'));
    for (var boardId in allSelectedBoards) {
      appData.showMyBoards.removeCreatedBoardById(int.parse(boardId));
      existingData.board.removeWhere((b) => b.boardId.toString() == boardId);
      appData.showMyBoards.removeMemberBoardById(int.parse(boardId));
      existingData.boardgroup.removeWhere(
        (b) => b.boardId.toString() == boardId,
      );
    }
    box.write('userDataAll', existingData.toJson());

    url = await loadAPIEndpoint();
    var response = await http.delete(
      Uri.parse("$url/board"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: jsonEncode({"board_id": allSelectedBoards}),
    );

    if (response.statusCode == 403) {
      await AppDataLoadNewRefreshToken().loadNewRefreshToken();
      await http.delete(
        Uri.parse("$url/board"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: jsonEncode({"board_id": allSelectedBoards}),
      );
    }
  }

  List<Task> getUpcomingTasks(List<Task> tasks) {
    List<Task> upcomingTasks = tasks
        .where((task) => task.boardId == "Today")
        .where((task) {
          if (task.notifications.isEmpty) return false;

          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day).toLocal();
          final todayEnd = todayStart.add(const Duration(days: 1));

          final notificationWithDueDate = task.notifications.firstWhere(
            (n) => n.dueDate.isNotEmpty,
            orElse: () => task.notifications.first,
          );

          if (notificationWithDueDate.dueDate.isEmpty) return false;

          DateTime? dueDate;
          try {
            dueDate = DateTime.parse(
              notificationWithDueDate.dueDate,
            ).toLocal().add(const Duration(seconds: 10));
          } catch (e) {
            return false;
          }

          return dueDate.isBefore(todayEnd) &&
              todayEnd.isAfter(todayStart) &&
              dueDate.isAfter(now);
        })
        .toList();

    // sort ตาม dueDate
    upcomingTasks.sort((a, b) {
      final aDue = a.notifications.firstWhere(
        (n) => n.dueDate.isNotEmpty,
        orElse: () => a.notifications.first,
      );
      final bDue = b.notifications.firstWhere(
        (n) => n.dueDate.isNotEmpty,
        orElse: () => b.notifications.first,
      );

      if (aDue.dueDate.isEmpty || bDue.dueDate.isEmpty) return 0;

      return DateTime.parse(
        aDue.dueDate,
      ).compareTo(DateTime.parse(bDue.dueDate));
    });

    return upcomingTasks.take(3).toList();
  }

  String timeUntilDetailed(String timestamp) {
    if (timestamp.isEmpty) return '';

    final DateTime targetTime = DateTime.parse(timestamp).toLocal();
    final DateTime now = DateTime.now();
    final Duration diff = targetTime.difference(now);

    final int days = diff.inDays;
    final int hours = diff.inHours % 24;
    final int minutes = diff.inMinutes % 60;
    final int seconds = diff.inSeconds % 60;

    if (diff.inSeconds >= -10 && diff.inSeconds <= 0) {
      return 'Time’s up';
    } else if (diff.inSeconds < 60) {
      return '$seconds seconds left';
    } else if (diff.inMinutes < 60) {
      return '$minutes minutes ${seconds}s left';
    } else if (diff.inHours < 24) {
      return '$hours hours ${minutes}m left';
    } else if (days < 7) {
      return '$days days ${hours}h left';
    } else {
      return 'Due on ${DateFormat('d MMM yyyy, HH:mm').format(targetTime)}';
    }
  }

  Future<void> checkExpiresRefreshToken() async {
    final userProfileData = box.read('userProfile');
    if (userProfileData == null) return;
    final userid = userProfileData['userid'].toString();
    var result = await FirebaseFirestore.instance
        .collection('refreshTokens')
        .doc(userid)
        .get();
    var data = result.data();
    if (data != null) {
      int createdAt = data['CreatedAt'];
      int expiresIn = data['ExpiresIn'];

      DateTime createdAtDate = DateTime.fromMillisecondsSinceEpoch(
        createdAt * 1000,
      );
      DateTime expiryDate = createdAtDate.add(Duration(seconds: expiresIn));
      DateTime now = DateTime.now();

      if (now.isAfter(expiryDate)) {
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
                await googleSignIn.initialize();
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

  void loadDisplays() {
    if (!mounted) return;

    // อ่านข้อมูลจาก box
    final boardDataRaw = box.read('userDataAll');
    final userProfileData = box.read('userProfile');

    if (boardDataRaw == null ||
        userProfileData == null ||
        userProfileData is! Map) {
      return;
    }

    final boardData = AllDataUserGetResponst.fromJson(boardDataRaw);
    final appData = Provider.of<Appdata>(context, listen: false);
    appData.showMyBoards.setBoards(boardData);
    appData.showMyTasks.setTasks(boardData.tasks);

    final createdBoards = appData.showMyBoards.createdBoards;
    final memberBoards = appData.showMyBoards.memberBoards;
    final task = appData.showMyTasks.tasks
        .where((task) => task.boardId == 'Today')
        .where((task) => task.status == "0")
        .toList();

    // เตรียมค่าใหม่ทั้งหมด
    List newBoards = privateFontWeight == FontWeight.w600
        ? createdBoards
        : memberBoards;

    setState(() {
      boards = newBoards;
      tasks = task;

      emailUser = userProfileData['email'];
      name = getFirstName(userProfileData['name']);
      userProfile = userProfileData['profile'];

      appData.changeMyProfileProvider.setName(name);
      appData.changeMyProfileProvider.setProfile(userProfile);
    });
  }

  String getFirstName(String fullName) {
    List<String> parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
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
        padding: EdgeInsets.symmetric(horizontal: width * 0.03),
        width: width * 0.4,
        height: height * 0.045,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: Get.textTheme.labelMedium!.fontSize!,
                fontWeight: FontWeight.w500,
                color: title == 'Delete board' ? Colors.red : Colors.black,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void showInfoMenuBoard(
    BuildContext context,
    dynamic board, {
    required String keyId,
    required bool grid,
    String? shareToken,
  }) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;
    final RenderBox renderBox = grid
        ? boardInfoKeysGrid[keyId]!.currentContext!.findRenderObject()
              as RenderBox
        : boardInfoKeysList[keyId]!.currentContext!.findRenderObject()
              as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    const double itemHeightFactor = 0.045;
    const double menuWidthFactor = 0.4;
    final double menuWidth = width * menuWidthFactor;
    final double menuHeight =
        (height * itemHeightFactor) *
        (board.createdBy.toString() ==
                box.read('userProfile')['userid'].toString()
            ? 3.2
            : 1.2);

    final isPrivateMode = privateFontWeight == FontWeight.w600;
    final currentSelected = isPrivateMode
        ? selectedPrivateBoards
        : selectedGroupBoards;

    menuEntryShowMenuBoard = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                menuEntryShowMenuBoard?.remove();
                menuEntryShowMenuBoard = null;
                if (focusedBoardId != null) {
                  setState(() {
                    focusedBoardId = null;
                  });
                }
              },
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: offset.dx + (size.width / 2) - (menuWidth / 2),
              top: offset.dy - menuHeight,
              child: Material(
                elevation: 1,
                borderRadius: BorderRadius.circular(8),
                color: Color(0xFFF2F2F6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildPopupItem(
                      context,
                      title: 'Show info',
                      trailing: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M11 11h2v6h-2zm0-4h2v2h-2z"></path></svg>',
                        height: height * 0.02,
                        fit: BoxFit.contain,
                      ),
                      onTap: () {
                        menuEntryShowMenuBoard?.remove();
                        menuEntryShowMenuBoard = null;
                        if (focusedBoardId != null) {
                          setState(() {
                            focusedBoardId = null;
                          });
                        }
                        AppDataShareShowEditInfo.showEditInfo(
                          context,
                          board,
                          shareToken ?? '',
                          privateFontWeight,
                          groupFontWeight,
                          loadDataAsync: loadDataAsync,
                        );
                      },
                    ),
                    if (board.createdBy.toString() ==
                        box.read('userProfile')['userid'].toString())
                      buildPopupItem(
                        context,
                        title: 'Select board',
                        trailing: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>',
                          height: height * 0.02,
                          fit: BoxFit.contain,
                        ),
                        onTap: () {
                          menuEntryShowMenuBoard?.remove();
                          menuEntryShowMenuBoard = null;
                          if (focusedBoardId != null) {
                            setState(() {
                              focusedBoardId = null;
                            });
                          }
                          setState(() {
                            isSelectBoard = !isSelectBoard;
                            if (currentSelected.contains(
                              board.boardId.toString(),
                            )) {
                              currentSelected.remove(board.boardId.toString());
                            } else {
                              currentSelected.add(board.boardId.toString());
                            }
                          });
                        },
                      ),
                    if (board.createdBy.toString() ==
                        box.read('userProfile')['userid'].toString())
                      buildPopupItem(
                        context,
                        title: 'Delete board',
                        trailing: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M5 20a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8h2V6h-4V4a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v2H3v2h2zM9 4h6v2H9zM8 8h9v12H7V8z"></path><path d="M9 10h2v8H9zm4 0h2v8h-2z"></path></svg>',
                          height: height * 0.02,
                          fit: BoxFit.contain,
                          color: Colors.red,
                        ),
                        onTap: () {
                          menuEntryShowMenuBoard?.remove();
                          menuEntryShowMenuBoard = null;
                          if (focusedBoardId != null) {
                            setState(() {
                              focusedBoardId = null;
                            });
                          }
                          Get.defaultDialog(
                            title: '',
                            titlePadding: EdgeInsets.zero,
                            backgroundColor: Colors.white,
                            barrierDismissible: false,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.04,
                              vertical:
                                  MediaQuery.of(context).size.height * 0.01,
                            ),
                            content: WillPopScope(
                              onWillPop: () async => false,
                              child: Column(
                                children: [
                                  Image.asset(
                                    "assets/images/aleart/question.png",
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.1,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.02,
                                  ),
                                  Text(
                                    'Do you want to delete this board?',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize!,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.01,
                                  ),
                                  Text(
                                    'Are you sure you want to delete this board and all its tasks.',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize!,
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
                                      deleteBoard(board.boardId);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF007AFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 1,
                                      fixedSize: Size(
                                        MediaQuery.of(context).size.width,
                                        MediaQuery.of(context).size.height *
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      fixedSize: Size(
                                        MediaQuery.of(context).size.width,
                                        MediaQuery.of(context).size.height *
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
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(menuEntryShowMenuBoard!);
  }

  Future<void> deleteBoard(int boardId) async {
    url = await loadAPIEndpoint();

    final appData = Provider.of<Appdata>(context, listen: false);

    if (isDeleteBoard) {
      Get.snackbar(
        'Delete Failed!',
        'Something went wrong, please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      isDeleteBoard = true;
    });
    try {
      var existingData = AllDataUserGetResponst.fromJson(
        box.read('userDataAll'),
      );
      if (privateFontWeight == FontWeight.w600) {
        appData.showMyBoards.removeCreatedBoardById(boardId);
        existingData.board.removeWhere((b) => b.boardId == boardId);
      } else if (groupFontWeight == FontWeight.w600) {
        appData.showMyBoards.removeMemberBoardById(boardId);
        existingData.boardgroup.removeWhere((b) => b.boardId == boardId);
      }
      box.write('userDataAll', existingData.toJson());

      var response = await http.delete(
        Uri.parse("$url/board"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: jsonEncode({
          "board_id": [boardId.toString()],
        }),
      );
      if (response.statusCode == 403) {
        await AppDataLoadNewRefreshToken().loadNewRefreshToken();
        await http.delete(
          Uri.parse("$url/board"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
          body: jsonEncode({
            "board_id": [boardId.toString()],
          }),
        );
      }
    } finally {
      isDeleteBoard = false;
    }
  }

  void loadMessages() {
    final List<String> jsonData = [
      "You can do it! 💪",
      "Believe in yourself! ✨",
      "Keep going! 🚀",
      "Stay strong! 💖",
      "Don't give up! 🙏",
      "You've got this! 🔥",
      "Stay positive! 🌈",
      "Keep moving forward! ➡️",
      "Never stop trying! 💡",
      "Dream big! 🌟",
      "Shine bright! ☀️",
      "Stay focused! 🎯",
      "One step at a time! 👣",
      "Keep believing! 🙌",
      "Be your best self! 🏆",
      "Keep pushing! 🏋️",
      "Trust the process! 🛤️",
      "Progress, not perfection! 🏃‍♂️",
      "Small steps matter! 🐾",
      "Your potential is limitless! 🌌",
    ];
    randomMessage = (jsonData..shuffle()).first;
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      checkBoardGroupActive();
      if (!mounted) return;
      setState(() {
        randomMessage = (jsonData..shuffle()).first;
      });
    });
  }

  void searchMyBoards() {
    setState(() {
      hideSearchMyBoards = !hideSearchMyBoards;
    });
    Future.delayed(Duration(milliseconds: 100), () {
      searchFocusNode.requestFocus();
    });
  }

  List<Board> showSearchResultCreatedBoards(String text) {
    final appData = Provider.of<Appdata>(context, listen: false);
    final createdBoards = appData.showMyBoards.createdBoards;
    return createdBoards
        .where((u) => u.boardName.toLowerCase().contains(text.toLowerCase()))
        .toList();
  }

  List<Boardgroup> showSearchResultMemberBoards(String text) {
    final appData = Provider.of<Appdata>(context, listen: false);
    final memberBoards = appData.showMyBoards.memberBoards;
    return memberBoards
        .where((u) => u.boardName.toLowerCase().contains(text.toLowerCase()))
        .toList();
  }

  void showDisplays() {
    if (!mounted) return;
    final userData = box.read('userDataAll');
    if (userData == null) return;

    var boardData = AllDataUserGetResponst.fromJson(userData);
    final appData = Provider.of<Appdata>(context, listen: false);
    appData.showMyBoards.setBoards(boardData);

    var createdBoards = appData.showMyBoards.createdBoards;
    var memberBoards = appData.showMyBoards.memberBoards;

    // ตั้งค่าดีฟอลต์
    if (box.read('showDisplays') == null) {
      box.write('showDisplays', {'privateTF': true, 'groupTF': false});
    }
    if (box.read('showDisplays2') == null) {
      box.write('showDisplays2', {'grid': true, 'private': false});
    }

    // อัปเดต displayFormat จาก box
    final showDisplay2 = box.read('showDisplays2');
    displayFormat = showDisplay2['private'] == true;

    // อัปเดต list/group
    final showDisplay = box.read('showDisplays');
    if (showDisplay['privateTF'] == true) {
      privateFontWeight = FontWeight.w600;
      groupFontWeight = FontWeight.w500;
      boards = createdBoards;
    } else if (showDisplay['groupTF'] == true) {
      privateFontWeight = FontWeight.w500;
      groupFontWeight = FontWeight.w600;
      boards = memberBoards;
    }
  }

  void toggleDisplayFormat(bool isList) {
    Map<String, dynamic> currentData = Map<String, dynamic>.from(
      box.read('showDisplays2') ?? {},
    );
    currentData['grid'] = !isList;
    currentData['private'] = isList;
    box.write('showDisplays2', currentData);
    setState(() {
      displayFormat = isList;
    });
  }

  void startLoading(int tempId) {
    setState(() {
      loadingBoardId = tempId;
      progressValue = 0.0;
    });

    progressTimer = Timer.periodic(Duration(milliseconds: 20), (timer) {
      if (progressValue < 0.9) {
        if (mounted) {
          setState(() {
            progressValue += 0.02;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> completeLoading() async {
    if (progressTimer != null) {
      progressTimer!.cancel();
    }

    if (!mounted) return;
    setState(() {
      progressValue = 1.0;
    });

    await Future.delayed(Duration(milliseconds: 100));

    if (!mounted) return;
    setState(() {
      loadingBoardId = null;
    });
  }

  void createNewBoard() async {
    url = await loadAPIEndpoint();
    String textError = '';

    Future.delayed(Duration(milliseconds: 50), () {
      boardFocusNode.requestFocus();
    });
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState1) {
            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height;

            return Padding(
              padding: EdgeInsets.only(
                top: height * 0.02,
                left: width * 0.05,
                right: width * 0.05,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + height * 0.02,
              ),
              child: SafeArea(
                child: SizedBox(
                  height: height * 0.18,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'New Board',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleLarge!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            controller: boardCtl,
                            focusNode: boardFocusNode,
                            keyboardType: TextInputType.text,
                            cursorColor: Color(0xFF007AFF),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize!,
                            ),
                            decoration: InputDecoration(
                              hintText: isTyping ? '' : 'Enter your board name',
                              hintStyle: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize!,
                                fontWeight: FontWeight.normal,
                                color: Color(0x4D000000),
                              ),
                              constraints: BoxConstraints(
                                maxHeight: height * 0.05,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: width * 0.05,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(width: 0.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(width: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (textError.isNotEmpty)
                        Text(
                          textError,
                          style: TextStyle(
                            fontSize: Get.textTheme.labelMedium!.fontSize!,
                            fontWeight: FontWeight.normal,
                            color: Colors.red,
                          ),
                        ),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final String boardName = boardCtl.text.trim();
                              if (boardCtl.text.trim().isEmpty) {
                                if (!mounted) return;
                                setState1(() {
                                  textError = 'Please enter your board name';
                                });
                                return;
                              }
                              int tempId = Random().nextInt(100000);
                              Board tempBoard = Board(
                                boardId: tempId,
                                boardName: boardName,
                                createdAt: DateTime.now().toIso8601String(),
                                createdBy: box.read('userProfile')['userid'],
                                createdByUser: CreatedByUser(
                                  email: box.read('userProfile')['email'],
                                  name: box.read('userProfile')['name'],
                                  profile: box.read('userProfile')['profile'],
                                  userId: box.read('userProfile')['userid'],
                                ),
                              );
                              Boardgroup tempBoardGroup = Boardgroup(
                                boardId: tempId,
                                boardName: boardName,
                                createdAt: DateTime.now().toIso8601String(),
                                createdBy: box.read('userProfile')['userid'],
                                token: '',
                                createdByUser: CreatedByUser(
                                  email: box.read('userProfile')['email'],
                                  name: box.read('userProfile')['name'],
                                  profile: box.read('userProfile')['profile'],
                                  userId: box.read('userProfile')['userid'],
                                ),
                              );

                              final appData = Provider.of<Appdata>(
                                context,
                                listen: false,
                              );
                              var existingData =
                                  AllDataUserGetResponst.fromJson(
                                    box.read('userDataAll'),
                                  );

                              await Future.delayed(Duration(milliseconds: 100));
                              startLoading(tempId);
                              Get.back();
                              Future.microtask(() async {
                                if (privateFontWeight == FontWeight.w600) {
                                  existingData.board.add(tempBoard);
                                  appData.showMyBoards.addCreatedBoard(
                                    tempBoard,
                                  );
                                  box.write(
                                    'userDataAll',
                                    existingData.toJson(),
                                  );

                                  var responseCreateBoradList = await http.post(
                                    Uri.parse("$url/board"),
                                    headers: {
                                      "Content-Type":
                                          "application/json; charset=utf-8",
                                      "Authorization":
                                          "Bearer ${box.read('accessToken')}",
                                    },
                                    body: createBoardListsPostRequestToJson(
                                      CreateBoardListsPostRequest(
                                        boardName: boardName,
                                        createdBy: box.read(
                                          'userProfile',
                                        )['userid'],
                                        isGroup: '0',
                                      ),
                                    ),
                                  );
                                  if (responseCreateBoradList.statusCode ==
                                      403) {
                                    await AppDataLoadNewRefreshToken()
                                        .loadNewRefreshToken();
                                    responseCreateBoradList = await http.post(
                                      Uri.parse("$url/board"),
                                      headers: {
                                        "Content-Type":
                                            "application/json; charset=utf-8",
                                        "Authorization":
                                            "Bearer ${box.read('accessToken')}",
                                      },
                                      body: createBoardListsPostRequestToJson(
                                        CreateBoardListsPostRequest(
                                          boardName: boardName,
                                          createdBy: box.read(
                                            'userProfile',
                                          )['userid'],
                                          isGroup: '0',
                                        ),
                                      ),
                                    );
                                  }
                                  if (responseCreateBoradList.statusCode ==
                                      201) {
                                    var data = jsonDecode(
                                      responseCreateBoradList.body,
                                    );
                                    // สร้างบอร์ดจริง
                                    Board realBoard = Board(
                                      boardId: data['boardID'],
                                      boardName: boardName,
                                      createdAt: DateTime.now()
                                          .toIso8601String(),
                                      createdBy: box.read(
                                        'userProfile',
                                      )['userid'],
                                      createdByUser: CreatedByUser(
                                        email: box.read('userProfile')['email'],
                                        name: box.read('userProfile')['name'],
                                        profile: box.read(
                                          'userProfile',
                                        )['profile'],
                                        userId: box.read(
                                          'userProfile',
                                        )['userid'],
                                      ),
                                    );
                                    await completeLoading();
                                    appData.showMyBoards.addCreatedBoard(
                                      realBoard,
                                    );
                                    appData.showMyBoards.removeCreatedBoardById(
                                      tempId,
                                    );
                                    existingData.board.removeWhere(
                                      (b) => b.boardId == tempId,
                                    );
                                    existingData.board.add(realBoard);
                                    box.write(
                                      'userDataAll',
                                      existingData.toJson(),
                                    );

                                    // ปิดหน้าต่างและเคลียร์ฟอร์ม
                                    if (!mounted) return;
                                    setState(() {
                                      boardCtl.clear();
                                      textError = '';
                                    });
                                  }
                                } else if (groupFontWeight == FontWeight.w600) {
                                  existingData.boardgroup.add(tempBoardGroup);
                                  appData.showMyBoards.addMemberBoard(
                                    tempBoardGroup,
                                  );
                                  box.write(
                                    'userDataAll',
                                    existingData.toJson(),
                                  );

                                  var responseCreateBoradGroup = await http.post(
                                    Uri.parse("$url/board"),
                                    headers: {
                                      "Content-Type":
                                          "application/json; charset=utf-8",
                                      "Authorization":
                                          "Bearer ${box.read('accessToken')}",
                                    },
                                    body: createBoardListsPostRequestToJson(
                                      CreateBoardListsPostRequest(
                                        boardName: boardName,
                                        createdBy: box.read(
                                          'userProfile',
                                        )['userid'],
                                        isGroup: '1',
                                      ),
                                    ),
                                  );
                                  if (responseCreateBoradGroup.statusCode ==
                                      403) {
                                    await AppDataLoadNewRefreshToken()
                                        .loadNewRefreshToken();
                                    responseCreateBoradGroup = await http.post(
                                      Uri.parse("$url/board"),
                                      headers: {
                                        "Content-Type":
                                            "application/json; charset=utf-8",
                                        "Authorization":
                                            "Bearer ${box.read('accessToken')}",
                                      },
                                      body: createBoardListsPostRequestToJson(
                                        CreateBoardListsPostRequest(
                                          boardName: boardName,
                                          createdBy: box.read(
                                            'userProfile',
                                          )['userid'],
                                          isGroup: '1',
                                        ),
                                      ),
                                    );
                                  }
                                  if (responseCreateBoradGroup.statusCode ==
                                      201) {
                                    var data = jsonDecode(
                                      responseCreateBoradGroup.body,
                                    );
                                    // สร้างบอร์ดจริง
                                    Boardgroup realBoard = Boardgroup(
                                      boardId: data['boardID'],
                                      boardName: boardName,
                                      createdAt: DateTime.now()
                                          .toIso8601String(),
                                      createdBy: box.read(
                                        'userProfile',
                                      )['userid'],
                                      token: data['deep_link'],
                                      createdByUser: CreatedByUser(
                                        email: box.read('userProfile')['email'],
                                        name: box.read('userProfile')['name'],
                                        profile: box.read(
                                          'userProfile',
                                        )['profile'],
                                        userId: box.read(
                                          'userProfile',
                                        )['userid'],
                                      ),
                                    );
                                    await completeLoading();
                                    appData.showMyBoards.addMemberBoard(
                                      realBoard,
                                    );
                                    appData.showMyBoards.removeMemberBoardById(
                                      tempId,
                                    );
                                    existingData.boardgroup.removeWhere(
                                      (b) => b.boardId == tempId,
                                    );
                                    existingData.boardgroup.add(realBoard);
                                    box.write(
                                      'userDataAll',
                                      existingData.toJson(),
                                    );

                                    // ปิดหน้าต่างและเคลียร์ฟอร์ม
                                    if (!mounted) return;
                                    setState(() {
                                      boardCtl.clear();
                                      textError = '';
                                    });
                                  }
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              fixedSize: Size(width, height * 0.05),
                              backgroundColor: Color(0xFF007AFF),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Create new board',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize!,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      boardCtl.clear();
    });
  }

  void goToMyTask(String idBoard, String boardName, {String? tokenBoard}) {
    if (focusedBoardId != null) {
      setState(() {
        focusedBoardId = null;
      });
    }
    final appData = Provider.of<Appdata>(context, listen: false);
    appData.boardDatas.setIdBoard(idBoard);
    appData.boardDatas.setBoardName(boardName);
    appData.boardDatas.setBoardToken(tokenBoard ?? '');
    Get.to(() => BoardshowtasksPage());
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
          padding: EdgeInsets.symmetric(horizontal: width * 0.02),
          height: height * 0.05,
          value: 'setting',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: Get.textTheme.titleSmall!.fontSize!,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 16c2.206 0 4-1.794 4-4s-1.794-4-4-4-4 1.794-4 4 1.794 4 4 4zm0-6c1.084 0 2 .916 2 2s-.916 2-2 2-2-.916-2-2 .916-2 2-2z"></path><path d="m2.845 16.136 1 1.73c.531.917 1.809 1.261 2.73.73l.529-.306A8.1 8.1 0 0 0 9 19.402V20c0 1.103.897 2 2 2h2c1.103 0 2-.897 2-2v-.598a8.132 8.132 0 0 0 1.896-1.111l.529.306c.923.53 2.198.188 2.731-.731l.999-1.729a2.001 2.001 0 0 0-.731-2.732l-.505-.292a7.718 7.718 0 0 0 0-2.224l.505-.292a2.002 2.002 0 0 0 .731-2.732l-.999-1.729c-.531-.92-1.808-1.265-2.731-.732l-.529.306A8.1 8.1 0 0 0 15 4.598V4c0-1.103-.897-2-2-2h-2c-1.103 0-2 .897-2 2v.598a8.132 8.132 0 0 0-1.896 1.111l-.529-.306c-.924-.531-2.2-.187-2.731.732l-.999 1.729a2.001 2.001 0 0 0 .731 2.732l.505.292a7.683 7.683 0 0 0 0 2.223l-.505.292a2.003 2.003 0 0 0-.731 2.733zm3.326-2.758A5.703 5.703 0 0 1 6 12c0-.462.058-.926.17-1.378a.999.999 0 0 0-.47-1.108l-1.123-.65.998-1.729 1.145.662a.997.997 0 0 0 1.188-.142 6.071 6.071 0 0 1 2.384-1.399A1 1 0 0 0 11 5.3V4h2v1.3a1 1 0 0 0 .708.956 6.083 6.083 0 0 1 2.384 1.399.999.999 0 0 0 1.188.142l1.144-.661 1 1.729-1.124.649a1 1 0 0 0-.47 1.108c.112.452.17.916.17 1.378 0 .461-.058.925-.171 1.378a1 1 0 0 0 .471 1.108l1.123.649-.998 1.729-1.145-.661a.996.996 0 0 0-1.188.142 6.071 6.071 0 0 1-2.384 1.399A1 1 0 0 0 13 18.7l.002 1.3H11v-1.3a1 1 0 0 0-.708-.956 6.083 6.083 0 0 1-2.384-1.399.992.992 0 0 0-1.188-.141l-1.144.662-1-1.729 1.124-.651a1 1 0 0 0 .471-1.108z"></path></svg>',
                height: height * 0.025,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.symmetric(horizontal: width * 0.02),
          height: height * 0.05,
          value: 'report',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Report',
                style: TextStyle(
                  fontSize: Get.textTheme.titleSmall!.fontSize!,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 6a3.939 3.939 0 0 0-3.934 3.934h2C10.066 8.867 10.934 8 12 8s1.934.867 1.934 1.934c0 .598-.481 1.032-1.216 1.626a9.208 9.208 0 0 0-.691.599c-.998.997-1.027 2.056-1.027 2.174V15h2l-.001-.633c.001-.016.033-.386.441-.793.15-.15.339-.3.535-.458.779-.631 1.958-1.584 1.958-3.182A3.937 3.937 0 0 0 12 6zm-1 10h2v2h-2z"></path><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path></svg>',
                height: height * 0.025,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      menuPadding: EdgeInsets.zero,
    ).then((value) {
      if (value == 'setting') {
        _navigateAndRefresh();
      } else if (value == 'report') {
        Get.to(() => MenureportPage());
      }
    });
  }

  Future<void> _navigateAndRefresh() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );

    if (result == 'refresh') {
      showDisplays();
      loadDataAsync();
    } else if (result == 'loadDisplays') {
      loadDataAsync();
    }
  }

  void loadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        content: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}
