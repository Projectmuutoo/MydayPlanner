import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/response/allReportAllGetResponst.dart';
import 'package:mydayplanner/pages/pageAdmin/secondPage/showSubject.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:mydayplanner/splash.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<Map<String, dynamic>> reportData = [];
  List<Map<String, dynamic>> rawReportData = [];
  int? touchedIndex;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  var box = GetStorage();
  final storage = FlutterSecureStorage();
  late Future<void> loadData;
  int itemCount = 3;
  bool isLoadings = true;
  bool showShimmer = true;
  late String url;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    loadData = loadDataAsync();
  }

  Future<http.Response> loadAllReport() async {
    url = await loadAPIEndpoint();
    var responseAllReport = await http.get(
      Uri.parse("$url/report/allreport"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );
    return responseAllReport;
  }

  Future<void> loadDataAsync() async {
    var result = await loadAllReport();

    setState(() {
      isLoadings = true;
      showShimmer = true;
    });

    if (result.statusCode == 403) {
      await loadNewRefreshToken();
      result = await loadAllReport();
    }

    if (result.statusCode == 200) {
      AllReportAllGetResponst response = allReportAllGetResponstFromJson(
        result.body,
      );
      List<Report> reports = response.reports;

      // หัวข้อหลักที่ต้องการ
      List<String> mainSubjects = [
        "Suggestions",
        "Incorrect Information",
        "Problems or Issues",
        "Accessibility Issues",
        "Notification Issues",
        "Security Issues",
      ];

      // เตรียม Map เพื่อเก็บจำนวนครั้งที่พบแต่ละ subject
      Map<String, Map<String, dynamic>> aggregatedData = {
        for (var subject in mainSubjects)
          subject: {"subject": subject, "count": 0, "color": ""},
      };

      for (var item in reports) {
        String subject = item.category;
        if (mainSubjects.contains(subject)) {
          aggregatedData[subject]!['count'] += 1;
          if ((aggregatedData[subject]!['color'] as String).isEmpty) {
            aggregatedData[subject]!['color'] = item.color;
          }
        }
      }

      int totalCount = aggregatedData.values.fold(
        0,
        (sum, item) => sum + item['count'] as int,
      );

      List<Map<String, dynamic>> adjustedReportData = [];
      aggregatedData.forEach((key, value) {
        double adjustedPercentage =
            totalCount > 0 ? (value['count'] / totalCount) * 100 : 0.0;
        adjustedReportData.add({
          "Category": value['subject'],
          "subject": value['subject'],
          "percentage": double.parse(adjustedPercentage.toStringAsFixed(2)),
          "Color": value['color'],
        });
      });

      if (!mounted) return;
      setState(() {
        rawReportData = reports.map((e) => e.toJson()).toList(); // แปลงเป็น Map
        reportData = adjustedReportData;
        isLoadings = false;
        showShimmer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return FutureBuilder(
      future: loadData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Future.delayed(Duration.zero, () {
            if (!mounted) return;
            setState(() {
              itemCount =
                  getLatestReports().isEmpty ? 3 : getLatestReports().length;
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
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Report',
                            style: TextStyle(
                              fontSize: Get.textTheme.displaySmall!.fontSize,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              SizedBox(
                                height: height * 0.3,
                                child:
                                    isLoadings || showShimmer
                                        ? TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0, end: 1),
                                          duration: Duration.zero,
                                          curve: Curves.easeOutCubic,
                                          builder: (context, value, child) {
                                            return Shimmer.fromColors(
                                              baseColor: Color(0xFFF7F7F7),
                                              highlightColor: Colors.grey[300]!,
                                              child: PieChart(
                                                PieChartData(
                                                  sections: List.generate(1, (
                                                    index,
                                                  ) {
                                                    return PieChartSectionData(
                                                      radius: 80,
                                                      color: Colors.grey,
                                                    );
                                                  }),
                                                  sectionsSpace: 0,
                                                  centerSpaceRadius: 50,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                        : SizedBox(
                                          height: height * 0.3,
                                          child:
                                              reportData.isEmpty
                                                  ? Center(
                                                    child: Text(
                                                      "No information",
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize:
                                                            Get
                                                                .textTheme
                                                                .titleMedium!
                                                                .fontSize,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  )
                                                  : TweenAnimationBuilder<
                                                    double
                                                  >(
                                                    tween: Tween(
                                                      begin: 0,
                                                      end: 1,
                                                    ),
                                                    duration: Duration(
                                                      milliseconds: 500,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    builder: (
                                                      context,
                                                      value,
                                                      child,
                                                    ) {
                                                      double startDegree =
                                                          270 +
                                                          360 * (1 + value);
                                                      return PieChart(
                                                        PieChartData(
                                                          sections: List.generate(reportData.length, (
                                                            index,
                                                          ) {
                                                            final data =
                                                                reportData[index];
                                                            final isTouched =
                                                                index ==
                                                                touchedIndex;
                                                            return PieChartSectionData(
                                                              value:
                                                                  data['percentage'] *
                                                                  value,
                                                              title:
                                                                  (value == 1)
                                                                      ? (isTouched
                                                                          ? ''
                                                                          : '${data['percentage']}%')
                                                                      : '',
                                                              badgeWidget:
                                                                  isTouched
                                                                      ? Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Text(
                                                                            data['Category'],
                                                                            style: TextStyle(
                                                                              fontSize:
                                                                                  20,
                                                                              fontWeight:
                                                                                  FontWeight.bold,
                                                                              color:
                                                                                  Colors.black54,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                          ),
                                                                          Text(
                                                                            '${data['percentage']}%',
                                                                            style: TextStyle(
                                                                              fontSize:
                                                                                  16,
                                                                              fontWeight:
                                                                                  FontWeight.w600,
                                                                              color:
                                                                                  Colors.black54,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                          ),
                                                                        ],
                                                                      )
                                                                      : null,
                                                              badgePositionPercentageOffset:
                                                                  .50,
                                                              titleStyle: TextStyle(
                                                                fontSize:
                                                                    isTouched
                                                                        ? 20
                                                                        : 16,
                                                                fontWeight:
                                                                    isTouched
                                                                        ? FontWeight
                                                                            .bold
                                                                        : FontWeight
                                                                            .w500,
                                                                color:
                                                                    isTouched
                                                                        ? Colors
                                                                            .black54
                                                                        : Colors
                                                                            .white,
                                                              ),
                                                              radius:
                                                                  isTouched
                                                                      ? 90
                                                                      : 80,
                                                              color: hexToColor(
                                                                data['Color'],
                                                              ),
                                                            );
                                                          }),
                                                          sectionsSpace: 0,
                                                          centerSpaceRadius: 50,
                                                          startDegreeOffset:
                                                              startDegree,
                                                          pieTouchData: PieTouchData(
                                                            enabled: true,
                                                            touchCallback: (
                                                              FlTouchEvent
                                                              event,
                                                              pieTouchResponse,
                                                            ) {
                                                              if (event
                                                                      is FlTapUpEvent &&
                                                                  pieTouchResponse !=
                                                                      null &&
                                                                  pieTouchResponse
                                                                          .touchedSection !=
                                                                      null) {
                                                                setState(() {
                                                                  touchedIndex =
                                                                      pieTouchResponse
                                                                          .touchedSection!
                                                                          .touchedSectionIndex;
                                                                });
                                                              } else if (event
                                                                  is FlTapCancelEvent) {
                                                                setState(() {
                                                                  touchedIndex =
                                                                      null;
                                                                });
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                        ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Latest Reports',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.headlineSmall!.fontSize,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children:
                                    isLoadings || showShimmer
                                        ? List.generate(
                                          itemCount,
                                          (index) => Padding(
                                            padding: EdgeInsets.only(
                                              bottom: height * 0.005,
                                            ),
                                            child: Shimmer.fromColors(
                                              baseColor: Color(0xFFF7F7F7),
                                              highlightColor: Colors.grey[300]!,
                                              child: Container(
                                                width: width,
                                                height: height * 0.048,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        : [
                                          ...getLatestReports().map((data) {
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom: height * 0.005,
                                              ),
                                              child: Material(
                                                color: Color(0xFFF2F2F6),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: InkWell(
                                                  onTap: () {
                                                    showModal(
                                                      data['ReportID'],
                                                      data['Category'],
                                                      data['Email'],
                                                      data['Name'],
                                                      data['Description'],
                                                      data['CreateAt'],
                                                    );
                                                    markAsRead(data);
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Container(
                                                    width: width,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal:
                                                              width * 0.02,
                                                          vertical:
                                                              height * 0.01,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          data['Category'],
                                                          style: TextStyle(
                                                            fontSize:
                                                                Get
                                                                    .textTheme
                                                                    .titleMedium!
                                                                    .fontSize,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            color: hexToColor(
                                                              data['Color'],
                                                            ),
                                                          ),
                                                        ),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              timeAgo(
                                                                data['CreateAt'],
                                                              ),
                                                              style: TextStyle(
                                                                fontSize:
                                                                    Get
                                                                        .textTheme
                                                                        .titleMedium!
                                                                        .fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                color:
                                                                    Colors
                                                                        .black54,
                                                              ),
                                                            ),
                                                            SvgPicture.string(
                                                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                                              color:
                                                                  Colors
                                                                      .black54,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                              ),
                              SizedBox(height: height * 0.01),
                              Row(
                                children: [
                                  Text(
                                    'Subject',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.headlineSmall!.fontSize,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children:
                                    isLoadings || showShimmer
                                        ? [
                                          GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            itemCount: 6,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 3,
                                                  crossAxisSpacing:
                                                      width * 0.02,
                                                  mainAxisSpacing:
                                                      height * 0.01,
                                                  childAspectRatio: 1.3,
                                                ),
                                            itemBuilder: (context, index) {
                                              return Shimmer.fromColors(
                                                baseColor: Color(0xFFF7F7F7),
                                                highlightColor:
                                                    Colors.grey[300]!,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ]
                                        : [
                                          GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            itemCount: reportData.length,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 3,
                                                  crossAxisSpacing:
                                                      width * 0.02,
                                                  mainAxisSpacing:
                                                      height * 0.01,
                                                  childAspectRatio: 1.3,
                                                ),
                                            itemBuilder: (context, index) {
                                              final data = reportData[index];
                                              return Material(
                                                color: Color(0xFFF2F2F6),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: InkWell(
                                                  onTap: () {
                                                    context
                                                            .read<Appdata>()
                                                            .subject
                                                            .subjectReport =
                                                        data['Category'];
                                                    _navigateAndRefresh();
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal:
                                                              width * 0.01,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '${data['Category']}\n(${countSubject(data['subject'])})',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize:
                                                              Get
                                                                  .textTheme
                                                                  .titleMedium!
                                                                  .fontSize,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: hexToColor(
                                                            data['Color'],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
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
  }

  void showModal(
    int id,
    String subject,
    String email,
    String name,
    String detail,
    String timestamp,
  ) {
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

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  right: width * 0.05,
                  left: width * 0.05,
                  top: height * 0.02,
                ),
                child: SizedBox(
                  height: height * 0.9,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
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
                          Text(
                            subject,
                            style: TextStyle(
                              fontSize: Get.textTheme.titleLarge!.fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              SizedBox(width: width * 0.03),
                              InkWell(
                                onTap: () => deleteReport(id, subject),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.02,
                                    vertical: height * 0.01,
                                  ),
                                  child: SvgPicture.string(
                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M5 20a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8h2V6h-4V4a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v2H3v2h2zM9 4h6v2H9zM8 8h9v12H7V8z"></path><path d="M9 10h2v8H9zm4 0h2v8h-2z"></path></svg>',
                                    fit: BoxFit.contain,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.01),
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: width * 0.03),
                            child: Text(
                              'Send by',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleLarge!.fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: width,
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.02,
                          vertical: height * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFF2F2F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Name: ',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.005),
                                Row(
                                  children: [
                                    Text(
                                      'Email: ',
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleMedium!.fontSize,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.01),
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: width * 0.03),
                            child: Text(
                              'Detail',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleLarge!.fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: width,
                        height: height * 0.5,
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03,
                          vertical: height * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFF2F2F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            detail,
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.normal,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            formatFullDateTime(timestamp),
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.w500,
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

  Future<void> markAsRead(Map<String, dynamic> report) async {
    await FirebaseFirestore.instance
        .collection('readReport')
        .doc(box.read('userProfile')['email'].toString())
        .collection(report['Category'])
        .doc('ID: ${report['ReportID']}')
        .set({
          'readAt': FieldValue.serverTimestamp(),
          'name': report['Name'],
          'email': report['Email'],
          'subject': report['Category'],
        });
  }

  String formatFullDateTime(String timestamp) {
    final DateTime utcTime = DateTime.parse(timestamp);
    final DateTime localTime = utcTime.toLocal();

    final String formatted = DateFormat(
      'EEEE, d MMMM yyyy : HH:mm',
    ).format(localTime);
    return formatted;
  }

  int countSubject(String subject) {
    return rawReportData.where((data) => data['Category'] == subject).length;
  }

  Color hexToColor(String hex) {
    if (hex.isEmpty) return Colors.grey; // Default color if empty

    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse('0x$hex'));
  }

  List<Map<String, dynamic>> getLatestReports() {
    if (rawReportData.isEmpty) return [];

    List<Map<String, dynamic>> sortedByDate = List.from(rawReportData);

    sortedByDate.sort((a, b) {
      DateTime aDate = DateTime.parse(a['CreateAt']);
      DateTime bDate = DateTime.parse(b['CreateAt']);
      return bDate.compareTo(aDate);
    });

    return sortedByDate.take(3).toList();
  }

  String timeAgo(String timestamp) {
    final DateTime postTimeUtc = DateTime.parse(timestamp);
    final DateTime postTimeLocal = postTimeUtc.toLocal();
    final DateTime nowLocal = DateTime.now();

    final Duration difference = nowLocal.difference(postTimeLocal);
    String formattedTime = DateFormat('HH:mm').format(postTimeLocal);

    if (difference.inSeconds < 10) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      bool isSameDay =
          postTimeLocal.year == nowLocal.year &&
          postTimeLocal.month == nowLocal.month &&
          postTimeLocal.day == nowLocal.day;

      if (isSameDay) {
        return '${difference.inHours}h ago';
      } else {
        return 'Yesterday, $formattedTime';
      }
    } else if (difference.inDays < 7) {
      DateTime yesterday = nowLocal.subtract(Duration(days: 1));
      bool isYesterday =
          postTimeLocal.year == yesterday.year &&
          postTimeLocal.month == yesterday.month &&
          postTimeLocal.day == yesterday.day;

      if (isYesterday) {
        return 'Yesterday, $formattedTime';
      } else {
        return '${difference.inDays}d ago, $formattedTime';
      }
    } else {
      return DateFormat('d MMM yyyy, HH:mm').format(postTimeLocal);
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

  void deleteReport(int id, String category) async {
    bool? confirm = await Get.defaultDialog<bool>(
      title: '',
      titlePadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      content: Column(
        children: [
          Image.asset(
            "assets/images/aleart/question.png",
            height: MediaQuery.of(context).size.height * 0.1,
            fit: BoxFit.contain,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Text(
            'Confirm?',
            style: TextStyle(
              fontSize: Get.textTheme.headlineSmall!.fontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF007AFF),
            ),
          ),
          Text(
            'You want to delete this report',
            style: TextStyle(
              fontSize: Get.textTheme.titleMedium!.fontSize,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Get.back(result: true);
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
            'Confirm',
            style: TextStyle(
              fontSize: Get.textTheme.titleLarge!.fontSize,
              color: Colors.white,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            fixedSize: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.05,
            ),
            backgroundColor: Color(0xFFE7F3FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
          ),
          child: Text(
            'Back',
            style: TextStyle(
              fontSize: Get.textTheme.titleLarge!.fontSize,
              color: Color(0xFF007AFF),
            ),
          ),
        ),
      ],
    );
    if (confirm != true) return;
    Get.back();
    url = await loadAPIEndpoint();
    loadingDialog();
    var responseDeleteReport = await http.delete(
      Uri.parse("$url/report/delete/$id"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );
    Get.back();

    if (responseDeleteReport.statusCode == 403) {
      loadingDialog();
      await loadNewRefreshToken();
      responseDeleteReport = await http.delete(
        Uri.parse("$url/report/delete/$id"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
      Get.back();
    }

    if (responseDeleteReport.statusCode == 200) {
      loadingDialog();
      await loadDataAsync();
      await FirebaseFirestore.instance
          .collection('readReport')
          .doc(box.read('userProfile')['email'].toString())
          .collection(category)
          .doc('ID: $id')
          .delete();
      Get.back();
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
                "assets/images/aleart/success.png",
                height: MediaQuery.of(context).size.height * 0.1,
                fit: BoxFit.contain,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Text(
                'Successfully!!',
                style: TextStyle(
                  fontSize: Get.textTheme.headlineSmall!.fontSize,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF007AFF),
                ),
              ),
              Text(
                'Delete report successfully',
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
            onPressed: () {
              Get.back();
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
              'Ok!',
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

  Future<void> _navigateAndRefresh() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShowsubjectPage()),
    );

    if (result == 'refresh') {
      loadDataAsync();
    }
  }
}
