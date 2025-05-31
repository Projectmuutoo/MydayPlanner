import 'dart:async';
import 'dart:convert';

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
import 'package:mydayplanner/models/response/allReportAllGetResponst.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:mydayplanner/splash.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

class ShowsubjectPage extends StatefulWidget {
  const ShowsubjectPage({super.key});

  @override
  State<ShowsubjectPage> createState() => _ShowsubjectPageState();
}

class _ShowsubjectPageState extends State<ShowsubjectPage> {
  List<Map<String, dynamic>> reportData = [];
  Set<String> readReportNos = {};
  var box = GetStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  final storage = FlutterSecureStorage();

  late String adminEmail;
  // 🔮 Future
  late Future<void> loadData;
  // 📊 Integer Variables
  int itemCount = 1;
  bool isLoadings = true;
  bool showShimmer = true;
  bool isSortLatestFirst = true;
  bool? confirm;
  late String url;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    loadData = loadReportDataAndFetchReads();
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

    if (result.statusCode == 403) {
      await loadNewRefreshToken();
      result = await loadAllReport();
    }

    if (result.statusCode == 200) {
      AllReportAllGetResponst response = allReportAllGetResponstFromJson(
        result.body,
      );
      reportData = response.reports.map((report) => report.toJson()).toList();
    }
  }

  Future<void> loadReportDataAndFetchReads() async {
    setState(() {
      isLoadings = true;
      showShimmer = true;
    });

    await loadDataAsync(); // โหลด reportData ก่อน
    sortReportData();
    var nos = await fetchReadReportNos(); // แล้วค่อยโหลด readReport
    if (!mounted) return;
    setState(() {
      readReportNos = nos;
      isLoadings = false;
    });

    Timer(Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        showShimmer = false;
      });
    });
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
                  reportData
                          .where(
                            (item) =>
                                item['Category'] ==
                                context.read<Appdata>().subject.subjectReport,
                          )
                          .isEmpty
                      ? 1
                      : reportData
                          .where(
                            (item) =>
                                item['Category'] ==
                                context.read<Appdata>().subject.subjectReport,
                          )
                          .length;
            });
          });
        }
        return WillPopScope(
          onWillPop: () async {
            if (confirm == true) {
              Navigator.pop(context, 'refresh');
            } else {
              Get.back();
            }
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: Colors.black,
              centerTitle: true,
              leading: InkWell(
                onTap: () {
                  if (confirm == true) {
                    Navigator.pop(context, 'refresh');
                  } else {
                    Get.back();
                  }
                },
                child: Center(
                  child: SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);"><path d="M21 11H6.414l5.293-5.293-1.414-1.414L2.586 12l7.707 7.707 1.414-1.414L6.414 13H21z"></path></svg>',
                    height: height * 0.03,
                    width: width * 0.03,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              title: Text(
                '${context.read<Appdata>().subject.subjectReport} (${countSubject(context.read<Appdata>().subject.subjectReport)})',
                style: TextStyle(
                  fontSize: Get.textTheme.titleLarge!.fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.all(width * 0.02),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        isSortLatestFirst = !isSortLatestFirst;
                        sortReportData();
                      });
                    },
                    child: SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M7 20h2V8h3L8 4 4 8h3zm13-4h-3V4h-2v12h-3l4 4z"></path></svg>',
                      height: height * 0.03,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  child: Column(
                    children: [
                      Expanded(
                        child: Scrollbar(
                          interactive: true,
                          child: SingleChildScrollView(
                            child: Column(
                              children:
                                  isLoadings || showShimmer
                                      ? List.generate(
                                        itemCount,
                                        (index) => Padding(
                                          padding: EdgeInsets.only(
                                            bottom: height * 0.01,
                                          ),
                                          child: Shimmer.fromColors(
                                            baseColor: Color(0xFFF7F7F7),
                                            highlightColor: Colors.grey[300]!,
                                            child: Container(
                                              width: width,
                                              height: height * 0.065,
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
                                        ...reportData
                                            .where(
                                              (item) =>
                                                  item['Category'] ==
                                                  context
                                                      .read<Appdata>()
                                                      .subject
                                                      .subjectReport,
                                            )
                                            .map((item) {
                                              bool isRead = readReportNos
                                                  .contains(
                                                    'ID: ${item['ReportID']}',
                                                  );
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: height * 0.01,
                                                ),
                                                child: Material(
                                                  color:
                                                      isRead
                                                          ? Colors.grey[300]
                                                          : Color(0xFFF2F2F6),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    onTap: () {
                                                      showModal(
                                                        item['ReportID'],
                                                        item['Category'],
                                                        item['Email'],
                                                        item['Name'],
                                                        item['Description'],
                                                        item['CreateAt'],
                                                      );
                                                      markAsRead(item);
                                                    },
                                                    child: Container(
                                                      width: width,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                width * 0.025,
                                                            vertical:
                                                                height * 0.005,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    item['Category'],
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          Get
                                                                              .textTheme
                                                                              .titleLarge!
                                                                              .fontSize,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
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
                                                              Text(
                                                                timeAgo(
                                                                  item['CreateAt'],
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
                                                            ],
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              SizedBox(
                                                                width:
                                                                    width * 0.1,
                                                              ),
                                                              Text(
                                                                item['Email'],
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      Get
                                                                          .textTheme
                                                                          .titleSmall!
                                                                          .fontSize,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
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
                                            }),
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

  void deleteReport(int id, String category) async {
    confirm = await Get.defaultDialog<bool>(
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
      await loadReportDataAndFetchReads();
      await FirebaseFirestore.instance
          .collection('readReport')
          .doc(box.read('userProfile')['email'].toString())
          .collection(category)
          .doc('ID: $id')
          .delete();
      readReportNos.remove('ID: $id');
      Get.back();
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

  Future<Set<String>> fetchReadReportNos() async {
    Set<String> readNos = {};

    final subjects = reportData.map((e) => e['Category']).toSet();

    for (var subject in subjects) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('readReport')
              .doc(box.read('userProfile')['email'].toString())
              .collection(subject)
              .get();

      for (var doc in snapshot.docs) {
        readNos.add(doc.id);
      }
    }

    return readNos;
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

    if (!mounted) return;
    setState(() {
      readReportNos.add('ID: ${report['ReportID']}');
    });
  }

  int countSubject(String subject) {
    return reportData.where((data) => data['Category'] == subject).length;
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

  void sortReportData() {
    reportData.sort((a, b) {
      DateTime timeA = DateTime.parse(a['CreateAt']);
      DateTime timeB = DateTime.parse(b['CreateAt']);
      return isSortLatestFirst
          ? timeB.compareTo(timeA) // ใหม่ก่อน
          : timeA.compareTo(timeB); // เก่าก่อน
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
}
