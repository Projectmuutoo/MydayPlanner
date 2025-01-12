import 'dart:developer';

import 'package:demomydayplanner/config/config.dart';
import 'package:demomydayplanner/models/request/getUserByEmailPostRequest.dart';
import 'package:demomydayplanner/models/response/boardCreateByIdUserGetResponse.dart';
import 'package:demomydayplanner/models/response/getUserByEmailPostResponst.dart';
import 'package:demomydayplanner/pages/pageMember/myTasksLists/boradLists.dart';
import 'package:demomydayplanner/pages/settings.dart';
import 'package:demomydayplanner/shared/appData.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<void> loadData;
  var box = GetStorage();
  String name = '';
  List<BoardCreateByIdUserGetResponse> boards = [];
  List<BoardCreateByIdUserGetResponse> boardsWorkSpaces = [];
  bool displayFormat = false;
  GlobalKey listKey = GlobalKey();
  GlobalKey workspacesKey = GlobalKey();
  GlobalKey priorityKey = GlobalKey();
  double slider = 10;
  FontWeight listsFontWeight = FontWeight.w600;
  FontWeight workspacesFontWeight = FontWeight.w500;
  FontWeight priorityFontWeight = FontWeight.w500;

  @override
  void initState() {
    if (box.read('grid') == null) {
      box.write('grid', true);
      box.write('list', false);
    }
    if (box.read('list')) {
      if (!displayFormat) {
        displayFormat = true;
      }
    }
    if (box.read('grid')) {
      if (!displayFormat) {
        displayFormat = false;
      }
    }

    loadData = loadDataAsync();
    super.initState();
  }

  Future<void> loadDataAsync() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];
    log(box.read('email'));
    GetUserByEmailPostRequest jsonPostuser = GetUserByEmailPostRequest(
      email: box.read('email'),
    );

    http
        .post(
      Uri.parse("$url/user/api/get_user"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: getUserByEmailPostRequestToJson(jsonPostuser),
    )
        .then((value) async {
      if (value.statusCode == 200) {
        GetUserByEmailPostResponst responst =
            getUserByEmailPostResponstFromJson(value.body);
        name = responst.name;

        log(box.read('email'));
        var board = await http
            .get(Uri.parse("$url/board/boardCreateby/${responst.userId}"));
        // boards = boardCreateByIdUserGetResponseFromJson(board.body);
        // boardsWorkSpaces = boards.where((i) => i.isGroup == 1).toList();
        setState(() {});
      }
    }).catchError((err) {});
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
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: null,
            body: Center(
              child: RefreshIndicator(
                color: Color(0xffCDBEAE),
                onRefresh: loadDataAsync,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.05,
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2A10.13 10.13 0 0 0 2 12a10 10 0 0 0 4 7.92V20h.1a9.7 9.7 0 0 0 11.8 0h.1v-.08A10 10 0 0 0 22 12 10.13 10.13 0 0 0 12 2zM8.07 18.93A3 3 0 0 1 11 16.57h2a3 3 0 0 1 2.93 2.36 7.75 7.75 0 0 1-7.86 0zm9.54-1.29A5 5 0 0 0 13 14.57h-2a5 5 0 0 0-4.61 3.07A8 8 0 0 1 4 12a8.1 8.1 0 0 1 8-8 8.1 8.1 0 0 1 8 8 8 8 0 0 1-2.39 5.64z"></path><path d="M12 6a3.91 3.91 0 0 0-4 4 3.91 3.91 0 0 0 4 4 3.91 3.91 0 0 0 4-4 3.91 3.91 0 0 0-4-4zm0 6a1.91 1.91 0 0 1-2-2 1.91 1.91 0 0 1 2-2 1.91 1.91 0 0 1 2 2 1.91 1.91 0 0 1-2 2z"></path></svg>',
                                  height: height * 0.08,
                                  fit: BoxFit.contain,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, $name',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleLarge!.fontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'you can do it!',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleSmall!.fontSize,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {},
                                  child: SvgPicture.string(
                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10 18a7.952 7.952 0 0 0 4.897-1.688l4.396 4.396 1.414-1.414-4.396-4.396A7.952 7.952 0 0 0 18 10c0-4.411-3.589-8-8-8s-8 3.589-8 8 3.589 8 8 8zm0-14c3.309 0 6 2.691 6 6s-2.691 6-6 6-6-2.691-6-6 2.691-6 6-6z"></path></svg>',
                                    height: height * 0.035,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    showPopupMenu(context);
                                  },
                                  child: SvgPicture.string(
                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 12c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"></path></svg>',
                                    height: height * 0.035,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        SizedBox(
                          height: height * 0.01,
                        ),
                        Container(
                          width: width,
                          height: height * 0.12,
                          decoration: const BoxDecoration(
                            color: Color(0xffF5EBE0),
                            borderRadius: BorderRadius.all(
                              Radius.circular(40),
                            ),
                            boxShadow: [
                              BoxShadow(
                                offset: Offset(0, 1),
                                blurRadius: 1,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.08,
                              vertical: height * 0.005,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'is comming!!',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleLarge!.fontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'To day',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleLarge!.fontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.string(
                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2z"></path></svg>',
                                          height: height * 0.01,
                                          fit: BoxFit.contain,
                                          color: Colors.white,
                                        ),
                                        SizedBox(
                                          width: width * 0.01,
                                        ),
                                        Text(
                                          'ไปกินข้าว',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme.titleSmall!.fontSize,
                                            fontWeight: FontWeight.normal,
                                            fontFamily: 'mali',
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '10m',
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
                        SizedBox(
                          height: height * 0.01,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.02,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Tasks',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.headlineSmall!.fontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  if (!displayFormat)
                                    InkWell(
                                      onTap: () {
                                        // log('list ยังไม่กด');
                                        box.write('list', true);
                                        box.write('grid', false);
                                        if (mounted) {
                                          setState(() {
                                            displayFormat = true;
                                          });
                                        }
                                      },
                                      child: SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M4 6h2v2H4zm0 5h2v2H4zm0 5h2v2H4zm16-8V6H8.023v2H18.8zM8 11h12v2H8zm0 5h12v2H8z"></path></svg>',
                                        height: height * 0.034,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  if (displayFormat)
                                    InkWell(
                                      onTap: () {
                                        // log('list กด');
                                        box.write('list', true);
                                        box.write('grid', false);
                                        if (!displayFormat) {
                                          if (mounted) {
                                            setState(() {
                                              displayFormat = false;
                                            });
                                          }
                                        }
                                      },
                                      child: SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M80-160v-160h160v160H80Zm240 0v-160h560v160H320ZM80-400v-160h160v160H80Zm240 0v-160h560v160H320ZM80-640v-160h160v160H80Zm240 0v-160h560v160H320Z"/></svg>',
                                        height: height * 0.03,
                                        fit: BoxFit.contain,
                                        color: Colors.black,
                                      ),
                                    ),
                                  SizedBox(
                                    width: width * 0.01,
                                  ),
                                  if (displayFormat)
                                    InkWell(
                                      onTap: () {
                                        // log('grid ไม่กด');
                                        box.write('grid', true);
                                        box.write('list', false);
                                        if (mounted) {
                                          setState(() {
                                            displayFormat = false;
                                          });
                                        }
                                      },
                                      child: SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10 3H4a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1zM9 9H5V5h4v4zm5 2h6a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1zm1-6h4v4h-4V5zM3 20a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1v-6a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v6zm2-5h4v4H5v-4zm8 5a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1v-6a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v6zm2-5h4v4h-4v-4z"></path></svg>',
                                        height: height * 0.03,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  if (!displayFormat)
                                    InkWell(
                                      onTap: () {
                                        // log('grid กด');
                                        box.write('grid', true);
                                        box.write('list', false);
                                        if (!displayFormat) {
                                          if (mounted) {
                                            setState(() {
                                              displayFormat = false;
                                            });
                                          }
                                        }
                                      },
                                      child: SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M4 11h6a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1zm10 0h6a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1zM4 21h6a1 1 0 0 0 1-1v-6a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1zm10 0h6a1 1 0 0 0 1-1v-6a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1z"></path></svg>',
                                        height: height * 0.03,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          thickness: 1,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.03,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                key: listKey,
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      moveSliderToKey(listKey);
                                      listsFontWeight = FontWeight.w600;
                                      workspacesFontWeight = FontWeight.w500;
                                      priorityFontWeight = FontWeight.w500;
                                    });
                                  }
                                },
                                child: Text(
                                  'Lists',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: listsFontWeight,
                                  ),
                                ),
                              ),
                              InkWell(
                                key: workspacesKey,
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      moveSliderToKey(workspacesKey);
                                      listsFontWeight = FontWeight.w500;
                                      workspacesFontWeight = FontWeight.w600;
                                      priorityFontWeight = FontWeight.w500;
                                    });
                                  }
                                },
                                child: Text(
                                  'Work spaces',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: workspacesFontWeight,
                                  ),
                                ),
                              ),
                              InkWell(
                                key: priorityKey,
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      moveSliderToKey(priorityKey);
                                      listsFontWeight = FontWeight.w500;
                                      workspacesFontWeight = FontWeight.w500;
                                      priorityFontWeight = FontWeight.w600;
                                    });
                                  }
                                },
                                child: Text(
                                  'Priority',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: priorityFontWeight,
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
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
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
                                decoration: const BoxDecoration(
                                  color: Color(0xffCDBEAE),
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(22),
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xffCDBEAE),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(18),
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.03,
                                        vertical: height * 0.01,
                                      ),
                                      child: Wrap(
                                        spacing: width * 0.02,
                                        runSpacing: width * 0.03,
                                        children: [
                                          ...boards.map(
                                            (board) {
                                              return SizedBox(
                                                child: Column(
                                                  children: [
                                                    InkWell(
                                                      onTap: () => goToMyList(
                                                          board.boardId
                                                              .toString()),
                                                      child: Container(
                                                        width: width * 0.4,
                                                        height: height * 0.15,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color:
                                                              Color(0xffEFEEEC),
                                                          borderRadius:
                                                              BorderRadius.all(
                                                            Radius.circular(12),
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              offset:
                                                                  Offset(0, 1),
                                                              blurRadius: 1,
                                                              spreadRadius: 0,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            board.boardName,
                                                            style: TextStyle(
                                                              fontSize: Get
                                                                  .textTheme
                                                                  .titleLarge!
                                                                  .fontSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          // ปุ่มสร้างบอร์ดใหม่
                                          SizedBox(
                                            child: Column(
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    log('Create new board');
                                                  },
                                                  child: Container(
                                                    width: width * 0.4,
                                                    height: height * 0.15,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color(0xffCFCFCF),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(12),
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          offset: Offset(0, 1),
                                                          blurRadius: 1,
                                                          spreadRadius: 0,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '+',
                                                        style: TextStyle(
                                                          fontSize: Get
                                                              .textTheme
                                                              .headlineSmall!
                                                              .fontSize,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.white,
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xffCDBEAE),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(18),
                                    ),
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.03,
                                      vertical: height * 0.01,
                                    ),
                                    itemCount: boards.length +
                                        1, // +1 สำหรับปุ่มสร้างบอร์ดใหม่
                                    itemBuilder: (context, index) {
                                      if (index < boards.length) {
                                        final board = boards[index];
                                        return Padding(
                                          padding: EdgeInsets.only(
                                              bottom: height * 0.01),
                                          child: InkWell(
                                            onTap: () => goToMyList(
                                                board.boardId.toString()),
                                            child: Container(
                                              width: width,
                                              height: height * 0.06,
                                              decoration: const BoxDecoration(
                                                color: Color(0xffEFEEEC),
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(12),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    offset: Offset(0, 1),
                                                    blurRadius: 1,
                                                    spreadRadius: 0,
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  board.boardName,
                                                  style: TextStyle(
                                                    fontSize: Get.textTheme
                                                        .titleLarge!.fontSize,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        // ปุ่มสร้างบอร์ดใหม่
                                        return InkWell(
                                          onTap: () {
                                            log('Create new board');
                                          },
                                          child: Container(
                                            width: width,
                                            height: height * 0.06,
                                            decoration: const BoxDecoration(
                                              color: Color(0xffCFCFCF),
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(12),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  offset: Offset(0, 1),
                                                  blurRadius: 1,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '+',
                                                style: TextStyle(
                                                  fontSize: Get.textTheme
                                                      .headlineSmall!.fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
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
          ),
        );
      },
    );
  }

  void goToMyList(String idBoard) {
    KeepIdBoard keeps = KeepIdBoard();
    keeps.idBoard = idBoard;
    context.read<Appdata>().idBoard = keeps;
    Get.to(() => BoradlistsPage());
  }

  // ฟังก์ชันเพื่อเลื่อน slider
  void moveSliderToKey(GlobalKey key) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    if (mounted) {
      setState(() {
        slider = position.dx +
            (renderBox.size.width / 2) -
            (MediaQuery.of(context).size.width * 0.1);
      });
    }
  }

  void showPopupMenu(BuildContext context) {
    //horizontal left right
    double width = MediaQuery.of(context).size.width;
    //vertical tob bottom
    double height = MediaQuery.of(context).size.height;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        width,
        height * 0.1,
        width * 0.1,
        0,
      ),
      items: [
        PopupMenuItem(
          value: 'setting',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 16c2.206 0 4-1.794 4-4s-1.794-4-4-4-4 1.794-4 4 1.794 4 4 4zm0-6c1.084 0 2 .916 2 2s-.916 2-2 2-2-.916-2-2 .916-2 2-2z"></path><path d="m2.845 16.136 1 1.73c.531.917 1.809 1.261 2.73.73l.529-.306A8.1 8.1 0 0 0 9 19.402V20c0 1.103.897 2 2 2h2c1.103 0 2-.897 2-2v-.598a8.132 8.132 0 0 0 1.896-1.111l.529.306c.923.53 2.198.188 2.731-.731l.999-1.729a2.001 2.001 0 0 0-.731-2.732l-.505-.292a7.718 7.718 0 0 0 0-2.224l.505-.292a2.002 2.002 0 0 0 .731-2.732l-.999-1.729c-.531-.92-1.808-1.265-2.731-.732l-.529.306A8.1 8.1 0 0 0 15 4.598V4c0-1.103-.897-2-2-2h-2c-1.103 0-2 .897-2 2v.598a8.132 8.132 0 0 0-1.896 1.111l-.529-.306c-.924-.531-2.2-.187-2.731.732l-.999 1.729a2.001 2.001 0 0 0 .731 2.732l.505.292a7.683 7.683 0 0 0 0 2.223l-.505.292a2.003 2.003 0 0 0-.731 2.733zm3.326-2.758A5.703 5.703 0 0 1 6 12c0-.462.058-.926.17-1.378a.999.999 0 0 0-.47-1.108l-1.123-.65.998-1.729 1.145.662a.997.997 0 0 0 1.188-.142 6.071 6.071 0 0 1 2.384-1.399A1 1 0 0 0 11 5.3V4h2v1.3a1 1 0 0 0 .708.956 6.083 6.083 0 0 1 2.384 1.399.999.999 0 0 0 1.188.142l1.144-.661 1 1.729-1.124.649a1 1 0 0 0-.47 1.108c.112.452.17.916.17 1.378 0 .461-.058.925-.171 1.378a1 1 0 0 0 .471 1.108l1.123.649-.998 1.729-1.145-.661a.996.996 0 0 0-1.188.142 6.071 6.071 0 0 1-2.384 1.399A1 1 0 0 0 13 18.7l.002 1.3H11v-1.3a1 1 0 0 0-.708-.956 6.083 6.083 0 0 1-2.384-1.399.992.992 0 0 0-1.188-.141l-1.144.662-1-1.729 1.124-.651a1 1 0 0 0 .471-1.108z"></path></svg>',
                height: height * 0.035,
                fit: BoxFit.contain,
                color: const Color(0xff787878),
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
                '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-280q17 0 28.5-11.5T520-320q0-17-11.5-28.5T480-360q-17 0-28.5 11.5T440-320q0 17 11.5 28.5T480-280Zm-40-160h80v-240h-80v240ZM330-120 120-330v-300l210-210h300l210 210v300L630-120H330Zm34-80h232l164-164v-232L596-760H364L200-596v232l164 164Zm116-280Z"/></svg>',
                height: height * 0.035,
                fit: BoxFit.contain,
                color: const Color(0xff787878),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      menuPadding: EdgeInsets.zero,
    ).then((value) {
      if (value == 'setting') {
        Get.to(() => const SettingsPage());
      } else if (value == 'report') {}
    });
  }
}
