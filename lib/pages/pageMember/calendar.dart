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
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart'
    as model;
import 'package:mydayplanner/pages/pageMember/detailBoards/tasksDetail.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:mydayplanner/splash.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  var box = GetStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FlutterSecureStorage storage = FlutterSecureStorage();
  List<model.Task> tasks = [];
  final GlobalKey iconKey = GlobalKey();
  DateTime selectedDate = DateTime.now();
  int selectedDay = DateTime.now().day;
  bool isCalendarExpanded = false;
  List<String> weekDays = ['Sat', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sun'];
  final List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  bool openSelectMonth = false;
  Timer? debounceTimer;
  OverlayEntry? mainMenuEntry;
  final GlobalKey monthButtonKey = GlobalKey();
  double dropdownTop = 0;
  bool isFinishing = false;
  double dropdownWidth = 0;
  double dropdownLeft = 0;
  bool hideMenu = false;
  bool showArchived = false;
  List<String> selectedTaskIds = [];
  Map<String, bool> creatingTasks = {};
  List<String> selectedIsArchived = [];
  late String url;
  Timer? timer;
  late PageController _pageController;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();

    loadDataAsync();
  }

  Future<void> loadDataAsync() async {
    if (!mounted) return;

    final rawData = box.read('userDataAll');
    final tasksData = model.AllDataUserGetResponst.fromJson(rawData);
    final appData = Provider.of<Appdata>(context, listen: false);

    List<model.Task> filteredTasks = tasksData.tasks
        .where(
          (task) => (showArchived
              ? ['0', '1', '2'].contains(task.status)
              : task.status != '2'),
        )
        .toList();

    appData.showMyTasks.setTasks(filteredTasks);

    setState(() {
      tasks = filteredTasks;
    });
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    List<model.Task> tasksForSelectedDate = getTasksForSelectedDate();

    // สร้าง calendar
    int daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;
    DateTime firstDayOfMonth = DateTime(
      selectedDate.year,
      selectedDate.month,
      1,
    );
    int startWeekday = firstDayOfMonth.weekday;

    // ปรับ weekday ให้เริ่มจากเสาร์ (0) ถึงศุกร์ (6)
    int adjustedStartWeekday = startWeekday == 7 ? 0 : startWeekday;

    // ตรวจสอบว่าต้องใช้ 6 สัปดาห์หรือไม่
    bool needsSixWeeks =
        (daysInMonth == 31 && adjustedStartWeekday >= 5) ||
        (daysInMonth == 30 && adjustedStartWeekday == 6);

    int totalWeeks = needsSixWeeks ? 6 : 5;
    int totalCells = totalWeeks * 7;

    // คำนวณวันที่ของเดือนก่อนหน้า
    DateTime previousMonth = DateTime(
      selectedDate.year,
      selectedDate.month - 1,
      1,
    );
    int daysInPreviousMonth = DateTime(
      previousMonth.year,
      previousMonth.month + 1,
      0,
    ).day;

    List<Widget> dayWidgets = [];

    // เพิ่มวันที่จากเดือนก่อนหน้า
    for (int i = adjustedStartWeekday - 1; i >= 0; i--) {
      int dayNumber = daysInPreviousMonth - i;
      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedDate = DateTime(
                selectedDate.year,
                selectedDate.month - 1,
                dayNumber,
              );
              selectedDay = dayNumber;
              openSelectMonth = false;
            });
          },
          child: Container(
            width: width * 0.08,
            height: height * 0.05,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: Get.textTheme.titleMedium!.fontSize!,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    // สร้างวันที่ของเดือนปัจจุบัน
    for (int i = 1; i <= daysInMonth; i++) {
      bool hasTask = hasTasksOnDay(i);

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedDay = i;
              openSelectMonth = false;
            });
          },
          child: Container(
            width: width * 0.08,
            height: height * 0.05,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectedDay == i ? Color(0xFF4790EB) : Colors.transparent,
              border: selectedDay == i
                  ? Border.all(color: Color(0xFF4790EB), width: 2)
                  : hasTask
                  ? Border.all(color: Colors.grey, width: 1)
                  : null,
            ),
            child: Text(
              '$i',
              style: TextStyle(
                fontSize: Get.textTheme.titleMedium!.fontSize!,
                color: selectedDay == i ? Colors.white : Colors.black,
                fontWeight: selectedDay == i
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    // เติมวันที่จากเดือนถัดไป เพื่อให้ครบตาม totalCells
    int remainingCells = totalCells - dayWidgets.length;

    for (int i = 1; i <= remainingCells; i++) {
      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedDate = DateTime(
                selectedDate.year,
                selectedDate.month + 1,
                i,
              );
              selectedDay = i;
              openSelectMonth = false;
            });
          },
          child: Container(
            width: width * 0.08,
            height: height * 0.05,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Text(
              '$i',
              style: TextStyle(
                fontSize: Get.textTheme.titleMedium!.fontSize!,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    Widget calendarWidget;

    if (isCalendarExpanded) {
      // Show full calendar
      List<Widget> rows = [];
      for (int i = 0; i < totalCells; i += 7) {
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayWidgets
                .sublist(i, (i + 7).clamp(0, dayWidgets.length))
                .map((widget) => Expanded(child: Center(child: widget)))
                .toList(),
          ),
        );
      }
      calendarWidget = Column(children: rows);
    } else {
      // Show only the week containing the selected day
      int selectedWeekIndex = 0;

      // หาสัปดาห์ที่มี selectedDay
      for (int week = 0; week < totalWeeks; week++) {
        int weekStart = week * 7;
        int weekEnd = weekStart + 7;

        for (
          int dayIndex = weekStart;
          dayIndex < weekEnd && dayIndex < dayWidgets.length;
          dayIndex++
        ) {
          int actualDay = dayIndex - adjustedStartWeekday + 1;
          if (actualDay == selectedDay &&
              actualDay > 0 &&
              actualDay <= daysInMonth) {
            selectedWeekIndex = week;
            break;
          }
        }
      }

      // Initialize PageController if not exists or update it
      _pageController = PageController(initialPage: selectedWeekIndex + 1);

      // Animate to correct page if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          int currentPage = _pageController.page?.round() ?? 0;
          if (currentPage != selectedWeekIndex + 1) {
            _pageController.animateToPage(
              selectedWeekIndex + 1,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });

      void calculateNewMonthValues(
        DateTime newDate, {
        bool goToLastWeek = false,
      }) {
        setState(() {
          selectedDate = newDate;

          // คำนวณวันที่ในเดือนใหม่
          int newDaysInMonth = DateTime(newDate.year, newDate.month + 1, 0).day;

          if (goToLastWeek) {
            // ไปสัปดาห์สุดท้ายของเดือนก่อนหน้า
            selectedDay = newDaysInMonth; // เลือกวันสุดท้ายของเดือน

            // คำนวณสัปดาห์ที่วันสุดท้ายอยู่
            int newStartWeekday = DateTime(
              newDate.year,
              newDate.month,
              1,
            ).weekday;
            int newAdjustedStartWeekday = newStartWeekday == 7
                ? 0
                : newStartWeekday;

            // คำนวณว่าต้องใช้กี่สัปดาห์
            bool needsSixWeeks =
                (newDaysInMonth == 31 && newAdjustedStartWeekday >= 5) ||
                (newDaysInMonth == 30 && newAdjustedStartWeekday == 6);
            int totalWeeksInMonth = needsSixWeeks ? 6 : 5;

            // หาสัปดาห์ที่วันสุดท้ายอยู่
            int lastDayIndex = newAdjustedStartWeekday + newDaysInMonth - 1;
            selectedWeekIndex = (lastDayIndex / 7).floor();

            // ตรวจสอบให้แน่ใจว่าไม่เกินจำนวนสัปดาห์ที่มี
            selectedWeekIndex = selectedWeekIndex.clamp(
              0,
              totalWeeksInMonth - 1,
            );
          } else {
            // ไปสัปดาห์แรกของเดือนถัดไป
            selectedWeekIndex = 0;
            selectedDay = 1;
          }
        });
      }

      calendarWidget = SizedBox(
        height: height * 0.05,
        child: PageView.builder(
          controller: _pageController,
          itemCount: totalWeeks + 2, // Add 2 for previous and next month
          onPageChanged: (index) {
            setState(() {
              if (index == 0) {
                // Previous month - ไปสัปดาห์สุดท้ายของเดือนก่อนหน้า
                DateTime previousMonth = DateTime(
                  selectedDate.year,
                  selectedDate.month - 1,
                  1,
                );
                calculateNewMonthValues(previousMonth, goToLastWeek: true);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(selectedWeekIndex + 1);
                  }
                });
                return;
              }

              if (index == totalWeeks + 1) {
                // Next month - ไปสัปดาห์แรกของเดือนถัดไป
                DateTime nextMonth = DateTime(
                  selectedDate.year,
                  selectedDate.month + 1,
                  1,
                );
                calculateNewMonthValues(nextMonth, goToLastWeek: false);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(
                      1,
                    ); // Jump to first week of next month
                  }
                });
                return;
              }

              // เลื่อนภายในเดือนเดียวกัน
              selectedWeekIndex = index - 1;

              // หาวันแรกในสัปดาห์ที่เลือกที่เป็นวันในเดือนปัจจุบัน
              int weekStart = selectedWeekIndex * 7;
              bool foundValidDay = false;

              for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
                int dayIndex = weekStart + dayOffset;
                if (dayIndex >= 0 && dayIndex < dayWidgets.length) {
                  int actualDay = dayIndex - adjustedStartWeekday + 1;
                  if (actualDay > 0 && actualDay <= daysInMonth) {
                    selectedDay = actualDay;
                    foundValidDay = true;
                    break;
                  }
                }
              }

              // ถ้าไม่เจอวันที่ถูกต้องในสัปดาห์นี้ ให้ใช้วันที่ 1
              if (!foundValidDay) {
                selectedDay = 1;
              }
            });
          },
          itemBuilder: (context, pageIndex) {
            // First page: last week of previous month
            if (pageIndex == 0) {
              DateTime prevMonth = DateTime(
                selectedDate.year,
                selectedDate.month - 1,
                1,
              );
              int prevMonthDays = DateTime(
                prevMonth.year,
                prevMonth.month + 1,
                0,
              ).day;

              List<Widget> prevWeekDays = [];
              int startDay = prevMonthDays - 6; // Start from the last week
              for (int i = 0; i < 7; i++) {
                int day = startDay + i;
                if (day > 0 && day <= prevMonthDays) {
                  prevWeekDays.add(
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDate = DateTime(
                                selectedDate.year,
                                selectedDate.month - 1,
                                day,
                              );
                              selectedDay = day;
                            });
                          },
                          child: Container(
                            width: width * 0.08,
                            height: height * 0.05,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize!,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  prevWeekDays.add(Expanded(child: Container()));
                }
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: prevWeekDays,
              );
            }

            // Last page: first week of next month
            if (pageIndex == totalWeeks + 1) {
              List<Widget> nextWeekDays = [];
              for (int i = 1; i <= 7; i++) {
                nextWeekDays.add(
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month + 1,
                              i,
                            );
                            selectedDay = i;
                          });
                        },
                        child: Container(
                          width: width * 0.08,
                          height: height * 0.05,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: Text(
                            '$i',
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize!,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: nextWeekDays,
              );
            }

            // Normal page: week in current month
            int weekIndex = pageIndex - 1;
            int startIndex = weekIndex * 7;
            int endIndex = (startIndex + 7).clamp(0, dayWidgets.length);

            if (startIndex >= dayWidgets.length) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  7,
                  (index) => Expanded(child: Container()),
                ),
              );
            }

            List<Widget> weekDays = dayWidgets.sublist(startIndex, endIndex);

            // เติมช่องว่างถ้าสัปดาห์ไม่ครบ 7 วัน
            while (weekDays.length < 7) {
              weekDays.add(Container());
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays
                  .map((day) => Expanded(child: Center(child: day)))
                  .toList(),
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          openSelectMonth = false;
        });
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        !hideMenu
                            ? Text(
                                'Calendar',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.headlineMedium!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : Text(
                                selectedTaskIds.isNotEmpty
                                    ? '${selectedTaskIds.length} Selected'
                                    : 'Select Task',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.headlineMedium!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                        Row(
                          children: [
                            if (!hideMenu)
                              GestureDetector(
                                key: iconKey,
                                onTap: () {
                                  setState(() {
                                    openSelectMonth = false;
                                  });
                                  showPopupMenuOverlay(context);
                                },
                                child: SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 12c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"></path></svg>',
                                  height: height * 0.035,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            if (hideMenu)
                              TextButton(
                                onPressed: hideMenu
                                    ? () {
                                        setState(() {
                                          selectedTaskIds.clear();
                                          hideMenu = false;
                                        });

                                        if (showArchived) {
                                          setState(() {
                                            showArchived = true;
                                          });
                                          loadDataAsync();
                                        }
                                      }
                                    : null,
                                child: Text(
                                  "Save",
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize!,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF007AFF),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        !hideMenu
                            ? SizedBox.shrink()
                            : selectedTaskIds.isNotEmpty || tasks.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (selectedTaskIds.length ==
                                        tasks.length) {
                                      selectedTaskIds.clear();
                                    } else {
                                      selectedTaskIds = tasks
                                          .map((task) => task.taskId.toString())
                                          .toList();
                                    }
                                  });
                                },
                                child: Row(
                                  children: [
                                    SvgPicture.string(
                                      selectedTaskIds.length == tasks.length
                                          ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>'
                                          : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                      height: height * 0.04,
                                      fit: BoxFit.contain,
                                      color:
                                          selectedTaskIds.length == tasks.length
                                          ? Color(0xFF007AFF)
                                          : Colors.grey,
                                    ),
                                    SizedBox(width: width * 0.01),
                                    Text(
                                      'Select All',
                                      style: TextStyle(
                                        fontSize: Get
                                            .textTheme
                                            .titleMedium!
                                            .fontSize!,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                  if (hideMenu) SizedBox(height: height * 0.01),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              key: monthButtonKey,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2F2F6),
                                borderRadius: openSelectMonth
                                    ? BorderRadius.vertical(
                                        top: Radius.circular(8),
                                      )
                                    : BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: openSelectMonth
                                      ? BorderRadius.vertical(
                                          top: Radius.circular(8),
                                        )
                                      : BorderRadius.circular(8),
                                  onTap: () {
                                    final RenderBox box =
                                        monthButtonKey.currentContext!
                                                .findRenderObject()
                                            as RenderBox;
                                    final Offset position = box.localToGlobal(
                                      Offset.zero,
                                    );

                                    setState(() {
                                      dropdownTop =
                                          position.dy +
                                          box.size.height +
                                          -(height * 0.03);
                                      dropdownLeft = position.dx;
                                      dropdownWidth = box.size.width;
                                      openSelectMonth = !openSelectMonth;
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.02,
                                      vertical: height * 0.005,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "${monthNames[selectedDate.month - 1]}, ${selectedDate.year}",
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .titleMedium!
                                                .fontSize!,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SvgPicture.string(
                                          !openSelectMonth
                                              ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"/></svg>'
                                              : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M16.293 9.293 12 13.586 7.707 9.293l-1.414 1.414L12 16.414l5.707-5.707z"/></svg>',
                                          width: width * 0.03,
                                          height: height * 0.03,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  isCalendarExpanded = !isCalendarExpanded;
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.02,
                                  vertical: height * 0.005,
                                ),
                                child: SvgPicture.string(
                                  !isCalendarExpanded
                                      ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M7 11h2v2H7zm0 4h2v2H7zm4-4h2v2h-2zm0 4h2v2h-2zm4-4h2v2h-2zm0 4h2v2h-2z"></path><path d="M5 22h14c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2h-2V2h-2v2H9V2H7v2H5c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2zM19 8l.001 12H5V8h14z"></path></svg>'
                                      : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M19 4h-3V2h-2v2h-4V2H8v2H5c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h14c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2zM5 20V7h14V6l.002 14H5z"></path><path d="M7 10v2h10V9H7z"></path></svg>',
                                  width: width * 0.03,
                                  height: height * 0.03,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: height * 0.01),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: height * 0.01),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFF2F2F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: weekDays
                                .map(
                                  (day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleSmall!
                                              .fontSize!,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          calendarWidget,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: tasksForSelectedDate.isEmpty
                        ? Center(
                            child: Text(
                              'No tasks for today',
                              style: TextStyle(
                                fontSize: Get.textTheme.titleMedium!.fontSize!,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: height * 0.01,
                                left: width * 0.03,
                                right: width * 0.03,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...tasksForSelectedDate.map((data) {
                                    return TweenAnimationBuilder(
                                      tween: Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ),
                                      duration: Duration(milliseconds: 400),
                                      curve: Curves.easeOutCirc,
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(0, (1 - value) * -30),
                                          child: Opacity(
                                            opacity: value.clamp(0.0, 1.0),
                                            child: Transform.scale(
                                              scale: 0.8 + (value * 0.2),
                                              child: child,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          top: height * 0.008,
                                        ),
                                        child: Material(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            onTap: hideMenu
                                                ? () {
                                                    if (selectedTaskIds
                                                        .contains(
                                                          data.taskId
                                                              .toString(),
                                                        )) {
                                                      selectedTaskIds.remove(
                                                        data.taskId.toString(),
                                                      );
                                                    } else {
                                                      selectedTaskIds.add(
                                                        data.taskId.toString(),
                                                      );
                                                    }
                                                    setState(() {});
                                                  }
                                                : null,
                                            child: Dismissible(
                                              key: ValueKey(data.taskId),
                                              direction:
                                                  hideMenu ||
                                                      creatingTasks[data.taskId
                                                              .toString()] ==
                                                          true
                                                  ? DismissDirection.none
                                                  : DismissDirection.endToStart,
                                              background: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                alignment:
                                                    Alignment.centerRight,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.02,
                                                ),
                                                child: Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              confirmDismiss: (direction) async {
                                                return await showDialog<bool>(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (_) {
                                                    return AlertDialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width *
                                                                0.04,
                                                            vertical:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.height *
                                                                0.02,
                                                          ),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Image.asset(
                                                            "assets/images/aleart/question.png",
                                                            height:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.height *
                                                                0.1,
                                                            fit: BoxFit.contain,
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.height *
                                                                0.02,
                                                          ),
                                                          Text(
                                                            'Do you want to delete this task?',
                                                            style: TextStyle(
                                                              fontSize: Get
                                                                  .textTheme
                                                                  .titleMedium!
                                                                  .fontSize!,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors.red,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.height *
                                                                0.02,
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(true),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Color(
                                                                    0xFF007AFF,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              fixedSize: Size(
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width,
                                                                MediaQuery.of(
                                                                      context,
                                                                    ).size.height *
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
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(false),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .red[400],
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              fixedSize: Size(
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width,
                                                                MediaQuery.of(
                                                                      context,
                                                                    ).size.height *
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
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              onDismissed: (direction) {
                                                setState(() {
                                                  tasks.removeWhere(
                                                    (t) =>
                                                        t.taskId == data.taskId,
                                                  );
                                                });
                                                deleteTaskById(
                                                  data.taskId.toString(),
                                                  false,
                                                );
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: height * 0.005,
                                                  horizontal: width * 0.01,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      selectedTaskIds.contains(
                                                        data.taskId.toString(),
                                                      )
                                                      ? Colors.black12
                                                      : data.status == "2" &&
                                                            hideMenu
                                                      ? Colors.grey[100]
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Color(0xFFE2E8F0),
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        GestureDetector(
                                                          onTap: !hideMenu
                                                              ? () =>
                                                                    handleTaskTap(
                                                                      data,
                                                                    )
                                                              : null,
                                                          child: !hideMenu
                                                              ? SvgPicture.string(
                                                                  selectedIsArchived.contains(
                                                                        data.taskId
                                                                            .toString(),
                                                                      )
                                                                      ? '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-292q78.47 0 133.23-54.77Q668-401.53 668-480t-54.77-133.23Q558.47-668 480-668t-133.23 54.77Q292-558.47 292-480t54.77 133.23Q401.53-292 480-292Zm.13 204q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>'
                                                                      : data.status ==
                                                                            "2"
                                                                      ? '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-292q78.47 0 133.23-54.77Q668-401.53 668-480t-54.77-133.23Q558.47-668 480-668t-133.23 54.77Q292-558.47 292-480t54.77 133.23Q401.53-292 480-292Zm.13 204q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>'
                                                                      : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                                                  height:
                                                                      height *
                                                                      0.04,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                  color:
                                                                      creatingTasks[data
                                                                              .taskId
                                                                              .toString()] ==
                                                                          true
                                                                      ? Colors
                                                                            .grey[300]
                                                                      : selectedIsArchived.contains(
                                                                          data.taskId
                                                                              .toString(),
                                                                        )
                                                                      ? Color(
                                                                          0xFF007AFF,
                                                                        )
                                                                      : data.status ==
                                                                            "2"
                                                                      ? Color(
                                                                          0xFF007AFF,
                                                                        )
                                                                      : Colors
                                                                            .grey,
                                                                )
                                                              : SvgPicture.string(
                                                                  selectedTaskIds.contains(
                                                                        data.taskId
                                                                            .toString(),
                                                                      )
                                                                      ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>'
                                                                      : '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                                                  height:
                                                                      height *
                                                                      0.04,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                  color:
                                                                      selectedTaskIds.contains(
                                                                        data.taskId
                                                                            .toString(),
                                                                      )
                                                                      ? Color(
                                                                          0xFF007AFF,
                                                                        )
                                                                      : Colors
                                                                            .grey,
                                                                ),
                                                        ),
                                                        SizedBox(
                                                          width: width * 0.01,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding: EdgeInsets.only(
                                                                  top:
                                                                      height *
                                                                      0.005,
                                                                  bottom:
                                                                      height *
                                                                      0.005,
                                                                  right:
                                                                      width *
                                                                      0.02,
                                                                ),
                                                                child: InkWell(
                                                                  onTap:
                                                                      !hideMenu
                                                                      ? creatingTasks[data.taskId.toString()] ==
                                                                                true
                                                                            ? null
                                                                            : () {
                                                                                if (!hideMenu) {
                                                                                  setState(
                                                                                    () {
                                                                                      hideMenu = false;
                                                                                      openSelectMonth = false;
                                                                                    },
                                                                                  );
                                                                                }
                                                                                Get.to(
                                                                                  () => TasksdetailPage(
                                                                                    taskId: data.taskId,
                                                                                  ),
                                                                                );
                                                                              }
                                                                      : null,
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Expanded(
                                                                        child: Column(
                                                                          children: [
                                                                            Row(
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Text(
                                                                                    data.taskName,
                                                                                    style: TextStyle(
                                                                                      fontSize: Get.textTheme.titleMedium!.fontSize!,
                                                                                      color:
                                                                                          creatingTasks[data.taskId.toString()] ==
                                                                                              true
                                                                                          ? Colors.grey
                                                                                          : selectedIsArchived.contains(
                                                                                                  data.taskId.toString(),
                                                                                                ) ||
                                                                                                data.status ==
                                                                                                    "2"
                                                                                          ? Colors.grey
                                                                                          : Colors.black,
                                                                                    ),
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                  ),
                                                                                ),
                                                                                data.priority.isEmpty
                                                                                    ? SizedBox.shrink()
                                                                                    : Padding(
                                                                                        padding: EdgeInsets.symmetric(
                                                                                          horizontal:
                                                                                              width *
                                                                                              0.01,
                                                                                        ),
                                                                                        child: Container(
                                                                                          width:
                                                                                              width *
                                                                                              0.03,
                                                                                          height:
                                                                                              height *
                                                                                              0.03,
                                                                                          decoration: BoxDecoration(
                                                                                            shape: BoxShape.circle,
                                                                                            color:
                                                                                                data.priority ==
                                                                                                    '3'
                                                                                                ? Colors.red
                                                                                                : data.priority ==
                                                                                                      '2'
                                                                                                ? Colors.orange
                                                                                                : Colors.green,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                              ],
                                                                            ),
                                                                            Row(
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      data.description.isEmpty
                                                                                          ? SizedBox.shrink()
                                                                                          : Text(
                                                                                              data.description,
                                                                                              style: TextStyle(
                                                                                                fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                                color: Colors.grey,
                                                                                              ),
                                                                                              maxLines: 2,
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                            ),
                                                                                      showDetailPrivateOrGroup(
                                                                                            data,
                                                                                          ).isEmpty
                                                                                          ? SizedBox.shrink()
                                                                                          : Text(
                                                                                              showDetailPrivateOrGroup(
                                                                                                data,
                                                                                              ),
                                                                                              style: TextStyle(
                                                                                                fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                                color: Color(
                                                                                                  0xFF007AFF,
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                      Row(
                                                                                        children: [
                                                                                          formatDateDisplay(
                                                                                                data.notifications,
                                                                                              ).isEmpty
                                                                                              ? SizedBox.shrink()
                                                                                              : Container(
                                                                                                  decoration: BoxDecoration(
                                                                                                    border: Border.all(
                                                                                                      width: 0.5,
                                                                                                      color: Colors.red,
                                                                                                    ),
                                                                                                    borderRadius: BorderRadius.circular(
                                                                                                      6,
                                                                                                    ),
                                                                                                  ),
                                                                                                  padding: EdgeInsets.symmetric(
                                                                                                    horizontal:
                                                                                                        width *
                                                                                                        0.01,
                                                                                                  ),
                                                                                                  child: Row(
                                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                                    children: [
                                                                                                      SvgPicture.string(
                                                                                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M13 7h-2v6h6v-2h-4z"></path></svg>',
                                                                                                        width:
                                                                                                            width *
                                                                                                            0.04,
                                                                                                        fit: BoxFit.contain,
                                                                                                        color: Colors.red,
                                                                                                      ),
                                                                                                      Text(
                                                                                                        " Due ",
                                                                                                        style: TextStyle(
                                                                                                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                                          color: Colors.red,
                                                                                                        ),
                                                                                                      ),
                                                                                                      Text(
                                                                                                        formatDateDisplay(
                                                                                                          data.notifications,
                                                                                                        ),
                                                                                                        style: TextStyle(
                                                                                                          fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                                          color: Colors.red,
                                                                                                        ),
                                                                                                      ),
                                                                                                    ],
                                                                                                  ),
                                                                                                ),
                                                                                          FutureBuilder<
                                                                                            List<
                                                                                              String
                                                                                            >
                                                                                          >(
                                                                                            future: showTimeRemineMeBefore(
                                                                                              data,
                                                                                              notiTasks: data.notifications,
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
                                                                                                                0.04,
                                                                                                            fit: BoxFit.contain,
                                                                                                            color: Colors.red,
                                                                                                          ),
                                                                                                        ),
                                                                                                        ...snapshot.data!.map(
                                                                                                          (
                                                                                                            time,
                                                                                                          ) => Padding(
                                                                                                            padding: EdgeInsets.only(
                                                                                                              right:
                                                                                                                  width *
                                                                                                                  0.01,
                                                                                                            ),
                                                                                                            child: Text(
                                                                                                              time,
                                                                                                              style: TextStyle(
                                                                                                                fontSize: Get.textTheme.labelMedium!.fontSize!,
                                                                                                                color: Colors.red,
                                                                                                              ),
                                                                                                            ),
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
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
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
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                  ),
                  if (hideMenu)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.01),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: width * 0.12,
                            decoration: BoxDecoration(
                              color: Color(0xFFF2F2F6),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: selectedTaskIds.isNotEmpty
                                    ? () {
                                        Get.defaultDialog(
                                          title: '',
                                          titlePadding: EdgeInsets.zero,
                                          backgroundColor: Colors.white,
                                          barrierDismissible: false,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.04,
                                            vertical:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.01,
                                          ),
                                          content: WillPopScope(
                                            onWillPop: () async => false,
                                            child: Column(
                                              children: [
                                                Image.asset(
                                                  "assets/images/aleart/question.png",
                                                  height:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.height *
                                                      0.1,
                                                  fit: BoxFit.contain,
                                                ),
                                                SizedBox(
                                                  height:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.height *
                                                      0.02,
                                                ),
                                                Text(
                                                  'Do you want to delete this board?',
                                                  style: TextStyle(
                                                    fontSize: Get
                                                        .textTheme
                                                        .titleMedium!
                                                        .fontSize!,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.red,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                SizedBox(
                                                  height:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.height *
                                                      0.01,
                                                ),
                                                Text(
                                                  'Are you sure you want to delete this board and all its tasks.',
                                                  style: TextStyle(
                                                    fontSize: Get
                                                        .textTheme
                                                        .titleSmall!
                                                        .fontSize!,
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
                                                    setState(() {
                                                      hideMenu = false;
                                                    });
                                                    deleteTaskById(
                                                      selectedTaskIds,
                                                      true,
                                                    );
                                                    selectedTaskIds.clear();
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Color(
                                                      0xFF007AFF,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    elevation: 1,
                                                    fixedSize: Size(
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width,
                                                      MediaQuery.of(
                                                            context,
                                                          ).size.height *
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
                                                    backgroundColor:
                                                        Colors.red[400],
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    fixedSize: Size(
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width,
                                                      MediaQuery.of(
                                                            context,
                                                          ).size.height *
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
                                      }
                                    : null,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.01,
                                    vertical: height * 0.005,
                                  ),
                                  child: SvgPicture.string(
                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M5 20a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8h2V6h-4V4a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v2H3v2h2zM9 4h6v2H9zM8 8h9v12H7V8z"></path><path d="M9 10h2v8H9zm4 0h2v8h-2z"></path></svg>',
                                    width: width * 0.035,
                                    height: height * 0.035,
                                    fit: BoxFit.contain,
                                    color: selectedTaskIds.isNotEmpty
                                        ? Colors.red
                                        : Colors.grey,
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
              if (openSelectMonth)
                Positioned(
                  top: dropdownTop,
                  left: dropdownLeft,
                  child: Container(
                    width: dropdownWidth,
                    decoration: BoxDecoration(
                      color: Color(0xFFF2F2F6),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      children: monthNames.asMap().entries.map((entry) {
                        int idx = entry.key;
                        String month = entry.value;

                        final isSelected = selectedDate.month == (idx + 1);
                        final isCurrentMonth =
                            DateTime.now().month == (idx + 1);

                        Color backgroundColor;

                        if (isSelected) {
                          backgroundColor = Color(0xFF3B82F6).withOpacity(0.8);
                        } else if (isCurrentMonth) {
                          backgroundColor = Colors.black12;
                        } else {
                          backgroundColor = Colors.transparent;
                        }

                        return Material(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() {
                                selectedDate = DateTime(
                                  selectedDate.year,
                                  idx + 1,
                                  selectedDay,
                                );
                                openSelectMonth = false;
                              });
                            },
                            child: Container(
                              width: dropdownWidth,
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                vertical: height * 0.01,
                              ),
                              child: Text(
                                month,
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color: !isSelected
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> showTimeRemineMeBefore(
    model.Task task, {
    required List<model.Notification> notiTasks,
  }) async {
    final rawData = box.read('userDataAll');
    final data = model.AllDataUserGetResponst.fromJson(rawData);
    final List<String> remindTimes = [];

    for (var notiTask in notiTasks) {
      DateTime? remindTimestamp;
      bool isGroup = data.boardgroup.any(
        (b) => b.boardId.toString() == task.boardId.toString(),
      );

      if (isGroup) {
        // DocumentSnapshot
        final docSnapshot = await FirebaseFirestore.instance
            .collection('BoardTasks')
            .doc(task.taskId.toString())
            .collection('Notifications')
            .doc(notiTask.notificationId.toString())
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null && data['remindMeBefore'] != null) {
            remindTimestamp = (data['remindMeBefore'] as Timestamp).toDate();
          }
        }
      } else {
        // QuerySnapshot
        final querySnapshot = await FirebaseFirestore.instance
            .collection('Notifications')
            .doc(box.read('userProfile')['email'])
            .collection('Tasks')
            .where('taskID', isEqualTo: task.taskId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          if (data['remindMeBefore'] != null) {
            remindTimestamp = (data['remindMeBefore'] as Timestamp).toDate();
          }
        }
      }

      if (remindTimestamp != null && remindTimestamp.isAfter(DateTime.now())) {
        final timeString =
            "${remindTimestamp.hour.toString().padLeft(2, '0')}:${remindTimestamp.minute.toString().padLeft(2, '0')}";
        remindTimes.add(timeString);
      }
    }

    return remindTimes;
  }

  // ฟังก์ชันสำหรับกรองงานตามวันที่ dueDate
  List<model.Task> getTasksForSelectedDate() {
    DateTime targetDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDay,
    );

    return tasks.where((task) {
      // ตรวจสอบ notifications แต่ละตัวของ task
      for (var notification in task.notifications) {
        if (notification.dueDate.isNotEmpty) {
          try {
            DateTime dueDate = DateTime.parse(notification.dueDate).toLocal();
            DateTime dueDateOnly = DateTime(
              dueDate.year,
              dueDate.month,
              dueDate.day,
            );

            if (dueDateOnly.isAtSameMomentAs(targetDate)) {
              return true;
            }
          } catch (e) {
            // หากไม่สามารถแปลงวันที่ได้ ให้ข้ามไป
            continue;
          }
        }
      }
      return false;
    }).toList();
  }

  // ฟังก์ชันเช็คว่าวันนั้นมีงานหรือไม่
  bool hasTasksOnDay(int day) {
    DateTime targetDate = DateTime(selectedDate.year, selectedDate.month, day);

    return tasks.any((task) {
      for (var notification in task.notifications) {
        if (notification.dueDate.isNotEmpty) {
          try {
            DateTime dueDate = DateTime.parse(notification.dueDate).toLocal();
            DateTime dueDateOnly = DateTime(
              dueDate.year,
              dueDate.month,
              dueDate.day,
            );

            if (dueDateOnly.isAtSameMomentAs(targetDate)) {
              return true;
            }
          } catch (e) {
            continue;
          }
        }
      }
      return false;
    });
  }

  void hideMainMenu() {
    mainMenuEntry?.remove();
    mainMenuEntry = null;
  }

  void hideMenus() {
    hideMainMenu();
  }

  void showPopupMenuOverlay(BuildContext context) {
    final RenderBox renderBox =
        iconKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    var height = MediaQuery.of(context).size.height;

    mainMenuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: hideMenus,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left:
                offset.dx +
                size.width -
                (MediaQuery.of(context).size.width * 0.5),
            top: offset.dy + size.height,
            child: Material(
              elevation: 1,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildPopupItem(
                    context,
                    title: 'Select Task',
                    trailing: SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="M9.999 13.587 7.7 11.292l-1.412 1.416 3.713 3.705 6.706-6.706-1.414-1.414z"></path></svg>',
                      height: height * 0.025,
                      fit: BoxFit.contain,
                    ),
                    onTap: () {
                      hideMenus();
                      setState(() {
                        hideMenu = true;
                      });
                    },
                  ),
                  buildPopupItem(
                    context,
                    title: '${showArchived ? 'Hide' : 'Show'} Completed',
                    trailing: SvgPicture.string(
                      showArchived
                          ? '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 19c.946 0 1.81-.103 2.598-.281l-1.757-1.757c-.273.021-.55.038-.841.038-5.351 0-7.424-3.846-7.926-5a8.642 8.642 0 0 1 1.508-2.297L4.184 8.305c-1.538 1.667-2.121 3.346-2.132 3.379a.994.994 0 0 0 0 .633C2.073 12.383 4.367 19 12 19zm0-14c-1.837 0-3.346.396-4.604.981L3.707 2.293 2.293 3.707l18 18 1.414-1.414-3.319-3.319c2.614-1.951 3.547-4.615 3.561-4.657a.994.994 0 0 0 0-.633C21.927 11.617 19.633 5 12 5zm4.972 10.558-2.28-2.28c.19-.39.308-.819.308-1.278 0-1.641-1.359-3-3-3-.459 0-.888.118-1.277.309L8.915 7.501A9.26 9.26 0 0 1 12 7c5.351 0 7.424 3.846 7.926 5-.302.692-1.166 2.342-2.954 3.558z"></path></svg>'
                          : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 9a3.02 3.02 0 0 0-3 3c0 1.642 1.358 3 3 3 1.641 0 3-1.358 3-3 0-1.641-1.359-3-3-3z"></path><path d="M12 5c-7.633 0-9.927 6.617-9.948 6.684L1.946 12l.105.316C2.073 12.383 4.367 19 12 19s9.927-6.617 9.948-6.684l.106-.316-.105-.316C21.927 11.617 19.633 5 12 5zm0 12c-5.351 0-7.424-3.846-7.926-5C4.578 10.842 6.652 7 12 7c5.351 0 7.424 3.846 7.926 5-.504 1.158-2.578 5-7.926 5z"></path></svg>',
                      height: height * 0.025,
                      fit: BoxFit.contain,
                    ),
                    onTap: () {
                      setState(() => showArchived = !showArchived);
                      hideMenus();
                      loadDataAsync();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(mainMenuEntry!);
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
        padding: EdgeInsets.symmetric(horizontal: width * 0.04),
        width: width * 0.5,
        height: height * 0.05,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Get.textTheme.titleSmall!.fontSize!,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void handleTaskTap(model.Task data) async {
    if (!mounted) return;
    final taskId = data.taskId;
    setState(() => hideMenu = false);

    if (data.status == "2") {
      await showArchiveTask(taskId.toString());
      selectedIsArchived.clear();
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (selectedIsArchived.contains(taskId.toString())) {
      selectedIsArchived.remove(taskId.toString());
    } else {
      selectedIsArchived.add(taskId.toString());
    }

    if (showArchived) {
      await finishAllSelectedTasks();
      selectedIsArchived.clear();
      return;
    }

    debounceTimer?.cancel();

    if (selectedIsArchived.isEmpty) return;
    debounceTimer = Timer(Duration(seconds: 1), () async {
      if (selectedIsArchived.isNotEmpty && !isFinishing) {
        isFinishing = true;
        await finishAllSelectedTasks();
        selectedIsArchived.clear();
        isFinishing = false;
      }
    });
  }

  Future<void> finishAllSelectedTasks() async {
    if (selectedIsArchived.isEmpty) return;

    List<Future<void>> finishTasks = [];

    for (var taskId in selectedIsArchived) {
      finishTasks.add(todayTasksFinish(taskId));
    }
    await Future.wait(finishTasks);
    selectedIsArchived.clear();
    if (mounted) setState(() {});
  }

  Future<void> todayTasksFinish(String id) async {
    if (!mounted) return;

    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = model.AllDataUserGetResponst.fromJson(userDataJson);
    final appData = Provider.of<Appdata>(context, listen: false);

    final index = existingData.tasks.indexWhere(
      (t) => t.taskId.toString() == id,
    );
    if (index == -1) return;

    existingData.tasks[index].status = '2';
    box.write('userDataAll', existingData.toJson());

    if (!showArchived) {
      appData.showMyTasks.removeTaskById(id);
      tasks.removeWhere((t) => t.taskId.toString() == id);
    } else {
      await loadDataAsync();
    }

    if (mounted) setState(() {});

    url = await loadAPIEndpoint();

    var response = await http.put(
      Uri.parse("$url/taskfinish/$id"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
    );

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      response = await http.put(
        Uri.parse("$url/taskfinish/$id"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
    }
  }

  Future<void> showArchiveTask(String id) async {
    if (!mounted) return;

    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = model.AllDataUserGetResponst.fromJson(userDataJson);

    final index = existingData.tasks.indexWhere(
      (t) => t.taskId.toString() == id,
    );
    if (index == -1) return;

    existingData.tasks[index].status = '0';
    box.write('userDataAll', existingData.toJson());

    await loadDataAsync();

    if (mounted) setState(() {});

    url = await loadAPIEndpoint();

    var response = await http.put(
      Uri.parse("$url/updatestatus/$id"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: jsonEncode({"status": "0"}),
    );

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      response = await http.put(
        Uri.parse("$url/updatestatus/$id"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: jsonEncode({"status": "0"}),
      );
    }
  }

  void deleteTaskById(dynamic ids, bool select) async {
    if (!mounted) return;

    dynamic taskIdPayload;
    List<String> idList;
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = model.AllDataUserGetResponst.fromJson(userDataJson);
    final appData = Provider.of<Appdata>(context, listen: false);

    if (ids is String) {
      idList = [ids];
      taskIdPayload = ids;
    } else if (ids is List && ids.every((e) => e is String)) {
      idList = List<String>.from(ids);
      taskIdPayload = idList;
    } else {
      throw ArgumentError("Invalid ids parameter");
    }

    for (var id in idList) {
      appData.showMyTasks.removeTaskById(id);
      existingData.tasks.removeWhere((t) => t.taskId.toString() == id);
      tasks.removeWhere((t) => t.taskId.toString() == id);
    }
    box.write('userDataAll', existingData.toJson());

    if (mounted) setState(() {});

    final endpoint = select ? "deltask" : "deltask/$taskIdPayload";
    final requestBody = select ? {"task_id": taskIdPayload} : null;
    await deleteWithRetry(endpoint, requestBody);
  }

  Future<http.Response> deleteWithRetry(
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    url = await loadAPIEndpoint();

    final token = box.read('accessToken');
    Uri uri = Uri.parse("$url/$endpoint");

    Future<http.Response> sendRequest(String token) {
      return body == null
          ? http.delete(
              uri,
              headers: {
                "Content-Type": "application/json; charset=utf-8",
                "Authorization": "Bearer $token",
              },
            )
          : http.delete(
              uri,
              headers: {
                "Content-Type": "application/json; charset=utf-8",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode(body),
            );
    }

    var response = await sendRequest(token);

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      final newToken = box.read('accessToken');
      if (newToken != null) {
        response = await sendRequest(newToken);
      }
    }

    return response;
  }

  String showDetailPrivateOrGroup(model.Task task) {
    final rawData = box.read('userDataAll');
    final data = model.AllDataUserGetResponst.fromJson(rawData);
    bool isPrivate = (data.board).any(
      (b) => b.boardId.toString() == task.boardId.toString(),
    );
    bool isGroup = (data.boardgroup).any(
      (b) => b.boardId.toString() == task.boardId.toString(),
    );
    if (isPrivate) return 'Private';
    if (isGroup) return 'Group';

    return '';
  }

  String formatDateDisplay(List<model.Notification> notifications) {
    if (notifications.isEmpty) return '';

    final now = DateTime.now();
    final dueDate = DateTime.parse(notifications.first.dueDate).toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (dueDateDay.isAtSameMomentAs(today)) {
      if (dueDate.isAfter(now)) {
        final hour = dueDate.hour.toString().padLeft(2, '0');
        final minute = dueDate.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }
      return '';
    }

    if (dueDateDay.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    }

    if (dueDateDay.isBefore(yesterday)) {
      final day = dueDate.day.toString().padLeft(2, '0');
      final month = dueDate.month.toString().padLeft(2, '0');
      final year = (dueDate.year % 100).toString().padLeft(2, '0');
      final hour = dueDate.hour.toString().padLeft(2, '0');
      final minute = dueDate.minute.toString().padLeft(2, '0');
      return '$day/$month/$year, $hour:$minute';
    }
    if (dueDateDay.isAfter(yesterday)) {
      final hour = dueDate.hour.toString().padLeft(2, '0');
      final minute = dueDate.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return '';
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
