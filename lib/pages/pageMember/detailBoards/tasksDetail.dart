import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart'
    as data;
import 'package:mydayplanner/pages/pageMember/menu/menuReport.dart';
import 'package:mydayplanner/pages/pageMember/menu/settings.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:mydayplanner/splash.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TasksdetailPage extends StatefulWidget {
  final int taskId;
  const TasksdetailPage({super.key, required this.taskId});

  @override
  State<TasksdetailPage> createState() => _TasksdetailPageState();
}

class _TasksdetailPageState extends State<TasksdetailPage> {
  late Future<void> loadData;
  var box = GetStorage();
  String text = '';
  late String url;
  bool isLoading = true;
  final GlobalKey iconKey = GlobalKey();
  Map<String, dynamic> combinedData = {};
  late TextEditingController _taskNameController;
  late FocusNode _taskNameFocusNode;
  bool _isEditingTaskName = false;
  int selectedTabIndex = 0;

  late TextEditingController _descriptionController;
  late FocusNode _descriptionFocusNode;
  bool _isEditingDescription = false;

  final FlutterSecureStorage storage = FlutterSecureStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  String? selectedReminder;
  DateTime? customReminderDateTime;

  bool isShowMenuRemind = false;
  bool isShowMenuPriority = false;
  bool isCustomReminderApplied = false;
  int itemCount = 1;
  int? selectedPriority;
  int? selectedBeforeMinutes;
  String? selectedRepeat;

  XFile? image;
  File? savedFile;

  List<StreamSubscription> _streamSubscriptions = [];

  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();

    // Initialize controllers และ focus nodes ทันที
    _taskNameController = TextEditingController();
    _taskNameFocusNode = FocusNode();
    _descriptionController = TextEditingController();
    _descriptionFocusNode = FocusNode();

    _taskNameFocusNode.addListener(() {
      setState(() {
        _isEditingTaskName = _taskNameFocusNode.hasFocus;
      });
    });

    _descriptionFocusNode.addListener(() {
      setState(() {
        _isEditingDescription = _descriptionFocusNode.hasFocus;
      });
    });

