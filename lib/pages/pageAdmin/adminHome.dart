import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/response/allUserGetResponse.dart';
import 'package:mydayplanner/splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

class AdminhomePage extends StatefulWidget {
  const AdminhomePage({super.key});

  @override
  State<AdminhomePage> createState() => _AdminhomePageState();
}

class _AdminhomePageState extends State<AdminhomePage> {
  var box = GetStorage();
  final storage = FlutterSecureStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  late Future<void> loadData;
  Map<String, dynamic> summaryData = {};
  String currentView = 'day';
  List<Map<String, dynamic>> matchingLogins = [];
  Map<String, dynamic> showMonth = {};
  int loginCount = 0;
  int itemCount = 1;
  List<AllUserGetResponse> responseGetAlluser = [];
  late List<AllUserGetResponse> allUsers = [];
  int totalLoginCount = 0;
  int totalUserCount = 0;
  int totalReportCount = 0;
  late String url;
  bool isLoadings = true;
  bool showShimmer = true;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    loadData = loadDataAsync();
  }

  Future<http.Response> loadAllUser() async {
    url = await loadAPIEndpoint();
    var responseAllUser = await http.get(
      Uri.parse("$url/user/ReadAllUser"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );
    return responseAllUser;
  }

  Future<void> loadDataAsync() async {
    var result = await loadAllUser();

    if (result.statusCode == 403) {
      await loadNewRefreshToken();
      result = await loadAllUser();
    }

    if (result.statusCode == 200) {
      responseGetAlluser = allUserGetResponseFromJson(result.body);
      allUsers = responseGetAlluser;
      await compareUsers();
      if (!mounted) return;
      setState(() {
        isLoadings = false;
      });

      Timer(Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() {
          showShimmer = false;
        });
      });
    }
    final String jsonString = await rootBundle.loadString(
      'assets/text/dataBarChart.json',
    );
    final jsonMap = jsonDecode(jsonString);
    setState(() {
      summaryData = jsonMap['data'];
      showMonth = jsonMap['summary'];
      updateTotalCounts();
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
              itemCount = allUsers.isEmpty ? 1 : allUsers.length;
            });
          });
        }
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: RefreshIndicator(
                color: Colors.grey,
                onRefresh: loadDataAsync,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: width * 0.05,
                    left: width * 0.05,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mydayplanner',
                            style: TextStyle(
                              fontSize: Get.textTheme.displaySmall!.fontSize,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              logout();
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.01,
                                vertical: height * 0.01,
                              ),
                              child: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M16 13v-2H7V8l-5 4 5 4v-3z"></path><path d="M20 3h-9c-1.103 0-2 .897-2 2v4h2V5h9v14h-9v-4H9v4c0 1.103.897 2 2 2h9c1.103 0 2-.897 2-2V5c0-1.103-.897-2-2-2z"></path></svg>',
                                height: height * 0.03,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                isLoadings || showShimmer
                                    ? Shimmer.fromColors(
                                      baseColor: Color(0xFFF7F7F7),
                                      highlightColor: Colors.grey[300]!,
                                      child: Container(
                                        width: width * 0.44,
                                        height: height * 0.12,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    )
                                    : Container(
                                      width: width * 0.44,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.03,
                                        vertical: height * 0.015,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF2F2F6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SvgPicture.string(
                                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2A10.13 10.13 0 0 0 2 12a10 10 0 0 0 4 7.92V20h.1a9.7 9.7 0 0 0 11.8 0h.1v-.08A10 10 0 0 0 22 12 10.13 10.13 0 0 0 12 2zM8.07 18.93A3 3 0 0 1 11 16.57h2a3 3 0 0 1 2.93 2.36 7.75 7.75 0 0 1-7.86 0zm9.54-1.29A5 5 0 0 0 13 14.57h-2a5 5 0 0 0-4.61 3.07A8 8 0 0 1 4 12a8.1 8.1 0 0 1 8-8 8.1 8.1 0 0 1 8 8 8 8 0 0 1-2.39 5.64z"></path><path d="M12 6a3.91 3.91 0 0 0-4 4 3.91 3.91 0 0 0 4 4 3.91 3.91 0 0 0 4-4 3.91 3.91 0 0 0-4-4zm0 6a1.91 1.91 0 0 1-2-2 1.91 1.91 0 0 1 2-2 1.91 1.91 0 0 1 2 2 1.91 1.91 0 0 1-2 2z"></path></svg>',
                                                width: width * 0.04,
                                                height: height * 0.04,
                                                fit: BoxFit.contain,
                                                color: Color(0xFF007AFF),
                                              ),
                                              Text(
                                                loginCount.toString(),
                                                style: TextStyle(
                                                  fontSize:
                                                      Get
                                                          .textTheme
                                                          .headlineMedium!
                                                          .fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black38,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                'Latest login now',
                                                style: TextStyle(
                                                  fontSize:
                                                      Get
                                                          .textTheme
                                                          .titleLarge!
                                                          .fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                isLoadings || showShimmer
                                    ? Shimmer.fromColors(
                                      baseColor: Color(0xFFF7F7F7),
                                      highlightColor: Colors.grey[300]!,
                                      child: Container(
                                        width: width * 0.44,
                                        height: height * 0.12,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    )
                                    : Container(
                                      width: width * 0.44,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.03,
                                        vertical: height * 0.015,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF2F2F6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SvgPicture.string(
                                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2a5 5 0 1 0 5 5 5 5 0 0 0-5-5zm0 8a3 3 0 1 1 3-3 3 3 0 0 1-3 3zm9 11v-1a7 7 0 0 0-7-7h-4a7 7 0 0 0-7 7v1h2v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1z"></path></svg>',
                                                width: width * 0.04,
                                                height: height * 0.04,
                                                fit: BoxFit.contain,
                                                color: Colors.green,
                                              ),
                                              Text(
                                                itemCount == 1
                                                    ? '${itemCount - 1}'
                                                    : '${allUsers.where((user) => user.isActive != '2').toList().length - 1}',
                                                style: TextStyle(
                                                  fontSize:
                                                      Get
                                                          .textTheme
                                                          .headlineMedium!
                                                          .fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black38,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                'Total User',
                                                style: TextStyle(
                                                  fontSize:
                                                      Get
                                                          .textTheme
                                                          .titleLarge!
                                                          .fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                              ],
                            ),
                            SizedBox(height: height * 0.01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                isLoadings || showShimmer
                                    ? Shimmer.fromColors(
                                      baseColor: Color(0xFFF7F7F7),
                                      highlightColor: Colors.grey[300]!,
                                      child: Container(
                                        width: width * 0.44,
                                        height: height * 0.12,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    )
                                    : Container(
                                      width: width * 0.44,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.03,
                                        vertical: height * 0.015,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF2F2F6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SvgPicture.string(
                                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m20 8-6-6H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8zM9 19H7v-9h2v9zm4 0h-2v-6h2v6zm4 0h-2v-3h2v3zM14 9h-1V4l5 5h-4z"></path></svg>',
                                                width: width * 0.04,
                                                height: height * 0.04,
                                                fit: BoxFit.contain,
                                                color: Colors.red,
                                              ),
                                              Text(
                                                totalReportCount.toString(),
                                                style: TextStyle(
                                                  fontSize:
                                                      Get
                                                          .textTheme
                                                          .headlineMedium!
                                                          .fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black38,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                currentView == 'day'
                                                    ? 'Daily Report'
                                                    : currentView == 'week'
                                                    ? 'Weekly Report'
                                                    : currentView == 'month'
                                                    ? 'Monthly Report'
                                                    : 'Total Report',
                                                style: TextStyle(
                                                  fontSize:
                                                      Get
                                                          .textTheme
                                                          .titleLarge!
                                                          .fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                Container(
                                  width: width * 0.44,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.03,
                                    vertical: height * 0.015,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF2F2F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Opacity(
                                    opacity: 0,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            SvgPicture.string(
                                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m20 8-6-6H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8zM9 19H7v-9h2v9zm4 0h-2v-6h2v6zm4 0h-2v-3h2v3zM14 9h-1V4l5 5h-4z"></path></svg>',
                                              width: width * 0.04,
                                              height: height * 0.04,
                                              fit: BoxFit.contain,
                                              color: Colors.red,
                                            ),
                                            Text(
                                              totalReportCount.toString(),
                                              style: TextStyle(
                                                fontSize:
                                                    Get
                                                        .textTheme
                                                        .headlineMedium!
                                                        .fontSize,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black38,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "Report",
                                              style: TextStyle(
                                                fontSize:
                                                    Get
                                                        .textTheme
                                                        .titleLarge!
                                                        .fontSize,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: height * 0.02),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //   children: [
                            //     Text(
                            //       "Overveiw",
                            //       style: TextStyle(
                            //         fontSize:
                            //             Get.textTheme.headlineSmall!.fontSize,
                            //         fontWeight: FontWeight.w500,
                            //       ),
                            //     ),
                            //     Text(
                            //       currentView == 'day'
                            //           ? format(showMonth['timestamp'], 'day')
                            //           : currentView == 'week'
                            //           ? format(showMonth['timestamp'], 'week')
                            //           : currentView == 'month'
                            //           ? format(showMonth['timestamp'], 'month')
                            //           : currentView == 'year'
                            //           ? format(showMonth['timestamp'], 'year')
                            //           : format(showMonth['timestamp'], 'all'),
                            //       style: TextStyle(
                            //         fontSize:
                            //             Get.textTheme.titleLarge!.fontSize,
                            //         fontWeight: FontWeight.w500,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.end,
                            //   children: [
                            //     Container(
                            //       decoration: BoxDecoration(
                            //         color: Color(0xFFF2F2F6),
                            //         borderRadius: BorderRadius.circular(8),
                            //       ),
                            //       child: Row(
                            //         children: [
                            //           Material(
                            //             color:
                            //                 currentView == 'day'
                            //                     ? Color(
                            //                       0xFF007AFF,
                            //                     ).withOpacity(0.2)
                            //                     : Colors.transparent,
                            //             borderRadius: BorderRadius.circular(8),
                            //             child: InkWell(
                            //               onTap: () {
                            //                 setState(() {
                            //                   currentView = 'day';
                            //                   updateTotalCounts();
                            //                 });
                            //               },
                            //               borderRadius: BorderRadius.circular(
                            //                 8,
                            //               ),
                            //               child: Padding(
                            //                 padding: EdgeInsets.symmetric(
                            //                   horizontal: width * 0.02,
                            //                   vertical: height * 0.005,
                            //                 ),
                            //                 child: Text(
                            //                   "day",
                            //                   style: TextStyle(
                            //                     fontSize:
                            //                         Get
                            //                             .textTheme
                            //                             .titleMedium!
                            //                             .fontSize,
                            //                     fontWeight: FontWeight.w500,
                            //                     color:
                            //                         currentView == 'day'
                            //                             ? Color(0xFF007AFF)
                            //                             : Colors.black87,
                            //                   ),
                            //                 ),
                            //               ),
                            //             ),
                            //           ),
                            //           Container(
                            //             height: 30,
                            //             width: 1,
                            //             color: Colors.black26,
                            //           ),
                            //           Material(
                            //             color:
                            //                 currentView == 'week'
                            //                     ? Color(
                            //                       0xFF007AFF,
                            //                     ).withOpacity(0.2)
                            //                     : Colors.transparent,
                            //             borderRadius: BorderRadius.circular(8),
                            //             child: InkWell(
                            //               onTap: () {
                            //                 setState(() {
                            //                   currentView = 'week';
                            //                   updateTotalCounts();
                            //                 });
                            //               },
                            //               borderRadius: BorderRadius.circular(
                            //                 8,
                            //               ),
                            //               child: Padding(
                            //                 padding: EdgeInsets.symmetric(
                            //                   horizontal: width * 0.02,
                            //                   vertical: height * 0.005,
                            //                 ),
                            //                 child: Text(
                            //                   "week",
                            //                   style: TextStyle(
                            //                     fontSize:
                            //                         Get
                            //                             .textTheme
                            //                             .titleMedium!
                            //                             .fontSize,
                            //                     fontWeight: FontWeight.w500,
                            //                     color:
                            //                         currentView == 'week'
                            //                             ? Color(0xFF007AFF)
                            //                             : Colors.black87,
                            //                   ),
                            //                 ),
                            //               ),
                            //             ),
                            //           ),
                            //           Container(
                            //             height: 30,
                            //             width: 1,
                            //             color: Colors.black26,
                            //           ),
                            //           Material(
                            //             color:
                            //                 currentView == 'month'
                            //                     ? Color(
                            //                       0xFF007AFF,
                            //                     ).withOpacity(0.2)
                            //                     : Colors.transparent,
                            //             borderRadius: BorderRadius.circular(8),
                            //             child: InkWell(
                            //               onTap: () {
                            //                 setState(() {
                            //                   currentView = 'month';
                            //                   updateTotalCounts();
                            //                 });
                            //               },
                            //               borderRadius: BorderRadius.circular(
                            //                 8,
                            //               ),
                            //               child: Padding(
                            //                 padding: EdgeInsets.symmetric(
                            //                   horizontal: width * 0.02,
                            //                   vertical: height * 0.005,
                            //                 ),
                            //                 child: Text(
                            //                   "month",
                            //                   style: TextStyle(
                            //                     fontSize:
                            //                         Get
                            //                             .textTheme
                            //                             .titleMedium!
                            //                             .fontSize,
                            //                     fontWeight: FontWeight.w500,
                            //                     color:
                            //                         currentView == 'month'
                            //                             ? Color(0xFF007AFF)
                            //                             : Colors.black87,
                            //                   ),
                            //                 ),
                            //               ),
                            //             ),
                            //           ),
                            //           Container(
                            //             height: 30,
                            //             width: 1,
                            //             color: Colors.black26,
                            //           ),
                            //           Material(
                            //             color:
                            //                 currentView == 'all'
                            //                     ? Color(
                            //                       0xFF007AFF,
                            //                     ).withOpacity(0.2)
                            //                     : Colors.transparent,
                            //             borderRadius: BorderRadius.circular(8),
                            //             child: InkWell(
                            //               onTap: () {
                            //                 setState(() {
                            //                   currentView = 'all';
                            //                   updateTotalCounts();
                            //                 });
                            //               },
                            //               borderRadius: BorderRadius.circular(
                            //                 8,
                            //               ),
                            //               child: Padding(
                            //                 padding: EdgeInsets.symmetric(
                            //                   horizontal: width * 0.02,
                            //                   vertical: height * 0.005,
                            //                 ),
                            //                 child: Text(
                            //                   "All",
                            //                   style: TextStyle(
                            //                     fontSize:
                            //                         Get
                            //                             .textTheme
                            //                             .titleMedium!
                            //                             .fontSize,
                            //                     fontWeight: FontWeight.w500,
                            //                     color:
                            //                         currentView == 'all'
                            //                             ? Color(0xFF007AFF)
                            //                             : Colors.black87,
                            //                   ),
                            //                 ),
                            //               ),
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            // SizedBox(height: height * 0.02),
                            // SizedBox(
                            //   height: height * 0.32,
                            //   child: BarChart(
                            //     BarChartData(
                            //       alignment: BarChartAlignment.spaceAround,
                            //       maxY:
                            //           getBarChartData(currentView)
                            //               .expand((group) => group.barRods)
                            //               .map((rod) => rod.toY)
                            //               .fold(0.0, (a, b) => a > b ? a : b) +
                            //           10,
                            //       barGroups: getBarChartData(currentView),
                            //       groupsSpace: 12,
                            //       barTouchData: BarTouchData(
                            //         enabled: true,
                            //         touchTooltipData: BarTouchTooltipData(
                            //           getTooltipItem: (
                            //             group,
                            //             groupIndex,
                            //             rod,
                            //             rodIndex,
                            //           ) {
                            //             String tooltipText = '';
                            //             if (rodIndex == 0) {
                            //               tooltipText =
                            //                   'Login: ${rod.toY.toInt()}';
                            //             } else if (rodIndex == 1) {
                            //               tooltipText =
                            //                   'User: ${rod.toY.toInt()}';
                            //             } else if (rodIndex == 2) {
                            //               tooltipText =
                            //                   'Report: ${rod.toY.toInt()}';
                            //             }
                            //             return BarTooltipItem(
                            //               tooltipText,
                            //               TextStyle(
                            //                 color: Colors.white,
                            //                 fontSize:
                            //                     Get
                            //                         .textTheme
                            //                         .titleMedium!
                            //                         .fontSize,
                            //               ),
                            //             );
                            //           },
                            //         ),
                            //       ),
                            //       titlesData: FlTitlesData(
                            //         show: true,
                            //         bottomTitles: AxisTitles(
                            //           sideTitles: SideTitles(
                            //             showTitles: true,
                            //             getTitlesWidget: (value, meta) {
                            //               int index = value.toInt();
                            //               final barGroups = getBarChartData(
                            //                 currentView,
                            //               );
                            //               if (index >= barGroups.length) {
                            //                 return Container();
                            //               }

                            //               if (currentView == 'all') {
                            //                 if (index == 0) {
                            //                   return Padding(
                            //                     padding: EdgeInsets.only(
                            //                       top: width * 0.02,
                            //                     ),
                            //                     child: Text(
                            //                       "Login",
                            //                       style: TextStyle(
                            //                         fontSize:
                            //                             Get
                            //                                 .textTheme
                            //                                 .labelSmall!
                            //                                 .fontSize,
                            //                       ),
                            //                     ),
                            //                   );
                            //                 } else if (index == 1) {
                            //                   return Padding(
                            //                     padding: EdgeInsets.only(
                            //                       top: width * 0.02,
                            //                     ),
                            //                     child: Text(
                            //                       "User",
                            //                       style: TextStyle(
                            //                         fontSize:
                            //                             Get
                            //                                 .textTheme
                            //                                 .labelSmall!
                            //                                 .fontSize,
                            //                       ),
                            //                     ),
                            //                   );
                            //                 } else if (index == 2) {
                            //                   return Padding(
                            //                     padding: EdgeInsets.only(
                            //                       top: width * 0.02,
                            //                     ),
                            //                     child: Text(
                            //                       "Report",
                            //                       style: TextStyle(
                            //                         fontSize:
                            //                             Get
                            //                                 .textTheme
                            //                                 .labelSmall!
                            //                                 .fontSize,
                            //                       ),
                            //                     ),
                            //                   );
                            //                 }
                            //               } else if (currentView == 'month') {
                            //                 if (summaryData['month'] != null &&
                            //                     index <
                            //                         (summaryData['month']
                            //                                 as List)
                            //                             .length) {
                            //                   return Padding(
                            //                     padding: EdgeInsets.only(
                            //                       top: width * 0.02,
                            //                     ),
                            //                     child: Text(
                            //                       (summaryData['month'][index]['period']
                            //                               as String)
                            //                           .split('-')
                            //                           .last,
                            //                       style: TextStyle(
                            //                         fontSize:
                            //                             Get
                            //                                 .textTheme
                            //                                 .labelSmall!
                            //                                 .fontSize,
                            //                       ),
                            //                     ),
                            //                   );
                            //                 }
                            //               } else if (currentView == 'week') {
                            //                 if (summaryData['week'] != null &&
                            //                     index <
                            //                         (summaryData['week']
                            //                                 as List)
                            //                             .length) {
                            //                   return Padding(
                            //                     padding: EdgeInsets.only(
                            //                       top: width * 0.02,
                            //                     ),
                            //                     child: Text(
                            //                       (summaryData['week'][index]['week']
                            //                               as String)
                            //                           .split('-')
                            //                           .last,
                            //                       style: TextStyle(
                            //                         fontSize:
                            //                             Get
                            //                                 .textTheme
                            //                                 .labelSmall!
                            //                                 .fontSize,
                            //                       ),
                            //                     ),
                            //                   );
                            //                 }
                            //               } else {
                            //                 // day view
                            //                 if (summaryData['day'] != null &&
                            //                     summaryData['day']['login'] !=
                            //                         null &&
                            //                     index <
                            //                         (summaryData['day']['login']
                            //                                 as List)
                            //                             .length) {
                            //                   return Padding(
                            //                     padding: EdgeInsets.only(
                            //                       top: width * 0.02,
                            //                     ),
                            //                     child: Text(
                            //                       formatDate(
                            //                         summaryData['day']['login'][index]['timestamp'],
                            //                       ),
                            //                       style: TextStyle(
                            //                         fontSize:
                            //                             Get
                            //                                 .textTheme
                            //                                 .labelSmall!
                            //                                 .fontSize,
                            //                       ),
                            //                     ),
                            //                   );
                            //                 }
                            //               }
                            //               return Container();
                            //             },
                            //           ),
                            //         ),
                            //         leftTitles: AxisTitles(
                            //           sideTitles: SideTitles(
                            //             showTitles: true,
                            //             reservedSize: 30,
                            //             getTitlesWidget: (value, meta) {
                            //               if (value == 0) return Container();
                            //               return Padding(
                            //                 padding: EdgeInsets.only(
                            //                   right: 4.0,
                            //                 ),
                            //                 child: Text(
                            //                   value.toInt().toString(),
                            //                   style: TextStyle(
                            //                     fontSize:
                            //                         Get
                            //                             .textTheme
                            //                             .labelMedium!
                            //                             .fontSize,
                            //                     color: Colors.grey[600],
                            //                   ),
                            //                 ),
                            //               );
                            //             },
                            //           ),
                            //         ),
                            //         rightTitles: AxisTitles(
                            //           sideTitles: SideTitles(showTitles: false),
                            //         ),
                            //         topTitles: AxisTitles(
                            //           sideTitles: SideTitles(showTitles: false),
                            //         ),
                            //       ),
                            //       gridData: FlGridData(
                            //         show: true,
                            //         horizontalInterval:
                            //             getBarChartData(currentView)
                            //                         .expand(
                            //                           (group) => group.barRods,
                            //                         )
                            //                         .map((rod) => rod.toY)
                            //                         .fold(
                            //                           0.0,
                            //                           (a, b) => a > b ? a : b,
                            //                         ) <=
                            //                     50
                            //                 ? 10
                            //                 : getBarChartData(currentView)
                            //                         .expand(
                            //                           (group) => group.barRods,
                            //                         )
                            //                         .map((rod) => rod.toY)
                            //                         .fold(
                            //                           0.0,
                            //                           (a, b) => a > b ? a : b,
                            //                         ) <=
                            //                     100
                            //                 ? 20
                            //                 : getBarChartData(currentView)
                            //                         .expand(
                            //                           (group) => group.barRods,
                            //                         )
                            //                         .map((rod) => rod.toY)
                            //                         .fold(
                            //                           0.0,
                            //                           (a, b) => a > b ? a : b,
                            //                         ) <=
                            //                     200
                            //                 ? 40
                            //                 : 50,
                            //         getDrawingHorizontalLine: (value) {
                            //           return FlLine(
                            //             color: Colors.black26,
                            //             strokeWidth: 1,
                            //             dashArray: [5, 5],
                            //           );
                            //         },
                            //         drawVerticalLine: false,
                            //       ),
                            //       borderData: FlBorderData(show: false),
                            //     ),
                            //   ),
                            // ),
                            // Padding(
                            //   padding: EdgeInsets.symmetric(
                            //     vertical: height * 0.01,
                            //   ),
                            //   child: Row(
                            //     mainAxisAlignment: MainAxisAlignment.center,
                            //     children: [
                            //       Row(
                            //         children: [
                            //           Container(
                            //             width: width * 0.03,
                            //             height: height * 0.014,
                            //             decoration: BoxDecoration(
                            //               color: Color(0xFF007AFF),
                            //               borderRadius: BorderRadius.circular(
                            //                 2,
                            //               ),
                            //             ),
                            //           ),
                            //           SizedBox(width: width * 0.01),
                            //           Text(
                            //             'Login',
                            //             style: TextStyle(
                            //               fontSize:
                            //                   Get
                            //                       .textTheme
                            //                       .labelMedium!
                            //                       .fontSize,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //       SizedBox(width: width * 0.05),
                            //       Row(
                            //         children: [
                            //           Container(
                            //             width: width * 0.03,
                            //             height: height * 0.014,
                            //             decoration: BoxDecoration(
                            //               color: Colors.green,
                            //               borderRadius: BorderRadius.circular(
                            //                 2,
                            //               ),
                            //             ),
                            //           ),
                            //           SizedBox(width: width * 0.01),
                            //           Text(
                            //             'User',
                            //             style: TextStyle(
                            //               fontSize:
                            //                   Get
                            //                       .textTheme
                            //                       .labelMedium!
                            //                       .fontSize,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //       SizedBox(width: width * 0.05),
                            //       Row(
                            //         children: [
                            //           Container(
                            //             width: width * 0.03,
                            //             height: height * 0.014,
                            //             decoration: BoxDecoration(
                            //               color: Colors.red,
                            //               borderRadius: BorderRadius.circular(
                            //                 2,
                            //               ),
                            //             ),
                            //           ),
                            //           SizedBox(width: width * 0.01),
                            //           Text(
                            //             'Report',
                            //             style: TextStyle(
                            //               fontSize:
                            //                   Get
                            //                       .textTheme
                            //                       .labelMedium!
                            //                       .fontSize,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
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
  }

  Future<void> compareUsers() async {
    final firestoreSnapshot =
        await FirebaseFirestore.instance.collection('usersLogin').get();

    matchingLogins.clear();
    loginCount = 0;

    for (var doc in firestoreSnapshot.docs) {
      var email = doc.id;
      var data = doc.data();
      var login = data['login'];
      var updatedAt = data['updated_at'].toDate();

      var matchedUser = responseGetAlluser.firstWhereOrNull(
        (u) => u.email == email,
      );

      if (matchedUser != null && login == 1) {
        matchingLogins.add({
          'email': email,
          'updated_at': updatedAt.toIso8601String(),
        });
        loginCount++;
      }
    }

    responseGetAlluser =
        responseGetAlluser
            .where(
              (user) => matchingLogins.any((m) => m['email'] == user.email),
            )
            .toList();
  }

  List<BarChartGroupData> getBarChartData(String view) {
    List<BarChartGroupData> barGroups = [];

    if (view == 'all') {
      // สร้างแท่งกราฟที่แสดงผลรวมทั้งหมดจากแต่ละหมวด
      // สร้าง 3 แท่งกราฟ (Login, User, Report)

      // คำนวณผลรวมของแต่ละหมวด
      double totalLogin = 0;
      double totalUser = 0;
      double totalReport = 0;

      // รวมจาก day
      if (summaryData.containsKey('day')) {
        totalLogin += (summaryData['day']['login'] as List).fold(
          0,
          (sum, item) => sum + (item['count'] as int),
        );

        totalUser += (summaryData['day']['user'] as List).fold(
          0,
          (sum, item) => sum + (item['count'] as int),
        );

        totalReport += (summaryData['day']['report'] as List).fold(
          0,
          (sum, item) => sum + (item['count'] as int),
        );
      }

      // รวมจาก week
      if (summaryData.containsKey('week')) {
        totalLogin += (summaryData['week'] as List).fold(
          0,
          (sum, item) => sum + (item['login'] as int),
        );

        totalUser += (summaryData['week'] as List).fold(
          0,
          (sum, item) => sum + (item['user'] as int),
        );

        totalReport += (summaryData['week'] as List).fold(
          0,
          (sum, item) => sum + (item['report'] as int),
        );
      }

      // รวมจาก month
      if (summaryData.containsKey('month')) {
        totalLogin += (summaryData['month'] as List).fold(
          0,
          (sum, item) => sum + (item['login'] as int),
        );

        totalUser += (summaryData['month'] as List).fold(
          0,
          (sum, item) => sum + (item['user'] as int),
        );

        totalReport += (summaryData['month'] as List).fold(
          0,
          (sum, item) => sum + (item['report'] as int),
        );
      }

      // สร้างกราฟแบบ grouped bar ที่มี 3 หมวดหลัก
      barGroups.add(
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: totalLogin,
              color: Color(0xFF007AFF), // Blue for login
              width: 25,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );

      barGroups.add(
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: totalUser,
              color: Colors.green, // Indigo for users
              width: 25,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );

      barGroups.add(
        BarChartGroupData(
          x: 2,
          barRods: [
            BarChartRodData(
              toY: totalReport,
              color: Colors.red, // Red for reports
              width: 25,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    } else if (view == 'day') {
      // Day view - show data for each day
      if (summaryData.containsKey('day')) {
        final loginData = summaryData['day']['login'] as List;
        final userData = summaryData['day']['user'] as List;
        final reportData = summaryData['day']['report'] as List;

        for (int i = 0; i < loginData.length; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (loginData[i]['count'] as num).toDouble(),
                  color: Color(0xFF007AFF), // Blue for login
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: (userData[i]['count'] as num).toDouble(),
                  color: Colors.green, // Indigo for users
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: (reportData[i]['count'] as num).toDouble(),
                  color: Colors.red, // Red for reports
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }
      }
    } else if (view == 'week') {
      // Week view - show data for each week
      if (summaryData.containsKey('week')) {
        final weekData = summaryData['week'] as List;

        for (int i = 0; i < weekData.length; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (weekData[i]['login'] as num).toDouble(),
                  color: Color(0xFF007AFF), // Blue for login
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: (weekData[i]['user'] as num).toDouble(),
                  color: Colors.green, // Indigo for users
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: (weekData[i]['report'] as num).toDouble(),
                  color: Colors.red, // Red for reports
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }
      }
    } else if (view == 'month') {
      // Month view - show data for each month
      if (summaryData.containsKey('month')) {
        final monthData = summaryData['month'] as List;

        for (int i = 0; i < monthData.length; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (monthData[i]['login'] as num).toDouble(),
                  color: Color(0xFF007AFF), // Blue for login
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: (monthData[i]['user'] as num).toDouble(),
                  color: Colors.green, // Indigo for users
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: (monthData[i]['report'] as num).toDouble(),
                  color: Colors.red, // Red for reports
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }
      }
    }

    return barGroups;
  }

  void updateTotalCounts() {
    if (currentView == 'all') {
      // คำนวณผลรวมของทุกมุมมอง
      int loginSum = 0;
      int reportSum = 0;

      // รวมข้อมูลจาก day view
      if (summaryData.containsKey('day')) {
        loginSum += (summaryData['day']['login'] as List).fold(
          0,
          (sum, item) => sum + (item['count'] as int),
        );

        reportSum += (summaryData['day']['report'] as List).fold(
          0,
          (sum, item) => sum + (item['count'] as int),
        );
      }

      // รวมข้อมูลจาก week view
      if (summaryData.containsKey('week')) {
        loginSum += (summaryData['week'] as List).fold(
          0,
          (sum, item) => sum + (item['login'] as int),
        );

        reportSum += (summaryData['week'] as List).fold(
          0,
          (sum, item) => sum + (item['report'] as int),
        );
      }

      // รวมข้อมูลจาก month view
      if (summaryData.containsKey('month')) {
        loginSum += (summaryData['month'] as List).fold(
          0,
          (sum, item) => sum + (item['login'] as int),
        );

        reportSum += (summaryData['month'] as List).fold(
          0,
          (sum, item) => sum + (item['report'] as int),
        );
      }

      totalLoginCount = loginSum;
      totalReportCount = reportSum;
    } else if (currentView == 'day' && summaryData.containsKey('day')) {
      totalLoginCount = (summaryData['day']['login'] as List).fold(
        0,
        (sum, item) => sum + (item['count'] as int),
      );

      totalReportCount = (summaryData['day']['report'] as List).fold(
        0,
        (sum, item) => sum + (item['count'] as int),
      );
    } else if (currentView == 'week' && summaryData.containsKey('week')) {
      totalLoginCount = (summaryData['week'] as List).fold(
        0,
        (sum, item) => sum + (item['login'] as int),
      );

      totalReportCount = (summaryData['week'] as List).fold(
        0,
        (sum, item) => sum + (item['report'] as int),
      );
    } else if (currentView == 'month' && summaryData.containsKey('month')) {
      totalLoginCount = (summaryData['month'] as List).fold(
        0,
        (sum, item) => sum + (item['login'] as int),
      );

      totalReportCount = (summaryData['month'] as List).fold(
        0,
        (sum, item) => sum + (item['report'] as int),
      );
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

  void logout() async {
    url = await loadAPIEndpoint();
    loadingDialog();
    var responseLogout = await http.post(
      Uri.parse("$url/auth/signout"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );
    Get.back();
    if (responseLogout.statusCode == 403) {
      loadingDialog();
      await loadNewRefreshToken();
      responseLogout = await http.post(
        Uri.parse("$url/auth/signout"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
      Get.back();
    }
    if (responseLogout.statusCode == 200) {
      await FirebaseFirestore.instance
          .collection('usersLogin')
          .doc(box.read('userProfile')['email'])
          .update({'deviceName': FieldValue.delete()});
      await box.erase();
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      await storage.deleteAll();
      Get.offAll(() => SplashPage());
    } else {
      await FirebaseFirestore.instance
          .collection('usersLogin')
          .doc(box.read('userProfile')['email'])
          .update({'deviceName': FieldValue.delete()});
      await box.erase();
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      await storage.deleteAll();
      Get.offAll(() => SplashPage());
    }
  }

  String format(String? timestamp, String type) {
    if (timestamp == null || timestamp.toLowerCase() == 'null') {
      return '';
    }

    if (timestamp.length == 7) {
      timestamp = '$timestamp-01T00:00:00Z';
    }

    final DateTime utcTime = DateTime.parse(timestamp);
    final DateTime localTime = utcTime.toLocal();
    String formattedDateTime;
    if (type == 'day') {
      formattedDateTime = DateFormat('MM, yyyy').format(localTime);
    } else if (type == 'week') {
      formattedDateTime = DateFormat('MM, yyyy').format(localTime);
    } else if (type == 'month') {
      formattedDateTime = DateFormat('yyyy').format(localTime);
    } else if (type == 'year') {
      formattedDateTime = DateFormat('MM - yyyy').format(localTime);
    } else {
      formattedDateTime = 'Tatal';
    }

    return formattedDateTime;
  }

  String formatDate(String timestamp) {
    final DateTime utcTime = DateTime.parse(timestamp);
    final DateTime localTime = utcTime.toLocal();

    final String formatted = DateFormat('dd').format(localTime);
    return formatted;
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
