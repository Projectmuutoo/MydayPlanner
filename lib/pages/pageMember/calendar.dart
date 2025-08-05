import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/request/todayTasksCreatePostRequest.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart'
    as model;
import 'package:mydayplanner/pages/pageMember/detailBoards/tasksDetail.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:rxdart/rxdart.dart' as rxdart;
import 'package:http/http.dart' as http;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage>
    with WidgetsBindingObserver {
  var box = GetStorage();
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
  bool addTask = false;
  // 📥 Text Editing Controllers
  final TextEditingController addTasknameCtl = TextEditingController();
  final TextEditingController addDescriptionCtl = TextEditingController();
  // 🧠 Focus Nodes
  final FocusNode addTasknameFocusNode = FocusNode();
  final FocusNode addDescriptionFocusNode = FocusNode();
  final GlobalKey addFormKey = GlobalKey();
  bool isTyping = false;
  String? selectedReminder;
  bool isShowMenuRemind = false;
  DateTime? customReminderDateTime;
  bool isCustomReminderApplied = false;
  bool isShowMenuPriority = false;
  String? focusedCategory;
  int? selectedPriority;
  final ScrollController scrollController = ScrollController();
  int? selectedBeforeMinutes;
  String? selectedRepeat;
  bool isKeyboardVisible = false;
  bool wasKeyboardOpen = false;
  Timer? _timer;
  bool isCreatingTask = false;
  StreamSubscription? combinedSubscription;
  StreamSubscription? notificationSubscription;
  bool isNavigatingToToday = false;
  int selectedWeekIndex = 0;

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    loadDataAsync();

    addTasknameFocusNode.addListener(() {
      if (addTasknameFocusNode.hasFocus && addTask) {
        Future.delayed(Duration(milliseconds: 200), () {
          _scrollToAddForm();
        });
      }
    });

    addDescriptionFocusNode.addListener(() {
      if (addDescriptionFocusNode.hasFocus && addTask) {
        _scrollToAddForm();
      }
    });
  }

  Future<void> loadDataAsync() async {
    if (!mounted) return;

    final rawData = box.read('userDataAll');
    final tasksData = model.AllDataUserGetResponst.fromJson(rawData);

    // กรอง tasks จาก local storage
    List<model.Task> localTasks = tasksData.tasks
        .where(
          (task) => (showArchived
              ? ['0', '1', '2'].contains(task.status)
              : task.status != '2'),
        )
        .toList();

    localTasks.sort((a, b) {
      DateTime dateA = DateTime.parse(a.createdAt);
      DateTime dateB = DateTime.parse(b.createdAt);
      return dateA.compareTo(dateB);
    });

    setState(() {
      tasks = localTasks;
    });

    // ตั้งค่า Firebase listeners
    _setupFirebaseListeners(localTasks);
  }

  void _setupFirebaseListeners(List<model.Task> localTasks) {
    // ยกเลิก subscriptions เก่าทั้งหมด
    combinedSubscription?.cancel();
    notificationSubscription?.cancel();

    List<Stream<QuerySnapshot>> boardStreams = [];

    // สร้าง stream สำหรับแต่ละ board
    Set<String> uniqueBoardIds = localTasks
        .map((task) => task.boardId.toString())
        .toSet();
    for (var boardId in uniqueBoardIds) {
      final tasksStream = FirebaseFirestore.instance
          .collection('Boards')
          .doc(boardId)
          .collection('Tasks')
          .snapshots();
      boardStreams.add(tasksStream);
    }

    final combinedTasksStream = rxdart.Rx.combineLatestList(boardStreams);

    combinedSubscription = combinedTasksStream.listen((taskSnapshots) async {
      if (!mounted) return;

      // ยกเลิก notification subscription เก่าก่อน
      notificationSubscription?.cancel();

      List<model.Task> allFirebaseTasks = [];
      Map<String, Stream<QuerySnapshot>> notificationStreamsMap = {};

      // รวม tasks จากทุก board
      for (var tasksSnapshot in taskSnapshots) {
        for (var doc in tasksSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final taskId = data['taskID'].toString();
          final status = data['status'].toString();

          // กรองตาม showArchived
          if (!showArchived && status == '2') continue;

          // สร้าง Task object
          final firebaseTask = model.Task(
            assigned: data['assigned'] ?? [],
            attachments: data['attachments'] ?? [],
            boardId: data['boardID'].toString(),
            checklists: data['checklists'] ?? [],
            createBy: int.parse(data['createBy'].toString()),
            createdAt: (data['createAt'] as Timestamp)
                .toDate()
                .toIso8601String(),
            description: data['description']?.toString() ?? '',
            notifications: [], // จะเติมจาก notifications stream
            priority: data['priority']?.toString() ?? '',
            status: status,
            taskId: int.parse(taskId),
            taskName: data['taskName'].toString(),
          );

          allFirebaseTasks.add(firebaseTask);

          // เตรียม notification stream สำหรับ task นี้
          notificationStreamsMap[taskId] = FirebaseFirestore.instance
              .collection('BoardTasks')
              .doc(taskId)
              .collection('Notifications')
              .snapshots();
        }
      }

      // หากไม่มี Firebase tasks ให้แสดงเฉพาะ Local
      if (allFirebaseTasks.isEmpty) {
        _updateDisplayTasks([]);
        return;
      }

      // หากไม่มี notification streams
      if (notificationStreamsMap.isEmpty) {
        _updateDisplayTasks(allFirebaseTasks);
        return;
      }

      // รวม notification streams
      List<Stream<QuerySnapshot>> notificationStreams = notificationStreamsMap
          .values
          .toList();
      List<String> taskIdsOrder = notificationStreamsMap.keys.toList();

      final combinedNotificationStream = rxdart.Rx.combineLatestList(
        notificationStreams,
      );

      // ใช้ notificationSubscription แยกจาก combinedSubscription
      notificationSubscription = combinedNotificationStream.listen((
        notificationSnapshots,
      ) async {
        if (!mounted) return;

        // สร้าง Map สำหรับเก็บ notifications ของแต่ละ task
        Map<String, List<model.Notification>> taskNotificationsMap = {};

        for (
          int i = 0;
          i < notificationSnapshots.length && i < taskIdsOrder.length;
          i++
        ) {
          String taskId = taskIdsOrder[i];
          List<model.Notification> notifications = [];

          final notificationSnapshot = notificationSnapshots[i];
          for (var notifDoc in notificationSnapshot.docs) {
            final notifData = notifDoc.data() as Map<String, dynamic>;
            notifications.add(
              model.Notification(
                beforeDueDate: notifData['beforeDueDate'] != null
                    ? (notifData['beforeDueDate'] as Timestamp)
                          .toDate()
                          .toIso8601String()
                    : '',
                createdAt: (notifData['createdAt'] as Timestamp)
                    .toDate()
                    .toIso8601String(),
                dueDate: (notifData['dueDate'] as Timestamp)
                    .toDate()
                    .toIso8601String(),
                isSend: notifData['isSend'].toString(),
                notificationId: notifData['notificationID'] ?? '',
                recurringPattern: notifData['recurringPattern'] ?? '',
                taskId: notifData['taskID'] ?? '',
              ),
            );
          }

          taskNotificationsMap[taskId] = notifications;
        }

        // อัพเดท Firebase tasks ด้วย notifications
        List<model.Task> finalFirebaseTasks = allFirebaseTasks.map((task) {
          String taskIdStr = task.taskId.toString();
          List<model.Notification> notifications =
              taskNotificationsMap[taskIdStr] ?? [];

          return model.Task(
            assigned: task.assigned,
            attachments: task.attachments,
            boardId: task.boardId,
            checklists: task.checklists,
            createBy: task.createBy,
            createdAt: task.createdAt,
            description: task.description,
            notifications: notifications,
            priority: task.priority,
            status: task.status,
            taskId: task.taskId,
            taskName: task.taskName,
          );
        }).toList();

        _updateDisplayTasks(finalFirebaseTasks);
      });
    });
  }

  void _updateDisplayTasks(List<model.Task> firebaseTasksList) {
    if (!mounted) return;

    final rawData = box.read('userDataAll');
    final tasksData = model.AllDataUserGetResponst.fromJson(rawData);

    // กรองข้อมูล Local Tasks
    List<model.Task> localTasks = tasksData.tasks
        .where(
          (task) => (showArchived
              ? ['0', '1', '2'].contains(task.status)
              : task.status != '2'),
        )
        .toList();

    // สร้าง Set ของ taskId ที่มีใน Firebase
    Set<int> firebaseTaskIds = firebaseTasksList.map((t) => t.taskId).toSet();

    // กรอง Local Tasks ให้เหลือเฉพาะที่ไม่มีใน Firebase
    List<model.Task> filteredLocalTasks = localTasks
        .where((localTask) => !firebaseTaskIds.contains(localTask.taskId))
        .toList();

    // รวม Firebase Tasks (มี priority สูงสุด) + Local Tasks ที่ไม่ซ้ำ
    List<model.Task> combinedTasks = [
      ...firebaseTasksList, // Firebase tasks ก่อน (realtime)
      ...filteredLocalTasks, // Local tasks ที่ไม่ซ้ำกับ Firebase
    ];

    // เรียงลำดับตาม createdAt
    combinedTasks.sort((a, b) {
      DateTime dateA = DateTime.parse(a.createdAt);
      DateTime dateB = DateTime.parse(b.createdAt);
      return dateA.compareTo(dateB);
    });

    setState(() {
      tasks = combinedTasks;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    addTasknameCtl.dispose();
    addDescriptionCtl.dispose();
    addTasknameFocusNode.dispose();
    addDescriptionFocusNode.dispose();
    scrollController.dispose();
    _pageController.dispose();
    debounceTimer?.cancel();
    timer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    //ทั้งหมดคือดักจับ keyboard และการบันทึก task
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newKeyboardVisible = bottomInset > 0;

    if (newKeyboardVisible != isKeyboardVisible) {
      setState(() {
        isKeyboardVisible = newKeyboardVisible;
      });
      if (newKeyboardVisible) {
        wasKeyboardOpen = true;
      }
      if (!newKeyboardVisible && wasKeyboardOpen) {
        wasKeyboardOpen = false;

        setState(() {
          addTask = false;
        });
        _saveData(addTasknameCtl.text, addDescriptionCtl.text);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    //ทั้งหมดคือการบันทึก task ที่ user พิมไว้และกดออกแอป มันจะบันทึกให้
    if (state == AppLifecycleState.paused) {
      _saveData(addTasknameCtl.text, addDescriptionCtl.text);
      _timer = Timer.periodic(Duration(seconds: 3), (timer) {
        loadDataAsync();
      });
    }
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
              selectedDate = DateTime(selectedDate.year, selectedDate.month, i);
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

      // หาสัปดาห์ที่มี selectedDay
      if (!isNavigatingToToday) {
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
      }

      // Initialize PageController if not exists or update it
      _pageController = PageController(initialPage: selectedWeekIndex + 1);

      // Animate to correct page if needed
      if (!isNavigatingToToday) {
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
      }

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
            // ถ้ากำลัง navigate ไป today ให้ข้ามการทำงานของ onPageChanged
            if (isNavigatingToToday) {
              return;
            }

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
              int newSelectedDay = selectedDay; // เก็บค่าเดิมไว้ก่อน

              for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
                int dayIndex = weekStart + dayOffset;
                if (dayIndex >= 0 && dayIndex < dayWidgets.length) {
                  int actualDay = dayIndex - adjustedStartWeekday + 1;
                  if (actualDay > 0 && actualDay <= daysInMonth) {
                    newSelectedDay = actualDay;
                    foundValidDay = true;
                    break;
                  }
                }
              }

              // ถ้าไม่เจอวันที่ถูกต้องในสัปดาห์นี้ ให้ใช้วันที่ 1
              if (!foundValidDay) {
                newSelectedDay = 1;
              }

              // อัพเดททั้ง selectedDay และ selectedDate
              selectedDay = newSelectedDay;
              selectedDate = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDay,
              );
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
        if (hideMenu) {
          setState(() {
            addTask = true;
          });
        }
        setState(() {
          openSelectMonth = false;
          isCalendarExpanded = false;
          addTask = !addTask;
        });
        Future.delayed(Duration(milliseconds: 200), () {
          addTasknameFocusNode.requestFocus();
        });
        _saveData(addTasknameCtl.text, addDescriptionCtl.text);
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        addTask = false;
                      });
                      _saveData(addTasknameCtl.text, addDescriptionCtl.text);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                      color: Colors.white,
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
                                    showPopupMenuOverlay(context);
                                  },
                                  child: SvgPicture.string(
                                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 12c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"></path></svg>',
                                    height: height * 0.035,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              if (hideMenu || addTask)
                                TextButton(
                                  onPressed: hideMenu
                                      ? () {
                                          setState(() {
                                            selectedTaskIds.clear();
                                            hideMenu = false;
                                            openSelectMonth = false;
                                          });

                                          if (showArchived) {
                                            setState(() {
                                              showArchived = true;
                                            });
                                            loadDataAsync();
                                          }
                                        }
                                      : () {
                                          setState(() {
                                            addTask = false;
                                            openSelectMonth = false;
                                          });
                                          _saveData(
                                            addTasknameCtl.text,
                                            addDescriptionCtl.text,
                                          );
                                        },
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        addTask = false;
                      });
                      _saveData(addTasknameCtl.text, addDescriptionCtl.text);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                      color: Colors.transparent,
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
                              if (selectedDate.year != DateTime.now().year ||
                                  selectedDate.month != DateTime.now().month ||
                                  selectedDate.day != DateTime.now().day)
                                Material(
                                  color: Color(0xFFF2F2F6),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        // รีเซ็ตกลับไปวันนี้
                                        DateTime today = DateTime.now();
                                        selectedDate = today;
                                        selectedDay = today.day;
                                        openSelectMonth = false;
                                        isNavigatingToToday = true; // ตั้ง flag
                                      });

                                      // ใช้ addPostFrameCallback เพื่อให้ setState ทำงานเสร็จก่อน
                                      WidgetsBinding.instance.addPostFrameCallback((
                                        _,
                                      ) {
                                        if (!isCalendarExpanded &&
                                            _pageController.hasClients) {
                                          DateTime today = DateTime.now();

                                          // คำนวณใหม่หลังจาก setState เสร็จแล้ว
                                          int daysInMonth = DateTime(
                                            today.year,
                                            today.month + 1,
                                            0,
                                          ).day;
                                          DateTime firstDayOfMonth = DateTime(
                                            today.year,
                                            today.month,
                                            1,
                                          );
                                          int startWeekday =
                                              firstDayOfMonth.weekday;
                                          int adjustedStartWeekday =
                                              startWeekday == 7
                                              ? 0
                                              : startWeekday;

                                          // ตรวจสอบว่าต้องใช้ 6 สัปดาห์หรือไม่
                                          bool needsSixWeeks =
                                              (daysInMonth == 31 &&
                                                  adjustedStartWeekday >= 5) ||
                                              (daysInMonth == 30 &&
                                                  adjustedStartWeekday == 6);
                                          int totalWeeks = needsSixWeeks
                                              ? 6
                                              : 5;

                                          // หาสัปดาห์ที่วันนี้อยู่
                                          int todayIndex =
                                              adjustedStartWeekday +
                                              today.day -
                                              1;
                                          int todayWeekIndex = (todayIndex / 7)
                                              .floor();

                                          // ตรวจสอบให้แน่ใจว่าไม่เกินจำนวนสัปดาห์ที่มี
                                          todayWeekIndex = todayWeekIndex.clamp(
                                            0,
                                            totalWeeks - 1,
                                          );
                                          // อัพเดท selectedWeekIndex ให้ตรงกับสัปดาห์ที่คำนวณได้
                                          setState(() {
                                            selectedWeekIndex = todayWeekIndex;
                                          });

                                          // เลื่อน PageController ไปสัปดาห์ที่ถูกต้อง
                                          _pageController
                                              .animateToPage(
                                                todayWeekIndex +
                                                    1, // +1 เพราะ page 0 เป็นเดือนก่อนหน้า
                                                duration: Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves.easeInOut,
                                              )
                                              .then((_) {
                                                // หลังจากเลื่อนเสร็จแล้ว ปิด flag
                                                setState(() {
                                                  isNavigatingToToday = false;
                                                });
                                              });
                                        } else {
                                          // ถ้าไม่มี PageController ก็ปิด flag ทันที
                                          setState(() {
                                            isNavigatingToToday = false;
                                          });
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.02,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Today',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleSmall!
                                              .fontSize!,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF007AFF),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(width: width * 0.01),
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    isCalendarExpanded = !isCalendarExpanded;
                                    openSelectMonth = false;
                                    addTask = false;
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
                  ),
                  SizedBox(height: height * 0.01),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        addTask = false;
                      });
                      _saveData(addTasknameCtl.text, addDescriptionCtl.text);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            openSelectMonth = false;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: height * 0.01,
                          ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
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
                    ),
                  ),
                  SizedBox(height: height * 0.005),
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
                            controller: scrollController,
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
                  if (addTask)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          addTask = true;
                        });
                      },
                      child: Container(
                        color: Color(0xFFF2F2F6),
                        key: addFormKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: width * 0.04,
                                    right: width * 0.018,
                                  ),
                                  child: SvgPicture.string(
                                    '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480.13-88q-81.31 0-152.89-30.86-71.57-30.86-124.52-83.76-52.95-52.9-83.83-124.42Q88-398.55 88-479.87q0-81.56 30.92-153.37 30.92-71.8 83.92-124.91 53-53.12 124.42-83.48Q398.67-872 479.87-872q81.55 0 153.35 30.34 71.79 30.34 124.92 83.42 53.13 53.08 83.49 124.84Q872-561.64 872-480.05q0 81.59-30.34 152.83-30.34 71.23-83.41 124.28-53.07 53.05-124.81 84Q561.7-88 480.13-88Zm-.13-66q136.51 0 231.26-94.74Q806-343.49 806-480t-94.74-231.26Q616.51-806 480-806t-231.26 94.74Q154-616.51 154-480t94.74 231.26Q343.49-154 480-154Z"/></svg>',
                                    height: height * 0.04,
                                    fit: BoxFit.contain,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.only(
                                      top: height * 0.005,
                                      right: width * 0.05,
                                    ),
                                    width: width,
                                    child: TextField(
                                      controller: addTasknameCtl,
                                      focusNode: addTasknameFocusNode,
                                      keyboardType: TextInputType.text,
                                      cursorColor: Color(0xFF007AFF),
                                      style: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleSmall!.fontSize!,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: isTyping ? '' : 'Add Title',
                                        hintStyle: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleSmall!
                                              .fontSize!,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.grey,
                                        ),
                                        constraints: BoxConstraints(
                                          maxHeight: height * 0.05,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: height * 0.01,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.only(
                                    left: width * 0.145,
                                    right: width * 0.05,
                                  ),
                                  width: width,
                                  child: TextField(
                                    controller: addDescriptionCtl,
                                    focusNode: addDescriptionFocusNode,
                                    keyboardType: TextInputType.text,
                                    cursorColor: Color(0xFF007AFF),
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize!,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: isTyping
                                          ? ''
                                          : 'Add Description',
                                      hintStyle: TextStyle(
                                        fontSize:
                                            Get.textTheme.titleSmall!.fontSize!,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey,
                                      ),
                                      constraints: BoxConstraints(
                                        maxHeight: height * 0.04,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: height * 0.005,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                left: width * 0.14,
                                right: width * 0.05,
                                bottom: height * 0.005,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    selectedReminder != null
                                        ? selectedReminder.toString()
                                        : 'Today',
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleSmall!.fontSize!,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (addTask) Divider(thickness: 1, height: 0),
                  if (addTask)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          addTask = true;
                        });
                      },
                      child: Column(
                        children: [
                          if (isShowMenuRemind)
                            Container(
                              width: width,
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.02,
                                vertical: height * 0.01,
                              ),
                              color: Color(0xFFF2F2F6),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Wrap(
                                  spacing: 6,
                                  children: [
                                    ...selectRemind().map((select) {
                                      bool isSelected =
                                          selectedReminder == select;
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            selectedReminder = isSelected
                                                ? null
                                                : select;
                                            customReminderDateTime = null;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.02,
                                            vertical: height * 0.005,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Color(0xFF007AFF)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            select,
                                            style: TextStyle(
                                              fontSize: Get
                                                  .textTheme
                                                  .titleSmall!
                                                  .fontSize!,
                                              fontWeight: FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          isCustomReminderApplied = true;
                                        });
                                        _showCustomDateTimePicker(
                                          context,
                                          selectedDate,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.02,
                                          vertical: height * 0.005,
                                        ),
                                        decoration: BoxDecoration(
                                          color: customReminderDateTime != null
                                              ? Color(0xFF007AFF)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          (selectedReminder != null &&
                                                  selectedReminder!.startsWith(
                                                    'Custom:',
                                                  ) &&
                                                  customReminderDateTime !=
                                                      null)
                                              ? showTimeCustom(
                                                  customReminderDateTime!,
                                                )
                                              : 'Custom',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .titleSmall!
                                                .fontSize!,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                (selectedReminder != null &&
                                                    selectedReminder!
                                                        .startsWith('Custom:'))
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (isShowMenuPriority)
                            Container(
                              width: width,
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.02,
                                vertical: height * 0.01,
                              ),
                              color: Color(0xFFF2F2F6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: selectPriority().map((select) {
                                  bool isSelected = selectedPriority == select;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedPriority = isSelected
                                            ? null
                                            : select;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.02,
                                        vertical: height * 0.005,
                                      ),
                                      decoration: BoxDecoration(
                                        color: select == 1 && isSelected
                                            ? Colors.green
                                            : select == 2 && isSelected
                                            ? Colors.orange
                                            : select == 3 && isSelected
                                            ? Colors.red
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        select == 1
                                            ? 'Low'
                                            : select == 2
                                            ? 'Medium'
                                            : 'High',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleSmall!
                                              .fontSize!,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          Divider(thickness: 1, height: 0),
                          Container(
                            color: Color(0xFFF2F2F6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          isShowMenuRemind = !isShowMenuRemind;
                                          isShowMenuPriority = false;
                                          _scrollToAddForm();
                                        });
                                      },
                                      child: SizedBox(
                                        width: width,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.02,
                                            vertical: height * 0.002,
                                          ),
                                          child: Column(
                                            children: [
                                              SvgPicture.string(
                                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M8 15h3v3h2v-3h3v-2h-3v-3h-2v3H8z"></path><path d="M19 4h-2V2h-2v2H9V2H7v2H5c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h14c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2zm.002 16H5V8h14l.002 12z"></path></svg>',
                                                height: height * 0.03,
                                                fit: BoxFit.contain,
                                                color:
                                                    selectedReminder != null ||
                                                        isShowMenuRemind
                                                    ? Color(0xFF007AFF)
                                                    : Colors.grey,
                                              ),
                                              Text(
                                                'Remind',
                                                style: TextStyle(
                                                  fontSize: Get
                                                      .textTheme
                                                      .labelMedium!
                                                      .fontSize!,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          isShowMenuPriority =
                                              !isShowMenuPriority;
                                          isShowMenuRemind = false;
                                          _scrollToAddForm();
                                        });
                                      },
                                      child: SizedBox(
                                        width: width,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.02,
                                            vertical: height * 0.002,
                                          ),
                                          child: Column(
                                            children: [
                                              SvgPicture.string(
                                                '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px" fill="#5f6368"><path d="M480-280q17 0 28.5-11.5T520-320q0-17-11.5-28.5T480-360q-17 0-28.5 11.5T440-320q0 17 11.5 28.5T480-280Zm-40-160h80v-240h-80v240ZM200-120q-33 0-56.5-23.5T120-200v-560q0-33 23.5-56.5T200-840h168q13-36 43.5-58t68.5-22q38 0 68.5 22t43.5 58h168q33 0 56.5 23.5T840-760v560q0 33-23.5 56.5T760-120H200Zm0-80h560v-560H200v560Zm280-590q13 0 21.5-8.5T510-820q0-13-8.5-21.5T480-850q-13 0-21.5 8.5T450-820q0 13 8.5 21.5T480-790ZM200-200v-560 560Z"/></svg>',
                                                height: height * 0.03,
                                                fit: BoxFit.contain,
                                                color: selectedPriority == 1
                                                    ? Colors.green
                                                    : selectedPriority == 2
                                                    ? Colors.orange
                                                    : selectedPriority == 3
                                                    ? Colors.red
                                                    : isShowMenuPriority
                                                    ? Color(0xFF007AFF)
                                                    : Colors.grey,
                                              ),
                                              Text(
                                                'Priority',
                                                style: TextStyle(
                                                  fontSize: Get
                                                      .textTheme
                                                      .labelMedium!
                                                      .fontSize!,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
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
                  if (!addTask && !hideMenu)
                    Container(
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFF2F2F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              isCalendarExpanded = false;
                              addTask = !addTask;
                            });
                            if (addTask) {
                              Future.delayed(Duration(milliseconds: 100), () {
                                addTasknameFocusNode.requestFocus();
                              });
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.04,
                              vertical: height * 0.015,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "New",
                                      style: TextStyle(
                                        fontSize: Get
                                            .textTheme
                                            .titleMedium!
                                            .fontSize!,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6).withOpacity(0.8),
                                        Color(0xFF1D4ED8).withOpacity(0.7),
                                      ],
                                    ),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
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
                    height: !addTask
                        ? height * 0.59
                        : openSelectMonth
                        ? height * 0.25
                        : 0,
                    decoration: BoxDecoration(
                      color: Color(0xFFF2F2F6),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: monthNames.asMap().entries.map((entry) {
                          int idx = entry.key;
                          String month = entry.value;

                          final isSelected = selectedDate.month == (idx + 1);
                          final isCurrentMonth =
                              DateTime.now().month == (idx + 1);

                          Color backgroundColor;

                          if (isSelected) {
                            backgroundColor = Color(
                              0xFF3B82F6,
                            ).withOpacity(0.8);
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
                                    fontSize:
                                        Get.textTheme.titleSmall!.fontSize!,
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveData(String value, String description) async {
    if (!mounted) return;
    final userProfile = box.read('userProfile');
    final userId = userProfile['userid'];
    final userEmail = userProfile['email'];
    if (userId == null || userEmail == null) return;

    if (isCustomReminderApplied) return;

    final trimmedTitle = value.trim();
    final trimmedDescription = description.trim();
    if (trimmedTitle.isEmpty && trimmedDescription.isEmpty) return;

    DateTime dueDate;
    if (selectedReminder != null && selectedReminder!.isNotEmpty) {
      if (selectedReminder!.startsWith('Custom:')) {
        dueDate = customReminderDateTime!;
      } else {
        dueDate = convertReminderToDateTime(selectedReminder!);
      }
    } else {
      dueDate = selectedDate;
    }

    DateTime? beforeDueDate;
    if (!isValidNotificationTime(dueDate, selectedBeforeMinutes)) {
      beforeDueDate = calculateNotificationTime(dueDate, selectedBeforeMinutes);
    } else {
      beforeDueDate = calculateNotificationTime(dueDate, selectedBeforeMinutes);
    }

    final titleToSave = trimmedTitle.isEmpty ? "Untitled" : trimmedTitle;
    final descriptionToSave = trimmedDescription;

    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempTask = model.Task(
      taskName: titleToSave,
      description: descriptionToSave,
      createdAt: DateTime.now().toIso8601String(),
      priority: selectedPriority == null ? '' : selectedPriority.toString(),
      status: '0',
      attachments: [],
      checklists: [],
      createBy: userId,
      taskId: tempId,
      assigned: [],
      boardId: "Today",
      notifications: [
        model.Notification(
          beforeDueDate: selectedBeforeMinutes != null
              ? beforeDueDate.toUtc().toIso8601String()
              : '',
          createdAt: DateTime.now().toIso8601String(),
          dueDate: dueDate.toUtc().toIso8601String(),
          isSend: '0',
          notificationId: tempId,
          recurringPattern: (selectedRepeat ?? 'Onetime').toLowerCase(),
          taskId: tempId,
        ),
      ],
    );

    if (mounted) {
      tasks.add(tempTask);

      setState(() {
        addTask = false;
        creatingTasks[tempId.toString()] = true;
        isCreatingTask = true;
        addTasknameCtl.clear();
        addDescriptionCtl.clear();
      });
    }

    //ฟังก์ชันอัพเดทลง storage
    await _updateLocalStorage(tempTask, isTemp: true);

    //เรียก api สร้าง task
    final success = await _createTaskAPI(
      titleToSave,
      descriptionToSave,
      userEmail,
      dueDate,
      beforeDueDate,
    );

    if (success['success']) {
      final realTaskId = success['taskId'];
      final notificationID = success['notificationID'];
      //ฟังก์ชัน replace เฉพาะ task จริงที่ได้รับ taskId,notificationID จาก api
      await _replaceWithRealTask(
        tempId.toString(),
        notificationID,
        realTaskId,
        tempTask,
        userId,
        dueDate,
        beforeDueDate,
      );
    } else {
      //หากเกิดข้อผิดพลาดให้ลบ TempTask ออก
      await _removeTempTask(tempId.toString());
    }

    if (mounted) {
      setState(() {
        creatingTasks.remove(tempId.toString());
        isCreatingTask = creatingTasks.isNotEmpty;
        customReminderDateTime = null;
        selectedReminder = null;
        selectedPriority = null;
        isShowMenuPriority = false;
        isShowMenuRemind = false;
        isCustomReminderApplied = false;
        selectedBeforeMinutes = null;
        selectedRepeat = 'Onetime';
      });
    }
  }

  Future<Map<String, dynamic>> _createTaskAPI(
    String title,
    String description,
    String email,
    DateTime dueDate,
    DateTime? beforeDueDate,
  ) async {
    url = await loadAPIEndpoint();

    var responseCreate = await http.post(
      Uri.parse("$url/todaytasks/create"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: todayTasksCreatePostRequestToJson(
        TodayTasksCreatePostRequest(
          taskName: title,
          description: description,
          status: '0',
          priority: selectedPriority == null ? '' : selectedPriority.toString(),
          reminder: Reminder(
            beforeDueDate:
                selectedBeforeMinutes != null && beforeDueDate != null
                ? beforeDueDate.toUtc().toIso8601String()
                : '',
            dueDate: dueDate.toUtc().toIso8601String(),
            recurringPattern: (selectedRepeat ?? 'Onetime').toLowerCase(),
          ),
        ),
      ),
    );

    if (responseCreate.statusCode == 403) {
      await AppDataLoadNewRefreshToken().loadNewRefreshToken();
      responseCreate = await http.post(
        Uri.parse("$url/todaytasks/create"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: todayTasksCreatePostRequestToJson(
          TodayTasksCreatePostRequest(
            taskName: title,
            description: description,
            status: '0',
            priority: selectedPriority == null
                ? ''
                : selectedPriority.toString(),
            reminder: Reminder(
              beforeDueDate:
                  selectedBeforeMinutes != null && beforeDueDate != null
                  ? beforeDueDate.toUtc().toIso8601String()
                  : '',
              dueDate: dueDate.toUtc().toIso8601String(),
              recurringPattern: (selectedRepeat ?? 'Onetime').toLowerCase(),
            ),
          ),
        ),
      );
    }

    if (responseCreate.statusCode == 201) {
      final responseData = jsonDecode(responseCreate.body);
      return {
        'success': true,
        'taskId': responseData['taskID'],
        'notificationID': responseData['notificationID'],
      };
    } else {
      return {
        'success': false,
        'error': 'Server error: ${responseCreate.statusCode}',
      };
    }
  }

  Future<void> _updateLocalStorage(
    model.Task task, {
    bool isTemp = false,
    String? tempIdToRemove,
  }) async {
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    final existingData = model.AllDataUserGetResponst.fromJson(userDataJson);

    // ลบ temp task ถ้ามี
    if (tempIdToRemove != null) {
      existingData.tasks.removeWhere(
        (t) => t.taskId.toString() == tempIdToRemove,
      );
    }

    // ตรวจสอบว่า task นี้มีอยู่ใน local storage แล้วหรือไม่
    final existingIndex = existingData.tasks.indexWhere(
      (t) => t.taskId == task.taskId,
    );

    if (existingIndex >= 0) {
      // ถ้ามีอยู่แล้ว ให้อัพเดท
      existingData.tasks[existingIndex] = task;
    } else {
      // ถ้าไม่มี ให้เพิ่มใหม่
      existingData.tasks.add(task);
    }

    // บันทึกกลับไปยัง storage
    box.write('userDataAll', existingData.toJson());
  }

  Future<void> _replaceWithRealTask(
    String tempId,
    int notificationID,
    int realId,
    model.Task tempTask,
    int userId,
    DateTime dueDate,
    DateTime? beforeDueDate,
  ) async {
    if (!mounted) return;

    final realTask = model.Task(
      taskName: tempTask.taskName,
      description: tempTask.description,
      createdAt: DateTime.now().toIso8601String(),
      priority: tempTask.priority,
      status: '0',
      attachments: [],
      checklists: [],
      createBy: userId,
      taskId: realId,
      assigned: [],
      boardId: "Today",
      notifications: [
        model.Notification(
          beforeDueDate: selectedBeforeMinutes != null && beforeDueDate != null
              ? beforeDueDate.toUtc().toIso8601String()
              : '',
          createdAt: DateTime.now().toIso8601String(),
          dueDate: dueDate.toUtc().toIso8601String(),
          isSend: '0',
          notificationId: notificationID,
          recurringPattern: (selectedRepeat ?? 'Onetime').toLowerCase(),
          taskId: realId,
        ),
      ],
    );

    await _waitForDocumentCreation(realId, notificationID);
    FirebaseFirestore.instance
        .collection('Notifications')
        .doc(box.read('userProfile')['email'])
        .collection('Tasks')
        .doc(notificationID.toString())
        .update({
          'isShow': dueDate.isAfter(DateTime.now())
              ? false
              : FieldValue.delete(),
          'isNotiRemind': false,
        });

    tasks.removeWhere((t) => t.taskId.toString() == tempId);
    tasks.add(realTask);

    await _updateLocalStorage(realTask, isTemp: false, tempIdToRemove: tempId);
  }

  Future<void> _waitForDocumentCreation(int realId, int notificationID) async {
    int maxRetries = 10; // จำกัดจำนวนครั้งที่ลอง
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        DocumentSnapshot doc;

        doc = await FirebaseFirestore.instance
            .collection('Notifications')
            .doc(box.read('userProfile')['email'])
            .collection('Tasks')
            .doc(notificationID.toString())
            .get();

        if (doc.exists) {
          // Document ถูกสร้างแล้ว สามารถทำงานต่อได้
          return;
        }

        // หาก document ยังไม่ถูกสร้าง รอ 500ms แล้วลองใหม่
        retryCount++;
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        // หากเกิดข้อผิดพลาด รอ 500ms แล้วลองใหม่
        retryCount++;
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
  }

  Future<void> _removeTempTask(String tempId) async {
    if (!mounted) return;

    tasks.removeWhere((t) => t.taskId.toString() == tempId);

    if (mounted) {
      setState(() {
        creatingTasks.remove(tempId);
        isCreatingTask = creatingTasks.isNotEmpty;
      });

      await loadDataAsync();
    }

    final userDataJson = box.read('userDataAll');
    if (userDataJson != null) {
      final existingData = model.AllDataUserGetResponst.fromJson(userDataJson);
      existingData.tasks.removeWhere((t) => t.taskId.toString() == tempId);
      box.write('userDataAll', existingData.toJson());
    }
  }

  DateTime calculateNotificationTime(
    DateTime dueDate,
    int? selectedBeforeMinutes,
  ) {
    if (selectedBeforeMinutes == null || selectedBeforeMinutes == 0) {
      return dueDate;
    }

    final minutesBefore = getMinutesFromIndex(selectedBeforeMinutes);
    if (minutesBefore <= 0) return dueDate;

    final calculatedNotificationTime = dueDate.subtract(
      Duration(minutes: minutesBefore),
    );

    // หากเวลาแจ้งเตือนอยู่ในอดีต ให้ใช้ dueDate
    if (calculatedNotificationTime.isBefore(DateTime.now())) {
      return dueDate;
    }

    return calculatedNotificationTime;
  }

  // ฟังก์ชันตรวจสอบว่าเวลาแจ้งเตือนสมเหตุสมผลหรือไม่
  bool isValidNotificationTime(DateTime dueDate, int? selectedBeforeMinutes) {
    if (selectedBeforeMinutes == null || selectedBeforeMinutes == 0) {
      return true; // Never หรือ ไม่ได้เลือก = ใช้ dueDate
    }

    final minutesBefore = getMinutesFromIndex(selectedBeforeMinutes);
    if (minutesBefore <= 0) return true;

    final calculatedNotificationTime = dueDate.subtract(
      Duration(minutes: minutesBefore),
    );
    return calculatedNotificationTime.isAfter(DateTime.now());
  }

  int getMinutesFromIndex(int? index) {
    if (index == null || index == 0) return 0; // Never

    final options = getRemindMeBeforeOptions();
    if (index >= 0 && index < options.length) {
      return options[index]['minutes'];
    }
    return 0;
  }

  DateTime convertReminderToDateTime(String reminder) {
    final now = DateTime.now();

    switch (reminder) {
      case '3 hours later':
        return now.add(Duration(hours: 3));
      case 'This evening':
        return DateTime(now.year, now.month, now.day, 18, 0);
      case 'Tomorrow':
        return now.add(Duration(days: 1));
      default:
        return now;
    }
  }

  DateTime? parseDateFromCategory(String category) {
    try {
      List<String> parts = category.split(' ');
      if (parts.length != 3) return null;

      int day = int.parse(parts[1]);
      String monthAbbr = parts[2];

      List<String> monthNames = [
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

      int month = monthNames.indexOf(monthAbbr) + 1;
      if (month == 0) return null;

      DateTime now = DateTime.now();
      DateTime date = DateTime(now.year, month, day, now.hour, now.minute);

      return date;
    } catch (e) {
      return null;
    }
  }

  void _scrollToAddForm() {
    if (!mounted) return;

    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted && scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted && scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );

        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted && addFormKey.currentContext != null) {
            Scrollable.ensureVisible(
              addFormKey.currentContext!,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: 1.0,
            );
          }
        });
      }
    });
  }

  String showTimeCustom(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == today) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = (dateTime.year % 100).toString().padLeft(2, '0');
      return '$day/$month/$year';
    }
  }

  List<String> selectRemind() {
    return ['3 hours later', 'This evening', 'Tomorrow'];
  }

  List<int> selectPriority() {
    return [1, 2, 3];
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
          if (data != null && data['beforeDueDate'] != null) {
            remindTimestamp = (data['beforeDueDate'] as Timestamp).toDate();
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
          if (data['beforeDueDate'] != null) {
            remindTimestamp = (data['beforeDueDate'] as Timestamp).toDate();
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
                        addTask = false;
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
                      _scrollToAddForm();
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
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;
    var existingData = model.AllDataUserGetResponst.fromJson(userDataJson);
    final taskId = data.taskId;

    bool isGroup = existingData.boardgroup.any(
      (b) => b.boardId.toString() == data.boardId.toString(),
    );

    final board = tasks.firstWhere(
      (b) => b.taskId.toString() == taskId.toString(),
    );

    final boardID = board.boardId.toString();
    setState(() => hideMenu = false);

    // กดเลือก task
    if (selectedIsArchived.contains(taskId.toString())) {
      selectedIsArchived.remove(taskId.toString());
    } else {
      selectedIsArchived.add(taskId.toString());
    }

    // หากกดเลือก task ที่เสร็จแล้ว
    if (data.status == "2") {
      if (isGroup) {
        await FirebaseFirestore.instance
            .collection('Boards')
            .doc(boardID)
            .collection('Tasks')
            .doc(taskId.toString())
            .update({'status': '0'});
        await showArchiveTask(taskId.toString());
        selectedIsArchived.clear();
      } else {
        selectedIsArchived.clear();
        await showArchiveTask(taskId.toString());
      }
      setState(() {});
      return;
    }

    // ถ้ายังไม่เสร็จ
    if (isGroup) {
      await FirebaseFirestore.instance
          .collection('Boards')
          .doc(boardID)
          .collection('Tasks')
          .doc(taskId.toString())
          .update({'status': '2'});
      await todayTasksFinish(taskId.toString());
      selectedIsArchived.clear();
    } else {
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

    final index = existingData.tasks.indexWhere(
      (t) => t.taskId.toString() == id,
    );
    if (index == -1) return;

    existingData.tasks[index].status = '2';
    box.write('userDataAll', existingData.toJson());

    if (!showArchived) {
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
      await AppDataLoadNewRefreshToken().loadNewRefreshToken();
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

    // อัพเดทสถานะใน local storage
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
      await AppDataLoadNewRefreshToken().loadNewRefreshToken();
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

    if (ids is String) {
      idList = [ids];
      taskIdPayload = ids;
    } else if (ids is List && ids.every((e) => e is String)) {
      idList = List<String>.from(ids);
      taskIdPayload = idList;
    } else {
      throw ArgumentError("Invalid ids parameter");
    }

    Map<String, String> taskIdToBoardId = {};

    for (var id in idList) {
      final task = tasks.firstWhereOrNull((t) => t.taskId.toString() == id);
      if (task != null && task.boardId != 'Today') {
        taskIdToBoardId[id] = task.boardId.toString();
      }

      tasks.removeWhere((t) => t.taskId.toString() == id);
      existingData.tasks.removeWhere((t) => t.taskId.toString() == id);
    }
    box.write('userDataAll', existingData.toJson());

    setState(() {
      tasks = List.from(tasks);
    });

    await _deleteFromFirebaseInBackground(taskIdToBoardId);

    final endpoint = select ? "deltask" : "deltask/$taskIdPayload";
    final requestBody = select ? {"task_id": taskIdPayload} : null;
    await deleteWithRetry(endpoint, requestBody);

    if (mounted) {
      setState(() {
        tasks = List.from(tasks);
      });
    }
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
      await AppDataLoadNewRefreshToken().loadNewRefreshToken();
      final newToken = box.read('accessToken');
      if (newToken != null) {
        response = await sendRequest(newToken);
      }
    }

    return response;
  }

  Future<void> _deleteFromFirebaseInBackground(
    Map<String, String> taskIdToBoardId,
  ) async {
    for (var entry in taskIdToBoardId.entries) {
      await _deleteSingleTaskFromFirebase(entry.value, entry.key);
    }
  }

  Future<void> _deleteSingleTaskFromFirebase(
    String boardId,
    String taskId,
  ) async {
    // ลบจาก Boards collection
    await FirebaseFirestore.instance
        .collection('Boards')
        .doc(boardId)
        .collection('Tasks')
        .doc(taskId)
        .delete();

    // ลบจาก BoardTasks collection
    final taskDocRef = FirebaseFirestore.instance
        .collection('BoardTasks')
        .doc(taskId);

    final notificationsSnapshot = await taskDocRef
        .collection('Notifications')
        .get();

    // ลบ notifications ทั้งหมด
    final deleteNotificationsFutures = notificationsSnapshot.docs.map(
      (doc) => doc.reference.delete(),
    );
    await Future.wait(deleteNotificationsFutures);

    await taskDocRef.delete();
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

  List<Map<String, dynamic>> getRemindMeBeforeOptions() {
    return [
      {'label': 'Never', 'minutes': 0},
      {'label': '5 min', 'minutes': 5},
      {'label': '10 min', 'minutes': 10},
      {'label': '15 min', 'minutes': 15},
      {'label': '30 min', 'minutes': 30},
      {'label': '1 hour', 'minutes': 60},
      {'label': '2 hours', 'minutes': 120},
      {'label': '1 day', 'minutes': 1440},
      {'label': '2 days', 'minutes': 2880},
      {'label': '1 week', 'minutes': 10080},
    ];
  }

  List<String> getRepeatOptions() {
    return ['Onetime', 'Daily', 'Weekly', 'Monthly', 'Yearly'];
  }

  String getLabelFromIndex(int? index) {
    if (index == null) return 'Never';

    final options = getRemindMeBeforeOptions();
    if (index >= 0 && index < options.length) {
      return options[index]['label'];
    }
    return 'Never';
  }

  void _showCustomDateTimePicker(BuildContext context, DateTime date) {
    DateTime tempSelectedDate = date;
    TimeOfDay tempSelectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState1) {
            double height = MediaQuery.of(context).size.height;
            double width = MediaQuery.of(context).size.width;

            return WillPopScope(
              onWillPop: () async => false,
              child: SizedBox(
                height: height * 0.94,
                child: Scaffold(
                  body: Padding(
                    padding: EdgeInsets.only(
                      top: height * 0.01,
                      left: width * 0.05,
                      right: width * 0.05,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Get.back();
                                  setState(() {
                                    addTask = true;
                                    selectedBeforeMinutes = null;
                                    selectedReminder = null;
                                    customReminderDateTime = null;
                                    isShowMenuRemind = false;
                                    isCustomReminderApplied = false;
                                  });
                                  addTasknameFocusNode.requestFocus();
                                  Future.delayed(
                                    Duration(microseconds: 300),
                                    () {
                                      _scrollToAddForm();
                                    },
                                  );
                                },
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize!,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              Text(
                                "Custom Date & Time",
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.titleMedium!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  final selectedDateTime = DateTime(
                                    tempSelectedDate.year,
                                    tempSelectedDate.month,
                                    tempSelectedDate.day,
                                    tempSelectedTime.hour,
                                    tempSelectedTime.minute,
                                  );

                                  setState(() {
                                    selectedReminder =
                                        'Custom: ${DateFormat('MMM dd, yyyy HH:mm').format(selectedDateTime)}';
                                    customReminderDateTime = selectedDateTime;
                                    isCustomReminderApplied = false;
                                    isShowMenuRemind = true;
                                    addTask = true;
                                  });
                                  addTasknameFocusNode.requestFocus();
                                  Future.delayed(
                                    Duration(microseconds: 300),
                                    () {
                                      _scrollToAddForm();
                                    },
                                  );
                                  Get.back();
                                },
                                child: Text(
                                  'Apply',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize!,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4790EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Date:",
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize!,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Color(0xFF4790EB),
                                  ),
                                  useMaterial3: true,
                                  textTheme: TextTheme(
                                    bodySmall: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  height: height * 0.35,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Material(
                                      color: Color(0xFFF2F2F6),
                                      child: CalendarDatePicker(
                                        initialDate: tempSelectedDate,
                                        firstDate: DateTime.now().subtract(
                                          Duration(days: 365),
                                        ),
                                        lastDate: DateTime.now().add(
                                          Duration(days: 365 * 5),
                                        ),
                                        onDateChanged: (date) {
                                          setState1(() {
                                            tempSelectedDate = date;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              Row(
                                children: [
                                  Text(
                                    "Time:",
                                    style: TextStyle(
                                      fontSize:
                                          Get.textTheme.titleMedium!.fontSize!,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: height * 0.16,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF2F2F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.time,
                                  initialDateTime: DateTime(
                                    tempSelectedDate.year,
                                    tempSelectedDate.month,
                                    tempSelectedDate.day,
                                    tempSelectedTime.hour,
                                    tempSelectedTime.minute,
                                  ),
                                  use24hFormat: true,
                                  onDateTimeChanged: (DateTime dateTime) {
                                    setState1(() {
                                      tempSelectedTime = TimeOfDay.fromDateTime(
                                        dateTime,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          InkWell(
                            onTap: () {
                              _showSelectRemindMeBefore(context, setState1);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFF2F2F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.02,
                                vertical: height * 0.005,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 4c-4.879 0-9 4.121-9 9s4.121 9 9 9 9-4.121 9-9-4.121-9-9-9zm0 16c-3.794 0-7-3.206-7-7s3.206-7 7-7 7 3.206 7 7-3.206 7-7 7z"></path><path d="M13 12V8h-2v6h6v-2zm4.284-8.293 1.412-1.416 3.01 3-1.413 1.417zm-10.586 0-2.99 2.999L2.29 5.294l2.99-3z"></path></svg>',
                                        color: selectedBeforeMinutes != null
                                            ? Color(0xFF007AFF)
                                            : Colors.black,
                                      ),
                                      SizedBox(width: width * 0.01),
                                      Text(
                                        "Remind me before",
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        getLabelFromIndex(
                                          selectedBeforeMinutes,
                                        ),
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black45,
                                        ),
                                      ),
                                      SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                        width: width * 0.03,
                                        height: height * 0.03,
                                        fit: BoxFit.contain,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          InkWell(
                            onTap: () {
                              _showSelectRepeat(context, setState1);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFF2F2F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.02,
                                vertical: height * 0.005,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M19 7a1 1 0 0 0-1-1h-8v2h7v5h-3l3.969 5L22 13h-3V7zM5 17a1 1 0 0 0 1 1h8v-2H7v-5h3L6 6l-4 5h3v6z"></path></svg>',
                                        color: Colors.black,
                                      ),
                                      SizedBox(width: width * 0.01),
                                      Text(
                                        "Repeat",
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        selectedRepeat ?? 'Onetime',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black45,
                                        ),
                                      ),
                                      SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M10.707 17.707 16.414 12l-5.707-5.707-1.414 1.414L13.586 12l-4.293 4.293z"></path></svg>',
                                        width: width * 0.03,
                                        height: height * 0.03,
                                        fit: BoxFit.contain,
                                        color: Colors.grey,
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
      },
    );
  }

  void _showSelectRemindMeBefore(
    BuildContext context,
    StateSetter parentSetState,
  ) {
    if (selectedBeforeMinutes == null) {
      setState(() {
        selectedBeforeMinutes = 0;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState1) {
            double height = MediaQuery.of(context).size.height;
            double width = MediaQuery.of(context).size.width;
            final options = getRemindMeBeforeOptions();

            return Padding(
              padding: EdgeInsets.only(
                top: height * 0.01,
                left: width * 0.05,
                right: width * 0.05,
              ),
              child: SizedBox(
                height: height * 0.4,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          child: Text(
                            "Back",
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize!,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          "Remind me before",
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize!,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: width * 0.15),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF2F2F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        mainAxisSpacing: height * 0.01,
                        crossAxisSpacing: width * 0.01,
                        childAspectRatio: 2.5,
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.02,
                          vertical: height * 0.01,
                        ),
                        physics: NeverScrollableScrollPhysics(),
                        children: options.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final data = entry.value;

                          return InkWell(
                            onTap: () {
                              setState1(() {
                                selectedBeforeMinutes = idx;
                              });

                              setState(() {
                                selectedBeforeMinutes = idx;
                              });

                              parentSetState(() {
                                selectedBeforeMinutes = idx;
                              });

                              Get.back();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    (selectedBeforeMinutes != null &&
                                        idx == selectedBeforeMinutes)
                                    ? Color(0xFF007AFF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                data['label'],
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      (selectedBeforeMinutes != null &&
                                          idx == selectedBeforeMinutes)
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (selectedBeforeMinutes == 0) {
        setState(() {
          selectedBeforeMinutes = null;
        });
        parentSetState(() {
          selectedBeforeMinutes = null;
        });
      } else {
        setState(() {});
        parentSetState(() {});
      }
    });
  }

  void _showSelectRepeat(BuildContext context, StateSetter parentSetState) {
    if (selectedRepeat == null) {
      setState(() {
        selectedRepeat = 'Onetime';
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState1) {
            double height = MediaQuery.of(context).size.height;
            double width = MediaQuery.of(context).size.width;
            final options = getRepeatOptions();

            return Padding(
              padding: EdgeInsets.only(
                top: height * 0.01,
                left: width * 0.05,
                right: width * 0.05,
              ),
              child: SizedBox(
                height: height * 0.4,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          child: Text(
                            "Back",
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize!,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          "Repeat",
                          style: TextStyle(
                            fontSize: Get.textTheme.titleMedium!.fontSize!,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: width * 0.15),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF2F2F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 1,
                        mainAxisSpacing: height * 0.005,
                        crossAxisSpacing: width * 0.01,
                        childAspectRatio: 9.5,
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.02,
                          vertical: height * 0.01,
                        ),
                        physics: NeverScrollableScrollPhysics(),
                        children: options.map((data) {
                          return InkWell(
                            onTap: () {
                              setState1(() {
                                selectedRepeat = data;
                              });

                              setState(() {
                                selectedRepeat = data;
                              });

                              parentSetState(() {
                                selectedRepeat = data;
                              });

                              Get.back();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.only(left: width * 0.02),
                              decoration: BoxDecoration(
                                color:
                                    (selectedRepeat != null &&
                                        data == selectedRepeat)
                                    ? Color(0xFF007AFF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                data,
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleSmall!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      (selectedRepeat != null &&
                                          data == selectedRepeat)
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (selectedRepeat == 'Onetime') {
        setState(() {
          selectedRepeat = 'Onetime';
        });
        parentSetState(() {
          selectedRepeat = 'Onetime';
        });
      } else {
        setState(() {});
        parentSetState(() {});
      }
    });
  }
}