    // โหลดข้อมูลหลังจาก build เสร็จ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadDataAsync();
    });
  }

  @override
  void dispose() {
    // ยกเลิก stream subscriptions
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();

    _taskNameController.dispose();
    _taskNameFocusNode.dispose();
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();

    super.dispose();
  }

  Future<void> loadDataAsync({VoidCallback? onDataLoaded}) async {
    log('Loading data for taskId: ${widget.taskId}');
    setState(() => isLoading = true);

    try {
      url = await loadAPIEndpoint();
      final tasksData = _getUserData();
      if (tasksData == null) return;

      final appDataAndTask = _getAppDataAndTask();
      final appData = appDataAndTask.appData;

      data.Task? foundTask;
      try {
        foundTask = tasksData.tasks.firstWhere(
          (task) => task.taskId == widget.taskId,
        );
      } catch (_) {
        log('ไม่พบ task ที่มี taskId: ${widget.taskId}');
        return;
      }

      if (foundTask.boardId != "Today") {
        try {
          // ลองค้นหาใน Individual Board
          final foundBoard = tasksData.board.firstWhere(
            (board) => board.boardId == foundTask!.boardId,
          );

          _taskNameController.text = foundTask.taskName ?? '';
          _descriptionController.text = foundTask.description ?? '';
          appData.showDetailTask.setCurrentTask(foundTask, isGroup: false);
        } catch (_) {
          // หากไม่พบ ให้ค้นหาใน Group Board
          try {
            final foundBoardgroup = tasksData.boardgroup.firstWhere(
              (boardgroup) => boardgroup.boardId == foundTask!.boardId,
            );

            if (foundBoardgroup.boardId != null) {
              appData.showDetailTask.setCurrentTask(foundTask, isGroup: true);
              fetchGroupDataAndAddStream(
                foundBoardgroup.boardId!,
                widget.taskId,
                (data) {
                  if (mounted) {
                    setState(() {
                      combinedData = data;

                      // ตรวจสอบว่ามีข้อมูล task จาก Firestore หรือยัง
                      if (data['task'] != null) {
                        if (data['task']['taskName'] != null) {
                          _taskNameController.text = data['task']['taskName'];
                        }
                        if (data['task']['description'] != null) {
                          _descriptionController.text =
                              data['task']['description']; // เพิ่มบรรทัดนี้
                        }
                      }
                    });

                    // เรียก callback เพื่อให้ popup อัปเดต
                    if (onDataLoaded != null) {
                      onDataLoaded();
                    }
                  }
                },
              );
            }
          } catch (_) {
            log('ไม่พบ boardgroup สำหรับ taskId: ${widget.taskId}');
          }
        }
      } else {
        _taskNameController.text = foundTask.taskName ?? '';
        _descriptionController.text = foundTask.description ?? '';
        appData.showDetailTask.setCurrentTask(foundTask, isGroup: false);
      }
    } catch (e) {
      log('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);

        // เรียก callback หลังจากโหลดเสร็จ (สำหรับกรณีที่ไม่ใช่ group task)
        if (onDataLoaded != null) {
          onDataLoaded();
        }
      }
    }
  }

  void fetchGroupDataAndAddStream(
    int boardId,
    int taskId,
    Function(Map<String, dynamic>) onData,
  ) {
    // ยกเลิก subscription เก่าก่อน (ถ้ามี)
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();

    final combinedData = <String, dynamic>{};

    final boardDocRef = FirebaseFirestore.instance
        .collection('Boards')
        .doc(boardId.toString());

    final taskDocRef = boardDocRef.collection('Tasks').doc(taskId.toString());

    final boardtaskDocRef = FirebaseFirestore.instance
        .collection('BoardTasks')
        .doc(taskId.toString());

    _streamSubscriptions.add(
      boardDocRef.snapshots().listen((snapshot) {
        combinedData['board'] = snapshot.data();
        onData({...combinedData});
        log('Combined data updated with board: ${combinedData['board']}');
      }),
    );

    _streamSubscriptions.add(
      boardDocRef.collection('BoardUsers').snapshots().listen((querySnapshot) {
        combinedData['boardUsers'] = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
        log(
          'Combined data updated with boardUsers: ${combinedData['boardUsers']}',
        );
        onData({...combinedData});
      }),
    );

    _streamSubscriptions.add(
      taskDocRef.snapshots().listen((snapshot) {
        combinedData['task'] = snapshot.data();
        log('Combined data updated with task: ${combinedData['task']}');
        onData({...combinedData});
      }),
    );

    _streamSubscriptions.add(
      boardtaskDocRef.collection('Checklist').snapshots().listen((snapshot) {
        combinedData['checklist'] = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
        // log('Combined data updated with checklist: ${combinedData['checklist']}');
        onData({...combinedData});
      }),
    );

    _streamSubscriptions.add(
      boardtaskDocRef.collection('Attachments').snapshots().listen((snapshot) {
        combinedData['attachments'] = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
        onData({...combinedData});
      }),
    );

    _streamSubscriptions.add(
      boardtaskDocRef.collection('Assigned').snapshots().listen((snapshot) {
        combinedData['assigned'] = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
        // log(combinedData['assigned'].toString());
        onData({...combinedData});
      }),
    );

    _streamSubscriptions.add(
      boardtaskDocRef.collection('Notifications').snapshots().listen((
        snapshot,
      ) {
        combinedData['notifications'] = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
        // log('Combined data updated with notification: ${combinedData['notifications']}');
        onData({...combinedData});
      }),
    );
  }

  int? _findIndexCurrentTask(data.Task currentTask) {
    final existingData = _getUserData();
    if (existingData == null) return null;

    // หาตำแหน่งของ task ที่มี id ตรงกับที่ส่งมา
    final index = existingData.tasks.indexWhere(
      (t) => t.taskId.toString() == currentTask.taskId.toString(),
    );

    if (index == -1) return null; // ถ้าไม่เจอ task ให้คืนค่า null
    return index;
  }

  // Helper method สำหรับอ่านและแปลงข้อมูล userDataAll
  data.AllDataUserGetResponst? _getUserData() {
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return null;

    try {
      return data.AllDataUserGetResponst.fromJson(userDataJson);
    } catch (e) {
      log('Error parsing userDataAll: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Appdata>(
      builder: (context, appData, child) {
        final isGroupTask = appData.showDetailTask.isGroupTask;
        log('Build - isGroupTask: $isGroupTask');
        return WillPopScope(
          onWillPop: () async {
            Navigator.pop(context, 'refresh');
            return false;
          },
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // Header Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Back Button
                            IconButton(
                              onPressed: () =>
                                  Navigator.pop(context, 'refresh'),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const SizedBox(width: 8),

                            // Title - แก้ไข Layout ของ Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getHeaderTitle(),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  Text(
                                    _getPathTaskTitle(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Share button for group tasks
                            if (isGroupTask)
                              IconButton(
                                onPressed: () {
                                  _shareTask();
                                },
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.blue,
                                ),
                              ),

                            // ปุ่ม 3 จุด
                            Builder(
                              builder: (context) {
                                double height = MediaQuery.of(
                                  context,
                                ).size.height;
                                return IconButton(
                                  key: iconKey,
                                  onPressed: () {
                                    final taskid = isGroupTask
                                        ? combinedData['task']['taskID']
                                        : appData
                                              .showDetailTask
                                              .currentTask
                                              ?.taskId;
                                    _deleteTask(taskid.toString(), isGroupTask);
                                  },
                                  icon: Icon(Icons.delete, color: Colors.red),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // กรอบครอบส่วนที่ต้องการ
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color.fromARGB(
                                  255,
                                  96,
                                  96,
                                  97,
                                ).withValues(alpha: 0.1),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ชื่องาน
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Name : ',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _taskNameController,
                                        focusNode: _taskNameFocusNode,
                                        style: const TextStyle(fontSize: 20),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          // ไม่ต้องทำอะไรตรงนี้ก็ได้ ถ้ายังไม่ใช้
                                        },
                                        onSubmitted: (value) {
                                          // เมื่อผู้ใช้กด Enter เพื่อยืนยัน
                                          _confirmTaskNameEdit(isGroupTask);
                                          setState(() {
                                            _isEditingTaskName = false;
                                          });
                                          FocusScope.of(context).unfocus();
                                        },
                                      ),
                                    ),
                                    if (_isEditingTaskName)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        ),
                                        onPressed: () {
                                          _confirmTaskNameEdit(isGroupTask);
                                          setState(() {
                                            _isEditingTaskName = false;
                                          });
                                          FocusScope.of(
                                            context,
                                          ).unfocus(); // ยกเลิก focus
                                        },
                                      ),
                                    if (!_isEditingTaskName)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isEditingTaskName = true;
                                          });
                                          _taskNameFocusNode
                                              .requestFocus(); // กำหนดให้ TextField ได้ focus
                                        },
                                      ),
                                  ],
                                ),

                                const Divider(),
                                const SizedBox(height: 8),

                                // ปุ่ม status งาน
                                Row(
                                  children: [
                                    Flexible(
                                      flex: 1,
                                      child: _buildStatusButton(
                                        Icons.check,
                                        'Success',
                                        isGroupTask,
                                      ),
                                    ),
                                    const SizedBox(width: 6), // ลดจาก 8 เป็น 6
                                    Flexible(
                                      flex: 1,
                                      child: _buildStatusButton(
                                        Icons.priority_high,
                                        'Priority',
                                        isGroupTask,
                                      ),
                                    ),
                                    if (isGroupTask) ...[
                                      const SizedBox(
                                        width: 6,
                                      ), // ลดจาก 8 เป็น 6
                                      Flexible(
                                        flex: 1,
                                        child: _buildStatusButton(
                                          Icons.trending_up,
                                          'Progress',
                                          isGroupTask,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Group task specific buttons
                                if (isGroupTask) ...[
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildFullWidthButton(
                                        Icons.person_add,
                                        'Add assignees',
                                        isGroupTask,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                // Due date button
                                _buildFullWidthButton(
                                  Icons.calendar_today,
                                  'Set due date',
                                  isGroupTask,
                                ),
                              ],
                            ),
                          ),

                          // ส่วนที่อยู่นอกกรอบ
                          // แท็ป Description, Checklist, File
                          Row(
                            children: [
                              Expanded(
                                child: _buildTabButton('Description', 0),
                              ),
                              Expanded(child: _buildTabButton('Checklist', 1)),
                              Expanded(child: _buildTabButton('File', 2)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Tab content
                          _buildTabContent(),
                          const SizedBox(height: 16),

                          // Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _getFooterTitle(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
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
            ),
          ),
        );
      },
    );
  }

  void _deleteTask(String taskId, bool isGroupTask) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.02,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images/aleart/question.png",
                height: MediaQuery.of(context).size.height * 0.1,
                fit: BoxFit.contain,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                'Do you want to delete this task?',
                style: TextStyle(
                  fontSize: Get.textTheme.titleMedium!.fontSize!,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF007AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  fixedSize: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height * 0.05,
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleMedium!.fontSize!,
                    color: Colors.white,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  fixedSize: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height * 0.05,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: Get.textTheme.titleMedium!.fontSize!,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      Get.snackbar('Deleting...', '');
      deleteTaskById(taskId, isGroupTask);
    }
  }

  void deleteTaskById(dynamic ids, bool isGroupTask) async {
    if (!mounted) return;

    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = data.AllDataUserGetResponst.fromJson(userDataJson);
    if (!isGroupTask) {
      // Local storage logic (เดิม)

      existingData.tasks.removeWhere((t) => t.taskId.toString() == ids);
      box.write('userDataAll', existingData.toJson());
    } else {
      // 🔥 Firebase mode with Deleted State Management
      // 3. 🔄 ลบจาก Firebase ใน background
      _deleteFromFirebaseInBackground(ids).then((_) {
        // 4. อัพเดท local storage หลังจากลบ Firebase สำเร็จ
        existingData.tasks.removeWhere((t) => t.taskId.toString() == ids);
        box.write('userDataAll', existingData.toJson());
      });
    }

    // เรียก API ลบใน background
    final endpoint = "deltask/$ids";
    final requestBody = {"task_id": ids};
    deleteWithRetry(endpoint, requestBody);
  }

  Future<http.Response> deleteWithRetry(
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    url = await loadAPIEndpoint();

    final token = box.read('accessToken');
    Uri uri = Uri.parse("$url/$endpoint");

    Future<http.Response> sendRequest(String token) {
      return http.delete(
        uri,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer $token",
        },
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
    log(response.statusCode.toString());
    if (response.statusCode == 200) {
      Get.snackbar('Task deleted successfully.', '');
      if (mounted) Navigator.pop(context, 'refresh');
    }

    return response;
  }

  Future<void> _deleteFromFirebaseInBackground(dynamic taskIdPayload) async {
    await _deleteSingleTaskFromFirebase(taskIdPayload.toString());
  }

  Future<void> _deleteSingleTaskFromFirebase(String taskId) async {
    final appData = Provider.of<Appdata>(context, listen: false);
    // ลบจาก Boards collection
    await FirebaseFirestore.instance
        .collection('Boards')
        .doc(appData.boardDatas.idBoard)
        .collection('Tasks')
        .doc(taskId)
        .delete();

    // ลบจาก BoardTasks collection รวม notifications
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
    await loadDataAsync();
    // ลบ BoardTasks document
    await taskDocRef.delete();
  }

  ({Appdata appData, data.Task? currentTask}) _getAppDataAndTask() {
    final appData = Provider.of<Appdata>(context, listen: false);
    final currentTask = appData.showDetailTask.currentTask;
    return (appData: appData, currentTask: currentTask);
  }

  // สร้างหัวข้อของ header
  String _getHeaderTitle() {
    // ถ้ามีข้อมูลจาก Firestore (Group Task) ให้ใช้เป็นหลัก
    if (combinedData.containsKey('task') &&
        combinedData['task']?['taskName'] != null) {
      return combinedData['task']['taskName'];
    }

    // ถ้าไม่มี ให้ fallback ไปใช้ข้อมูลจาก local
    final data = _getAppDataAndTask();
    return data.currentTask?.taskName ?? 'กำลังโหลดข้อมูล...';
  }

  String _getPathTaskTitle() {
    final data = _getAppDataAndTask();
    final currentTask = data.currentTask;
    final appData = data.appData;

    if (currentTask == null) {
      return 'กำลังโหลดข้อมูล...';
    }

    // ========== กรณี Group Task (Firestore) ==========
    if (appData.showDetailTask.isGroupTask) {
      final taskName = combinedData['task']?['taskName'] ?? 'ไม่มีชื่อ Task';
      final boardName = combinedData['board']?['BoardName'] ?? 'ไม่มีชื่อบอร์ด';
      return '$boardName > $taskName';
    }

    // ========== กรณี Task Today ==========
    if (currentTask.boardId == 'Today') {
      return 'Today > ${currentTask.taskName}';
    }

    // ========== กรณี Individual Task ==========
    final boardId = currentTask.boardId;

    if (boardId == null) {
      return 'ไม่พบชื่อบอร์ด > ${currentTask.taskName}';
    }

    final boardIdInt = _parseBoardId(boardId);
    if (boardIdInt == null) {
      return 'ไม่พบชื่อบอร์ด > ${currentTask.taskName}';
    }

    String boardName;
    try {
      boardName = appData.showMyBoards.createdBoards
          .firstWhere((b) => b.boardId == boardIdInt)
          .boardName;
    } catch (_) {
      boardName = 'ไม่พบชื่อบอร์ด';
    }
    return '$boardName > ${currentTask.taskName}';
  }

  // สร้างหัวข้อที่ footer
  String _getFooterTitle() {
    final appData = Provider.of<Appdata>(context, listen: false);
    final currentTask = appData.showDetailTask.currentTask;

    final taskData = combinedData['task'];
    final rawTimestamp = taskData?['createAt'] ?? currentTask?.createdAt;

    final timestampStr = _convertTimestampToString(rawTimestamp);

    try {
      final dateTime = DateTime.parse(timestampStr);
      final formattedDate = DateFormat(
        'dd MMM yyyy HH:mm',
        'th',
      ).format(dateTime);
      return 'Created at $formattedDate';
    } catch (e) {
      return 'Created at $timestampStr';
    }
  }

  // แปลงtimestampของfirestore
  String _convertTimestampToString(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now().toIso8601String();
    } else if (timestamp is String) {
      return timestamp;
    } else if (timestamp.toString().contains('Timestamp')) {
      // สำหรับ Firestore Timestamp
      return timestamp.toDate().toIso8601String();
    } else {
      // สำหรับกรณีอื่นๆ ลองแปลงเป็น String
      return timestamp.toString();
    }
  }

  int? _parseBoardId(dynamic boardId) {
    if (boardId is int) return boardId;
    if (boardId is String) return int.tryParse(boardId);
    return null;
  }

  // เปลี่ยนชื่องาน
  Future<void> _confirmTaskNameEdit(bool isgroup) async {
    final existingData = _getUserData();
    if (existingData == null) return;

    final data = _getAppDataAndTask();
    final currentTask = data.currentTask;
    final appData = data.appData;
    final newTaskName = _taskNameController.text.trim();

    String? oldName;
    int? taskId;
    bool hasChanges = false; // เพิ่มตัวแปรเช็คการเปลี่ยนแปลง

    try {
      if (isgroup) {
        final taskData = combinedData['task'];
        if (taskData != null) {
          final currentTaskName = taskData['taskName'] ?? '';
          oldName = taskData['taskName'];
          taskId = taskData['taskID'];
          if (newTaskName != currentTaskName) {
            combinedData['task']['taskName'] = newTaskName;
            hasChanges = true; // มีการเปลี่ยนแปลง
          } else {
            log("ไม่มีการเปลี่ยนแปลงชื่อ task");
          }
        }
      } else {
        if (currentTask != null) {
          final currentTaskName = currentTask.taskName ?? '';
          oldName = currentTaskName;
          taskId = currentTask.taskId;
          if (newTaskName != currentTaskName) {
            currentTask.taskName = newTaskName;
            hasChanges = true; // มีการเปลี่ยนแปลง
          } else {
            log("ไม่มีการเปลี่ยนแปลงชื่อ task");
          }
        }
      }

      // ออกจาก focus เสมอไม่ว่าจะมีการเปลี่ยนแปลงหรือไม่
      setState(() {
        _isEditingTaskName = false;
        FocusScope.of(context).unfocus();
      });

      // ถ้าไม่มีการเปลี่ยนแปลงให้หยุดทำงานที่นี่
      if (!hasChanges) {
        return;
      }

      if (currentTask != null) {
        int? index = _findIndexCurrentTask(currentTask);
        if (index != null) {
          existingData.tasks[index].taskName = newTaskName;
          box.write('userDataAll', existingData.toJson());
        }
      }

      url = await loadAPIEndpoint();

      final body = jsonEncode({
        "task_name": newTaskName,
        "description": currentTask?.description ?? "",
        "priority": currentTask?.priority ?? "",
      });

      var response = await http.put(
        Uri.parse("$url/updatetask/$taskId"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: body,
      );

      if (response.statusCode == 403) {
        await loadNewRefreshToken();
        response = await http.put(
          Uri.parse("$url/updatetask/$taskId"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
          body: body,
        );
      }

      if (response.statusCode == 200) {
        log('อัปเดตชื่อ task สำเร็จ');
        await loadDataAsync();
      } else {
        log('Error updating task: ${response.statusCode}');
        setState(() {
          if (isgroup) {
            combinedData['task']['taskName'] = oldName ?? "";
          } else {
            currentTask?.taskName = oldName ?? "";
          }
        });
      }
    } catch (e) {
      log('Exception during task name update: $e');
      setState(() {
        if (isgroup) {
          combinedData['task']['taskName'] = oldName ?? "";
        } else {
          currentTask?.taskName = oldName ?? "";
        }
      });
    }
  }

  // สร้างปุ่ม 3 ปุ่ม
  Widget _buildStatusButton(IconData icon, String label, bool isGroupTask) {
    // ดึงข้อมูล task ตามประเภท
    String currentStatus = '0';
    String currentPriority = '1';
    String taskName = '';

    if (isGroupTask) {
      // ข้อมูลจาก combinedData (Firestore)
      final taskData = combinedData['task'];
      if (taskData != null) {
        currentStatus = taskData['status']?.toString() ?? '0';
        currentPriority = taskData['priority']?.toString() ?? '1';
        taskName = taskData['taskName'] ?? '';
      }
    } else {
      // ข้อมูลจาก currentTask (Individual)
      final data = _getAppDataAndTask();
      final currentTask = data.currentTask;
      if (currentTask != null) {
        currentStatus = currentTask.status ?? '0';
        currentPriority = currentTask.priority ?? '1';
        taskName = currentTask.taskName ?? '';
      }
    }

    bool isCompleted = currentStatus == '2';
    bool isInProgress = currentStatus == '1';

    // กำหนดสีและสถานะของปุ่ม
    Color backgroundColor;
    Color textColor;
    IconData displayIcon;
    String displayLabel = label;

    if (label == 'Success') {
      if (isCompleted) {
        backgroundColor = Colors.green;
        textColor = Colors.white;
        displayIcon = Icons.check;
        displayLabel = 'Success';
      } else {
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[600]!;
        displayIcon = icon;
      }
    } else if (label == 'Progress') {
      // Progress button styling
      Map<String, dynamic> progressStyle = _getProgressStyle(currentStatus);
      backgroundColor = progressStyle['backgroundColor'];
      textColor = progressStyle['textColor'];
      displayIcon = progressStyle['icon'];
      displayLabel = progressStyle['label'];
    } else if (label == 'Priority') {
      // Priority button styling with color indicators
      Map<String, dynamic> priorityStyle = _getPriorityStyle(currentPriority);
      backgroundColor = priorityStyle['backgroundColor'];
      textColor = priorityStyle['textColor'];
      displayIcon = priorityStyle['icon'];
      displayLabel = priorityStyle['label'];
    } else {
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.grey[600]!;
      displayIcon = icon;
    }

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        if (label == 'Progress' || label == 'Priority') {
          _showStatusDropdown(
            context,
            label,
            isGroupTask,
            details.globalPosition,
          );
        }
      },
      onTap: () {
        if (label != 'Progress' && label != 'Priority') {
          log('Status button "$displayLabel" clicked for task: $taskName');
          switch (label) {
            case 'Success':
              // ตรวจสอบสถานะปัจจุบันและสลับระหว่าง success/complete
              if (currentStatus == '2') {
                // ถ้าสถานะเป็น complete (2) ให้รีเซ็ตเป็น 0
                _updateTaskStatus(isGroupTask, '0');
              } else {
                // ถ้าสถานะเป็น 0 หรือ 1 ให้เปลี่ยนเป็น success (2)
                _updateTaskStatus(isGroupTask, '2');
              }
              break;
            default:
              log('Unknown label: $label');
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(displayIcon, size: 16, color: textColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // แสดง priority indicator สำหรับ Priority button
            if (label == 'Priority') ...[
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getPriorityIndicatorColor(currentPriority),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Progress ไอคอน
  Map<String, dynamic> _getProgressStyle(String currentStatus) {
    switch (currentStatus) {
      case '0': // Not started
        return {
          'backgroundColor': Colors.grey[200]!,
          'textColor': Colors.grey[600]!,
          'icon': Icons.radio_button_unchecked,
          'label': 'Todo',
        };
      case '1': // In progress
        return {
          'backgroundColor': Colors.orange[100]!,
          'textColor': Colors.orange[700]!,
          'icon': Icons.autorenew,
          'label': 'In Progress',
        };
      case '2': // Completed
        return {
          'backgroundColor': Colors.green[100]!,
          'textColor': Colors.green[700]!,
          'icon': Icons.check_circle,
          'label': 'Completed',
        };
      default:
        return {
          'backgroundColor': Colors.grey[200]!,
          'textColor': Colors.grey[600]!,
          'icon': Icons.help_outline,
          'label': 'Progress',
        };
    }
  }

  // Priority ไอคอน
  Map<String, dynamic> _getPriorityStyle(String currentPriority) {
    switch (currentPriority) {
      case '1': // Low priority
        return {
          'backgroundColor': Colors.green[50]!,
          'textColor': Colors.green[700]!,
          'icon': Icons.keyboard_arrow_down,
          'label': 'Low',
        };
      case '2': // Medium priority
        return {
          'backgroundColor': Colors.orange[50]!,
          'textColor': Colors.orange[700]!,
          'icon': Icons.remove,
          'label': 'Medium',
        };
      case '3': // High priority
        return {
          'backgroundColor': Colors.red[50]!,
          'textColor': Colors.red[700]!,
          'icon': Icons.keyboard_arrow_up,
          'label': 'High',
        };
      default:
        return {
          'backgroundColor': Colors.grey[200]!,
          'textColor': Colors.grey[600]!,
          'icon': Icons.priority_high,
          'label': 'Priority',
        };
    }
  }

  // Helper method สำหรับสี indicator ของ Priority
  Color _getPriorityIndicatorColor(String currentPriority) {
    switch (currentPriority) {
      case '1': // Low priority
        return Colors.green;
      case '2': // Medium priority
        return Colors.orange;
      case '3': // High priority
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // dropdown priority กับ progress
  void _showStatusDropdown(
    BuildContext context,
    String type,
    bool isGroupTask,
    Offset buttonPosition,
  ) {
    List<Map<String, dynamic>> options = [];

    if (type == 'Progress') {
      options = [
        {
          'label': 'Not Started',
          'value': 'not_started',
          'icon': Icons.radio_button_unchecked,
          'statusValue': '0',
          'color': Colors.grey[600],
          'backgroundColor': Colors.grey[50],
        },
        {
          'label': 'In Progress',
          'value': 'in_progress',
          'icon': Icons.autorenew,
          'statusValue': '1',
          'color': Colors.orange[700],
          'backgroundColor': Colors.orange[50],
        },
        {
          'label': 'Completed',
          'value': 'completed',
          'icon': Icons.check_circle,
          'statusValue': '2',
          'color': Colors.green[700],
          'backgroundColor': Colors.green[50],
        },
      ];
    } else if (type == 'Priority') {
      options = [
        {
          'label': 'Low',
          'value': 'low',
          'icon': Icons.keyboard_arrow_down,
          'priorityValue': '1', // แก้ไขจาก '1' เป็น '0'
          'color': Colors.green[700],
          'backgroundColor': Colors.green[50],
          'indicatorColor': Colors.green,
        },
        {
          'label': 'Medium',
          'value': 'medium',
          'icon': Icons.remove,
          'priorityValue': '2', // แก้ไขจาก '2' เป็น '1'
          'color': Colors.orange[700],
          'backgroundColor': Colors.orange[50],
          'indicatorColor': Colors.orange,
        },
        {
          'label': 'High',
          'value': 'high',
          'icon': Icons.keyboard_arrow_up,
          'priorityValue': '3', // แก้ไขจาก '3' เป็น '2'
          'color': Colors.red[700],
          'backgroundColor': Colors.red[50],
          'indicatorColor': Colors.red,
        },
      ];
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx,
        buttonPosition.dy + 20, // ปรับตำแหน่งให้อยู่ใต้ปุ่ม
        buttonPosition.dx + 180, // เพิ่มความกว้างเล็กน้อย
        buttonPosition.dy + 200,
      ),
      items: options.map((option) {
        return PopupMenuItem(
          value: option['value'],
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: option['backgroundColor'],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(option['icon'], size: 18, color: option['color']),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option['label'],
                    style: TextStyle(
                      color: option['color'],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // แสดง priority indicator สำหรับ Priority dropdown
                if (type == 'Priority') ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: option['indicatorColor'],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ).then((selectedValue) {
      if (selectedValue != null) {
        if (type == 'Priority') {
          // หาค่า priorityValue ที่ตรงกับ selectedValue
          final selectedOption = options.firstWhere(
            (option) => option['value'] == selectedValue,
          );
          _updateTaskPriority(isGroupTask, selectedOption['priorityValue']);
        } else if (type == 'Progress') {
          // หาค่า statusValue ที่ตรงกับ selectedValue
          final selectedOption = options.firstWhere(
            (option) => option['value'] == selectedValue,
          );
          _updateTaskStatus(isGroupTask, selectedOption['statusValue']);
        }
      }
    });
  }

  // เปลี่ยน status งาน
  Future<void> _updateTaskStatus(bool isGroupTask, String newStatus) async {
    final existingData = _getUserData();
    if (existingData == null) return;

    final appDataAndTask = _getAppDataAndTask();
    final currentTask = appDataAndTask.appData.showDetailTask.currentTask;

    if (!isGroupTask && currentTask == null) {
      log('Error: currentTask is null for individual task');
      return;
    }
    try {
      String? taskId;
      String? oldStatus;
      if (isGroupTask) {
        // ข้อมูลจาก combinedData (Firestore)
        final taskData = combinedData['task'];
        if (taskData != null) {
          taskId = taskData['taskID']?.toString();
          oldStatus = taskData['status']?.toString() ?? '0';

          // อัปเดตสถานะใน UI ทันที
          setState(() {
            combinedData['task']['status'] = newStatus;
          });
        }
      } else {
        if (currentTask != null) {
          taskId = currentTask.taskId.toString();
          oldStatus = currentTask.status ?? '0';

          // อัปเดตสถานะใน UI ทันที
          setState(() {
            currentTask.status = newStatus;
          });
        }
      }

      int? index = _findIndexCurrentTask(currentTask!);
      log('Current task index: $index');

      existingData.tasks[index!].status = newStatus;
      box.write('userDataAll', existingData.toJson());

      // ตรวจสอบว่ามี taskId หรือไม่
      if (taskId == null) {
        log('Error: taskId is null');
        return;
      }
      log('Updating task status to $newStatus for taskId: $taskId');
      url = await loadAPIEndpoint();
      final body = jsonEncode({"status": newStatus});

      var response = await http.put(
        Uri.parse("$url/updatestatus/$taskId"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: body,
      );

      if (response.statusCode == 403) {
        await loadNewRefreshToken();
        response = await http.put(
          Uri.parse("$url/updatestatus/$taskId"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
          body: body,
        );
      }

      if (response.statusCode == 200) {
        log('อัปเดตสถานะ task สำเร็จ: $newStatus');

        await loadDataAsync();
      } else {
        log('Error updating task status: ${response.statusCode}');
        // กรณี error ให้ revert สถานะกลับ
        setState(() {
          if (isGroupTask) {
            final taskData = combinedData['task'];
            if (taskData != null) {
              combinedData['task']['status'] = oldStatus ?? '0';
            }
          } else {
            final appDataAndTask = _getAppDataAndTask();
            final currentTask =
                appDataAndTask.appData.showDetailTask.currentTask;
            if (currentTask != null) {
              currentTask.status = oldStatus ?? '0';
            }
          }
        });
      }
    } catch (e) {
      log('Exception updating task status: $e');
      // กรณี exception ให้ revert สถานะกลับ
      String revertStatus = '0'; // default

      if (isGroupTask) {
        final taskData = combinedData['task'];
        if (taskData != null) {
          // หาสถานะเดิมจากการตรวจสอบ
          revertStatus = (newStatus == '2') ? '0' : '2';
        }
      } else {
        final appDataAndTask = _getAppDataAndTask();
        final currentTask = appDataAndTask.appData.showDetailTask.currentTask;
        if (currentTask != null) {
          revertStatus = (newStatus == '2') ? '0' : '2';
        }
      }

      setState(() {
        if (isGroupTask) {
          final taskData = combinedData['task'];
          if (taskData != null) {
            combinedData['task']['status'] = revertStatus;
          }
        } else {
          final appDataAndTask = _getAppDataAndTask();
          final currentTask = appDataAndTask.appData.showDetailTask.currentTask;
          if (currentTask != null) {
            currentTask.status = revertStatus;
          }
        }
      });
    }
  }

  //เปลี่ยน priority งาน
  Future<void> _updateTaskPriority(
    bool isGroupTask,
    String selectedPriority,
  ) async {
    if (!mounted) return;
    final existingData = _getUserData();
    if (existingData == null) return;
    final appDataAndTask = _getAppDataAndTask();
    final currentTask = appDataAndTask.appData.showDetailTask.currentTask;

    if (!isGroupTask && currentTask == null) {
      log('Error: currentTask is null for individual task');
      return;
    }
    try {
      String? taskId;
      String? oldPriority;
      log(selectedPriority);
      if (isGroupTask) {
        // ข้อมูลจาก combinedData (Firestore)
        final taskData = combinedData['task'];
        if (taskData != null) {
          taskId = taskData['taskID']?.toString();
          oldPriority = taskData['priority']?.toString() ?? '1';

          // อัปเดตสถานะใน UI ทันที
          if (mounted) {
            setState(() {
              combinedData['task']['priority'] = selectedPriority;
            });
          }
        }
      } else {
        if (currentTask != null) {
          taskId = currentTask.taskId.toString();
          oldPriority = currentTask.priority ?? '1';

          // อัปเดตสถานะใน UI ทันที
          setState(() {
            currentTask?.priority = selectedPriority;
          });
        }
      }

      int? index = _findIndexCurrentTask(currentTask!);
      log('Current task index: $index');

      existingData.tasks[index!].priority = selectedPriority;
      box.write('userDataAll', existingData.toJson());

      url = await loadAPIEndpoint();

      final body = jsonEncode({
        "task_name": currentTask?.taskName ?? "",
        "description": currentTask?.description ?? "",
        "priority": selectedPriority,
      });
      var response = await http.put(
        Uri.parse("$url/updatetask/${currentTask?.taskId}"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: body,
      );
      if (response.statusCode == 403) {
        await loadNewRefreshToken();
        var response = await http.put(
          Uri.parse("$url/updatetask/${currentTask?.taskId}"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
          body: body,
        );
      }
      if (response.statusCode == 200) {
        log('อัปเดต priority task สำเร็จ: $selectedPriority');
        await loadDataAsync();
      } else {
        log('Error updating task priority: ${response.statusCode}');
        // กรณี error ให้ revert priority กลับ
        setState(() {
          if (isGroupTask) {
            final taskData = combinedData['task'];
            if (taskData != null) {
              combinedData['task']['priority'] = oldPriority ?? '1';
            }
          } else {
            final appData = _getAppDataAndTask();
            final currentTask = appData.appData.showDetailTask.currentTask;
            if (currentTask != null) {
              currentTask.priority = oldPriority ?? '1';
            }
          }
        });
      }
    } catch (e) {
      log('Exception updating task status: $e');
      // กรณี exception ให้ revert สถานะกลับ
      String revertPriority = '1'; // default

      if (isGroupTask) {
        final taskData = combinedData['task'];
        if (taskData != null) {
          // หาสถานะเดิมจากการตรวจสอบ
          revertPriority = (selectedPriority == '3') ? '1' : '2';
        }
      } else {
        final appData = _getAppDataAndTask();
        final currentTask = appData.appData.showDetailTask.currentTask;
        if (currentTask != null) {
          revertPriority = (selectedPriority == '3') ? '1' : '2';
        }
      }

      if (mounted) {
        setState(() {
          if (isGroupTask) {
            final taskData = combinedData['task'];
            if (taskData != null) {
              combinedData['task']['priority'] = revertPriority;
            }
          } else {
            final appData = _getAppDataAndTask();
            final currentTask = appData.appData.showDetailTask.currentTask;
            if (currentTask != null) {
              currentTask.priority = revertPriority;
            }
          }
        });
      }
    }
  }

  // สร้างแท็ป assigned กับ set duedate
  Widget _buildFullWidthButton(IconData icon, String label, bool isGroupTask) {
    final appData = Provider.of<Appdata>(context, listen: false);
    final currentTask = appData.showDetailTask.currentTask;

    // สร้างข้อความที่จะแสดงบนปุ่ม
    String displayText = label;
    final userinBoard = combinedData['boardUsers'] as List<dynamic>? ?? [];
    final userAssigned = combinedData['assigned'] as List<dynamic>? ?? [];
    List<dynamic> notification = [];

    if (isGroupTask) {
      // สำหรับ Group Task ใช้ข้อมูลจาก combinedData
      if (combinedData != null) {
        notification = combinedData['notifications'] as List<dynamic>? ?? [];
      }
    } else {
      // สำหรับ Individual Task ใช้ข้อมูลจาก currentTask
      if (currentTask != null) {
        notification = currentTask.notifications
            .map((n) => n.toJson())
            .toList();
      }
    }

    // แก้ไขการแสดงผลสำหรับ Set due date
    String isSend = '2';
    DateTime? dueDate;
    if (label == 'Set due date' && notification.isNotEmpty) {
      final firstNotification = notification.first;

      if (isGroupTask) {
        // สำหรับ Group Task
        isSend = firstNotification['isSend'].toString();
        if (firstNotification['dueDate'] != null) {
          // Handle Timestamp object
          final timestamp = firstNotification['dueDate'];
          if (timestamp.runtimeType.toString().contains('Timestamp')) {
            dueDate = DateTime.fromMillisecondsSinceEpoch(
              timestamp.seconds * 1000 +
                  (timestamp.nanoseconds / 1000000).round(),
            );
          }
        }
      } else {
        // สำหรับ Individual Task
        isSend = firstNotification['IsSend'] ?? true;
        if (firstNotification['DueDate'] != null) {
          // แปลงจาก UTC เป็น local time
          dueDate = DateTime.parse(firstNotification['DueDate']).toLocal();
        }
      }

      // เปลี่ยน displayText ตามเงื่อนไข
      if (isSend != "2" && dueDate != null) {
        displayText = ''; // เราจะใช้ widget แทน
      }
    }

    final assignedUserDetails = userAssigned
        .map((assignedUser) {
          final userId = assignedUser['userId'];
          final matchedUser = userinBoard.firstWhere(
            (user) => user['UserID'] == userId,
            orElse: () => <String, dynamic>{}, // Fixed: specify correct type
          );
          return matchedUser.isNotEmpty ? matchedUser : null;
        })
        .where((user) => user != null)
        .toList();

    // ฟังก์ชันสำหรับสร้างอวตารของ user
    Widget buildUserAvatar(Map<String, dynamic> user) {
      final profileUrl = user['Profile'] as String?;
      final userName = user['Name'] as String? ?? '';

      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: ClipOval(
          child: profileUrl != null && profileUrl != 'none-url'
              ? Image.network(
                  profileUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    );
                  },
                )
              : Icon(Icons.person, size: 16, color: Colors.grey[600]),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (label == 'Set due date') {
          _showCustomDateTimePicker(context);
          log("set date and time");
        } else if (label == 'Add assignees') {
          _buildDialogAssignedUser();
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: label == 'Add assignees' && assignedUserDetails.isNotEmpty
                  ? Row(
                      children: [
                        // แสดงอวตารของ assigned users
                        Wrap(
                          spacing: 4,
                          children: assignedUserDetails.take(3).map((user) {
                            return buildUserAvatar(
                              user as Map<String, dynamic>,
                            );
                          }).toList(),
                        ),
                        // แสดงจำนวนที่เหลือถ้ามีมากกว่า 3 คน
                        if (assignedUserDetails.length > 3) ...[
                          SizedBox(width: 8),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                            child: Center(
                              child: Text(
                                '+${assignedUserDetails.length - 3}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  : label == 'Set due date' &&
                        notification.isNotEmpty &&
                        isSend != "2" &&
                        dueDate != null
                  ? _buildDueDateReminderWidget(notification.first, isGroupTask)
                  : Text(
                      displayText,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสำหรับสร้าง widget แสดงเวลาแจ้งเตือน
  Widget _buildDueDateReminderWidget(
    Map<String, dynamic> notification,
    bool isGroupTask,
  ) {
    final dueDate = _getDueDate(notification, isGroupTask);
    if (dueDate == null) return Text('Set due date');

    final now = DateTime.now();
    final difference = dueDate.difference(now);

    // ฟอร์แมตวันที่เป็น dd/MM/yyyy (พ.ศ.)
    final buddhistYear = dueDate.year + 543;
    final formattedDate =
        '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/$buddhistYear';

    String timeText;
    if (difference.inDays > 0) {
      timeText =
          'remind in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ';
    } else if (difference.inHours > 0) {
      timeText =
          'remind in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ';
    } else if (difference.inMinutes > 0) {
      timeText =
          'remind in ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ';
    } else if (difference.inSeconds > 0) {
      timeText =
          'remind in ${difference.inSeconds} second${difference.inSeconds > 1 ? 's' : ''} ';
    } else {
      timeText = 'overdue ';
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: timeText,
            style: TextStyle(color: Colors.black),
          ),
          TextSpan(
            text: '($formattedDate)',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  // ฟังก์ชันสำหรับได้รับ dueDate
  DateTime? _getDueDate(Map<String, dynamic> notification, bool isGroupTask) {
    if (isGroupTask) {
      if (notification['dueDate'] != null) {
        final timestamp = notification['dueDate'];
        if (timestamp.runtimeType.toString().contains('Timestamp')) {
          return DateTime.fromMillisecondsSinceEpoch(
            timestamp.seconds * 1000 +
                (timestamp.nanoseconds / 1000000).round(),
          );
        }
      }
    } else {
      if (notification['DueDate'] != null) {
        return DateTime.parse(notification['DueDate']);
      }
    }
    return null;
  }

  void _showCustomDateTimePicker(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime tempSelectedDate = now;
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
                                    selectedBeforeMinutes = null;
                                    selectedReminder = null;
                                    customReminderDateTime = null;
                                    isShowMenuRemind = false;
                                    isCustomReminderApplied = false;
                                  });
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
                                  });
                                  _updateDueDate();
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
                        childAspectRatio: 8.5,
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

  Future<void> _updateDueDate() async {
    log("_updateDueDate");
    try {
      final userDataJson = box.read('userDataAll');
      if (userDataJson == null) return;

      final appData = Provider.of<Appdata>(context, listen: false);

      // อ่านข้อมูลครั้งเดียวและเก็บไว้ใช้ต่อ
      var existingData = data.AllDataUserGetResponst.fromJson(userDataJson);

      // เก็บข้อมูลเดิมไว้สำหรับ rollback (deep copy)
      final originalDataJson = json.encode(existingData.toJson());
      final originalData = data.AllDataUserGetResponst.fromJson(
        json.decode(originalDataJson),
      );

      final currentTask = appData.showDetailTask.currentTask;
      bool isGroupTask = appData.showDetailTask.isGroupTask;

      int? taskId;
      int? index;
      int? notificationId;
      String? boardId;

      if (isGroupTask) {
        taskId = combinedData['task']['taskID'];
        notificationId = combinedData['notifications'][0]['notificationID'];
        boardId = combinedData['board']['BoardID'].toString();
        if (taskId == null) {
          log('Error: taskId is null for group task');
          return;
        }
      } else {
        taskId = currentTask?.taskId;
        notificationId = currentTask?.notifications.isNotEmpty == true
            ? currentTask!.notifications.first.notificationId
            : null;
        boardId = currentTask?.boardId.toString();
        if (taskId == null) {
          log('Error: taskId is null for individual task');
          return;
        }
      }

      index = _findIndexCurrentTask(currentTask!);
      if (index == null) {
        log('Error: Cannot find current task index');
        return;
      }

      // ตรวจสอบว่า notification มีอยู่จริง
      if (existingData.tasks[index].notifications.isEmpty) {
        log('Error: No notifications found for this task');
        return;
      }

      DateTime dueDate;
      if (selectedReminder != null && selectedReminder!.isNotEmpty) {
        if (selectedReminder!.startsWith('Custom:')) {
          dueDate = customReminderDateTime!;
        } else {
          dueDate = convertReminderToDateTime(selectedReminder!);
        }
      } else {
        dueDate = DateTime.now();
      }
      DateTime? beforeDueDate;
      if (!_isValidNotificationTime(dueDate, selectedBeforeMinutes)) {
        beforeDueDate = calculateNotificationTime(
          dueDate,
          selectedBeforeMinutes,
        );
      } else {
        beforeDueDate = calculateNotificationTime(
          dueDate,
          selectedBeforeMinutes,
        );
      }

      log("New dueDate to set: ${dueDate.toString()}");
      log(dueDate.toUtc().toIso8601String().toString());

      // อัพเดทข้อมูลใน existingData
      final newDueDateString = dueDate.toUtc().toIso8601String();
      final newBeforeDueDateString =
          selectedBeforeMinutes != null && beforeDueDate != null
          ? beforeDueDate.toUtc().toIso8601String()
          : null;
      final newIsSend = '0';
      final newRecurringPattern = (selectedRepeat ?? 'Onetime').toLowerCase();

      // 1. อัพเดท local storage
      existingData.tasks[index].notifications[0].dueDate = newDueDateString;
      existingData.tasks[index].notifications[0].isSend = newIsSend;
      existingData.tasks[index].notifications[0].recurringPattern =
          newRecurringPattern;
      box.write('userDataAll', existingData.toJson());

      // 2. อัพเดท currentTask ใน showDetailTask
      if (!isGroupTask && currentTask != null) {
        // สร้าง Task object ใหม่ที่มีข้อมูลอัปเดท
        final updatedTask = data.Task(
          assigned: currentTask.assigned,
          attachments: currentTask.attachments,
          boardId: currentTask.boardId,
          checklists: currentTask.checklists,
          createBy: currentTask.createBy,
          createdAt: currentTask.createdAt,
          description: currentTask.description,
          notifications: currentTask.notifications.map((notification) {
            if (notification.notificationId == notificationId) {
              return data.Notification(
                beforeDueDate:
                    selectedBeforeMinutes != null && beforeDueDate != null
                    ? beforeDueDate.toUtc().toIso8601String()
                    : null.toString(),
                createdAt: notification.createdAt,
                dueDate: newDueDateString,
                isSend: newIsSend,
                notificationId: notification.notificationId,
                recurringPattern: newRecurringPattern,
                taskId: notification.taskId,
              );
            }
            return notification;
          }).toList(),
          priority: currentTask.priority,
          status: currentTask.status,
          taskId: currentTask.taskId,
          taskName: currentTask.taskName,
        );

        // อัพเดท currentTask ใน provider
        appData.showDetailTask.setCurrentTask(
          updatedTask,
          isGroup: isGroupTask,
        );
      }

      log("✅ currentTask updated for individual task");
      log("✅ Local data updated - New dueDate: $newDueDateString");
      log("✅ Local data updated - New isSend: $newIsSend");
      log("✅ Local data updated - New beforeDueDate: $newBeforeDueDateString");

      // อัพเดท UI ทันที
      setState(() {
        // UI จะแสดงข้อมูลใหม่ทันที
      });

      // ส่ง API request
      final url = await loadAPIEndpoint();
      var requestBody = {
        "due_date": newDueDateString,
        "before_due_date": newBeforeDueDateString,
        "recurring_pattern": (selectedRepeat ?? 'Onetime').toLowerCase(),
        "is_send": newIsSend,
      };

      var headers = {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      };

      var response = await http.put(
        Uri.parse("$url/notification/update/$taskId"),
        headers: headers,
        body: json.encode(requestBody),
      );

      // Handle token refresh
      if (response.statusCode == 403) {
        log("Token expired, refreshing...");
        await loadNewRefreshToken();
        headers["Authorization"] = "Bearer ${box.read('accessToken')}";

        response = await http.put(
          Uri.parse("$url/notification/update/$taskId"),
          headers: headers,
          body: json.encode(requestBody),
        );
      }

      if (response.statusCode == 200) {
        // API สำเร็จ
        log("✅ API request successful");

        // Setup notification
        _setupTaskNotifications(
          taskId,
          notificationId!,
          dueDate,
          appData,
          isGroupTask,
          boardId!,
        );

        // แสดง success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Due date updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // *** ไม่เรียก loadDataAsync() ทันที เพื่อป้องกันการเขียนทับ ***
        // หากจำเป็นต้อง sync ข้อมูลอื่น ให้ delay หรือทำแบบ selective sync
      } else {
        // API ล้มเหลว - Rollback
        log("❌ API request failed: ${response.statusCode}");
        log("Rolling back local data...");

        // Rollback ข้อมูล local
        box.write('userDataAll', originalData.toJson());

        // Rollback currentTask ใน showDetailTask
        if (!isGroupTask && currentTask != null) {
          // สร้าง Task object เดิมกลับคืนมา
          final originalTask = originalData.tasks[index];
          appData.showDetailTask.setCurrentTask(
            originalTask,
            isGroup: isGroupTask,
          );
        }

        setState(() {
          // Rollback UI
        });

        // แสดง error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update due date. Changes reverted.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      log('❌ Exception in _updateDueDate: $e');
      log('Stack trace: $stackTrace');

      // Rollback ในกรณี exception
      try {
        final userDataJson = box.read('userDataAll');
        if (userDataJson != null) {
          // อ่านข้อมูลล่าสุดจาก storage
          final currentData = data.AllDataUserGetResponst.fromJson(
            userDataJson,
          );
          // หรือใช้ข้อมูล backup ที่เตรียมไว้

          // Rollback currentTask หาก exception เกิดขึ้นหลังจากอัปเดท
          final appData = Provider.of<Appdata>(context, listen: false);
          final currentTask = appData.showDetailTask.currentTask;
          bool isGroupTask = appData.showDetailTask.isGroupTask;

          if (!isGroupTask && currentTask != null) {
            final index = _findIndexCurrentTask(currentTask);
            if (index != null && index < currentData.tasks.length) {
              final originalTask = currentData.tasks[index];
              appData.showDetailTask.setCurrentTask(
                originalTask,
                isGroup: isGroupTask,
              );
            }
          }
        }
      } catch (rollbackError) {
        log('Error during rollback: $rollbackError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setupTaskNotifications(
    int realTaskId,
    int notificationID,
    DateTime dueDate,
    dynamic appData,
    bool isGroupTask,
    String boardiD,
  ) async {
    await FirebaseFirestore.instance
        .collection(isGroupTask ? 'BoardTasks' : 'Notifications')
        .doc(
          isGroupTask
              ? realTaskId.toString()
              : box.read('userProfile')['email'],
        )
        .collection(isGroupTask ? 'Notifications' : 'Tasks')
        .doc(notificationID.toString())
        .update({
          'isNotiRemind': false,
          'isShow': dueDate.isAfter(DateTime.now())
              ? false
              : FieldValue.delete(),
        });

    if (isGroupTask) {
      // ตั้งค่า user notifications
      var boardUsersSnapshot = await FirebaseFirestore.instance
          .collection('Boards')
          .doc(boardiD)
          .collection('BoardUsers')
          .get();

      for (var boardUsersDoc in boardUsersSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('BoardTasks')
            .doc(realTaskId.toString())
            .collection('Notifications')
            .doc(notificationID.toString())
            .update({
              'userNotifications.${boardUsersDoc['UserID']}': {
                'isShow': false,
                'isNotiRemindShow': false,
              },
            });
      }
    }
  }

  bool _isValidNotificationTime(DateTime dueDate, int? selectedBeforeMinutes) {
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

  // dialog มอบหมายงาน
  void _buildDialogAssignedUser() {
    bool isDisposed = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        Map<int, bool> selectedMap = {};

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                void safeSetModalState(VoidCallback fn) {
                  if (!isDisposed && mounted) {
                    try {
                      setModalState(fn);
                    } catch (e) {
                      log('Error in safeSetModalState: $e');
                    }
                  }
                }

                // เมื่อ modal ปิด จะตั้ง isDisposed = true
                ModalRoute.of(context)?.addScopedWillPopCallback(() async {
                  isDisposed = true;
                  return true;
                });

                // ตรวจสอบว่า combinedData มีค่าหรือไม่
                if (combinedData == null) {
                  return Container(
                    height: 200,
                    child: Center(child: Text('No data available')),
                  );
                }

                final userinBoard =
                    combinedData['boardUsers'] as List<dynamic>? ?? [];
                final userAssigned =
                    combinedData['assigned'] as List<dynamic>? ?? [];

                final assignedIds = userAssigned
                    .map((u) => (u as Map<String, dynamic>)['userId'])
                    .where((id) => id != null) // กรองค่า null
                    .toSet();

                final userCurrentlyAssigned = userinBoard.where((user) {
                  final u = user as Map<String, dynamic>;
                  final userId = u['UserID'];
                  return userId != null && assignedIds.contains(userId);
                }).toList();

                final userAvailable = userinBoard.where((user) {
                  final u = user as Map<String, dynamic>;
                  final userId = u['UserID'];
                  return userId != null && !assignedIds.contains(userId);
                }).toList();

                final taskMap =
                    combinedData['task'] as Map<String, dynamic>? ?? {};
                final taskId = taskMap['taskID'];
                final taskName = taskMap['taskName'];

                // ตรวจสอบว่า taskId มีค่าหรือไม่
                if (taskId == null) {
                  return Container(
                    height: 200,
                    child: Center(child: Text('Task ID not found')),
                  );
                }

                return SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_add, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Add Assignees',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // ผู้ใช้ที่ถูกมอบหมายแล้ว
                        if (userCurrentlyAssigned.isNotEmpty) ...[
                          Text(
                            'Currently Assigned (${userCurrentlyAssigned.length})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: userCurrentlyAssigned.length,
                              itemBuilder: (context, index) {
                                final u =
                                    userCurrentlyAssigned[index]
                                        as Map<String, dynamic>;
                                final userId = u['UserID'];
                                final name = u['Name'] ?? 'Unknown';
                                final profileUrl = u['Profile'] ?? '';
                                final isSelected = selectedMap[userId] ?? false;

                                return GestureDetector(
                                  onTap: () async {
                                    try {
                                      final assignedUser = userAssigned
                                          .cast<Map<String, dynamic>>()
                                          .firstWhere(
                                            (assigned) =>
                                                assigned['userId'] == userId,
                                            orElse: () => <String, dynamic>{},
                                          );

                                      if (assignedUser.isNotEmpty) {
                                        final assId = assignedUser['assId'];
                                        if (assId != null) {
                                          // แสดง popup ยืนยันก่อน (Currently Assigned Users)
                                          final bool?
                                          shouldProceed = await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext dialogContext) {
                                              return AlertDialog(
                                                title: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person_remove,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Remove Assignee'),
                                                  ],
                                                ),
                                                content: Text(
                                                  'Are you sure you want to remove "$name" from this task?',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(
                                                        dialogContext,
                                                      ).pop(false);
                                                    },
                                                    child: Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(
                                                        dialogContext,
                                                      ).pop(true);
                                                    },
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: Text('Remove'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          // ถ้าผู้ใช้ยืนยัน จึงทำการ process
                                          if (shouldProceed == true) {
                                            await _deleteAssignedUser(
                                              assId,
                                              safeSetModalState,
                                              selectedMap,
                                              userId,
                                              combinedData['board']['BoardID']
                                                  .toString(),
                                            );
                                          }
                                        }
                                      }
                                    } catch (e) {
                                      log('Error in onTap: $e');
                                    }
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(right: 12),
                                    child: Column(
                                      children: [
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 25,
                                              backgroundColor: Colors.grey[200],
                                              child: profileUrl.isNotEmpty
                                                  ? ClipOval(
                                                      child: Image.network(
                                                        profileUrl,
                                                        width: 50,
                                                        height: 50,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => Icon(
                                                              Icons.person,
                                                              color: Colors
                                                                  .grey[600],
                                                              size: 30,
                                                            ),
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.person,
                                                      color: Colors.grey[600],
                                                      size: 30,
                                                    ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          name.length > 8
                                              ? '${name.substring(0, 8)}...'
                                              : name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 16),
                        ],

                        // ผู้ใช้ที่ยังไม่ถูกมอบหมาย
                        Text(
                          'Available Users (${userAvailable.length})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: userAvailable.isEmpty
                              ? Center(
                                  child: Text(
                                    'No available users',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: userAvailable.length,
                                  itemBuilder: (context, index) {
                                    final u =
                                        userAvailable[index]
                                            as Map<String, dynamic>;
                                    final userId = u['UserID'];
                                    final name = u['Name'] ?? 'Unknown';
                                    final email = u['Email'] ?? 'No email';
                                    final profileUrl = u['Profile'] ?? '';
                                    final isSelected =
                                        selectedMap[userId] ?? false;

                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue[100],
                                          child: profileUrl.isNotEmpty
                                              ? ClipOval(
                                                  child: Image.network(
                                                    profileUrl,
                                                    width: 40,
                                                    height: 40,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) => Icon(
                                                          Icons.person,
                                                          color:
                                                              Colors.blue[600],
                                                        ),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.person,
                                                  color: Colors.blue[600],
                                                ),
                                        ),
                                        title: Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        subtitle: Text(
                                          email,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        trailing: Checkbox(
                                          value: isSelected,
                                          onChanged: (value) async {
                                            if (value != null) {
                                              // แสดง popup ยืนยันก่อน (Checkbox)
                                              final bool?
                                              shouldProceed = await showDialog<bool>(
                                                context: context,
                                                builder: (BuildContext dialogContext) {
                                                  return AlertDialog(
                                                    title: Row(
                                                      children: [
                                                        Icon(
                                                          value
                                                              ? Icons.person_add
                                                              : Icons
                                                                    .person_remove,
                                                          color: value
                                                              ? Colors.blue
                                                              : Colors.red,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          value
                                                              ? 'Assign User'
                                                              : 'Remove User',
                                                        ),
                                                      ],
                                                    ),
                                                    content: Text(
                                                      value
                                                          ? 'Are you sure you want to assign "$name" to this task?'
                                                          : 'Are you sure you want to remove "$name" from this task?',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop(false);
                                                        },
                                                        child: Text(
                                                          'Cancel',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop(true);
                                                        },
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  value
                                                                  ? Colors.blue
                                                                  : Colors.red,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                        child: Text(
                                                          value
                                                              ? 'Assign'
                                                              : 'Remove',
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              // ถ้าผู้ใช้ยืนยัน จึงทำการ process
                                              if (shouldProceed == true) {
                                                safeSetModalState(() {
                                                  selectedMap[userId] = value;
                                                });
                                                await _assignUserToTask(
                                                  userId,
                                                  name,
                                                  value,
                                                  taskId,
                                                  taskName,
                                                  combinedData['board']['BoardID']
                                                      .toString(),
                                                  combinedData['board']['BoardName']
                                                      .toString(),
                                                  safeSetModalState,
                                                );
                                              }
                                            }
                                          },
                                          activeColor: Colors.blue,
                                        ),
                                        onTap: () async {
                                          final newVal = !isSelected;

                                          // แสดง popup ยืนยันก่อน (ListTile onTap)
                                          final bool?
                                          shouldProceed = await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext dialogContext) {
                                              return AlertDialog(
                                                title: Row(
                                                  children: [
                                                    Icon(
                                                      newVal
                                                          ? Icons.person_add
                                                          : Icons.person_remove,
                                                      color: newVal
                                                          ? Colors.blue
                                                          : Colors.red,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      newVal
                                                          ? 'Assign User'
                                                          : 'Remove User',
                                                    ),
                                                  ],
                                                ),
                                                content: Text(
                                                  newVal
                                                      ? 'Are you sure you want to assign "$name" to this task?'
                                                      : 'Are you sure you want to remove "$name" from this task?',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(
                                                        dialogContext,
                                                      ).pop(false);
                                                    },
                                                    child: Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(
                                                        dialogContext,
                                                      ).pop(true);
                                                    },
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              newVal
                                                              ? Colors.blue
                                                              : Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: Text(
                                                      newVal
                                                          ? 'Assign'
                                                          : 'Remove',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          // ถ้าผู้ใช้ยืนยัน จึงทำการ process
                                          if (shouldProceed == true) {
                                            safeSetModalState(() {
                                              selectedMap[userId] = newVal;
                                            });
                                            await _assignUserToTask(
                                              userId,
                                              name,
                                              newVal,
                                              taskId,
                                              taskName,
                                              combinedData['board']['BoardID']
                                                  .toString(),
                                              combinedData['board']['BoardName']
                                                  .toString(),
                                              safeSetModalState,
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      isDisposed = true;
    });
  }

  // ฟังก์ชั่นเพิ่ม assigned
  Future<void> _assignUserToTask(
    int userId,
    String nameuser,
    bool isAssigned,
    int taskId,
    String taskName,
    String boardId,
    String boardName,
    StateSetter setModalState,
  ) async {
    try {
      final url = await loadAPIEndpoint();
      final token = box.read('accessToken');

      final headers = {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer $token",
      };

      final assignBody = jsonEncode({
        "task_id": taskId.toString(),
        "user_id": userId.toString(),
      });

      final notifyBody = jsonEncode({
        "recieveid": userId.toString(),
        "task_id": taskId.toString(),
      });

      // Call assign API
      final assignResponse = await _postWithAuthRetry(
        "$url/assigned",
        headers,
        assignBody,
      );

      // Call notify API
      final notifyResponse = await _postWithAuthRetry(
        "$url/assignedtaskNotify",
        headers,
        notifyBody,
      );

      if (assignResponse.statusCode == 201) {
        final batch = FirebaseFirestore.instance.batch();
        // 1. ส่งการแจ้งเตือนให้คนที่เชิญ
        var boardUsersSnapshot = await FirebaseFirestore.instance
            .collection('Boards')
            .doc(boardId)
            .collection('BoardUsers')
            .get();

        for (var boardUsersDoc in boardUsersSnapshot.docs) {
          final responseDoc = FirebaseFirestore.instance
              .collection('Notifications')
              .doc(boardUsersDoc['Email'])
              .collection('AddAssigness')
              .doc('${boardId}from-${box.read('userProfile')['email']}');

          batch.set(responseDoc, {
            'AssignBy': box.read('userProfile')['userid'],
            'Profile': box.read('userProfile')['profile'],
            'nameUser': nameuser,
            'boardId': boardId,
            'boardName': boardName,
            'taskId': taskId.toString(),
            'taskName': taskName,
            'notiCount': false,
            'updatedAt': Timestamp.now(),
          });
        }
        await batch.commit();
        log('✅ User assigned successfully');

        await loadDataAsync(
          onDataLoaded: () {
            if (mounted) {
              try {
                setModalState(() {}); // Rebuild modal if still mounted
              } catch (e) {
                log('Modal already disposed: $e');
              }
            }
          },
        );
      } else {
        log('❌ Failed to assign user: ${assignResponse.statusCode}');
        log('Response: ${assignResponse.body}');
        _showErrorSnackBar('Failed to assign user. Please try again.');
      }
    } catch (e) {
      log('❌ Exception in _assignUserToTask: $e');
      _showErrorSnackBar('An error occurred. Please try again.');
    }
  }

  Future<http.Response> _postWithAuthRetry(
    String url,
    Map<String, String> headers,
    String body,
  ) async {
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      headers["Authorization"] = "Bearer ${box.read('accessToken')}";
      response = await http.post(Uri.parse(url), headers: headers, body: body);
    }

    return response;
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // ฟังก์ชั่นลบ assigned
  Future<void> _deleteAssignedUser(
    int assId,
    StateSetter setModalState,
    Map<int, bool> selectedMap,
    int userId,
    String boardId,
  ) async {
    log('Managing assigned user $assId');
    try {
      log('assid & userId: $assId, $userId');
      final url = await loadAPIEndpoint();
      var headers = {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      };

      // 🔔 เรียก notify เฉพาะตอนลบสำเร็จ
      final notifyBody = jsonEncode({
        "recieveid": userId.toString(),
        "assign_id": assId.toString(),
      });

      final responseUnassignNotify = await http.post(
        Uri.parse("$url/unassignedtaskNotify"),
        headers: headers,
        body: notifyBody,
      );

      if (responseUnassignNotify.statusCode != 200) {
        log('⚠️ Failed to notify unassignment');
      }

      var response = await http.delete(
        Uri.parse("$url/assigned/$assId"),
        headers: headers,
      );

      // ถ้า token หมดอายุ ลอง refresh แล้วเรียกใหม่
      if (response.statusCode == 403) {
        await loadNewRefreshToken();
        headers["Authorization"] = "Bearer ${box.read('accessToken')}";
        response = await http.delete(
          Uri.parse("$url/assigned/$assId"),
          headers: headers,
        );
      }

      if (response.statusCode == 200) {
        log('✅ User unassigned successfully');

        final batch = FirebaseFirestore.instance.batch();
        // 1. ส่งการแจ้งเตือนให้คนที่เชิญ
        var boardUsersSnapshot = await FirebaseFirestore.instance
            .collection('Boards')
            .doc(boardId)
            .collection('BoardUsers')
            .get();

        for (var boardUsersDoc in boardUsersSnapshot.docs) {
          final responseDoc = FirebaseFirestore.instance
              .collection('Notifications')
              .doc(boardUsersDoc['Email'])
              .collection('AddAssigness')
              .doc('${boardId}from-${box.read('userProfile')['email']}');

          batch.delete(responseDoc);
        }
        await batch.commit();

        // รีเซ็ตสถานะ checkbox
        setModalState(() {
          selectedMap[userId] = false;
        });

        // โหลดข้อมูลใหม่
        await loadDataAsync(
          onDataLoaded: () {
            if (mounted) {
              try {
                setModalState(() {});
              } catch (e) {
                log('Modal already disposed: $e');
              }
            }
          },
        );
      } else {
        log('❌ Error unassigning user: ${response.statusCode}');
        log('Response body: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unassign user. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      log('Exception in _deleteAssignedUser: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =================================================== description, checklist, file ==================================================\\
  // สร้างปุ่ม description, checklist, file
  Widget _buildTabButton(String title, int index) {
    bool isSelected = selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 3, // เพิ่มความหนาของเส้นใต้
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ช่องของปุ่ม description, checklist, file
  Widget _buildTabContent() {
    final appData = Provider.of<Appdata>(context, listen: false);
    final currentTask = appData.showDetailTask.currentTask;
    final isGroupTask = appData.showDetailTask.isGroupTask;

    if (currentTask == null) {
      return const Center(child: Text('No task data available'));
    }

    switch (selectedTabIndex) {
      case 0: // Description
        // ดึงข้อมูล description จาก group หรือ individual
        String currentDescription = '';
        if (isGroupTask && combinedData['task'] != null) {
          currentDescription = combinedData['task']['description'] ?? '';
        } else {
          currentDescription = currentTask.description ?? '';
        }

        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.brown[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (_isEditingDescription)
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        _confirmDescriptionEdit(currentTask);
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _descriptionFocusNode.requestFocus();
                      },
                    ),
                ],
              ),
              SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocusNode,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: 'add description',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  onChanged: (value) {
                    // ไม่ต้องอัพเดททันที เพราะจะอัพเดทตอนยืนยัน
                  },
                ),
              ),
            ],
          ),
        );

      case 1: // Checklist
        // ดึงข้อมูล checklist จาก group หรือ individual
        List<dynamic> checklistItems = [];
        if (isGroupTask && combinedData['checklist'] != null) {
          checklistItems = combinedData['checklist'];
        } else {
          checklistItems = currentTask.checklists ?? [];
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Checklist',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      final TextEditingController checklistController =
                          TextEditingController();

                      Get.dialog(
                        AlertDialog(
                          title: Text('Add Checklist Item'),
                          content: TextField(
                            controller: checklistController,
                            // autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Enter checklist item',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (checklistController.text
                                    .trim()
                                    .isNotEmpty) {
                                  _addChecklistItem(
                                    checklistController.text.trim(),
                                  );
                                  Get.back();
                                }
                              },

                              child: Text('Add'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),

              /// แสดง checklist items
              if (checklistItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'add checklist',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                ...checklistItems.map(
                  (item) => _buildChecklistItem(item, currentTask, isGroupTask),
                ),

              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final TextEditingController checklistController =
                      TextEditingController();

                  Get.dialog(
                    AlertDialog(
                      title: Text('Add Checklist Item'),
                      content: TextField(
                        controller: checklistController,
                        // autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Enter checklist item',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (checklistController.text.trim().isNotEmpty) {
                              _addChecklistItem(
                                checklistController.text.trim(),
                              );
                              Get.back();
                            }
                          },

                          child: Text('Add'),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.add),
                label: Text('Add item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.green[800],
                ),
              ),
            ],
          ),
        );

      case 2: // File
        // ดึงข้อมูล attachments จาก group หรือ individual
        List<dynamic> attachments = [];
        if (isGroupTask && combinedData['attachments'] != null) {
          attachments = combinedData['attachments'];
        } else {
          attachments = currentTask.attachments ?? [];
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // ให้ Column ขยายตามเนื้อหา
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Files',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file),
                    onPressed: () {
                      _uploadFileDialog(isGroupTask);
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              // กรอบสำหรับแสดงไฟล์ที่ขยายตามเนื้อหา
              attachments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Icon(
                            Icons.cloud_upload,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No files uploaded',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              _uploadFileDialog(isGroupTask);
                            },
                            icon: Icon(Icons.attach_file),
                            label: Text('Upload File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[100],
                              foregroundColor: Colors.blue[800],
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // สร้าง ListView ที่ไม่ใช้ Expanded เพื่อให้ขยายตามเนื้อหา
                        ListView.builder(
                          shrinkWrap: true, // ให้ ListView ขยายตามเนื้อหา
                          physics:
                              NeverScrollableScrollPhysics(), // ปิดการ scroll ของ ListView
                          itemCount: attachments.length,
                          itemBuilder: (context, index) {
                            final attachment = attachments[index];
                            return _buildFileItem(attachment, isGroupTask);
                          },
                        ),
                        SizedBox(height: 16),
                        // ปุ่ม Upload File เมื่อมีไฟล์แล้ว - จัดชิดซ้าย
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _uploadFileDialog(isGroupTask);
                            },
                            icon: Icon(Icons.add),
                            label: Text('Upload File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[100],
                              foregroundColor: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        );
      default:
        return Container();
    }
  }

  // แก้ไข description
  Future<void> _confirmDescriptionEdit(data.Task currentTask) async {
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) {
      log('Error: userDataAll not found in storage');
      return;
    }

    final appData = Provider.of<Appdata>(context, listen: false);
    var existingData = data.AllDataUserGetResponst.fromJson(userDataJson);
    final newDescription = _descriptionController.text.trim();
    String? oldDescription;
    int? taskId;
    final isgroup = appData.showDetailTask.isGroupTask;

    try {
      bool hasChanges = false;

      if (isgroup) {
        final taskData = combinedData['task'];
        if (taskData != null) {
          final currentDescription = taskData['description'] ?? '';
          oldDescription = taskData['description'];
          taskId = taskData['taskID'];
          if (newDescription != currentDescription) {
            hasChanges = true;
            setState(() {
              combinedData['task']['description'] = newDescription;
              _isEditingDescription = false;
              FocusScope.of(context).unfocus();
            });
          } else {
            setState(() {
              _isEditingDescription = false;
              FocusScope.of(context).unfocus();
            });
            log("ไม่มีการเปลี่ยนแปลง description");
            return; // ออกจาก method ทันที
          }
        }
      } else {
        if (currentTask != null) {
          final currentDescription = currentTask.description ?? '';
          oldDescription = currentDescription;
          taskId = currentTask.taskId;
          if (newDescription != currentDescription) {
            hasChanges = true;
            setState(() {
              currentTask.description = newDescription;
              _isEditingDescription = false;
              FocusScope.of(context).unfocus();
            });
          } else {
            setState(() {
              _isEditingDescription = false;
              FocusScope.of(context).unfocus();
            });
            log("ไม่มีการเปลี่ยนแปลง description");
            return; // ออกจาก method ทันที
          }
        }
      }

      // ถ้าไม่มีการเปลี่ยนแปลง จะไม่ถึงจุดนี้
      if (!hasChanges) return;

      if (currentTask != null) {
        int? index = _findIndexCurrentTask(currentTask);
        log('Current task index: $index');
        if (index != null) {
          existingData.tasks[index].description = newDescription;
          box.write('userDataAll', existingData.toJson());
        }
      }

      url = await loadAPIEndpoint();

      final body = jsonEncode({
        "task_name": currentTask?.taskName ?? "",
        "description": newDescription,
        "priority": currentTask?.priority ?? "",
      });

      var response = await http.put(
        Uri.parse("$url/updatetask/$taskId"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: body,
      );

      if (response.statusCode == 403) {
        await loadNewRefreshToken();
        response = await http.put(
          Uri.parse("$url/updatetask/$taskId"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
          body: body,
        );
      }

      if (response.statusCode == 200) {
        log('อัปเดต description สำเร็จ');
        await loadDataAsync();
      } else {
        log('Error updating description: ${response.statusCode}');
        // กรณี error ให้ revert ข้อมูลกลับ
        setState(() {
          if (isgroup) {
            combinedData['task']['description'] = oldDescription ?? "";
          } else {
            currentTask?.description = oldDescription ?? "";
          }
          _isEditingDescription = false;
          FocusScope.of(context).unfocus();
        });
      }
    } catch (e) {
      log('Exception during description update: $e');
      setState(() {
        if (isgroup) {
          combinedData['task']['description'] = oldDescription ?? "";
        } else {
          currentTask?.description = oldDescription ?? "";
        }
        _isEditingDescription = false;
        FocusScope.of(context).unfocus();
      });
    }
  }

  // สร้างกรอบchecklist กับปุ่มเพิ่ม, ลบ
  Widget _buildChecklistItem(
    dynamic item,
    data.Task? currentTask,
    bool? isGroupTask,
  ) {
    bool isCompleted = false;
    String checklistName = '';
    int? checklistId;

    if (item is data.Checklist) {
      // Individual Task - Checklist object
      isCompleted = item.status == "1" || item.status == "completed";
      checklistName = item.checklistName;
      checklistId = item.checklistId;
    } else if (item is Map<String, dynamic>) {
      // Group Task - Map from Firestore
      isCompleted = (int.tryParse('${item['status']}') ?? 0) == 1;
      checklistName = item['checklist_name']?.toString() ?? '';
      checklistId = item['checklist_id'];
    }

    return Container(
      key: ValueKey('checklist_${checklistId}'), // เพิ่ม unique key
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: isCompleted,
            onChanged: (value) {
              // แปลง Checklist object เป็น Map ก่อนส่งไปยัง _finishChecklistStatus
              Map<String, dynamic> itemMap;

              if (item is data.Checklist) {
                itemMap = {
                  'checklist_name': item.checklistName,
                  'status': item.status,
                  'checklist_id': item.checklistId,
                  'task_id': item.taskId,
                  'created_at': item.createdAt,
                };
              } else {
                // สร้าง copy ของ Map เพื่อป้องกันการ reference ไปยัง object เดียวกัน
                itemMap = Map<String, dynamic>.from(item);
              }

              _finishChecklistStatus(value, itemMap, isGroupTask);
            },
          ),
          Expanded(
            child: Text(
              checklistName,
              style: TextStyle(
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: isCompleted ? Colors.grey : null,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red[300]),
            onPressed: () {
              _showDeleteChecklistDialog(
                isGroupTask ?? false,
                checklistId,
                checklistName, // เพิ่ม parameter นี้
                currentTask, // เพิ่ม parameter นี้
                item, // เพิ่ม parameter นี้
              );
            },
          ),
        ],
      ),
    );
  }

  // เพิ่ม checklist
  Future<void> _addChecklistItem(String checklistName) async {
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    final appData = Provider.of<Appdata>(context, listen: false);
    var existingData = data.AllDataUserGetResponst.fromJson(userDataJson);
    final currentTask = appData.showDetailTask.currentTask;
    final isGroupTask = appData.showDetailTask.isGroupTask;

    int? taskId;
    int? index;
    late int tempChecklistId;

    // หา taskId และ index
    if (isGroupTask) {
      taskId = combinedData['task']['taskID'];
      if (taskId == null) {
        log('Error: taskId is null for group task');
        return;
      }
    } else {
      taskId = currentTask?.taskId;
      if (taskId == null) {
        log('Error: taskId is null for individual task');
        return;
      }

      if (currentTask != null) {
        index = _findIndexCurrentTask(currentTask);
        log('Current task index: $index');
      }

      if (index == null) {
        log('Error: Cannot find current task index');
        return;
      }
    }

    // สร้าง unique temp ID
    tempChecklistId = DateTime.now().millisecondsSinceEpoch;

    // ตรวจสอบให้แน่ใจว่า ID ไม่ซ้ำ
    while (_checkDuplicateChecklistId(
      tempChecklistId,
      isGroupTask,
      existingData,
      index,
    )) {
      tempChecklistId = DateTime.now().millisecondsSinceEpoch + 1;
      await Future.delayed(
        Duration(milliseconds: 1),
      ); // รอสักครู่เพื่อให้ timestamp ต่าง
    }

    // สร้าง temp checklist object
    final tempChecklist = data.Checklist(
      checklistId: tempChecklistId,
      checklistName: checklistName,
      createdAt: DateTime.now().toIso8601String(),
      status: '0', // สถานะชั่วคราว
      taskId: taskId,
    );

    // เพิ่ม temp data สำหรับแสดงผล
    if (isGroupTask) {
      // สำหรับ Group Task - เพิ่มใน combinedData
      final tempChecklistMap = {
        'checklist_id': tempChecklistId,
        'checklist_name': checklistName,
        'create_at': DateTime.now().toIso8601String(),
        'status': '0',
        'task_id': taskId,
      };

      if (combinedData['checklist'] == null) {
        combinedData['checklist'] = [];
      }
      combinedData['checklist'].add(tempChecklistMap);

      // **เพิ่มส่วนนี้: บันทึกใน existingData สำหรับ Group Task ด้วย**
      final taskIndex = existingData.tasks.indexWhere(
        (t) => t.taskId == taskId,
      );
      if (taskIndex != -1) {
        existingData.tasks[taskIndex].checklists.add(tempChecklist);
        box.write('userDataAll', existingData.toJson());

        // อัพเดท Provider สำหรับ Group Task ด้วย
        appData.showDetailTask.setCurrentTask(
          existingData.tasks[taskIndex],
          isGroup: true,
        );
      }
    }

    // เพิ่มใน local data สำหรับ Individual Task
    if (!isGroupTask && index != null) {
      existingData.tasks[index].checklists.add(tempChecklist);
      box.write('userDataAll', existingData.toJson());

      // อัพเดท Provider
      appData.showDetailTask.setCurrentTask(
        existingData.tasks[index],
        isGroup: false,
      );
    }

    // รีเฟรช UI
    if (mounted) setState(() {});

    // เรียก API เพื่อบันทึกข้อมูลจริง
    try {
      final url = await loadAPIEndpoint();
      final body = jsonEncode({"checklist_name": checklistName});

      var response = await http.post(
        Uri.parse("$url/checklist/$taskId"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: body,
      );

      // จัดการ token หมดอายุ
      if (response.statusCode == 403) {
        await loadNewRefreshToken();
        response = await http.post(
          Uri.parse("$url/checklist/$taskId"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
          body: body,
        );
      }

      if (response.statusCode == 201) {
        // สำเร็จ - อัพเดท ID จาก server
        log('เพิ่ม checklist สำเร็จ: $checklistName');
        final responseData = jsonDecode(response.body);
        final int newChecklistId = responseData['checklistID'];

        // อัพเดท Group Task data
        if (isGroupTask && combinedData['checklist'] != null) {
          final checklistList = combinedData['checklist'] as List;
          final checklistIndex = checklistList.indexWhere(
            (c) => c['checklist_id'] == tempChecklistId,
          );

          if (checklistIndex != -1) {
            checklistList[checklistIndex]['checklist_id'] = newChecklistId;
            checklistList[checklistIndex]['status'] =
                '0'; // อัพเดทสถานะเป็นจริง
          }
        }

        // อัพเดท Local data - **เพิ่มการอัพเดท existingData ด้วย**
        if (index != null) {
          final checklistIndex = existingData.tasks[index].checklists
              .indexWhere((c) => c.checklistId == tempChecklistId);

          if (checklistIndex != -1) {
            existingData.tasks[index].checklists[checklistIndex].checklistId =
                newChecklistId;
            existingData.tasks[index].checklists[checklistIndex].status =
                '0'; // อัพเดทสถานะ
            box.write('userDataAll', existingData.toJson()); // บันทึกลง storage

            // รีเฟรช Provider
            appData.showDetailTask.setCurrentTask(existingData.tasks[index]);
          }
        }

        // **เพิ่มส่วนนี้: อัพเดท existingData สำหรับ Group Task ด้วย**
        if (isGroupTask) {
          // หา task ใน existingData และอัพเดท checklist ID
          final taskIndex = existingData.tasks.indexWhere(
            (t) => t.taskId == taskId,
          );
          if (taskIndex != -1) {
            final checklistIndex = existingData.tasks[taskIndex].checklists
                .indexWhere((c) => c.checklistId == tempChecklistId);

            if (checklistIndex != -1) {
              existingData
                      .tasks[taskIndex]
                      .checklists[checklistIndex]
                      .checklistId =
                  newChecklistId;
              existingData.tasks[taskIndex].checklists[checklistIndex].status =
                  '0';
              box.write(
                'userDataAll',
                existingData.toJson(),
              ); // บันทึกลง storage
            }
          }
        }

        // รีเฟรช UI
        if (mounted) setState(() {});

        // โหลดข้อมูลใหม่ทั้งหมด (optional)
        await loadDataAsync();
      } else {
        // ล้มเหลว - ลบ temp data
        _removeTempChecklist(
          tempChecklistId,
          isGroupTask,
          existingData,
          index,
          appData,
        );

        log('Error adding checklist: ${response.statusCode}');
        Get.snackbar(
          'Error',
          'Failed to add checklist item',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Exception - ลบ temp data
      _removeTempChecklist(
        tempChecklistId,
        isGroupTask,
        existingData,
        index,
        appData,
      );

      log('Exception adding checklist: $e');
      Get.snackbar(
        'Error',
        'Failed to add checklist item',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // function เพื่อตรวจสอบ ID checklist ซ้ำ
  bool _checkDuplicateChecklistId(
    int checklistId,
    bool isGroupTask,
    data.AllDataUserGetResponst existingData,
    int? index,
  ) {
    // ตรวจสอบใน Group Task
    if (isGroupTask && combinedData['checklist'] != null) {
      final checklistList = combinedData['checklist'] as List;
      final exists = checklistList.any((c) => c['checklist_id'] == checklistId);
      if (exists) return true;
    }

    // ตรวจสอบใน Local Task
    if (index != null) {
      final exists = existingData.tasks[index].checklists.any(
        (c) => c.checklistId == checklistId,
      );
      if (exists) return true;
    }

    return false;
  }

  // temp checklist
  void _removeTempChecklist(
    int tempChecklistId,
    bool isGroupTask,
    data.AllDataUserGetResponst existingData,
    int? index,
    Appdata appData,
  ) {
    // ลบจาก Group Task
    if (isGroupTask && combinedData['checklist'] != null) {
      final checklistList = combinedData['checklist'] as List;
      checklistList.removeWhere((c) => c['checklist_id'] == tempChecklistId);
    }

    // ลบจาก Local Task
    if (index != null) {
      existingData.tasks[index].checklists.removeWhere(
        (c) => c.checklistId == tempChecklistId,
      );
      box.write('userDataAll', existingData.toJson());

      // รีเฟรช Provider
      appData.showDetailTask.setCurrentTask(existingData.tasks[index]);
    }

    // รีเฟรช UI
    if (mounted) setState(() {});
  }

  // เสร็จ checklist
  Future<void> _finishChecklistStatus(
    bool? value,
    Map<String, dynamic> item,
    bool? isGroupTask,
  ) async {
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) {
      log('Error: userDataAll not found in storage');
      return;
    }

    final appData = Provider.of<Appdata>(context, listen: false);
    var existingData = data.AllDataUserGetResponst.fromJson(userDataJson);
    final currentTask = appData.showDetailTask.currentTask;

    // ตอนนี้ item เป็น Map เสมอ ไม่ต้องตรวจสอบชนิดข้อมูล
    int? taskId = item['task_id'];
    int? checklistId = item['checklist_id'];

    // log('TaskId: $taskId, ChecklistId: $checklistId');
    // log('IsGroupTask: $isGroupTask');
    // log('value: $value');

    if (taskId == null || checklistId == null) {
      log('Error: taskId or checklistId is null');
      return;
    }

    bool isCompleted = value == true;
    String newStatus = isCompleted ? '1' : '0';

    // // เก็บสถานะเดิมไว้สำหรับ revert
    String oldStatus = item['status']?.toString() ?? '0';

    // อัปเดตสถานะใน UI ทันที - อัปเดตเฉพาะ item นี้
    if (isGroupTask == true) {
      // กรณี checklist มาจาก combinedData (Group Task)
      List<dynamic> checklistList = combinedData['checklist'] ?? [];
      log('1');
      setState(() {
        for (var checklist in checklistList) {
          if (checklist['checklist_id'] == checklistId) {
            checklist['status'] = newStatus;
            break;
          }
        }
      });
    } else {
      // กรณี checklist มาจาก currentTask (Individual Task)
      if (currentTask != null) {
        setState(() {
          for (var checklist in currentTask.checklists) {
            if (checklist.checklistId == checklistId) {
              checklist.status = newStatus;
              break;
            }
          }
        });
      }
    }

    log('2');

    final taskIndex = existingData.tasks.indexWhere(
      (task) => task.taskId == taskId,
    );
    if (taskIndex != -1) {
      final checklistIndex = existingData.tasks[taskIndex].checklists
          .indexWhere((checklist) => checklist.checklistId == checklistId);
      log('3');
      log(checklistIndex.toString());

      if (checklistIndex != -1) {
        log('4');
        existingData.tasks[taskIndex].checklists[checklistIndex].status =
            newStatus;
        box.write('userDataAll', existingData.toJson());

        String url = await loadAPIEndpoint();
        log('5');
        var response = await http.put(
          Uri.parse("$url/checklistfinish/$checklistId"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
        );

        // กรณี token หมดอายุ
        if (response.statusCode == 403) {
          await loadNewRefreshToken();
          response = await http.put(
            Uri.parse("$url/checklistfinish/$checklistId"),
            headers: {
              "Content-Type": "application/json; charset=utf-8",
              "Authorization": "Bearer ${box.read('accessToken')}",
            },
          );
        }

        if (response.statusCode == 200) {
          log('อัปเดตสถานะ checklist สำเร็จ: ${item['checklist_name']}');
          loadDataAsync();
        } else {
          log('Error updating checklist status: ${response.statusCode}');
        }
      }
    }
  }

  // dialog ลบ checklist
  void _showDeleteChecklistDialog(
    bool isGroupTask,
    int? checklistId,
    String checklistName, // เพิ่ม parameter
    data.Task? currentTask, // เพิ่ม parameter
    dynamic item, // เพิ่ม parameter
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Checklist'),
        content: Text('Are you sure you want to delete "$checklistName"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _deleteChecklistItem(checklistId, isGroupTask);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ลบ checklist
  Future<void> _deleteChecklistItem(int? checklistId, bool isgroupTask) async {
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    final appData = Provider.of<Appdata>(context, listen: false);
    var existingData = data.AllDataUserGetResponst.fromJson(userDataJson);
    final currentTask = appData.showDetailTask.currentTask;
    int? index;
    int? taskId;
    if (currentTask != null) {
      index = _findIndexCurrentTask(currentTask);
      // 🔧 วิธีที่ถูกต้องในการดึง taskId
      if (isgroupTask && combinedData?['checklist'] != null) {
        // สำหรับ Group Task: พยายามหา taskId จาก checklist item ใดๆ
        final checklistList = combinedData['checklist'] as List<dynamic>;
        if (checklistList.isNotEmpty) {
          final firstItem = checklistList.first;
          taskId = firstItem['task_id'] ?? currentTask.taskId;
        } else {
          taskId = currentTask.taskId;
        }
      } else {
        // สำหรับ Individual Task: ใช้ taskId จาก currentTask
        taskId = currentTask.taskId;
      }
      log('Current task index: $index, taskId: $taskId');
    }

    if (index == null || taskId == null) return;
    // ตัวแปรสำหรับเก็บข้อมูลที่จะลบ (สำหรับสำรองข้อมูล)
    data.Checklist? removedChecklist;

    if (isgroupTask) {
      // กรณี Group Task - filter จาก combinedData
      if (combinedData != null && combinedData['checklist'] != null) {
        final checklistList = combinedData['checklist'] as List<dynamic>;

        // หา checklist item ที่ต้องการลบ
        Map<String, dynamic>? checklistItem;
        try {
          checklistItem = checklistList.firstWhere((item) {
            // ลองเปรียบเทียบทั้งแบบ int และ string
            final itemId = item['checklistId'] ?? item['id'];
            if (itemId is int) {
              return itemId == checklistId;
            } else if (itemId is String) {
              return int.tryParse(itemId) == checklistId;
            }
            return false;
          });
        } catch (e) {
          checklistItem = null;
          log('Checklist item not found in group task: $e');
        }

        if (checklistItem != null) {
          // สร้าง Checklist object สำหรับสำรองข้อมูล
          removedChecklist = data.Checklist(
            checklistId:
                checklistItem['checklistId'] ??
                int.tryParse(checklistItem['id'] ?? ''),
            checklistName: checklistItem['checklist_name'] ?? '',
            createdAt:
                checklistItem['createdAt'] ?? DateTime.now().toIso8601String(),
            status: checklistItem['status'] ?? false,
            taskId: checklistItem['task_id'],
          );

          log(
            'Group task - Found checklist to delete: ${removedChecklist?.toJson()}',
          );
        }
      }
    } else {
      // กรณีไม่ใช่ Group Task - filter จาก currentTask
      if (currentTask?.checklists != null &&
          currentTask!.checklists.isNotEmpty) {
        // หา checklist item ในรายการของ task ปัจจุบัน
        removedChecklist = existingData.tasks[index].checklists.firstWhere(
          (c) => c.checklistId == checklistId,
        );

        log(
          'Individual task - Found checklist to delete: ${removedChecklist?.toJson()}',
        );
      }
    }

    // ลบจาก local ชั่วคราว
    existingData.tasks[index].checklists.removeWhere(
      (c) => c.checklistId == checklistId,
    );
    box.write('userDataAll', existingData.toJson());

    if (isgroupTask == true && combinedData?['checklist'] != null) {
      final checklistList = combinedData['checklist'] as List<dynamic>;
      checklistList.removeWhere((item) {
        final itemId = item['ChecklistID'] ?? item['checklist_id'];
        if (itemId is int) {
          return itemId == checklistId;
        } else if (itemId is String) {
          return int.tryParse(itemId) == checklistId;
        }
        return false;
      });
    }

    // รีเฟรช Provider
    if (isgroupTask) {
      appData.showDetailTask.setCurrentTask(
        existingData.tasks[index],
        isGroup: true,
      );
    } else {
      appData.showDetailTask.setCurrentTask(
        existingData.tasks[index],
        isGroup: false,
      );
    }

    // รีเฟรช UI ถ้ามี
    if (mounted) setState(() {});

    try {
      url = await loadAPIEndpoint();
      var response = await http.delete(
        Uri.parse("$url/checklist/${taskId}/${checklistId}"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
      // ตรวจสอบและ refresh token ถ้า access denied
      if (response.statusCode == 403) {
        await loadNewRefreshToken();
        response = await http.delete(
          Uri.parse("$url/checklist/${taskId}/${checklistId}"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
        );
      }

      if (response.statusCode == 200) {
        loadDataAsync();
      } else {
        // ล้มเหลว: rollback กลับ
        existingData.tasks[index].checklists.add(removedChecklist!);
        box.write('userDataAll', existingData.toJson());

        // 🔥 รีเฟรช Provider กลับไปสถานะเดิม
        if (isgroupTask) {
          appData.showDetailTask.setCurrentTask(
            existingData.tasks[index],
            isGroup: true,
          );
        } else {
          appData.showDetailTask.setCurrentTask(
            existingData.tasks[index],
            isGroup: false,
          );
        }

        if (mounted) setState(() {});

        log('Error deleting checklist: ${response.statusCode}');
        Get.snackbar(
          'Error',
          'Failed to delete checklist item',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // ล้มเหลว: rollback กลับ
      existingData.tasks[index].checklists.add(removedChecklist!);
      box.write('userDataAll', existingData.toJson());

      // 🔥 รีเฟรช Provider กลับไปสถานะเดิม
      if (isgroupTask) {
        appData.showDetailTask.setCurrentTask(
          existingData.tasks[index],
          isGroup: true,
        );
      } else {
        appData.showDetailTask.setCurrentTask(
          existingData.tasks[index],
          isGroup: false,
        );
      }

      if (mounted) setState(() {});

      log('Exception deleting checklist: $e');
      Get.snackbar(
        'Error',
        'Failed to delete checklist item',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // สร้าง widget สำหรับแสดงไฟล์แนบ
  Widget _buildFileItem(dynamic attachment, bool isGroupTask) {
    // ตรวจสอบว่าเป็นข้อมูลจาก local (Attachment class) หรือ Firestore
    String fileName = '';
    String filePath = '';
    String fileType = '';
    String uploadAt = '';
    int? attachmentId;

    if (attachment is data.Attachment) {
      // ข้อมูลจาก local (Attachment class)
      fileName = attachment.fileName;
      fileType = attachment.fileType;
      filePath = attachment.filePath;
      uploadAt = attachment.uploadAt;
      attachmentId = attachment.attachmentId;
    } else if (attachment is Map<String, dynamic>) {
      // ข้อมูลจาก Firestore
      fileName = attachment['file_name'] ?? 'Unknown file';
      fileType = attachment['file_type'] ?? '';
      filePath = attachment['file_path'] ?? '';

      // จัดการ Timestamp จาก Firestore
      var uploadAtData = attachment['UploadAt'] ?? attachment['upload_at'];
      if (uploadAtData != null) {
        if (uploadAtData is Timestamp) {
          uploadAt = uploadAtData.toDate().toString();
        } else {
          uploadAt = uploadAtData.toString();
        }
      } else {
        uploadAt = '';
      }

      attachmentId = attachment['AttachmentID'] ?? attachment['attachment_id'];
    }

    // กำหนดไอคอนตามประเภทไฟล์
    IconData fileIcon;
    Color iconColor;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        fileIcon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'picture':
        fileIcon = Icons.image;
        iconColor = Colors.green;
        break;
      case 'link':
        fileIcon = Icons.description;
        iconColor = Colors.blue;
        break;

      default:
        fileIcon = Icons.attach_file;
        iconColor = Colors.grey;
    }

    // กำหนด PopupMenu items ตาม fileType
    List<PopupMenuEntry<String>> getPopupMenuItems() {
      // สำหรับ link: copy และ delete
      return [
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 8),
              Text('Copy Link'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ];
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: () {
          // log(filePath);
          _openfilePath(filePath, context);
        },
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(fileIcon, color: iconColor, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (uploadAt.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(() {
                      final parsed = DateTime.tryParse(uploadAt);
                      return 'Uploaded: ${parsed != null ? '${parsed.day}/${parsed.month}/${parsed.year}' : uploadAt}';
                    }(), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'copy':
                    _copyFile(attachment, isGroupTask);
                    break;
                  case 'delete':
                    _showDeleteFileDialog(attachment, isGroupTask);
                    break;
                }
              },
              itemBuilder: (context) => getPopupMenuItems(),
              child: Icon(Icons.more_vert, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันเปิดไฟล์แนบ
  void _openfilePath(String filepath, BuildContext context) async {
    log(filepath);

    // แสดง dialog ยืนยัน
    bool? shouldOpen = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm to Open Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Do you want to open this link?'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  filepath,
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open'),
            ),
          ],
        );
      },
    );

    // ถ้าผู้ใช้กด "เปิด" หรือ dialog ไม่ถูกยกเลิก
    if (shouldOpen == true) {
      try {
        // วิธีที่ 1: ใช้ launchUrl โดยไม่ต้องเช็ค canLaunchUrl (แนะนำ)
        final Uri url = Uri.parse(filepath);
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        log('เกิดข้อผิดพลาดในการเปิด URL: $e');

        // วิธีที่ 2: ใช้ launch แบบเก่า (fallback)
        try {
          await launch(filepath);
        } catch (e2) {
          log('เกิดข้อผิดพลาดในการเปิด URL (fallback): $e2');

          // แสดง error dialog ถ้าเปิดไม่ได้
          if (context.mounted) {
            final message = 'Unable to open link. Please try again.';
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('An error occurred'),
                  content: Text(message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    }
  }

  // ฟังก์ชั่น copy file ลง clipboard
  Future<void> _copyFile(dynamic attachment, bool? isgroupTask) async {
    try {
      // Get file_path from attachment object
      String filePath = attachment['file_path'] ?? '';

      if (filePath.isNotEmpty) {
        // Copy file_path to clipboard
        await Clipboard.setData(ClipboardData(text: filePath));

        // Show SnackBar to notify user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File link copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );

        log('File path copied to clipboard: $filePath');
      } else {
        log('File path is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File link not found'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      log('Error copying file path: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error copying file link'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ฟังก์ชั่นลบไฟล์
  Future<void> _showDeleteFileDialog(
    dynamic attachment,
    bool? isgroupTask,
  ) async {
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    final appData = Provider.of<Appdata>(context, listen: false);
    var existingData = data.AllDataUserGetResponst.fromJson(userDataJson);
    final currentTask = appData.showDetailTask.currentTask;
    int? index;
    int? taskId;
    int? attachmentId;

    // ดึงข้อมูล attachment และ task ID
    if (attachment is data.Attachment) {
      attachmentId = attachment.attachmentId;
      taskId = attachment.tasksId;
    } else if (attachment is Map<String, dynamic>) {
      attachmentId = attachment['AttachmentID'] ?? attachment['attachment_id'];
      taskId = attachment['tasks_id'];
    }

    if (currentTask != null) {
      index = _findIndexCurrentTask(currentTask);
      if (isgroupTask == true && combinedData?['attachments'] != null) {
        final attachmentList = combinedData['attachments'] as List<dynamic>;
        if (attachmentList.isNotEmpty) {
          final firstItem = attachmentList.first;
          taskId = firstItem['tasks_id'] ?? currentTask.taskId;
        } else {
          taskId = currentTask.taskId;
        }
      } else {
        taskId = taskId ?? currentTask.taskId;
      }
      log(
        'Current task index: $index, taskId: $taskId, attachmentId: $attachmentId',
      );
    }

    if (index == null || taskId == null || attachmentId == null) return;

    // ตัวแปรสำหรับเก็บข้อมูลที่จะลบ (สำหรับสำรองข้อมูล)
    data.Attachment? removedAttachment;
    Map<String, dynamic>?
    removedAttachmentFromCombined; // สำหรับ backup combinedData

    if (isgroupTask == true) {
      // กรณี Group Task - filter จาก combinedData
      if (combinedData != null && combinedData['attachments'] != null) {
        final attachmentList = combinedData['attachments'] as List<dynamic>;

        // หา attachment item ที่ต้องการลบ
        Map<String, dynamic>? attachmentItem;
        try {
          attachmentItem = attachmentList.firstWhere((item) {
            final itemId = item['AttachmentID'] ?? item['attachment_id'];
            if (itemId is int) {
              return itemId == attachmentId;
            } else if (itemId is String) {
              return int.tryParse(itemId) == attachmentId;
            }
            return false;
          });
        } catch (e) {
          attachmentItem = null;
          log('Attachment item not found in group task: $e');
        }

        if (attachmentItem != null) {
          // เก็บข้อมูลดิบสำหรับ rollback combinedData
          removedAttachmentFromCombined = Map<String, dynamic>.from(
            attachmentItem,
          );

          // สร้าง Attachment object สำหรับสำรองข้อมูล
          removedAttachment = data.Attachment(
            attachmentId: attachmentItem['attachment_id'] ?? '',
            fileName: attachmentItem['file_name'] ?? '',
            filePath: attachmentItem['file_path'] ?? '',
            fileType: attachmentItem['file_type'] ?? '',
            uploadAt: _convertTimestampToString(attachmentItem['upload_at']),
            tasksId: attachmentItem['tasks_id'],
          );

          log(
            'Group task - Found attachment to delete: ${removedAttachment?.toJson()}',
          );
        }
      }
    } else {
      // กรณีไม่ใช่ Group Task - filter จาก currentTask
      if (currentTask?.attachments != null &&
          currentTask!.attachments.isNotEmpty) {
        // หา attachment item ในรายการของ task ปัจจุบัน
        try {
          removedAttachment = existingData.tasks[index].attachments.firstWhere(
            (c) => c.attachmentId == attachmentId,
          );

          log(
            'Individual task - Found attachment to delete: ${removedAttachment?.toJson()}',
          );
        } catch (e) {
          log('Attachment not found in individual task: $e');
          return;
        }
      }
    }

    if (removedAttachment == null) {
      Get.snackbar(
        'Error',
        'Attachment not found',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // แสดง Dialog ยืนยันการลบ
    bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Delete Attachment'),
        content: Text(
          'Are you sure you want to delete this attachment?\n\n${removedAttachment.fileName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // ลบจาก local ชั่วคราว
    existingData.tasks[index].attachments.removeWhere(
      (c) => c.attachmentId == attachmentId,
    );
    box.write('userDataAll', existingData.toJson());

    // สำหรับ Group Task: ลบจาก combinedData ด้วย
    if (isgroupTask == true && combinedData?['attachments'] != null) {
      final attachmentList = combinedData['attachments'] as List<dynamic>;
      attachmentList.removeWhere((item) {
        final itemId = item['AttachmentID'] ?? item['attachment_id'];
        if (itemId is int) {
          return itemId == attachmentId;
        } else if (itemId is String) {
          return int.tryParse(itemId) == attachmentId;
        }
        return false;
      });
    }

    // รีเฟรช Provider
    if (isgroupTask == true) {
      appData.showDetailTask.setCurrentTask(
        existingData.tasks[index],
        isGroup: true,
      );
    } else {
      appData.showDetailTask.setCurrentTask(
        existingData.tasks[index],
        isGroup: false,
      );
    }

    // รีเฟรช UI ถ้ามี
    if (mounted) setState(() {});

    try {
      url = await loadAPIEndpoint();
      var response = await http.delete(
        Uri.parse("$url/attachment/delete/${taskId}/${attachmentId}"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );

      // ตรวจสอบและ refresh token ถ้า access denied
      if (response.statusCode == 403) {
        await loadNewRefreshToken();
        response = await http.delete(
          Uri.parse("$url/attachment/delete/${taskId}/${attachmentId}"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
        );
      }

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'Attachment deleted successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // ล้มเหลว: rollback กลับ
        existingData.tasks[index].attachments.add(removedAttachment);
        box.write('userDataAll', existingData.toJson());

        // สำหรับ Group Task: rollback combinedData กลับด้วย
        if (isgroupTask == true &&
            combinedData?['attachments'] != null &&
            removedAttachmentFromCombined != null) {
          final attachmentList = combinedData['attachments'] as List<dynamic>;
          attachmentList.add(removedAttachmentFromCombined);
        }

        // 🔥 รีเฟรช Provider กลับไปสถานะเดิม
        if (isgroupTask == true) {
          appData.showDetailTask.setCurrentTask(
            existingData.tasks[index],
            isGroup: true,
          );
        } else {
          appData.showDetailTask.setCurrentTask(
            existingData.tasks[index],
            isGroup: false,
          );
        }

        if (mounted) setState(() {});

        log('Error deleting attachment: ${response.statusCode}');
        Get.snackbar(
          'Error',
          'Failed to delete attachment',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // ล้มเหลว: rollback กลับ
      existingData.tasks[index].attachments.add(removedAttachment);
      box.write('userDataAll', existingData.toJson());

      // สำหรับ Group Task: rollback combinedData กลับด้วย
      if (isgroupTask == true &&
          combinedData?['attachments'] != null &&
          removedAttachmentFromCombined != null) {
        final attachmentList = combinedData['attachments'] as List<dynamic>;
        attachmentList.add(removedAttachmentFromCombined);
      }

      // 🔥 รีเฟรช Provider กลับไปสถานะเดิม
      if (isgroupTask == true) {
        appData.showDetailTask.setCurrentTask(
          existingData.tasks[index],
          isGroup: true,
        );
      } else {
        appData.showDetailTask.setCurrentTask(
          existingData.tasks[index],
          isGroup: false,
        );
      }

      if (mounted) setState(() {});

      log('Exception deleting attachment: $e');
      Get.snackbar(
        'Error',
        'Failed to delete attachment',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ฟังก์ชั่นdialog สำหรับอัปโหลดไฟล์ มี file, picture, link
  Future<void> _uploadFileDialog(bool? isgroupTask) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // อนุญาตให้ปิด popup โดยแตะด้านนอก
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Upload Options',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ปุ่ม File
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด popup
                    _uploadFileFromDevice(
                      isgroupTask,
                    ); // เรียกฟังก์ชันสำหรับอัปโหลดไฟล์
                  },
                  icon: Icon(Icons.insert_drive_file, color: Colors.blue[800]),
                  label: Text('File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[800],
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              SizedBox(height: 12),
              // ปุ่ม Picture
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด popup
                    _uploadPicture(
                      isgroupTask,
                    ); // เรียกฟังก์ชันสำหรับอัปโหลดรูปภาพ
                  },
                  icon: Icon(Icons.image, color: Colors.green[800]),
                  label: Text('Picture'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[50],
                    foregroundColor: Colors.green[800],
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              SizedBox(height: 12),
              // ปุ่ม Link
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด popup
                    _uploadLink(isgroupTask); // เรียกฟังก์ชันสำหรับเพิ่มลิงก์
                  },
                  icon: Icon(Icons.link, color: Colors.orange[800]),
                  label: Text('Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[50],
                    foregroundColor: Colors.orange[800],
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ปิด popup
              },
              child: Text('Cancel'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันสำหรับอัปโหลดไฟล์จากอุปกรณ์
  Future<void> _uploadFileFromDevice(bool? isgroupTask) async {
    final TextEditingController fileNameController = TextEditingController();
    String selectedFileName = '';
    String selectedFilePath = '';

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Upload File',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ช่องใส่ชื่อไฟล์
                  Text(
                    'File Name',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: fileNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter file name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // ปุ่มเลือกไฟล์
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          // เลือกไฟล์จากเครื่อง
                          FilePickerResult?
                          result = await FilePicker.platform.pickFiles(
                            type: FileType.any, // หรือระบุประเภทไฟล์ที่ต้องการ
                            allowMultiple: false, // เลือกได้ไฟล์เดียว
                          );

                          if (result != null) {
                            PlatformFile file = result.files.first;
                            setState(() {
                              selectedFileName = file.name;
                              selectedFilePath = file.path ?? '';
                            });

                            // หากไม่ได้ใส่ชื่อไฟล์ ให้ใช้ชื่อไฟล์ที่เลือกมา
                            if (fileNameController.text.isEmpty) {
                              fileNameController.text = file.name
                                  .split('.')
                                  .first;
                            }
                          }
                        } catch (e) {
                          // จัดการ error
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error selecting file: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.folder_open),
                      label: Text(
                        selectedFileName.isEmpty
                            ? 'Choose File'
                            : selectedFileName,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),

                  // แสดงข้อมูลไฟล์ที่เลือก (ถ้ามี)
                  if (selectedFileName.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected File:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            selectedFileName,
                            style: TextStyle(fontSize: 14),
                          ),
                          if (selectedFilePath.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              'Size: ${_getFileSize(selectedFilePath)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด popup ปัจจุบัน
                    _uploadFileDialog(isgroupTask); // กลับไปที่ popup หลัก
                  },
                  child: Text('Back'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedFilePath.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          // ทำการอัปโหลดไฟล์ที่นี่
                          Future.microtask(() {
                            _handleFileUpload(
                              fileName: fileNameController.text,
                              filePath: selectedFilePath,
                              isgroupTask: isgroupTask,
                            );
                          });
                        },
                  child: Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ฟังก์ชันบันทึกไฟล์ลงfirebase
  Future<void> _handleFileUpload({
    required String fileName,
    required String filePath,
    bool? isgroupTask,
  }) async {
    String downloadUrl = "";
    String filetype = "";

    // แสดง loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Uploading file...'),
            ],
          ),
        );
      },
    );

    try {
      if (filePath.isEmpty) {
        throw Exception('File path is empty');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found at path: $filePath');
      }

      savedFile = file;

      // ดึง file extension และกำหนด filetype
      final extension = savedFile!.path.split('.').last.toLowerCase();
      filetype = _getFileType(extension);

      final storageReference = FirebaseStorage.instance.ref().child(
        'uploadsFile/${DateTime.now().millisecondsSinceEpoch}_${savedFile!.path.split('/').last}',
      );

      final uploadTask = storageReference.putFile(savedFile!);
      final snapshot = await uploadTask;
      downloadUrl = await snapshot.ref.getDownloadURL();

      Navigator.of(context, rootNavigator: true).pop();

      // บันทึกข้อมูลไฟล์ลงฐานข้อมูล
      await _saveFileToDatabase(
        fileName: fileName,
        filePath: downloadUrl,
        fileType: filetype,
      );
    } catch (e) {
      log('Upload error: $e');

      // ปิด loading dialog
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // บันทึกลงdatabase
  Future<void> _saveFileToDatabase({
    required String fileName,
    required String filePath,
    required String fileType,
  }) async {
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    final appData = Provider.of<Appdata>(context, listen: false);
    var existingData = data.AllDataUserGetResponst.fromJson(userDataJson);

    final currentTask = appData.showDetailTask.currentTask;
    final isGroupTask = appData.showDetailTask.isGroupTask;

    int? taskId;
    int? index;
    late int tempAttachmentId;

    if (isGroupTask) {
      taskId = combinedData['task']['taskID'];
      if (taskId == null) {
        log('Error: taskId is null for group task');
        return;
      }
    } else {
      taskId = currentTask?.taskId;
      if (taskId == null) {
        log('Error: taskId is null for individual task');
        return;
      }

      index = _findIndexCurrentTask(currentTask!);
      if (index == null) {
        log('Error: Cannot find current task index');
        return;
      }
    }

    tempAttachmentId = DateTime.now().millisecondsSinceEpoch;

    while (_checkDuplicateAttachmentId(
      tempAttachmentId,
      isGroupTask,
      existingData,
      index,
    )) {
      tempAttachmentId = DateTime.now().millisecondsSinceEpoch + 1;
      await Future.delayed(Duration(milliseconds: 1));
    }

    final now = DateTime.now().toIso8601String();

    final tempAttachment = data.Attachment(
      attachmentId: tempAttachmentId,
      fileName: fileName,
      filePath: filePath,
      fileType: fileType,
      tasksId: taskId,
      uploadAt: now,
    );

    if (isGroupTask) {
      final tempAttachmentMap = {
        'attachment_id': tempAttachmentId,
        'file_name': fileName,
        'file_path': filePath,
        'file_type': fileType,
        'upload_at': now,
        'task_id': taskId,
      };

      combinedData['attachments'] ??= [];
      combinedData['attachments'].add(tempAttachmentMap);

      final taskIndex = existingData.tasks.indexWhere(
        (t) => t.taskId == taskId,
      );
      if (taskIndex != -1) {
        existingData.tasks[taskIndex].attachments.add(tempAttachment);
        box.write('userDataAll', existingData.toJson());
        appData.showDetailTask.setCurrentTask(
          existingData.tasks[taskIndex],
          isGroup: true,
        );
      }
    } else if (index != null) {
      existingData.tasks[index].attachments.add(tempAttachment);
      box.write('userDataAll', existingData.toJson());
      appData.showDetailTask.setCurrentTask(
        existingData.tasks[index],
        isGroup: false,
      );
    }

    if (mounted) setState(() {});

    try {
      final url = await loadAPIEndpoint();
      final body = jsonEncode({
        "filename": fileName,
        "filepath": filePath,
        "filetype": fileType,
      });

      var response = await http.post(
        Uri.parse("$url/attachment/create/$taskId"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: body,
      );

      if (response.statusCode == 403) {
        await loadNewRefreshToken();
        response = await http.post(
          Uri.parse("$url/attachment/create/$taskId"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
          body: body,
        );
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final int newAttachmentId = responseData['attachment_id'];

        if (isGroupTask && combinedData['attachments'] != null) {
          final list = combinedData['attachments'] as List;
          final i = list.indexWhere(
            (c) => c['attachment_id'] == tempAttachmentId,
          );
          if (i != -1) {
            list[i]['attachment_id'] = newAttachmentId;
          }
        }

        if (!isGroupTask && index != null) {
          final attachmentIndex = existingData.tasks[index].attachments
              .indexWhere((a) => a.attachmentId == tempAttachmentId);
          if (attachmentIndex != -1) {
            existingData
                    .tasks[index]
                    .attachments[attachmentIndex]
                    .attachmentId =
                newAttachmentId;
            box.write('userDataAll', existingData.toJson());
            appData.showDetailTask.setCurrentTask(existingData.tasks[index]);
          }
        }

        if (isGroupTask) {
          final taskIndex = existingData.tasks.indexWhere(
            (t) => t.taskId == taskId,
          );
          if (taskIndex != -1) {
            final attachmentIndex = existingData.tasks[taskIndex].attachments
                .indexWhere((a) => a.attachmentId == tempAttachmentId);
            if (attachmentIndex != -1) {
              existingData
                      .tasks[taskIndex]
                      .attachments[attachmentIndex]
                      .attachmentId =
                  newAttachmentId;
              box.write('userDataAll', existingData.toJson());
            }
          }
        }

        if (mounted) setState(() {});
        await loadDataAsync();
      } else {
        _removeTempAttachment(
          tempAttachmentId,
          isGroupTask,
          existingData,
          index,
          appData,
        );
        log('Error uploading file: ${response.statusCode}');
      }
    } catch (e) {
      _removeTempAttachment(
        tempAttachmentId,
        isGroupTask,
        existingData,
        index,
        appData,
      );
      log('Exception uploading file: $e');
    }
  }

  // ฟังก์ชันสำหรับอัปโหลดรูปภาพ
  Future<void> _uploadPicture(bool? isgroupTask) async {
    final TextEditingController pictureNameController = TextEditingController();
    String selectedImageName = '';
    String selectedImagePath = '';
    XFile? selectedImage;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Upload Picture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ช่องใส่ชื่อภาพ
                  Text(
                    'Picture Name',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: pictureNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter picture name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // ปุ่มเลือกภาพ
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showImageSourceDialog(
                          context,
                          setState,
                          pictureNameController,
                          (image, imageName, imagePath) {
                            selectedImage = image;
                            selectedImageName = imageName;
                            selectedImagePath = imagePath;
                          },
                        );
                      },
                      icon: Icon(Icons.photo_library),
                      label: Text(
                        selectedImageName.isEmpty
                            ? 'Choose Picture'
                            : selectedImageName,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),

                  // แสดงภาพที่เลือก (ถ้ามี)
                  if (selectedImagePath.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(selectedImagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.error_outline,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Image:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            selectedImageName,
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Size: ${_getFileSize(selectedImagePath)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด popup ปัจจุบัน
                    _uploadFileDialog(isgroupTask); // กลับไปที่ popup หลัก
                  },
                  child: Text('Back'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedImagePath.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          // อัปโหลดภาพ
                          Future.microtask(() {
                            _handleImageUpload(
                              imageName: pictureNameController.text,
                              imagePath: selectedImagePath,
                              isgroupTask: isgroupTask,
                            );
                          });
                        },
                  child: Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ฟังก์ชันแสดง dialog เลือกแหล่งที่มาของภาพ
  void _showImageSourceDialog(
    BuildContext context,
    StateSetter setState,
    TextEditingController nameController,
    Function(XFile?, String, String) onImageSelected,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickImage(
                    ImageSource.camera,
                    setState,
                    nameController,
                    onImageSelected,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickImage(
                    ImageSource.gallery,
                    setState,
                    nameController,
                    onImageSelected,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ฟังก์ชันเลือกภาพจากกล้องหรือแกลอรี่
  Future<void> _pickImage(
    ImageSource source,
    StateSetter setState,
    TextEditingController nameController,
    Function(XFile?, String, String) onImageSelected,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920, // จำกัดความกว้างสูงสุด
        maxHeight: 1920, // จำกัดความสูงสูงสุด
        imageQuality: 85, // คุณภาพภาพ (0-100)
      );

      if (image != null) {
        setState(() {
          String imageName = image.name;
          String imagePath = image.path;

          // หากไม่ได้ใส่ชื่อภาพ ให้ใช้ชื่อไฟล์ที่เลือกมา (ไม่รวม extension)
          if (nameController.text.isEmpty) {
            nameController.text = imageName.split('.').first;
          }

          onImageSelected(image, imageName, imagePath);
        });
      }
    } catch (e) {
      // จัดการ error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ฟังก์ชันจัดการการอัปโหลดภาพ
  Future<void> _handleImageUpload({
    required String imageName,
    required String imagePath,
    bool? isgroupTask,
  }) async {
    String downloadUrl = "";
    String fileType = "";

    // แสดง loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Uploading image...'),
            ],
          ),
        );
      },
    );

    try {
      log('Uploading image...');
      log('Name: $imageName');
      log('Path: $imagePath');
      log('Is group task: $isgroupTask');

      if (imagePath.isEmpty) {
        throw Exception('Image path is empty');
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found at path: $imagePath');
      }

      // อัพเดต savedFile สำหรับใช้ในส่วนอื่นๆ
      savedFile = file;

      // ดึง file extension และกำหนด filetype
      final extension = file.path.split('.').last.toLowerCase();
      fileType = _getImageType(extension);

      log('Image extension: $extension');
      log('Image type: $fileType');

      // สร้าง reference ใน Firebase Storage (โฟลเดอร์แยกสำหรับภาพ)
      final storageReference = FirebaseStorage.instance.ref().child(
        'uploadImages/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}',
      );

      final uploadTask = storageReference.putFile(file);
      final snapshot = await uploadTask;
      downloadUrl = await snapshot.ref.getDownloadURL();

      log('Image uploaded successfully. Download URL: $downloadUrl');

      // ปิด loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // บันทึกข้อมูลภาพลงฐานข้อมูล
      await _saveFileToDatabase(
        fileName: imageName,
        filePath: downloadUrl,
        fileType: fileType,
      );
    } catch (e) {
      log('Upload error: $e');

      // ปิด loading dialog
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // ฟังก์ชันสำหรับเพิ่มลิงก์
  Future<void> _uploadLink(bool? isgroupTask) async {
    final TextEditingController linkNameController = TextEditingController();
    final TextEditingController linkUrlController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add Link',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ช่องใส่ชื่อลิงก์
              Text('Link Name', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              TextField(
                controller: linkNameController,
                decoration: InputDecoration(
                  hintText: 'Enter link name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // ช่องใส่ URL
              Text('URL', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              TextField(
                controller: linkUrlController,
                decoration: InputDecoration(
                  hintText: 'Enter URL (https://...)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ปิด popup ปัจจุบัน
                _uploadFileDialog(isgroupTask); // กลับไปที่ popup หลัก
              },
              child: Text('Back'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
            ElevatedButton(
              onPressed: () async {
                // ตรวจสอบว่ากรอกข้อมูลครบหรือไม่
                if (linkNameController.text.trim().isEmpty ||
                    linkUrlController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // ตรวจสอบรูปแบบ URL
                String url = linkUrlController.text.trim();
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  url = 'https://$url'; // เพิ่ม https:// หากไม่มี
                }

                try {
                  // ส่งข้อมูลไปบันทึกในฐานข้อมูล
                  Future.microtask(() {
                    _saveFileToDatabase(
                      fileName: linkNameController.text.trim(),
                      filePath: url,
                      fileType: 'link', // กำหนดประเภทเป็น 'link'
                    );
                  });

                  Navigator.of(context).pop(); // ปิด popup
                } catch (e) {}
              },
              child: Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  String _getImageType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
      case 'tiff':
      case 'tif':
      case 'ico':
      case 'heic':
      default:
        return 'picture';
    }
  }

  String _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown size';
    }
  }

  String _getFileType(String extension) {
    switch (extension) {
      // เอกสาร
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'xls':
      case 'xlsx':
        return 'Excel Spreadsheet';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint Presentation';
      case 'txt':
        return 'Text File';

      // รูปภาพ
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return 'picture';

      // วิดีโอ
      case 'mp4':
        return 'MP4 Video';
      case 'avi':
        return 'AVI Video';
      case 'mkv':
        return 'MKV Video';
      case 'mov':
        return 'MOV Video';
      case 'wmv':
        return 'WMV Video';

      // เสียง
      case 'mp3':
        return 'MP3 Audio';
      case 'wav':
        return 'WAV Audio';
      case 'flac':
        return 'FLAC Audio';
      case 'm4a':
        return 'M4A Audio';

      // บีบอัดไฟล์
      case 'zip':
        return 'ZIP Archive';
      case 'rar':
        return 'RAR Archive';
      case '7z':
        return '7-Zip Archive';
      case 'tar':
        return 'TAR Archive';

      // อื่นๆ
      default:
        return 'Unknown File Type';
    }
  }

  void _removeTempAttachment(
    int tempId,
    bool isGroup,
    data.AllDataUserGetResponst existingData,
    int? index,
    Appdata appData,
  ) {
    if (isGroup) {
      combinedData['attachments']?.removeWhere(
        (a) => a['attachment_id'] == tempId,
      );
      final taskIndex = existingData.tasks.indexWhere(
        (t) => t.taskId == combinedData['task']['taskID'],
      );
      if (taskIndex != -1) {
        existingData.tasks[taskIndex].attachments.removeWhere(
          (a) => a.attachmentId == tempId,
        );
      }
    } else if (index != null) {
      existingData.tasks[index].attachments.removeWhere(
        (a) => a.attachmentId == tempId,
      );
    }

    box.write('userDataAll', existingData.toJson());
    appData.showDetailTask.setCurrentTask(
      existingData.tasks[index ?? 0],
      isGroup: isGroup,
    );

    if (mounted) setState(() {});
  }

  bool _checkDuplicateAttachmentId(
    int attachmentId,
    bool isGroupTask,
    data.AllDataUserGetResponst existingData,
    int? index,
  ) {
    if (isGroupTask) {
      return existingData.tasks.any(
        (task) => task.attachments.any((a) => a.attachmentId == attachmentId),
      );
    } else {
      if (index == null) return false;
      return existingData.tasks[index].attachments.any(
        (a) => a.attachmentId == attachmentId,
      );
    }
  }

  // =================================================== end ==================================================\\

  // =================================================== sharetask ==================================================\\

  void _shareTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                final board =
                    combinedData['board'] as Map<String, dynamic>? ?? {};
                final boarduser =
                    combinedData['boardUsers'] as List<dynamic>? ?? [];
                final boardid = board['BoardID'].toString();
                checkAndHandleExpire(board['ShareExpiresAt'], boardid);
                final shareToken = board['ShareToken'] as String? ?? '';
                final userIsownerboard =
                    (combinedData['board']?['CreatedBy'] ?? '') ==
                    (box.read('userProfile')?['userid'] ?? '');

                // log(userIsownerboard.toString());

                final shareUrl =
                    'myapp://mydayplanner-app/source?join=$shareToken';
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Scrollable content
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: ListView(
                            controller: scrollController,
                            children: [
                              // Handle bar
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),

                              // Title
                              Text(
                                'ShareBoard',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 20),

                              // Share URL Section
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Share URL',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            shareUrl,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            // Copy to clipboard
                                            Clipboard.setData(
                                              ClipboardData(text: shareUrl),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'URL copied to clipboard',
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Icon(
                                              Icons.copy,
                                              size: 16,
                                              color: Colors.blue[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),

                              // Board Users Section
                              Text(
                                'Board Members',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),

                              // Users List
                              ...boarduser.map((user) {
                                final userName =
                                    user['Name'] as String? ?? 'Unknown';
                                final userProfile = user['Profile'] as String?;
                                final userEmail =
                                    user['Email'] as String? ?? '';
                                final userId = user['UserID'].toString();

                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // User Avatar
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child:
                                              userProfile != null &&
                                                  userProfile != 'none-url'
                                              ? Image.network(
                                                  userProfile,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Icon(
                                                          Icons.person,
                                                          size: 24,
                                                          color:
                                                              Colors.grey[600],
                                                        );
                                                      },
                                                )
                                              : Icon(
                                                  Icons.person,
                                                  size: 24,
                                                  color: Colors.grey[600],
                                                ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      // User Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (userEmail.isNotEmpty) ...[
                                              SizedBox(height: 2),
                                              Text(
                                                userEmail,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      // แสดง delete icon กับทุกคน ยกเว้นเจ้าของบอร์ด
                                      if (userIsownerboard &&
                                          userId !=
                                              combinedData['board']['CreatedBy']
                                                  .toString())
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red[400],
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext dialogContext) {
                                                return AlertDialog(
                                                  title: const Text(
                                                    'Confirm Deletion',
                                                  ),
                                                  content: const Text(
                                                    'Are you sure you want to remove this user from the board?',
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(); // Close dialog
                                                      },
                                                    ),
                                                    TextButton(
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(); // Close dialog
                                                        deleteUserAssigned(
                                                          userId,
                                                          boardid,
                                                          setModalState,
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              // Add some bottom padding to prevent overlap with button
                              SizedBox(
                                height:
                                    100 + MediaQuery.of(context).padding.bottom,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Fixed Add User Button at bottom
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 16 + MediaQuery.of(context).padding.bottom,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!, width: 1),
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            _showAddUserPopup(context, setModalState);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Add User',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // เช็คเวลาหมดอายุของลิ้งค์แชร์
  void checkAndHandleExpire(dynamic shareExpiresAt, String boardid) async {
    DateTime? expireDate;
    if (shareExpiresAt is Timestamp) {
      expireDate = shareExpiresAt.toDate(); // แปลงจาก Firestore Timestamp
    }

    if (expireDate != null) {
      final now = DateTime.now();

      if (now.isAfter(expireDate)) {
        final url = await loadAPIEndpoint();
        var headers = {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        };

        var response = await http.put(
          Uri.parse("$url/newtoken/${boardid.toString()}"),
          headers: headers,
        );

        if (response.statusCode == 403) {
          await loadNewRefreshToken();
          headers["Authorization"] = "Bearer ${box.read('accessToken')}";

          response = await http.put(
            Uri.parse("$url/newtoken/${boardid.toString()}"),
            headers: headers,
          );
        }

        if (response.statusCode == 200) {
          loadDataAsync();
        }

        log('⏳ Token หมดอายุแล้ว');
      } else {
        log('✅ Token ยังไม่หมดอายุ');
      }
    } else {
      log('⚠️ ไม่พบวันหมดอายุ');
    }
  }

  Future<void> deleteUserAssigned(
    String? userid,
    String? boardid,
    StateSetter setModalState,
  ) async {
    if (userid == null) return;

    url = await loadAPIEndpoint();
    final body = jsonEncode({"board_id": boardid, "user_id": userid});

    var response = await http.delete(
      Uri.parse("$url/board/boarduser"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: body,
    );

    if (response.statusCode == 403) {
      await loadNewRefreshToken();
      response = await http.delete(
        Uri.parse("$url/board/boarduser"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: body,
      );
    }

    if (response.statusCode == 200) {
      // ลบ user ออกจาก combinedData ทันที
      combinedData['boardUsers'] = (combinedData['boardUsers'] as List)
          .where((user) => user['UserID'].toString() != userid)
          .toList();

      // อัปเดต modal UI
      setModalState(() {});

      // โหลดข้อมูลใหม่จาก server (optional - เพื่อ sync ข้อมูล)
      await loadDataAsync();
    } else {
      log('error delete boarduser${response.statusCode}');
    }
  }

  // popup adduser ของปุ่ม share
  Future<void> _showAddUserPopup(
    BuildContext context,
    StateSetter setModalState,
  ) async {
    // Move controllers and state variables outside of the dialog
    final TextEditingController emailController = TextEditingController();
    final FocusNode searchFocusNode = FocusNode();
    Timer? debounceTimer;
    List<Map<String, dynamic>> searchResults = [];
    bool isLoading = false;
    bool hasSearched = false;
    bool isDialogMounted = true;
    bool isControllerDisposed = false;

    // เพิ่ม flag สำหรับตรวจสอบการ focus
    bool shouldAutoFocus = true;

    // เคลียร์ข้อมูล
    void cleanupResources() {
      if (isControllerDisposed) return;

      isDialogMounted = false;
      debounceTimer?.cancel();
      debounceTimer = null;

      try {
        if (!isControllerDisposed) {
          isControllerDisposed = true;

          // ไม่ต้อง clear text ก่อน dispose
          emailController.dispose();
          searchFocusNode.dispose();
        }
      } catch (e) {
        log('Error during cleanup: $e');
        isControllerDisposed = true;
      }
    }

    // function ค้นหาuser
    Future<void> searchUsers(String query, StateSetter dialogSetState) async {
      if (query.trim().isEmpty) {
        if (isDialogMounted && !isControllerDisposed) {
          dialogSetState(() {
            searchResults.clear();
            hasSearched = false;
          });
        }
        return;
      }

      if (isDialogMounted && !isControllerDisposed) {
        dialogSetState(() {
          isLoading = true;
        });
      }

      try {
        final url = await loadAPIEndpoint();
        final body = jsonEncode({"email": query.trim()});

        var response = await http.post(
          Uri.parse("$url/user/search"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
          body: body,
        );

        // Handle token refresh if needed
        if (response.statusCode == 403) {
          await loadNewRefreshToken();
          response = await http.post(
            Uri.parse("$url/user/search"),
            headers: {
              "Content-Type": "application/json; charset=utf-8",
              "Authorization": "Bearer ${box.read('accessToken')}",
            },
            body: body,
          );
        }

        if (response.statusCode == 200) {
          final List<dynamic> responseData = jsonDecode(response.body);
          if (isDialogMounted && !isControllerDisposed) {
            dialogSetState(() {
              searchResults = responseData.cast<Map<String, dynamic>>();
              hasSearched = true;
              isLoading = false;
            });
          }
        } else {
          log('Error searching users: ${response.statusCode}');
          if (isDialogMounted && !isControllerDisposed) {
            dialogSetState(() {
              searchResults.clear();
              hasSearched = true;
              isLoading = false;
            });
          }
        }
      } catch (e) {
        log('Error searching users: $e');
        if (isDialogMounted && !isControllerDisposed) {
          dialogSetState(() {
            searchResults.clear();
            hasSearched = true;
            isLoading = false;
          });
        }
      }
    }

    // ตรวจสอบข้อมูลบนช่องค้นหาemail
    void onSearchChanged(String value, StateSetter dialogSetState) {
      if (isControllerDisposed || !isDialogMounted) return;
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (isDialogMounted && !isControllerDisposed) {
          searchUsers(value, dialogSetState);
        }
      });
    }

    // ตรวจสอบว่ามีคำเชิญที่ยังรออยู่หรือถูก Accept แล้วหรือไม่
    Future<bool> canSendInvitation(
      String inviterEmail,
      String inviteeEmail,
      String boardId,
    ) async {
      try {
        final existingInvite = await FirebaseFirestore.instance
            .collection('Notifications')
            .doc(inviteeEmail)
            .collection('InviteJoin')
            .where('Inviter', isEqualTo: inviterEmail)
            .where('BoardId', isEqualTo: boardId)
            .get();

        if (existingInvite.docs.isEmpty) {
          return true; // ไม่มีคำเชิญ สามารถส่งได้
        }

        final inviteData = existingInvite.docs.first.data();
        final response = inviteData['Response'];

        // ถ้า Response เป็น Accept แล้ว ไม่สามารถส่งได้อีก
        if (response == 'Accept') {
          return false;
        }

        // ถ้า Response เป็น Waiting หรือ Decline ยังส่งได้
        return response == 'Decline' || response == 'Waiting';
      } catch (e) {
        log('Error checking invitation status: $e');
        return false;
      }
    }

    // เพิ่มuser เข้าบอร์ด
    Future<void> addUserToBoard(
      Map<String, dynamic> selectedUser,
      BuildContext dialogContext,
    ) async {
      try {
        // Add your implementation here
        final user = SearchUserModel.fromMap(selectedUser);
        final boardId =
            combinedData['task']['boardID'] ?? combinedData['board']['BoardID'];
        final boardName = combinedData['board']['BoardName'];
        try {
          // ตรวจสอบก่อนส่ง
          if (!await canSendInvitation(
            box.read('userProfile')['email'],
            user.email,
            boardId.toString(),
          )) {
            Get.snackbar(
              'Cannot Send',
              'Invitation already sent or user already accepted',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            return;
          }
          log(
            'recive invitation to ${user.email} for board $boardId sending${box.read('userProfile')['email']}}',
          );

          // ส่งคำเชิญ
          await FirebaseFirestore.instance
              .collection('Notifications')
              .doc(user.email)
              .collection('InviteJoin')
              .doc('${boardId}from-${box.read('userProfile')['email']}')
              .set({
                'Profile': box.read('userProfile')['profile'],
                'BoardId': boardId.toString(),
                'BoardName': boardName,
                'InviterName': box.read('userProfile')['name'],
                'Inviter': box.read('userProfile')['email'],
                'Response': 'Waiting',
                'Invitation time': DateTime.now(),
                'notiCount': false,
                'updatedAt': Timestamp.now(),
              });
          final reciverEmail = user.email;
          final sendingEmail = box.read('userProfile')['email'] ?? 'unknown';

          url = await loadAPIEndpoint();
          final body = jsonEncode({
            "recieveemail": reciverEmail,
            "sendingemail": sendingEmail,
            "board_id": boardId.toString(),
          });

          var response = await http.post(
            Uri.parse("$url/inviteboardNotify"),
            headers: {
              "Content-Type": "application/json; charset=utf-8",
              "Authorization": "Bearer ${box.read('accessToken')}",
            },
            body: body,
          );

          if (response.statusCode == 403) {
            await loadNewRefreshToken();
            response = await http.post(
              Uri.parse("$url/inviteboardNotify"),
              headers: {
                "Content-Type": "application/json; charset=utf-8",
                "Authorization": "Bearer ${box.read('accessToken')}",
              },
              body: body,
            );
          }
          if (response.statusCode == 200) {
            loadDataAsync();
            log('Invitation sent successfully to $reciverEmail');
          } else {
            log('Failed to send invitation: ${response.statusCode}');
          }
        } catch (e) {
          Get.snackbar(
            'Error',
            'Failed to send invitation: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
        // log(user.email);
      } catch (e) {
        // Handle error
      }
    }

    // เลือกuser
    Future<void> onUserSelectedWithReset(
      Map<String, dynamic> user,
      BuildContext dialogContext,
      StateSetter dialogSetState,
    ) async {
      if (!isDialogMounted || isControllerDisposed) return;

      try {
        log('Selected user: ${user['email']}');
        // ✅ ยืนยันความต้องการก่อนดำเนินการ
        final confirm = await showDialog<bool>(
          context: dialogContext,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm Add User'),
              content: Text(
                'Are you sure you want to add ${user['name']} to this board?',
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  child: Text('Confirm'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );

        if (confirm != true) return; // 🛑 ถ้าไม่ยืนยันก็ไม่ทำต่อ

        // ✅ ดำเนินการเพิ่มผู้ใช้
        await addUserToBoard(user, dialogContext);

        // ✅ รีเซ็ต UI และแสดงข้อความสำเร็จ
        if (isDialogMounted && dialogContext.mounted && !isControllerDisposed) {
          // แสดง success message
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Text('User ${user['name']} added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // เคลียร์และรีเซ็ต UI
          // emailController.clear();
          // dialogSetState(() {
          //   searchResults.clear();
          //   hasSearched = false;
          // });

          // Focus กลับไปที่ search field
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!isControllerDisposed &&
                isDialogMounted &&
                searchFocusNode.canRequestFocus) {
              searchFocusNode.requestFocus();
            }
          });
        }
      } catch (e) {
        log('Error adding user: $e');
        if (isDialogMounted && dialogContext.mounted && !isControllerDisposed) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Text('ไม่สามารถเพิ่มผู้ใช้ได้: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // widget แสดงรายการuser
    Widget buildUserItem(
      Map<String, dynamic> user,
      BuildContext dialogContext,
      StateSetter dialogSetState, // เพิ่มพารามิเตอร์นี้
    ) {
      final String userName = user['name'] ?? '';
      final String userEmail = user['email'] ?? '';
      final String userProfile = user['profile'] ?? 'none-url';
      final bool isActive = user['is_active'] == '1';

      return Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // User Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: ClipOval(
                child: userProfile != 'none-url'
                    ? Image.network(
                        userProfile,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.grey[600],
                          );
                        },
                      )
                    : Icon(Icons.person, size: 24, color: Colors.grey[600]),
              ),
            ),
            SizedBox(width: 12),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (userEmail.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  if (!isActive)
                    Text(
                      'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            // Add button
            InkWell(
              onTap: () async {
                if (!isDialogMounted || isControllerDisposed) return;
                try {
                  // ✅ เรียก onUserSelected แล้วรีเซ็ต UI หลังจากเสร็จ
                  await onUserSelectedWithReset(
                    user,
                    dialogContext,
                    dialogSetState,
                  );
                } catch (e) {
                  log('Error in onUserSelected: $e');
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add,
                  color: Colors.blue[600],
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // widget แสดงการค้นหา
    Widget buildResultsSection(
      StateSetter dialogSetState,
      BuildContext dialogContext,
    ) {
      final searchText = emailController.text;

      if (!hasSearched && searchText.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Start typing to search for users',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        );
      }

      if (isLoading) {
        return Center(child: CircularProgressIndicator());
      }

      if (hasSearched && searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Try searching with a different email',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          return buildUserItem(
            searchResults[index],
            dialogContext,
            dialogSetState, // ✅ ส่ง dialogSetState ไปด้วย
          );
        },
      );
    }

    // แสดง dialog adduser
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            // Auto focus หลังจาก dialog แสดงแล้ว
            if (shouldAutoFocus) {
              shouldAutoFocus = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!isControllerDisposed &&
                    isDialogMounted &&
                    searchFocusNode.canRequestFocus) {
                  searchFocusNode.requestFocus();
                }
              });
            }

            return WillPopScope(
              onWillPop: () async {
                if (!isControllerDisposed) {
                  cleanupResources();
                }
                return true;
              },
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Text(
                              'Search Users',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              onPressed: () {
                                if (!isControllerDisposed) {
                                  cleanupResources();
                                }
                                Navigator.of(dialogContext).pop(false);
                              },
                              icon: Icon(Icons.close),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Search Field
                        TextField(
                          controller: emailController,
                          focusNode: searchFocusNode,
                          onChanged: (value) =>
                              onSearchChanged(value, dialogSetState),
                          decoration: InputDecoration(
                            hintText: 'Enter email to search...',
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: isLoading
                                ? Container(
                                    width: 20,
                                    height: 20,
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : (emailController.text.isNotEmpty)
                                ? IconButton(
                                    onPressed: () {
                                      if (!isControllerDisposed &&
                                          isDialogMounted) {
                                        emailController.clear();
                                        dialogSetState(() {
                                          searchResults.clear();
                                          hasSearched = false;
                                        });
                                      }
                                    },
                                    icon: Icon(Icons.clear),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Results
                        Expanded(
                          child: buildResultsSection(
                            dialogSetState,
                            dialogContext,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Final cleanup
    if (!isControllerDisposed) {
      cleanupResources();
    }
  }

  // =========================================================

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
                  fontSize:
                      Get.textTheme.headlineSmall!.fontSize! *
                      MediaQuery.of(context).textScaleFactor,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              Text(
                'The system has expired. Please log in again.',
                style: TextStyle(
                  fontSize:
                      Get.textTheme.titleSmall!.fontSize! *
                      MediaQuery.of(context).textScaleFactor,
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
              await googleSignIn.initialize();
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
                fontSize:
                    Get.textTheme.titleMedium!.fontSize! *
                    MediaQuery.of(context).textScaleFactor,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
  }
}

class SearchUserModel {
  final int userId;
  final String name;
  final String email;
  final String profile;
  final String role;
  final bool isVerify;
  final bool isActive;
  final DateTime createdAt;

  SearchUserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.profile,
    required this.role,
    required this.isVerify,
    required this.isActive,
    required this.createdAt,
  });

  factory SearchUserModel.fromMap(Map<String, dynamic> map) {
    return SearchUserModel(
      userId: map['user_id'] is int
          ? map['user_id']
          : int.tryParse(map['user_id'].toString()) ?? 0,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profile: map['profile'] ?? '',
      role: map['role'] ?? '',
      isVerify: map['is_verify'] == 1 || map['is_verify'] == true,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
