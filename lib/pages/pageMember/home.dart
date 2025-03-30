import 'dart:async';
import 'dart:developer';

import 'package:demomydayplanner/config/config.dart';
import 'package:demomydayplanner/models/request/createBoardListsPostRequest.dart';
import 'package:demomydayplanner/models/request/getBoardByIdUserPostRequest.dart';
import 'package:demomydayplanner/models/request/getUserByEmailPostRequest.dart';
import 'package:demomydayplanner/models/response/getBoardByIdUserGroupsPostResponse.dart';
import 'package:demomydayplanner/models/response/getBoardByIdUserListsPostResponse.dart';
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
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<void> loadData;
  var box = GetStorage();
  String name = '';
  int userId = 0;
  String userProfile = '';
  TextEditingController boardCtl = TextEditingController();
  List<GetBoardByIdUserListsPostResponse> boardsLists = [];
  List<GetBoardByIdUserGroupsPostResponse> boardsGroup = [];
  late List boards = [];
  bool displayFormat = false;
  GlobalKey listKey = GlobalKey();
  GlobalKey groupKey = GlobalKey();
  GlobalKey priorityKey = GlobalKey();
  double slider = 0;
  FontWeight listsFontWeight = FontWeight.w600;
  FontWeight groupFontWeight = FontWeight.w500;
  FontWeight priorityFontWeight = FontWeight.w500;
  bool isTyping = false;
  int itemCount = 1;
  bool isLoadings = true;
  bool showShimmer = true;

  @override
  void initState() {
    super.initState();

    showDisplays();
    loadData = loadDataAsync();
  }

  Future<void> loadDataAsync() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    var responseGetUser = await http.post(
      Uri.parse("$url/user/api/get_user"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: getUserByEmailPostRequestToJson(
        GetUserByEmailPostRequest(
          email: box.read('email'),
        ),
      ),
    );

    if (responseGetUser.statusCode == 200) {
      GetUserByEmailPostResponst responst =
          getUserByEmailPostResponstFromJson(responseGetUser.body);
      name = responst.name;
      userId = responst.userId;
      userProfile = responst.profile;

      var responseGetBoardGroup0 = await http.post(
        Uri.parse("$url/board/boardbyID"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: getBoardByIdUserPostRequestToJson(
          GetBoardByIdUserPostRequest(
            userId: userId,
            group: 0,
          ),
        ),
      );
      var responseGetBoardGroup1 = await http.post(
        Uri.parse("$url/board/boardbyID"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: getBoardByIdUserPostRequestToJson(
          GetBoardByIdUserPostRequest(
            userId: userId,
            group: 1,
          ),
        ),
      );

      boardsLists = getBoardByIdUserListsPostResponseFromJson(
          responseGetBoardGroup0.body);
      boardsGroup = getBoardByIdUserGroupsPostResponseFromJson(
          responseGetBoardGroup1.body);

      if (listsFontWeight == FontWeight.w600) {
        boards = boardsLists;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          moveSliderToKey(listKey);
        });
      } else if (groupFontWeight == FontWeight.w600) {
        boards = boardsGroup;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          moveSliderToKey(groupKey);
        });
      }

      isLoadings = false;
      setState(() {});

      Timer(Duration(seconds: 2), () {
        showShimmer = false;
        setState(() {});
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
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) {
              itemCount = boards.isEmpty ? 1 : boards.length;
              setState(() {});
            }
          });
        }
        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: null,
            body: Center(
              child: RefreshIndicator(
                color: Colors.grey,
                onRefresh: loadDataAsync,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: width * 0.05,
                    left: width * 0.05,
                    top: height * 0.03,
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
                                        child: userProfile == 'none-url'
                                            ? Container(
                                                width: height * 0.07,
                                                height: height * 0.07,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      height: height * 0.1,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Color.fromRGBO(
                                                            242, 242, 246, 1),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: 0,
                                                      right: 0,
                                                      bottom: 0,
                                                      child: SvgPicture.string(
                                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                        height: height * 0.05,
                                                        fit: BoxFit.contain,
                                                        color: Color.fromRGBO(
                                                            151, 149, 149, 1),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              )
                                            : Image.network(
                                                userProfile,
                                                width: height * 0.07,
                                                height: height * 0.07,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                SizedBox(width: width * 0.01),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    isLoadings || showShimmer
                                        ? Shimmer.fromColors(
                                            baseColor: Color(0xFFF7F7F7),
                                            highlightColor: Colors.grey[300]!,
                                            child: Container(
                                              width: _calculateTextWidth(
                                                  'Hello, $name',
                                                  Get.textTheme.titleSmall!
                                                      .fontSize!),
                                              height: Get.textTheme.titleSmall!
                                                  .fontSize,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'Hello, $name',
                                            style: TextStyle(
                                              fontSize: Get.textTheme
                                                  .titleSmall!.fontSize,
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
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.02,
                          ),
                          child: Container(
                            width: width,
                            height: height * 0.12,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(242, 242, 246, 1),
                              borderRadius: BorderRadius.all(
                                Radius.circular(40),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                  color: Color.fromRGBO(151, 149, 149, 1),
                                  spreadRadius: 0.1,
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
                                          fontSize: Get
                                              .textTheme.titleLarge!.fontSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'To day',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme.titleLarge!.fontSize,
                                          fontWeight: FontWeight.w500,
                                          color: Color.fromRGBO(0, 122, 255, 1),
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
                                            color: Color.fromRGBO(
                                                151, 149, 149, 1),
                                          ),
                                          SizedBox(
                                            width: width * 0.01,
                                          ),
                                          Text(
                                            'ไปกินข้าว',
                                            style: TextStyle(
                                              fontSize: Get.textTheme
                                                  .labelMedium!.fontSize,
                                              fontWeight: FontWeight.normal,
                                              fontFamily: 'mali',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '10m',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme.labelMedium!.fontSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: height * 0.01,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Boards',
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
                                        displayFormat = true;
                                        setState(() {});
                                      },
                                      child: SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M4 6h2v2H4zm0 5h2v2H4zm0 5h2v2H4zm16-8V6H8.023v2H18.8zM8 11h12v2H8zm0 5h12v2H8z"></path></svg>',
                                        height: height * 0.034,
                                        fit: BoxFit.contain,
                                        color: Color.fromRGBO(151, 149, 149, 1),
                                      ),
                                    ),
                                  if (displayFormat)
                                    InkWell(
                                      onTap: () {
                                        // log('list กด');
                                        box.write('list', true);
                                        box.write('grid', false);
                                        if (!displayFormat) {
                                          displayFormat = false;
                                          setState(() {});
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
                                        displayFormat = false;
                                        setState(() {});
                                      },
                                      child: SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10 3H4a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1zM9 9H5V5h4v4zm5 2h6a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1zm1-6h4v4h-4V5zM3 20a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1v-6a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v6zm2-5h4v4H5v-4zm8 5a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1v-6a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v6zm2-5h4v4h-4v-4z"></path></svg>',
                                        height: height * 0.03,
                                        fit: BoxFit.contain,
                                        color: Color.fromRGBO(151, 149, 149, 1),
                                      ),
                                    ),
                                  if (!displayFormat)
                                    InkWell(
                                      onTap: () {
                                        // log('grid กด');
                                        box.write('grid', true);
                                        box.write('list', false);
                                        if (!displayFormat) {
                                          displayFormat = false;
                                          setState(() {});
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
                        Divider(
                          thickness: 0,
                          height: 0,
                          color: Color.fromRGBO(151, 149, 149, 1),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: width * 0.03,
                            right: width * 0.03,
                            top: height * 0.01,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              InkWell(
                                key: listKey,
                                onTap: () {
                                  boards = boardsLists;
                                  moveSliderToKey(listKey);
                                  listsFontWeight = FontWeight.w600;
                                  groupFontWeight = FontWeight.w500;
                                  priorityFontWeight = FontWeight.w500;
                                  setState(() {});
                                },
                                child: Text(
                                  'Lists',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: listsFontWeight,
                                    color: listsFontWeight == FontWeight.w600
                                        ? Color.fromRGBO(0, 122, 255, 1)
                                        : null,
                                  ),
                                ),
                              ),
                              InkWell(
                                key: groupKey,
                                onTap: () {
                                  boards = boardsGroup;
                                  moveSliderToKey(groupKey);
                                  listsFontWeight = FontWeight.w500;
                                  groupFontWeight = FontWeight.w600;
                                  priorityFontWeight = FontWeight.w500;
                                  setState(() {});
                                },
                                child: Text(
                                  'Groups',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleLarge!.fontSize,
                                    fontWeight: groupFontWeight,
                                    color: groupFontWeight == FontWeight.w600
                                        ? Color.fromRGBO(0, 122, 255, 1)
                                        : null,
                                  ),
                                ),
                              ),
                              // InkWell(
                              //   key: priorityKey,
                              //   onTap: () {
                              //     if (mounted) {
                              //       setState(() {
                              //         moveSliderToKey(priorityKey);
                              //         listsFontWeight = FontWeight.w500;
                              //         groupFontWeight = FontWeight.w500;
                              //         priorityFontWeight = FontWeight.w600;
                              //       });
                              //     }
                              //   },
                              //   child: Text(
                              //     'Priority',
                              //     style: TextStyle(
                              //       fontSize:
                              //           Get.textTheme.titleLarge!.fontSize,
                              //       fontWeight: priorityFontWeight,
                              //     ),
                              //   ),
                              // ),
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
                                decoration: const BoxDecoration(
                                  color: Color.fromRGBO(0, 122, 255, 1),
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
                                    color: Color.fromRGBO(242, 242, 246, 1),
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
                                        children: isLoadings || showShimmer
                                            ? List.generate(
                                                itemCount,
                                                (index) => Shimmer.fromColors(
                                                  baseColor: Color(0xFFF7F7F7),
                                                  highlightColor:
                                                      Colors.grey[300]!,
                                                  child: Container(
                                                    width: width * 0.4,
                                                    height: height * 0.15,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : [
                                                ...boards.map(
                                                  (board) {
                                                    return SizedBox(
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            width: width * 0.4,
                                                            height:
                                                                height * 0.15,
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  offset:
                                                                      Offset(
                                                                          0, 1),
                                                                  blurRadius: 3,
                                                                  color: Color
                                                                      .fromRGBO(
                                                                          151,
                                                                          149,
                                                                          149,
                                                                          1),
                                                                  spreadRadius:
                                                                      0.1,
                                                                ),
                                                              ],
                                                            ),
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              child: InkWell(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                                onTap: () =>
                                                                    goToMyList(board
                                                                        .boardName),
                                                                child: Center(
                                                                  child: Text(
                                                                    board
                                                                        .boardName,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize: Get
                                                                          .textTheme
                                                                          .titleMedium!
                                                                          .fontSize,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                  ),
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
                                                      Container(
                                                        width: width * 0.4,
                                                        height: height * 0.15,
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            color:
                                                                Colors.white),
                                                        child: Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            onTap:
                                                                createNewBoard,
                                                            child: Center(
                                                              child: Text(
                                                                '+',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: Get
                                                                      .textTheme
                                                                      .headlineSmall!
                                                                      .fontSize,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Color
                                                                      .fromRGBO(
                                                                          0,
                                                                          122,
                                                                          255,
                                                                          1),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
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
                                    color: Color.fromRGBO(242, 242, 246, 1),
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
                                      if (isLoadings || showShimmer) {
                                        return Shimmer.fromColors(
                                          baseColor: Color(0xFFF7F7F7),
                                          highlightColor: Colors.grey[300]!,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              bottom: height * 0.01,
                                            ),
                                            child: Container(
                                              width: width,
                                              height: height * 0.06,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        if (index < boards.length) {
                                          final board = boards[index];
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: height * 0.01,
                                            ),
                                            child: Container(
                                              width: width,
                                              height: height * 0.06,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    offset: Offset(0, 1),
                                                    blurRadius: 3,
                                                    color: Color.fromRGBO(
                                                        151, 149, 149, 1),
                                                    spreadRadius: 0.1,
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  onTap: () => goToMyList(board
                                                      .boardName
                                                      .toString()),
                                                  child: Center(
                                                    child: Text(
                                                      board.boardName,
                                                      style: TextStyle(
                                                        fontSize: Get
                                                            .textTheme
                                                            .titleMedium!
                                                            .fontSize,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.black,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          // ปุ่มสร้างบอร์ดใหม่
                                          return Container(
                                            width: width,
                                            height: height * 0.06,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: Colors.white,
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onTap: createNewBoard,
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
                                                      color: Color.fromRGBO(
                                                          0, 122, 255, 1),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
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

  void showDisplays() {
    if (box.read('listsTF') == null) {
      box.write('listsTF', true);
      box.write('groupTF', false);
      box.write('PriorityTF', false);
    }
    if (box.read('grid') == null) {
      box.write('grid', true);
      box.write('list', false);
    }
    if (box.read('listsTF')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        moveSliderToKey(listKey);
      });
      listsFontWeight = FontWeight.w600;
      groupFontWeight = FontWeight.w500;
      priorityFontWeight = FontWeight.w500;
    } else if (box.read('groupTF')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        moveSliderToKey(groupKey);
      });
      listsFontWeight = FontWeight.w500;
      groupFontWeight = FontWeight.w600;
      priorityFontWeight = FontWeight.w500;
    } else if (box.read('PriorityTF')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        moveSliderToKey(priorityKey);
      });
      listsFontWeight = FontWeight.w500;
      groupFontWeight = FontWeight.w500;
      priorityFontWeight = FontWeight.w600;
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
  }

  double _calculateTextWidth(String text, double fontSize) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }

  void createNewBoard() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

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

            return Padding(
              padding: EdgeInsets.only(
                left: width * 0.05,
                right: width * 0.05,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + height * 0.02,
              ),
              child: SizedBox(
                height: height * 0.3,
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
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: width * 0.03,
                              ),
                              child: Text(
                                'Name board',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: boardCtl,
                          keyboardType: TextInputType.text,
                          cursorColor: Colors.black,
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize,
                          ),
                          decoration: InputDecoration(
                            hintText: isTyping ? '' : 'Enter your board name',
                            hintStyle: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.normal,
                              color: const Color.fromRGBO(0, 0, 0, 0.3),
                            ),
                            prefixIcon: IconButton(
                              onPressed: null,
                              icon: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M19.937 8.68c-.011-.032-.02-.063-.033-.094a.997.997 0 0 0-.196-.293l-6-6a.997.997 0 0 0-.293-.196c-.03-.014-.062-.022-.094-.033a.991.991 0 0 0-.259-.051C13.04 2.011 13.021 2 13 2H6c-1.103 0-2 .897-2 2v16c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2V9c0-.021-.011-.04-.013-.062a.99.99 0 0 0-.05-.258zM16.586 8H14V5.414L16.586 8zM6 20V4h6v5a1 1 0 0 0 1 1h5l.002 10H6z"></path></svg>',
                                color: const Color(0xff7B7B7B),
                              ),
                            ),
                            constraints: BoxConstraints(
                              maxHeight: height * 0.05,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: width * 0.02,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (textError.isNotEmpty)
                      Text(
                        textError,
                        style: TextStyle(
                          fontSize: Get.textTheme.titleSmall!.fontSize,
                          fontWeight: FontWeight.normal,
                          color: Colors.red,
                        ),
                      ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            if (boardCtl.text.isEmpty) {
                              textError = 'Please enter your board name';
                              setState(() {});
                              return;
                            }
                            loadingDialog();
                            if (listsFontWeight == FontWeight.w600) {
                              var responseCreateBoradList = await http.post(
                                  Uri.parse("$url/board/createBoard"),
                                  headers: {
                                    "Content-Type":
                                        "application/json; charset=utf-8"
                                  },
                                  body: createBoardListsPostRequestToJson(
                                    CreateBoardListsPostRequest(
                                      boardName: boardCtl.text,
                                      createBy: userId,
                                      isGroup: 0,
                                    ),
                                  ));
                              if (responseCreateBoradList.statusCode == 201) {
                                Get.back();
                                Get.back();
                                loadDataAsync();
                                boardCtl.clear();
                                textError = '';
                                setState(() {});
                              } else {
                                Get.back();
                                textError = 'Error!';
                                setState(() {});
                              }
                            } else if (groupFontWeight == FontWeight.w600) {
                              var responseCreateBoradGroup = await http.post(
                                  Uri.parse("$url/board/createBoard"),
                                  headers: {
                                    "Content-Type":
                                        "application/json; charset=utf-8"
                                  },
                                  body: createBoardListsPostRequestToJson(
                                    CreateBoardListsPostRequest(
                                      boardName: boardCtl.text,
                                      createBy: userId,
                                      isGroup: 1,
                                    ),
                                  ));
                              if (responseCreateBoradGroup.statusCode == 201) {
                                Get.back();
                                Get.back();
                                loadDataAsync();
                                boardCtl.clear();
                                textError = '';
                                setState(() {});
                              } else {
                                Get.back();
                                textError = 'Error!';
                                setState(() {});
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(
                              width,
                              height * 0.06,
                            ),
                            backgroundColor: Color.fromRGBO(0, 122, 255, 1),
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
    slider = position.dx +
        (renderBox.size.width / 2) -
        (MediaQuery.of(context).size.width * 0.1);
    setState(() {});
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
        height * 0.12,
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
                color: Color.fromRGBO(151, 149, 149, 1),
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
                color: Color.fromRGBO(255, 58, 49, 1),
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

  void loadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        content: Center(
          child: CircularProgressIndicator(
            color: Color(0xffCDBEAE),
          ),
        ),
      ),
    );
  }
}
