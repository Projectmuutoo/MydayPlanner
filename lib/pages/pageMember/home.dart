import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' show Random;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/createBoardListsPostRequest.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
import 'package:mydayplanner/pages/pageMember/menu/menuReport.dart';
import 'package:mydayplanner/pages/pageMember/myTasksLists/boradLists.dart';
import 'package:mydayplanner/pages/pageMember/menu/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mydayplanner/shared/appData.dart';
import 'package:mydayplanner/splash.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 📦 Storage
  var box = GetStorage();
  final storage = FlutterSecureStorage();
  // 📊 Integer Variables
  int itemCount = 1;
  int? loadingBoardId;

  int currentIndexMessagesRandom = 0;

  // 🔤 String Variables
  String emailUser = '';
  String name = '';
  String userProfile = '';
  String? focusedBoardId;

  // 📥 TextEditingController
  TextEditingController boardCtl = TextEditingController();
  TextEditingController searchCtl = TextEditingController();
  TextEditingController boardListNameCtl = TextEditingController();

  // 🧠 Focus Nodes
  FocusNode searchFocusNode = FocusNode();
  FocusNode boardFocusNode = FocusNode();
  FocusNode boardListNameFocusNode = FocusNode();

  // 🔘 Boolean Variables
  bool displayFormat = false;
  bool isTyping = false;
  bool isLoadings = true;
  bool showShimmer = true;
  bool hideSearchMyBoards = false;
  bool isDeleteBoard = false;

  double progressValue = 0.0;
  Timer? progressTimer;
  // 🔲 Double Variables
  double slider = 0;

  // 🔤 Font Weights
  FontWeight listsFontWeight = FontWeight.w600;
  FontWeight groupFontWeight = FontWeight.w500;

  // 📋 Global Keys
  GlobalKey listKey = GlobalKey();
  GlobalKey groupKey = GlobalKey();
  GlobalKey iconKey = GlobalKey();

  Map<String, GlobalKey> boardInfoKeys = {};

  // 🧠 Data (Lists and Future)
  late Future<void> loadData;
  List boards = [];
  List<Todaytask> tasks = [];
  List<String> messagesRandom = [];

  // 🎯 Utility
  Timer? _timer;
  late String url;

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

    showDisplays(null);
    loadMessages();
    loadData = loadDataAsync();
  }

  @override
  void dispose() {
    searchCtl.dispose();
    searchFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadDataAsync() async {
    loadDisplays();
    bool isExpired = await checkExpiresRefreshToken();
    if (isExpired) return;
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
              itemCount = boards.isEmpty ? 1 : boards.length;
            });
          });
        }

        return PopScope(
          canPop: false,
          child: GestureDetector(
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
                child: RefreshIndicator(
                  color: Colors.grey,
                  onRefresh: loadDataAsync,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: width * 0.05,
                      left: width * 0.05,
                      top: height * 0.01,
                    ),
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              !hideSearchMyBoards
                                  ? Row(
                                    children: [
                                      isLoadings || showShimmer
                                          ? Shimmer.fromColors(
                                            baseColor: Color(0xFFF7F7F7),
                                            highlightColor: Colors.grey[300]!,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              width: height * 0.07,
                                              height: height * 0.07,
                                            ),
                                          )
                                          : ClipOval(
                                            child:
                                                userProfile == 'none-url'
                                                    ? Container(
                                                      width: height * 0.07,
                                                      height: height * 0.07,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          Container(
                                                            height:
                                                                height * 0.1,
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Color(
                                                                    0xFFF2F2F6,
                                                                  ),
                                                                  shape:
                                                                      BoxShape
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
                                                                  height * 0.05,
                                                              fit:
                                                                  BoxFit
                                                                      .contain,
                                                              color: Color(
                                                                0xFF979595,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                    : Image.network(
                                                      context
                                                          .watch<Appdata>()
                                                          .changeMyProfileProvider
                                                          .profile,
                                                      width: height * 0.07,
                                                      height: height * 0.07,
                                                      fit: BoxFit.cover,
                                                    ),
                                          ),
                                      SizedBox(width: width * 0.01),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hello, ${context.watch<Appdata>().changeMyProfileProvider.name}',
                                            style: TextStyle(
                                              fontSize:
                                                  Get
                                                      .textTheme
                                                      .titleMedium!
                                                      .fontSize,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          isLoadings || showShimmer
                                              ? SizedBox.shrink()
                                              : Text(
                                                messagesRandom.isNotEmpty
                                                    ? messagesRandom[currentIndexMessagesRandom %
                                                        messagesRandom.length]
                                                    : "Have a great day!",
                                                style: TextStyle(
                                                  fontSize:
                                                      Get
                                                          .textTheme
                                                          .titleSmall!
                                                          .fontSize,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                        ],
                                      ),
                                    ],
                                  )
                                  : SizedBox(
                                    width: width * 0.8,
                                    child: TextField(
                                      controller: searchCtl,
                                      focusNode: searchFocusNode,
                                      keyboardType: TextInputType.text,
                                      cursorColor: Colors.black,
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: isTyping ? '' : 'Search',
                                        hintStyle: TextStyle(
                                          fontSize:
                                              Get
                                                  .textTheme
                                                  .titleMedium!
                                                  .fontSize,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.grey,
                                        ),
                                        prefixIcon: IconButton(
                                          onPressed: null,
                                          icon: SvgPicture.string(
                                            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10 18a7.952 7.952 0 0 0 4.897-1.688l4.396 4.396 1.414-1.414-4.396-4.396A7.952 7.952 0 0 0 18 10c0-4.411-3.589-8-8-8s-8 3.589-8 8 3.589 8 8 8zm0-14c3.309 0 6 2.691 6 6s-2.691 6-6 6-6-2.691-6-6 2.691-6 6-6z"></path></svg>',
                                            color: Colors.grey,
                                          ),
                                        ),
                                        suffixIcon:
                                            searchCtl.text.isNotEmpty
                                                ? IconButton(
                                                  onPressed: () {
                                                    searchCtl.clear();
                                                  },
                                                  icon: SvgPicture.string(
                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M9.172 16.242 12 13.414l2.828 2.828 1.414-1.414L13.414 12l2.828-2.828-1.414-1.414L12 10.586 9.172 7.758 7.758 9.172 10.586 12l-2.828 2.828z"></path><path d="M12 22c5.514 0 10-4.486 10-10S17.514 2 12 2 2 6.486 2 12s4.486 10 10 10zm0-18c4.411 0 8 3.589 8 8s-3.589 8-8 8-8-3.589-8-8 3.589-8 8-8z"></path></svg>',
                                                    color: Colors.grey,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(width: 0.5),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(width: 0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                              Row(
                                children: [
                                  !hideSearchMyBoards
                                      ? InkWell(
                                        onTap: searchMyBoards,
                                        child: SvgPicture.string(
                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10 18a7.952 7.952 0 0 0 4.897-1.688l4.396 4.396 1.414-1.414-4.396-4.396A7.952 7.952 0 0 0 18 10c0-4.411-3.589-8-8-8s-8 3.589-8 8 3.589 8 8 8zm0-14c3.309 0 6 2.691 6 6s-2.691 6-6 6-6-2.691-6-6 2.691-6 6-6z"></path></svg>',
                                          height: height * 0.035,
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                      : SizedBox.shrink(),
                                  InkWell(
                                    key: iconKey,
                                    onTap: () {
                                      !hideSearchMyBoards
                                          ? showPopupMenu(context)
                                          : hideSearchMyBoards = false;
                                      if (searchCtl.text.isNotEmpty) {
                                        searchCtl.clear();
                                      }
                                    },
                                    child: SvgPicture.string(
                                      !hideSearchMyBoards
                                          ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 12c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"></path></svg>'
                                          : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m16.192 6.344-4.243 4.242-4.242-4.242-1.414 1.414L10.535 12l-4.242 4.242 1.414 1.414 4.242-4.242 4.243 4.242 1.414-1.414L13.364 12l4.242-4.242z"></path></svg>',
                                      height:
                                          !hideSearchMyBoards
                                              ? height * 0.035
                                              : height * 0.04,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (searchCtl.text.isEmpty)
                            Stack(
                              children: [
                                Column(
                                  children: [
                                    SizedBox(height: height * 0.01),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.01,
                                      ),
                                      child: Container(
                                        width: width,
                                        height: height * 0.12,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF2F2F6),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 2,
                                              color: Color(0xFF979595),
                                              spreadRadius: 0.1,
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.06,
                                            vertical: height * 0.005,
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'is comming!!',
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .titleLarge!
                                                              .fontSize,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    'To day',
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .titleLarge!
                                                              .fontSize,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF007AFF),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (getUpcomingTasks(
                                                tasks,
                                              ).isEmpty)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: height * 0.01,
                                                  ),
                                                  child: Text(
                                                    "No tasks for today",
                                                    style: TextStyle(
                                                      fontSize:
                                                          Get
                                                              .textTheme
                                                              .titleMedium!
                                                              .fontSize,
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ...getUpcomingTasks(tasks).map((
                                                task,
                                              ) {
                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.task,
                                                            color: Colors.grey,
                                                            size:
                                                                Get
                                                                    .textTheme
                                                                    .labelLarge!
                                                                    .fontSize,
                                                          ),
                                                          SizedBox(
                                                            width: width * 0.01,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              task.taskName,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    Get
                                                                        .textTheme
                                                                        .labelMedium!
                                                                        .fontSize,
                                                                fontFamily:
                                                                    'mali',
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: width * 0.15,
                                                    ),
                                                    Text(
                                                      timeUntilDetailed(
                                                        task.createdAt,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize:
                                                            Get
                                                                .textTheme
                                                                .labelMedium!
                                                                .fontSize,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: height * 0.01),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'My Boards',
                                          style: TextStyle(
                                            fontSize:
                                                Get
                                                    .textTheme
                                                    .headlineSmall!
                                                    .fontSize,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap:
                                                  () =>
                                                      toggleDisplayFormat(true),
                                              child: SvgPicture.string(
                                                displayFormat
                                                    ? '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M80-160v-160h160v160H80Zm240 0v-160h560v160H320ZM80-400v-160h160v160H80Zm240 0v-160h560v160H320ZM80-640v-160h160v160H80Zm240 0v-160h560v160H320Z"/></svg>'
                                                    : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M4 6h2v2H4zm0 5h2v2H4zm0 5h2v2H4zm16-8V6H8.023v2H18.8zM8 11h12v2H8zm0 5h12v2H8z"></path></svg>',
                                                height:
                                                    displayFormat
                                                        ? height * 0.03
                                                        : height * 0.032,
                                                fit: BoxFit.contain,
                                                color:
                                                    displayFormat
                                                        ? Colors.black
                                                        : Color(0xFF979595),
                                              ),
                                            ),
                                            SizedBox(width: width * 0.01),
                                            InkWell(
                                              onTap:
                                                  () => toggleDisplayFormat(
                                                    false,
                                                  ),
                                              child: SvgPicture.string(
                                                !displayFormat
                                                    ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M4 11h6a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1zm10 0h6a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1zM4 21h6a1 1 0 0 0 1-1v-6a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1zm10 0h6a1 1 0 0 0 1-1v-6a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1z"></path></svg>'
                                                    : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10 3H4a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1zM9 9H5V5h4v4zm5 2h6a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1zm1-6h4v4h-4V5zM3 20a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1v-6a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v6zm2-5h4v4H5v-4zm8 5a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1v-6a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v6zm2-5h4v4h-4v-4z"></path></svg>',
                                                height: height * 0.03,
                                                fit: BoxFit.contain,
                                                color:
                                                    !displayFormat
                                                        ? Colors.black
                                                        : Color(0xFF979595),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: width * 0.03,
                                        right: width * 0.03,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          InkWell(
                                            key: listKey,
                                            onTap: () {
                                              var boardData =
                                                  AllDataUserGetResponst.fromJson(
                                                    box.read('userDataAll'),
                                                  );
                                              Provider.of<Appdata>(
                                                context,
                                                listen: false,
                                              ).showMyBoards.setBoards(
                                                boardData,
                                              );
                                              var createdBoards =
                                                  Provider.of<Appdata>(
                                                    context,
                                                    listen: false,
                                                  ).showMyBoards.createdBoards;
                                              setState(() {
                                                boards = createdBoards;
                                                moveSliderToKey(listKey);
                                                listsFontWeight =
                                                    FontWeight.w600;
                                                groupFontWeight =
                                                    FontWeight.w500;
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.02,
                                              ),
                                              child: Text(
                                                'Lists',
                                                style: TextStyle(
                                                  fontSize:
                                                      Get
                                                          .textTheme
                                                          .titleLarge!
                                                          .fontSize,
                                                  fontWeight: listsFontWeight,
                                                  color:
                                                      listsFontWeight ==
                                                              FontWeight.w600
                                                          ? Color(0xFF007AFF)
                                                          : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            key: groupKey,
                                            onTap: () {
                                              var boardData =
                                                  AllDataUserGetResponst.fromJson(
                                                    box.read('userDataAll'),
                                                  );
                                              Provider.of<Appdata>(
                                                context,
                                                listen: false,
                                              ).showMyBoards.setBoards(
                                                boardData,
                                              );
                                              var memberBoards =
                                                  Provider.of<Appdata>(
                                                    context,
                                                    listen: false,
                                                  ).showMyBoards.memberBoards;
                                              setState(() {
                                                boards = memberBoards;
                                                moveSliderToKey(groupKey);
                                                listsFontWeight =
                                                    FontWeight.w500;
                                                groupFontWeight =
                                                    FontWeight.w600;
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.02,
                                              ),
                                              child: Text(
                                                'Groups',
                                                style: TextStyle(
                                                  fontSize:
                                                      Get
                                                          .textTheme
                                                          .titleLarge!
                                                          .fontSize,
                                                  fontWeight: groupFontWeight,
                                                  color:
                                                      groupFontWeight ==
                                                              FontWeight.w600
                                                          ? Color(0xFF007AFF)
                                                          : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        Container(
                                          width: width,
                                          height: height * 0.54,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                          ),
                                        ),
                                        AnimatedPositioned(
                                          left: slider,
                                          top: 0,
                                          duration: Duration(milliseconds: 500),
                                          curve: Curves.easeInOut,
                                          child: Container(
                                            width: width * 0.1,
                                            height: height * 0.06,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF007AFF),
                                              shape: BoxShape.rectangle,
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                          ),
                                        ),
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
                                        if (!displayFormat)
                                          Positioned(
                                            top: 10,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              width: width,
                                              height: height * 0.52,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.01,
                                                vertical: height * 0.01,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Color(0xFFF2F2F6),
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              child: SingleChildScrollView(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: width * 0.03,
                                                    vertical: height * 0.01,
                                                  ),
                                                  child: Wrap(
                                                    spacing: width * 0.02,
                                                    runSpacing: width * 0.034,
                                                    children:
                                                        isLoadings ||
                                                                showShimmer
                                                            ? List.generate(
                                                              itemCount,
                                                              (
                                                                index,
                                                              ) => Shimmer.fromColors(
                                                                baseColor: Color(
                                                                  0xFFF7F7F7,
                                                                ),
                                                                highlightColor:
                                                                    Colors
                                                                        .grey[300]!,
                                                                child: Container(
                                                                  width:
                                                                      width *
                                                                      0.4,
                                                                  height:
                                                                      height *
                                                                      0.15,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                            : [
                                                              ...boards.asMap().entries.map((
                                                                entry,
                                                              ) {
                                                                final int
                                                                index =
                                                                    entry.key;
                                                                final board =
                                                                    entry.value;
                                                                final String
                                                                keyId =
                                                                    '${board.boardName}_$index';
                                                                final bool
                                                                loadWaitNewBoard =
                                                                    loadingBoardId ==
                                                                    board
                                                                        .boardId;
                                                                if (!boardInfoKeys
                                                                    .containsKey(
                                                                      keyId,
                                                                    )) {
                                                                  boardInfoKeys[keyId] =
                                                                      GlobalKey();
                                                                }
                                                                final bool
                                                                isSelected =
                                                                    focusedBoardId ==
                                                                    keyId;
                                                                return SizedBox(
                                                                  key:
                                                                      boardInfoKeys[keyId],
                                                                  child: Column(
                                                                    children: [
                                                                      Transform.scale(
                                                                        scale:
                                                                            isSelected
                                                                                ? 1.05
                                                                                : 1.0,
                                                                        child: AnimatedContainer(
                                                                          duration: Duration(
                                                                            milliseconds:
                                                                                200,
                                                                          ),
                                                                          width:
                                                                              width *
                                                                              0.4,
                                                                          height:
                                                                              height *
                                                                              0.15,
                                                                          decoration: BoxDecoration(
                                                                            color:
                                                                                loadWaitNewBoard
                                                                                    ? Color(
                                                                                      0xFFF2F2F6,
                                                                                    )
                                                                                    : Colors.white,
                                                                            borderRadius: BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                            boxShadow:
                                                                                isSelected
                                                                                    ? [
                                                                                      BoxShadow(
                                                                                        color:
                                                                                            Colors.black26,
                                                                                        blurRadius:
                                                                                            10,
                                                                                        offset: Offset(
                                                                                          0,
                                                                                          5,
                                                                                        ),
                                                                                      ),
                                                                                    ]
                                                                                    : [
                                                                                      BoxShadow(
                                                                                        color:
                                                                                            loadWaitNewBoard
                                                                                                ? Color.fromRGBO(
                                                                                                  151,
                                                                                                  149,
                                                                                                  149,
                                                                                                  progressValue,
                                                                                                )
                                                                                                : Color(
                                                                                                  0xFF979595,
                                                                                                ),
                                                                                        blurRadius:
                                                                                            3,
                                                                                        offset: Offset(
                                                                                          0,
                                                                                          1,
                                                                                        ),
                                                                                        spreadRadius:
                                                                                            0.1,
                                                                                      ),
                                                                                    ],
                                                                          ),
                                                                          child: Stack(
                                                                            children: [
                                                                              Material(
                                                                                color:
                                                                                    Colors.transparent,
                                                                                child: InkWell(
                                                                                  borderRadius: BorderRadius.circular(
                                                                                    12,
                                                                                  ),
                                                                                  onTap:
                                                                                      !loadWaitNewBoard
                                                                                          ? () => goToMyList(
                                                                                            board.boardName,
                                                                                          )
                                                                                          : null,
                                                                                  onLongPress: () {
                                                                                    final String keyId =
                                                                                        '${board.boardName}_$index';
                                                                                    setState(
                                                                                      () {
                                                                                        focusedBoardId =
                                                                                            focusedBoardId ==
                                                                                                    keyId
                                                                                                ? null
                                                                                                : keyId;
                                                                                      },
                                                                                    );
                                                                                    showInfoMenuBoard(
                                                                                      context,
                                                                                      board.boardId,
                                                                                      board.boardName,
                                                                                      keyId:
                                                                                          keyId,
                                                                                    );
                                                                                  },
                                                                                  child: Center(
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.symmetric(
                                                                                        horizontal:
                                                                                            width *
                                                                                            0.02,
                                                                                      ),
                                                                                      child: Text(
                                                                                        board.boardName,
                                                                                        style: TextStyle(
                                                                                          fontSize:
                                                                                              Get.textTheme.titleMedium!.fontSize,
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
                                                                                                  : Colors.black,
                                                                                        ),
                                                                                        textAlign:
                                                                                            TextAlign.center,
                                                                                        maxLines:
                                                                                            3,
                                                                                        overflow:
                                                                                            TextOverflow.ellipsis,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              if (focusedBoardId !=
                                                                                      null &&
                                                                                  !isSelected)
                                                                                Positioned.fill(
                                                                                  child: ClipRRect(
                                                                                    borderRadius: BorderRadius.circular(
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
                                                                    ],
                                                                  ),
                                                                );
                                                              }),
                                                              // ปุ่มสร้างบอร์ดใหม่
                                                              SizedBox(
                                                                child: Column(
                                                                  children: [
                                                                    Container(
                                                                      width:
                                                                          width *
                                                                          0.4,
                                                                      height:
                                                                          height *
                                                                          0.15,
                                                                      decoration: BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                        color: Color.fromARGB(
                                                                          160,
                                                                          255,
                                                                          255,
                                                                          255,
                                                                        ),
                                                                      ),
                                                                      child: Material(
                                                                        color:
                                                                            Colors.transparent,
                                                                        child: InkWell(
                                                                          borderRadius: BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                          onTap:
                                                                              loadingBoardId ==
                                                                                      null
                                                                                  ? createNewBoard
                                                                                  : null,
                                                                          child: Stack(
                                                                            alignment:
                                                                                Alignment.center,
                                                                            children: [
                                                                              if (focusedBoardId !=
                                                                                  null)
                                                                                ClipRRect(
                                                                                  borderRadius: BorderRadius.circular(
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

                                                                              if (focusedBoardId !=
                                                                                  null) ...[
                                                                                Text(
                                                                                  '+',
                                                                                  style: TextStyle(
                                                                                    fontSize:
                                                                                        Get.textTheme.headlineSmall!.fontSize,
                                                                                    fontWeight:
                                                                                        FontWeight.w500,
                                                                                    color: Color(
                                                                                      0x66007AFF,
                                                                                    ), // จางลง
                                                                                    shadows: [
                                                                                      Shadow(
                                                                                        blurRadius:
                                                                                            8,
                                                                                        color:
                                                                                            Colors.blueAccent,
                                                                                        offset: Offset(
                                                                                          0,
                                                                                          0,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                              // ตัวอักษรคม
                                                                              Text(
                                                                                '+',
                                                                                style: TextStyle(
                                                                                  fontSize:
                                                                                      Get.textTheme.headlineSmall!.fontSize,
                                                                                  fontWeight:
                                                                                      FontWeight.w500,
                                                                                  color: Color(
                                                                                    0xFF007AFF,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
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
                                            ),
                                          ),
                                        if (displayFormat)
                                          Positioned(
                                            top: 10,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              width: width,
                                              height: height * 0.52,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.01,
                                                vertical: height * 0.01,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Color(0xFFF2F2F6),
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              child: SingleChildScrollView(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: width * 0.03,
                                                    vertical: height * 0.01,
                                                  ),
                                                  child: Column(
                                                    children:
                                                        isLoadings ||
                                                                showShimmer
                                                            ? List.generate(
                                                              itemCount,
                                                              (
                                                                index,
                                                              ) => Shimmer.fromColors(
                                                                baseColor: Color(
                                                                  0xFFF7F7F7,
                                                                ),
                                                                highlightColor:
                                                                    Colors
                                                                        .grey[300]!,
                                                                child: Padding(
                                                                  padding: EdgeInsets.only(
                                                                    bottom:
                                                                        height *
                                                                        0.013,
                                                                  ),
                                                                  child: Container(
                                                                    width:
                                                                        width,
                                                                    height:
                                                                        height *
                                                                        0.07,
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          Colors
                                                                              .white,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                            : [
                                                              ...boards.asMap().entries.map((
                                                                entry,
                                                              ) {
                                                                final int
                                                                index =
                                                                    entry.key;
                                                                final board =
                                                                    entry.value;
                                                                final String
                                                                keyId =
                                                                    '${board.boardName}_$index';
                                                                final bool
                                                                loadWaitNewBoard =
                                                                    loadingBoardId ==
                                                                    board
                                                                        .boardId;
                                                                if (!boardInfoKeys
                                                                    .containsKey(
                                                                      keyId,
                                                                    )) {
                                                                  boardInfoKeys[keyId] =
                                                                      GlobalKey();
                                                                }
                                                                final bool
                                                                isSelected =
                                                                    focusedBoardId ==
                                                                    keyId;

                                                                return Padding(
                                                                  key:
                                                                      boardInfoKeys[keyId],
                                                                  padding: EdgeInsets.only(
                                                                    bottom:
                                                                        height *
                                                                        0.013,
                                                                  ),
                                                                  child: Transform.scale(
                                                                    scale:
                                                                        isSelected
                                                                            ? 1.05
                                                                            : 1.0,
                                                                    child: AnimatedContainer(
                                                                      duration: Duration(
                                                                        milliseconds:
                                                                            200,
                                                                      ),
                                                                      width:
                                                                          width,
                                                                      height:
                                                                          height *
                                                                          0.07,
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            loadWaitNewBoard
                                                                                ? Color(
                                                                                  0xFFF2F2F6,
                                                                                )
                                                                                : Colors.white,
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                        boxShadow:
                                                                            isSelected
                                                                                ? [
                                                                                  BoxShadow(
                                                                                    color:
                                                                                        Colors.black26,
                                                                                    blurRadius:
                                                                                        10,
                                                                                    offset: Offset(
                                                                                      0,
                                                                                      5,
                                                                                    ),
                                                                                  ),
                                                                                ]
                                                                                : [
                                                                                  BoxShadow(
                                                                                    color:
                                                                                        loadWaitNewBoard
                                                                                            ? Color.fromRGBO(
                                                                                              151,
                                                                                              149,
                                                                                              149,
                                                                                              progressValue,
                                                                                            )
                                                                                            : Color(
                                                                                              0xFF979595,
                                                                                            ),
                                                                                    blurRadius:
                                                                                        3,
                                                                                    offset: Offset(
                                                                                      0,
                                                                                      1,
                                                                                    ),
                                                                                    spreadRadius:
                                                                                        0.1,
                                                                                  ),
                                                                                ],
                                                                      ),
                                                                      child: Stack(
                                                                        children: [
                                                                          Material(
                                                                            color: Color(
                                                                              0x000A0606,
                                                                            ),
                                                                            child: InkWell(
                                                                              borderRadius: BorderRadius.circular(
                                                                                12,
                                                                              ),
                                                                              onTap:
                                                                                  !loadWaitNewBoard
                                                                                      ? () => goToMyList(
                                                                                        board.boardName,
                                                                                      )
                                                                                      : null,
                                                                              onLongPress: () {
                                                                                final String
                                                                                keyId =
                                                                                    '${board.boardName}_$index';
                                                                                setState(
                                                                                  () {
                                                                                    focusedBoardId =
                                                                                        focusedBoardId ==
                                                                                                keyId
                                                                                            ? null
                                                                                            : keyId;
                                                                                  },
                                                                                );
                                                                                showInfoMenuBoard(
                                                                                  context,
                                                                                  board.boardId,
                                                                                  board.boardName,
                                                                                  keyId:
                                                                                      keyId,
                                                                                );
                                                                              },
                                                                              child: Center(
                                                                                child: Padding(
                                                                                  padding: EdgeInsets.symmetric(
                                                                                    horizontal:
                                                                                        width *
                                                                                        0.02,
                                                                                  ),
                                                                                  child: Text(
                                                                                    board.boardName,
                                                                                    style: TextStyle(
                                                                                      fontSize:
                                                                                          Get.textTheme.titleMedium!.fontSize,
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
                                                                                              : Colors.black,
                                                                                    ),
                                                                                    textAlign:
                                                                                        TextAlign.center,
                                                                                    maxLines:
                                                                                        1,
                                                                                    overflow:
                                                                                        TextOverflow.ellipsis,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          if (focusedBoardId !=
                                                                                  null &&
                                                                              !isSelected)
                                                                            Positioned.fill(
                                                                              child: ClipRRect(
                                                                                borderRadius: BorderRadius.circular(
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
                                                                );
                                                              }),
                                                              // ปุ่มสร้างบอร์ดใหม่
                                                              Container(
                                                                width: width,
                                                                height:
                                                                    height *
                                                                    0.07,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                  color:
                                                                      Color.fromARGB(
                                                                        160,
                                                                        255,
                                                                        255,
                                                                        255,
                                                                      ),
                                                                ),
                                                                child: Material(
                                                                  color:
                                                                      Colors
                                                                          .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                    onTap:
                                                                        loadingBoardId ==
                                                                                null
                                                                            ? createNewBoard
                                                                            : null,
                                                                    child: Stack(
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      children: [
                                                                        if (focusedBoardId !=
                                                                            null)
                                                                          ClipRRect(
                                                                            borderRadius: BorderRadius.circular(
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

                                                                        if (focusedBoardId !=
                                                                            null) ...[
                                                                          Text(
                                                                            '+',
                                                                            style: TextStyle(
                                                                              fontSize:
                                                                                  Get.textTheme.headlineSmall!.fontSize,
                                                                              fontWeight:
                                                                                  FontWeight.w500,
                                                                              color: Color(
                                                                                0x66007AFF,
                                                                              ),
                                                                              shadows: [
                                                                                Shadow(
                                                                                  blurRadius:
                                                                                      8,
                                                                                  color:
                                                                                      Colors.blueAccent,
                                                                                  offset: Offset(
                                                                                    0,
                                                                                    0,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                        // ตัวอักษรคม
                                                                        Text(
                                                                          '+',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                Get.textTheme.headlineSmall!.fontSize,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            color: Color(
                                                                              0xFF007AFF,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
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
                                      ],
                                    ),
                                  ],
                                ),
                                if (searchFocusNode.hasFocus)
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
                          if (searchCtl.text.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: height * 0.02),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Lists",
                                        style: TextStyle(
                                          fontSize:
                                              Get
                                                  .textTheme
                                                  .titleLarge!
                                                  .fontSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children:
                                        showSearchResultCreatedBoards(
                                          searchCtl.text,
                                        ).map((data) {
                                          return Column(
                                            children: [
                                              InkWell(
                                                onTap: () {},
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: width * 0.02,
                                                    vertical: height * 0.01,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        data.boardName,
                                                        style: TextStyle(
                                                          fontSize:
                                                              Get
                                                                  .textTheme
                                                                  .titleLarge!
                                                                  .fontSize,
                                                        ),
                                                      ),
                                                    ],
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
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          if (searchCtl.text.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: height * 0.02),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Groups",
                                        style: TextStyle(
                                          fontSize:
                                              Get
                                                  .textTheme
                                                  .titleLarge!
                                                  .fontSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children:
                                        showSearchResultMemberBoards(
                                          searchCtl.text,
                                        ).map((data) {
                                          return Column(
                                            children: [
                                              InkWell(
                                                onTap: () {},
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: width * 0.02,
                                                    vertical: height * 0.01,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        data.boardName,
                                                        style: TextStyle(
                                                          fontSize:
                                                              Get
                                                                  .textTheme
                                                                  .titleLarge!
                                                                  .fontSize,
                                                        ),
                                                      ),
                                                    ],
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
                                          );
                                        }).toList(),
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
            ),
          ),
        );
      },
    );
  }

  List<Todaytask> getUpcomingTasks(List<Todaytask> tasks) {
    final now = DateTime.now();

    List<Todaytask> upcomingTasks =
        tasks.where((task) {
          final taskTime = DateTime.parse(task.createdAt);
          return taskTime.isAfter(now) || now.difference(taskTime).inHours < 24;
        }).toList();

    upcomingTasks.sort(
      (a, b) =>
          DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)),
    );

    return upcomingTasks.take(3).toList();
  }

  String timeUntilDetailed(String timestamp) {
    final DateTime targetTime = DateTime.parse(timestamp).toLocal();
    final DateTime now = DateTime.now();
    final Duration diff = targetTime.difference(now);

    if (diff.isNegative) {
      return 'Time’s up';
    }

    final int days = diff.inDays;
    final int hours = diff.inHours % 24;
    final int minutes = diff.inMinutes % 60;
    final int seconds = diff.inSeconds % 60;

    if (diff.inSeconds < 60) {
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

  Future<bool> checkExpiresRefreshToken() async {
    var result =
        await FirebaseFirestore.instance
            .collection('refreshTokens')
            .doc(box.read('userProfile')['userid'].toString())
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
                Get.back();
                await storage.deleteAll();
                box.remove('userProfile');
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
                  fontSize: Get.textTheme.titleLarge!.fontSize,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
        return true;
      } else {
        return false;
      }
    }
    return false;
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
    appData.showMyTasks.setTasks(boardData.todaytasks);

    final createdBoards = appData.showMyBoards.createdBoards;
    final memberBoards = appData.showMyBoards.memberBoards;
    final task = appData.showMyTasks.tasks;

    // เตรียมค่าใหม่ทั้งหมด
    List newBoards =
        listsFontWeight == FontWeight.w600 ? createdBoards : memberBoards;
    GlobalKey? sliderKey =
        listsFontWeight == FontWeight.w600 ? listKey : groupKey;

    // เรียกเลื่อน Slider หลัง build เสร็จ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      moveSliderToKey(sliderKey);
    });

    // อัปเดตข้อมูลทั้งหมดใน setState เดียว
    setState(() {
      isLoadings = false;
      showShimmer = false;

      boards = newBoards;
      tasks = task;

      emailUser = userProfileData['email'] ?? '';
      name = getFirstName(userProfileData['name'] ?? '');
      userProfile = userProfileData['profile'] ?? '';

      appData.changeMyProfileProvider.setName(name);
      appData.changeMyProfileProvider.setProfile(userProfile);
    });
  }

  String getFirstName(String fullName) {
    List<String> parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  showInfoMenuBoard(
    BuildContext context,
    int boardId,
    String boardName, {
    required String keyId,
  }) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;
    final RenderBox renderBox =
        boardInfoKeys[keyId]!.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final double menuWidth = width * 0.4;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + (size.width / 2) - (menuWidth / 2),
        offset.dy - 110,
        offset.dx + (size.width / 2) + (menuWidth / 2),
        offset.dy + size.height,
      ),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      menuPadding: EdgeInsets.zero,
      color: Color(0xFFF2F2F6),
      items: [
        PopupMenuItem(
          value: 'Info',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M11 11h2v6h-2zm0-4h2v2h-2z"></path></svg>',
                height: height * 0.025,
                fit: BoxFit.contain,
              ),
              Text(
                'Show info',
                style: TextStyle(
                  fontSize: Get.textTheme.titleMedium!.fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Delete',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M5 20a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8h2V6h-4V4a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v2H3v2h2zM9 4h6v2H9zM8 8h9v12H7V8z"></path><path d="M9 10h2v8H9zm4 0h2v8h-2z"></path></svg>',
                height: height * 0.025,
                fit: BoxFit.contain,
                color: Colors.red,
              ),
              Text(
                'Delete List',
                style: TextStyle(
                  fontSize: Get.textTheme.titleMedium!.fontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) async {
      url = await loadAPIEndpoint();
      if (focusedBoardId != null) {
        setState(() {
          focusedBoardId = null;
        });
      }
      if (value == 'Info') {
        showEditInfo(boardName, keyId);
      } else if (value == 'Delete') {
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
          final appData = Provider.of<Appdata>(context, listen: false);
          var existingData = AllDataUserGetResponst.fromJson(
            box.read('userDataAll'),
          );
          if (listsFontWeight == FontWeight.w600) {
            appData.showMyBoards.removeCreatedBoardById(boardId);
            existingData.board.removeWhere((b) => b.boardId == boardId);
          } else if (groupFontWeight == FontWeight.w600) {
            appData.showMyBoards.removeMemberBoardById(boardId);
            existingData.boardgroup.removeWhere((b) => b.boardId == boardId);
          }
          box.write('userDataAll', existingData.toJson());

          var response = await http.delete(
            Uri.parse("$url/board/delete/$boardId"),
            headers: {
              "Content-Type": "application/json; charset=utf-8",
              "Authorization": "Bearer ${box.read('accessToken')}",
            },
          );
          if (response.statusCode == 403) {
            await loadNewRefreshToken();
            await http.delete(
              Uri.parse("$url/board/delete/$boardId"),
              headers: {
                "Content-Type": "application/json; charset=utf-8",
                "Authorization": "Bearer ${box.read('accessToken')}",
              },
            );
          }
        } finally {
          isDeleteBoard = false;
        }
      }
    });
  }

  showEditInfo(String boardname, String keyId) {
    boardListNameCtl.text = boardname;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height;

            return GestureDetector(
              onTap: () {
                if (boardListNameFocusNode.hasFocus) {
                  boardListNameFocusNode.unfocus();
                }
              },
              child: FractionallySizedBox(
                heightFactor: 0.94,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: width * 0.05,
                    right: width * 0.05,
                    top: height * 0.01,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Get.back();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.02,
                                      vertical: height * 0.01,
                                    ),
                                    child: SvgPicture.string(
                                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M21 11H6.414l5.293-5.293-1.414-1.414L2.586 12l7.707 7.707 1.414-1.414L6.414 13H21z"></path></svg>',
                                      height: height * 0.03,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                'List Info',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleLarge!.fontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.back();
                                  boardListNameCtl.clear();
                                },
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4790EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: width,
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.04,
                              vertical: height * 0.02,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFF2F2F6),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              children: [
                                SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M11 11h2v6h-2zm0-4h2v2h-2z"></path></svg>',
                                  height: height * 0.1,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: height * 0.01),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: boardListNameCtl,
                                    focusNode: boardListNameFocusNode,
                                    keyboardType: TextInputType.text,
                                    cursorColor: Color(0xFF4790EB),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleLarge!.fontSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    decoration: InputDecoration(
                                      hintText: 'Board List Name',
                                      hintStyle: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleLarge!.fontSize,
                                        fontWeight: FontWeight.normal,
                                        color:
                                            boardListNameCtl.text.isEmpty
                                                ? Colors.black
                                                : Colors.grey,
                                      ),
                                      suffixIcon:
                                          boardListNameFocusNode.hasFocus
                                              ? Material(
                                                color: Colors.transparent,
                                                child: IconButton(
                                                  onPressed: () {
                                                    boardListNameCtl.clear();
                                                  },
                                                  icon: SvgPicture.string(
                                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M9.172 16.242 12 13.414l2.828 2.828 1.414-1.414L13.414 12l2.828-2.828-1.414-1.414L12 10.586 9.172 7.758 7.758 9.172 10.586 12l-2.828 2.828z"></path><path d="M12 22c5.514 0 10-4.486 10-10S17.514 2 12 2 2 6.486 2 12s4.486 10 10 10zm0-18c4.411 0 8 3.589 8 8s-3.589 8-8 8-8-3.589-8-8 3.589-8 8-8z"></path></svg>',
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              )
                                              : null,
                                      constraints: BoxConstraints(
                                        maxHeight: height * 0.05,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: width * 0.04,
                                        vertical: height * 0.01,
                                      ),
                                      border: InputBorder.none,
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
            );
          },
        );
      },
    );
  }

  Future<void> loadMessages() async {
    final String jsonString = await rootBundle.loadString(
      'assets/text/text.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);

    if (!mounted) return;
    setState(() {
      messagesRandom = jsonData.cast<String>();
    });

    // เริ่ม Timer หลังโหลดข้อความเสร็จ
    startMessageRotation();
  }

  void startMessageRotation() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      final boardDataRaw = box.read('userDataAll');
      final boardData = AllDataUserGetResponst.fromJson(boardDataRaw);
      final appData = Provider.of<Appdata>(context, listen: false);
      appData.showMyTasks.setTasks(boardData.todaytasks);
      if (!mounted) return;
      setState(() {
        tasks = appData.showMyTasks.tasks;
        currentIndexMessagesRandom =
            (currentIndexMessagesRandom + 1) % messagesRandom.length;
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

  void showDisplays(String? show) {
    var boardData = AllDataUserGetResponst.fromJson(box.read('userDataAll'));
    Provider.of<Appdata>(
      context,
      listen: false,
    ).showMyBoards.setBoards(boardData);

    var createdBoards =
        Provider.of<Appdata>(context, listen: false).showMyBoards.createdBoards;
    var memberBoards =
        Provider.of<Appdata>(context, listen: false).showMyBoards.memberBoards;

    // ตั้งค่าดีฟอลต์
    if (box.read('showDisplays') == null) {
      box.write('showDisplays', {'listsTF': true, 'groupTF': false});
    }
    if (box.read('showDisplays2') == null) {
      box.write('showDisplays2', {'grid': true, 'list': false});
    }

    // อัปเดต displayFormat จาก box
    final showDisplay2 = box.read('showDisplays2');
    displayFormat = showDisplay2['list'] == true;

    // อัปเดต list/group
    final showDisplay = box.read('showDisplays');
    if (showDisplay['listsTF'] == true) {
      if (show == 'group') {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => moveSliderToKey(groupKey),
        );
        listsFontWeight = FontWeight.w500;
        groupFontWeight = FontWeight.w600;
        boards = memberBoards;
      } else {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => moveSliderToKey(listKey),
        );
        listsFontWeight = FontWeight.w600;
        groupFontWeight = FontWeight.w500;
        boards = createdBoards;
      }
    } else if (showDisplay['groupTF'] == true) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => moveSliderToKey(groupKey),
      );
      listsFontWeight = FontWeight.w500;
      groupFontWeight = FontWeight.w600;
      boards = memberBoards;
    }
  }

  void toggleDisplayFormat(bool isList) {
    final displaySettings = {'grid': !isList, 'list': isList};
    box.write('showDisplays2', displaySettings);
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
        setState(() {
          progressValue += 0.02;
        });
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height;
            Future.delayed(Duration(milliseconds: 50), () {
              boardFocusNode.requestFocus();
            });
            return Padding(
              padding: EdgeInsets.only(
                left: width * 0.05,
                right: width * 0.05,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + height * 0.02,
              ),
              child: SizedBox(
                height: height * 0.25,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'New Board',
                              style: TextStyle(
                                fontSize:
                                    Get.textTheme.headlineMedium!.fontSize,
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
                            fontSize: Get.textTheme.titleLarge!.fontSize,
                          ),
                          decoration: InputDecoration(
                            hintText: isTyping ? '' : 'Enter your board name',
                            hintStyle: TextStyle(
                              fontSize: Get.textTheme.titleLarge!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: Color(0x4D000000),
                            ),
                            constraints: BoxConstraints(
                              maxHeight: height * 0.05,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: width * 0.02,
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
                          fontSize: Get.textTheme.titleMedium!.fontSize,
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
                              setState(() {
                                textError = 'Please enter your board name';
                              });
                              return;
                            }
                            int tempId = Random().nextInt(100000);
                            Board tempBoard = Board(
                              boardId: tempId,
                              boardName: boardName,
                              createdAt: '',
                              createdBy: box.read('userProfile')['userid'],
                              tasks: [],
                            );
                            Boardgroup tempBoardGroup = Boardgroup(
                              boardId: tempId,
                              boardName: boardName,
                              createdAt: '',
                              createdBy: box.read('userProfile')['userid'],
                              tasks: [],
                            );

                            final appData = Provider.of<Appdata>(
                              context,
                              listen: false,
                            );
                            var existingData = AllDataUserGetResponst.fromJson(
                              box.read('userDataAll'),
                            );

                            await Future.delayed(Duration(milliseconds: 100));
                            startLoading(tempId);
                            Get.back();

                            if (listsFontWeight == FontWeight.w600) {
                              existingData.board.add(tempBoard);
                              appData.showMyBoards.addCreatedBoard(tempBoard);
                              box.write('userDataAll', existingData.toJson());

                              var responseCreateBoradList = await http.post(
                                Uri.parse("$url/board/create"),
                                headers: {
                                  "Content-Type":
                                      "application/json; charset=utf-8",
                                  "Authorization":
                                      "Bearer ${box.read('accessToken')}",
                                },
                                body: createBoardListsPostRequestToJson(
                                  CreateBoardListsPostRequest(
                                    boardName: boardName,
                                    createdBy:
                                        box.read('userProfile')['userid'],
                                    isGroup: '0',
                                  ),
                                ),
                              );
                              if (responseCreateBoradList.statusCode == 403) {
                                await loadNewRefreshToken();
                                responseCreateBoradList = await http.post(
                                  Uri.parse("$url/board/create"),
                                  headers: {
                                    "Content-Type":
                                        "application/json; charset=utf-8",
                                    "Authorization":
                                        "Bearer ${box.read('accessToken')}",
                                  },
                                  body: createBoardListsPostRequestToJson(
                                    CreateBoardListsPostRequest(
                                      boardName: boardName,
                                      createdBy:
                                          box.read('userProfile')['userid'],
                                      isGroup: '0',
                                    ),
                                  ),
                                );
                              }
                              if (responseCreateBoradList.statusCode == 201) {
                                var data = jsonDecode(
                                  responseCreateBoradList.body,
                                );
                                // สร้างบอร์ดจริง
                                Board realBoard = Board(
                                  boardId: data['boardID'],
                                  boardName: boardName,
                                  createdAt: DateTime.now().toIso8601String(),
                                  createdBy: box.read('userProfile')['userid'],
                                  tasks: [],
                                );
                                await completeLoading();
                                appData.showMyBoards.addCreatedBoard(realBoard);
                                appData.showMyBoards.removeCreatedBoardById(
                                  tempId,
                                );
                                existingData.board.removeWhere(
                                  (b) => b.boardId == tempId,
                                );
                                existingData.board.add(realBoard);
                                box.write('userDataAll', existingData.toJson());

                                // ปิดหน้าต่างและเคลียร์ฟอร์ม
                                showDisplays(null);
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
                              box.write('userDataAll', existingData.toJson());

                              var responseCreateBoradGroup = await http.post(
                                Uri.parse("$url/board/create"),
                                headers: {
                                  "Content-Type":
                                      "application/json; charset=utf-8",
                                  "Authorization":
                                      "Bearer ${box.read('accessToken')}",
                                },
                                body: createBoardListsPostRequestToJson(
                                  CreateBoardListsPostRequest(
                                    boardName: boardName,
                                    createdBy:
                                        box.read('userProfile')['userid'],
                                    isGroup: '1',
                                  ),
                                ),
                              );
                              if (responseCreateBoradGroup.statusCode == 403) {
                                await loadNewRefreshToken();
                                responseCreateBoradGroup = await http.post(
                                  Uri.parse("$url/board/create"),
                                  headers: {
                                    "Content-Type":
                                        "application/json; charset=utf-8",
                                    "Authorization":
                                        "Bearer ${box.read('accessToken')}",
                                  },
                                  body: createBoardListsPostRequestToJson(
                                    CreateBoardListsPostRequest(
                                      boardName: boardName,
                                      createdBy:
                                          box.read('userProfile')['userid'],
                                      isGroup: '1',
                                    ),
                                  ),
                                );
                              }
                              if (responseCreateBoradGroup.statusCode == 201) {
                                var data = jsonDecode(
                                  responseCreateBoradGroup.body,
                                );
                                // สร้างบอร์ดจริง
                                Boardgroup realBoard = Boardgroup(
                                  boardId: data['boardID'],
                                  boardName: boardName,
                                  createdAt: DateTime.now().toIso8601String(),
                                  createdBy: box.read('userProfile')['userid'],
                                  tasks: [],
                                );
                                await completeLoading();
                                appData.showMyBoards.addMemberBoard(realBoard);
                                appData.showMyBoards.removeMemberBoardById(
                                  tempId,
                                );
                                existingData.boardgroup.removeWhere(
                                  (b) => b.boardId == tempId,
                                );
                                existingData.boardgroup.add(realBoard);
                                box.write('userDataAll', existingData.toJson());

                                // ปิดหน้าต่างและเคลียร์ฟอร์ม
                                showDisplays('group');
                                if (!mounted) return;
                                setState(() {
                                  boardCtl.clear();
                                  textError = '';
                                });
                              }
                            }
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
                              fontSize: Get.textTheme.titleLarge!.fontSize,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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

  void goToMyList(String idBoard) {
    KeepIdBoard keeps = KeepIdBoard();
    keeps.idBoard = idBoard;
    context.read<Appdata>().idBoard = keeps;
    Get.to(() => BoradlistsPage());

    if (focusedBoardId != null) {
      setState(() {
        focusedBoardId = null;
      });
    }
  }

  // ฟังก์ชันเพื่อเลื่อน slider
  void moveSliderToKey(GlobalKey key) {
    if (key.currentContext == null) return;

    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    if (!mounted) return;
    setState(() {
      slider =
          position.dx +
          (renderBox.size.width / 2) -
          (MediaQuery.of(context).size.width * 0.1);
    });
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
          value: 'setting',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 16c2.206 0 4-1.794 4-4s-1.794-4-4-4-4 1.794-4 4 1.794 4 4 4zm0-6c1.084 0 2 .916 2 2s-.916 2-2 2-2-.916-2-2 .916-2 2-2z"></path><path d="m2.845 16.136 1 1.73c.531.917 1.809 1.261 2.73.73l.529-.306A8.1 8.1 0 0 0 9 19.402V20c0 1.103.897 2 2 2h2c1.103 0 2-.897 2-2v-.598a8.132 8.132 0 0 0 1.896-1.111l.529.306c.923.53 2.198.188 2.731-.731l.999-1.729a2.001 2.001 0 0 0-.731-2.732l-.505-.292a7.718 7.718 0 0 0 0-2.224l.505-.292a2.002 2.002 0 0 0 .731-2.732l-.999-1.729c-.531-.92-1.808-1.265-2.731-.732l-.529.306A8.1 8.1 0 0 0 15 4.598V4c0-1.103-.897-2-2-2h-2c-1.103 0-2 .897-2 2v.598a8.132 8.132 0 0 0-1.896 1.111l-.529-.306c-.924-.531-2.2-.187-2.731.732l-.999 1.729a2.001 2.001 0 0 0 .731 2.732l.505.292a7.683 7.683 0 0 0 0 2.223l-.505.292a2.003 2.003 0 0 0-.731 2.733zm3.326-2.758A5.703 5.703 0 0 1 6 12c0-.462.058-.926.17-1.378a.999.999 0 0 0-.47-1.108l-1.123-.65.998-1.729 1.145.662a.997.997 0 0 0 1.188-.142 6.071 6.071 0 0 1 2.384-1.399A1 1 0 0 0 11 5.3V4h2v1.3a1 1 0 0 0 .708.956 6.083 6.083 0 0 1 2.384 1.399.999.999 0 0 0 1.188.142l1.144-.661 1 1.729-1.124.649a1 1 0 0 0-.47 1.108c.112.452.17.916.17 1.378 0 .461-.058.925-.171 1.378a1 1 0 0 0 .471 1.108l1.123.649-.998 1.729-1.145-.661a.996.996 0 0 0-1.188.142 6.071 6.071 0 0 1-2.384 1.399A1 1 0 0 0 13 18.7l.002 1.3H11v-1.3a1 1 0 0 0-.708-.956 6.083 6.083 0 0 1-2.384-1.399.992.992 0 0 0-1.188-.141l-1.144.662-1-1.729 1.124-.651a1 1 0 0 0 .471-1.108z"></path></svg>',
                height: height * 0.03,
                fit: BoxFit.contain,
              ),
              SizedBox(width: width * 0.08),
              Text(
                'Setting',
                style: TextStyle(
                  fontSize: Get.textTheme.titleLarge!.fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'report',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 6a3.939 3.939 0 0 0-3.934 3.934h2C10.066 8.867 10.934 8 12 8s1.934.867 1.934 1.934c0 .598-.481 1.032-1.216 1.626a9.208 9.208 0 0 0-.691.599c-.998.997-1.027 2.056-1.027 2.174V15h2l-.001-.633c.001-.016.033-.386.441-.793.15-.15.339-.3.535-.458.779-.631 1.958-1.584 1.958-3.182A3.937 3.937 0 0 0 12 6zm-1 10h2v2h-2z"></path><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path></svg>',
                height: height * 0.03,
                fit: BoxFit.contain,
              ),
              SizedBox(width: width * 0.08),
              Text(
                'Report',
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
      showDisplays(null);
      loadDataAsync();
    } else if (result == 'loadDisplays') {
      loadDataAsync();
    }
  }

  void loadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            content: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
    );
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

      final responseAll = await http.get(
        Uri.parse("$url/user/AlldataUser"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
      if (responseAll.statusCode == 200) {
        final response2 = allDataUserGetResponstFromJson(responseAll.body);

        box.write('userDataAll', response2.toJson());
        var boardData = AllDataUserGetResponst.fromJson(
          box.read('userDataAll'),
        );

        if (listsFontWeight == FontWeight.w600) {
          setState(() {
            boards = boardData.board;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            moveSliderToKey(listKey);
          });
        } else if (groupFontWeight == FontWeight.w600) {
          setState(() {
            boards = boardData.boardgroup.cast<Board>();
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            moveSliderToKey(groupKey);
          });
        }
      }
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
              Get.back();
              await storage.deleteAll();
              box.remove('userProfile');
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
