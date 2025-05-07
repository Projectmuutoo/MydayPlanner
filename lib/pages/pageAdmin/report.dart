import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/pages/pageAdmin/secondPage/showSubject.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<Map<String, dynamic>> reportData = [];
  List<Map<String, dynamic>> rawReportData = [];
  int? touchedIndex;
  var box = GetStorage();
  late Future<void> loadData;
  int itemCount = 1;
  bool isLoadings = true;
  bool showShimmer = true;

  @override
  void initState() {
    super.initState();
    loadData = loadDataAsync();
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
                    getLatestReports().isEmpty ? 0 : getLatestReports().length;
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
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(seconds: 1),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      double startDegree =
                                          270 + 360 * (1 + value);
                                      return PieChart(
                                        PieChartData(
                                          sections: List.generate(
                                              reportData.length, (index) {
                                            final data = reportData[index];
                                            final isTouched =
                                                index == touchedIndex;
                                            return PieChartSectionData(
                                              value: data['percentage'] * value,
                                              title: (value == 1)
                                                  ? (isTouched
                                                      ? ''
                                                      : '${data['percentage']}%')
                                                  : '',
                                              badgeWidget: isTouched
                                                  ? Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          data['subject'],
                                                          style: TextStyle(
                                                            fontSize: 20,
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
                                                            fontSize: 16,
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
                                                fontSize: isTouched ? 20 : 16,
                                                fontWeight: isTouched
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isTouched
                                                    ? Colors.black54
                                                    : Colors.white,
                                              ),
                                              radius: isTouched ? 90 : 80,
                                              color: hexToColor(data['color']),
                                            );
                                          }),
                                          sectionsSpace: 0,
                                          centerSpaceRadius: 50,
                                          startDegreeOffset: startDegree,
                                          pieTouchData: PieTouchData(
                                            enabled: true,
                                            touchCallback: (FlTouchEvent event,
                                                pieTouchResponse) {
                                              if (event is FlTapUpEvent &&
                                                  pieTouchResponse != null &&
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
                                                  touchedIndex = null;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Latest Reports',
                                      style: TextStyle(
                                        fontSize: Get
                                            .textTheme.headlineSmall!.fontSize,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: isLoadings || showShimmer
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
                                          ...getLatestReports().map(
                                            (data) {
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
                                                        data['subject'],
                                                        data['email'],
                                                        data['name'],
                                                        data['detail'],
                                                        data['timestamp'],
                                                      );
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Container(
                                                      width: width,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        horizontal:
                                                            width * 0.02,
                                                        vertical: height * 0.01,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            data['subject'],
                                                            style: TextStyle(
                                                              fontSize: Get
                                                                  .textTheme
                                                                  .titleMedium!
                                                                  .fontSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color: hexToColor(
                                                                  data[
                                                                      'color']),
                                                            ),
                                                          ),
                                                          Row(
                                                            children: [
                                                              Text(
                                                                timeAgo(data[
                                                                    'timestamp']),
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: Get
                                                                      .textTheme
                                                                      .titleMedium!
                                                                      .fontSize,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  color: Colors
                                                                      .black54,
                                                                ),
                                                              ),
                                                              SvgPicture.string(
                                                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                                                color: Colors
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
                                            },
                                          ),
                                        ],
                                ),
                                SizedBox(height: height * 0.01),
                                Row(
                                  children: [
                                    Text(
                                      'Subject',
                                      style: TextStyle(
                                        fontSize: Get
                                            .textTheme.headlineSmall!.fontSize,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: reportData.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: width * 0.02,
                                    mainAxisSpacing: height * 0.01,
                                    childAspectRatio: 1.3,
                                  ),
                                  itemBuilder: (context, index) {
                                    final data = reportData[index];
                                    return Material(
                                      color: Color(0xFFF2F2F6),
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        onTap: () {
                                          context
                                              .read<Appdata>()
                                              .subject
                                              .subjectReport = data['subject'];
                                          Get.to(() => ShowsubjectPage());
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.01,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${data['subject']}\n(${countSubject(data['subject'])})',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: Get.textTheme
                                                    .titleMedium!.fontSize,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    hexToColor(data['color']),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
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

  Future<void> loadDataAsync() async {
    final String response =
        await rootBundle.loadString('assets/text/report_data.json');
    final data = json.decode(response) as List<dynamic>;

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
        subject: {
          "subject": subject,
          "count": 0,
          "color": "", // จะเอาสีจากอันแรกที่เจอ
        }
    };

    for (var item in data) {
      String subject = item['subject'];
      if (mainSubjects.contains(subject)) {
        aggregatedData[subject]!['count'] += 1;
        if ((aggregatedData[subject]!['color'] as String).isEmpty) {
          aggregatedData[subject]!['color'] = item['color'];
        }
      }
    }

    // คำนวณเปอร์เซ็นต์ตามจำนวน
    int totalCount = aggregatedData.values
        .fold(0, (sum, item) => sum + item['count'] as int);

    List<Map<String, dynamic>> adjustedReportData = [];
    aggregatedData.forEach((key, value) {
      double adjustedPercentage = (value['count'] / totalCount) * 100;
      adjustedReportData.add({
        "subject": value['subject'],
        "percentage": double.parse(adjustedPercentage.toStringAsFixed(2)),
        "color": value['color'],
      });
    });

    final List<Map<String, dynamic>> loadedData =
        List<Map<String, dynamic>>.from(data);

    if (!mounted) return;
    setState(() {
      rawReportData = loadedData;
      reportData = adjustedReportData;
      isLoadings = false;
    });

    Timer(Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        showShimmer = false;
      });
    });
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

  String formatFullDateTime(String timestamp) {
    final DateTime utcTime = DateTime.parse(timestamp);
    final DateTime localTime = utcTime.toLocal();

    final String formatted =
        DateFormat('EEEE, d MMMM yyyy : HH:mm').format(localTime);
    return formatted;
  }

  int countSubject(String subject) {
    return rawReportData.where((data) => data['subject'] == subject).length;
  }

  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse('0x$hex'));
  }

  List<Map<String, dynamic>> getLatestReports() {
    List<Map<String, dynamic>> sortedByDate = List.from(rawReportData);

    sortedByDate.sort((a, b) {
      DateTime aDate = DateTime.parse(a['timestamp']);
      DateTime bDate = DateTime.parse(b['timestamp']);
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
}
