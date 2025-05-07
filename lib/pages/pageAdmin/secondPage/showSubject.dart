import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ShowsubjectPage extends StatefulWidget {
  const ShowsubjectPage({super.key});

  @override
  State<ShowsubjectPage> createState() => _ShowsubjectPageState();
}

class _ShowsubjectPageState extends State<ShowsubjectPage> {
  List<Map<String, dynamic>> reportData = [];
  Set<String> readReportNos = {};
  var box = GetStorage();

  late String adminEmail;
  // 🔮 Future
  late Future<void> loadData;
  // 📊 Integer Variables
  int itemCount = 1;
  bool isLoadings = true;
  bool showShimmer = true;
  bool isSortLatestFirst = true;

  @override
  void initState() {
    super.initState();
    loadData = loadReportDataAndFetchReads();
  }

  Future<void> loadReportDataAndFetchReads() async {
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

  Future<void> loadDataAsync() async {
    final String response =
        await rootBundle.loadString('assets/text/report_data.json');
    final data = json.decode(response) as List<dynamic>;

    reportData = List<Map<String, dynamic>>.from(data);
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
              itemCount = reportData
                      .where((item) =>
                          item['subject'] ==
                          context.read<Appdata>().subject.subjectReport)
                      .isEmpty
                  ? 1
                  : reportData
                      .where((item) =>
                          item['subject'] ==
                          context.read<Appdata>().subject.subjectReport)
                      .length;
            });
          });
        }
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
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
                          '${context.read<Appdata>().subject.subjectReport} (${countSubject(context.read<Appdata>().subject.subjectReport)})',
                          style: TextStyle(
                            fontSize: Get.textTheme.titleLarge!.fontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            SizedBox(width: width * 0.05),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  isSortLatestFirst = !isSortLatestFirst;
                                  sortReportData();
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.01,
                                  vertical: height * 0.005,
                                ),
                                child: SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M7 20h2V8h3L8 4 4 8h3zm13-4h-3V4h-2v12h-3l4 4z"></path></svg>',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.01),
                    Expanded(
                      child: Scrollbar(
                        interactive: true,
                        child: SingleChildScrollView(
                          child: Column(
                            children: isLoadings || showShimmer
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
                                        .where((item) =>
                                            item['subject'] ==
                                            context
                                                .read<Appdata>()
                                                .subject
                                                .subjectReport)
                                        .map(
                                      (item) {
                                        bool isRead = readReportNos
                                            .contains('ID: ${item['no']}');
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom: height * 0.01,
                                          ),
                                          child: Material(
                                            color: isRead
                                                ? Colors.grey[300]
                                                : Color(0xFFF2F2F6),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () {
                                                showModal(
                                                  item['subject'],
                                                  item['email'],
                                                  item['name'],
                                                  item['detail'],
                                                  item['timestamp'],
                                                );
                                                markAsRead(item);
                                              },
                                              child: Container(
                                                width: width,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.025,
                                                  vertical: height * 0.005,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                                              item['subject'],
                                                              style: TextStyle(
                                                                fontSize: Get
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
                                                              color: Colors
                                                                  .black54,
                                                            ),
                                                          ],
                                                        ),
                                                        Text(
                                                          timeAgo(item[
                                                              'timestamp']),
                                                          style: TextStyle(
                                                            fontSize: Get
                                                                .textTheme
                                                                .titleMedium!
                                                                .fontSize,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            color:
                                                                Colors.black54,
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
                                                            width: width * 0.1),
                                                        Text(
                                                          item['email'],
                                                          style: TextStyle(
                                                            fontSize: Get
                                                                .textTheme
                                                                .titleSmall!
                                                                .fontSize,
                                                            fontWeight:
                                                                FontWeight.w500,
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
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showModal(
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
                                onTap: () {},
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

  Future<Set<String>> fetchReadReportNos() async {
    Set<String> readNos = {};

    final subjects = reportData.map((e) => e['subject']).toSet();

    for (var subject in subjects) {
      final snapshot = await FirebaseFirestore.instance
          .collection('readReport')
          .doc(box.read('email').toString())
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
        .doc(box.read('email').toString())
        .collection(report['subject'])
        .doc('ID: ${report['no']}')
        .set({
      'readAt': FieldValue.serverTimestamp(),
      'name': report['name'],
      'email': report['email'],
      'subject': report['subject'],
    });

    if (!mounted) return;
    setState(() {
      readReportNos.add('ID: ${report['no']}');
    });
  }

  int countSubject(String subject) {
    return reportData.where((data) => data['subject'] == subject).length;
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
      bool isSameDay = postTimeLocal.year == nowLocal.year &&
          postTimeLocal.month == nowLocal.month &&
          postTimeLocal.day == nowLocal.day;

      if (isSameDay) {
        return '${difference.inHours}h ago';
      } else {
        return 'Yesterday, $formattedTime';
      }
    } else if (difference.inDays < 7) {
      DateTime yesterday = nowLocal.subtract(Duration(days: 1));
      bool isYesterday = postTimeLocal.year == yesterday.year &&
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
      DateTime timeA = DateTime.parse(a['timestamp']);
      DateTime timeB = DateTime.parse(b['timestamp']);
      return isSortLatestFirst
          ? timeB.compareTo(timeA) // ใหม่ก่อน
          : timeA.compareTo(timeB); // เก่าก่อน
    });
  }

  String formatFullDateTime(String timestamp) {
    final DateTime utcTime = DateTime.parse(timestamp);
    final DateTime localTime = utcTime.toLocal();

    final String formatted =
        DateFormat('EEEE, d MMMM yyyy : HH:mm').format(localTime);
    return formatted;
  }
}
