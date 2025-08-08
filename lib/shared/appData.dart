import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
import 'package:http/http.dart' as http;
import 'package:mydayplanner/pages/pageMember/detailBoards/tasksDetail.dart';
import 'package:mydayplanner/pages/pageMember/navBar.dart';
import 'package:mydayplanner/splash.dart';
import 'package:provider/provider.dart';

List<Map<String, dynamic>> boardUsers = [];
var box = GetStorage();
final FlutterSecureStorage storage = FlutterSecureStorage();
final GoogleSignIn googleSignIn = GoogleSignIn.instance;
late String url;
TextEditingController boardListNameCtl = TextEditingController();
FocusNode boardListNameFocusNode = FocusNode();

Future<String> loadAPIEndpoint() async {
  var config = await Configuration.getConfig();
  return config['apiEndpoint'];
}

class Appdata with ChangeNotifier {
  KeepIdBoard boardDatas = KeepIdBoard();
  KeepSubjectReportPageAdmin subject = KeepSubjectReportPageAdmin();
  ChangeMyProfileProvider changeMyProfileProvider = ChangeMyProfileProvider();
  KeepEmailToUserPageVerifyOTP keepEmailToUserPageVerifyOTP =
      KeepEmailToUserPageVerifyOTP();
  ShowMyBoards showMyBoards = ShowMyBoards();
  ShowMyTasks showMyTasks = ShowMyTasks();
  ShowDetailTask showDetailTask = ShowDetailTask();
  ShowNotiTasks showNotiTasks = ShowNotiTasks();
  KeepPendingUri keepPendingUri = KeepPendingUri();
}

class KeepPendingUri extends ChangeNotifier {
  Uri? _pendingUri;

  Uri? get pendingUri => _pendingUri;

  void setPendingUri(Uri? newPendingUri) {
    _pendingUri = newPendingUri;
    notifyListeners();
  }

  void clear() {
    _pendingUri = null;
    notifyListeners();
  }

  bool get hasPendingUri => _pendingUri != null;
}

class ShowNotiTasks extends ChangeNotifier {
  String _boardId = '';
  String _taskId = '';

  String get boardId => _boardId;
  String get taskId => _taskId;

  void setBoardId(String newBoardId) {
    _boardId = newBoardId;
    notifyListeners();
  }

  void setTaskId(String newTaskId) {
    _taskId = newTaskId;
    notifyListeners();
  }
}

class ShowDetailTask extends ChangeNotifier {
  Task? _currentTask;
  bool _isGroupTask = false;

  Task? get currentTask => _currentTask;
  bool get isGroupTask => _isGroupTask;

  // ===== Set Task =====
  void setCurrentTask(Task task, {bool isGroup = false}) {
    _currentTask = task;
    _isGroupTask = isGroup;
    notifyListeners();
  }

  // ===== Clear Data =====
  void clearData() {
    _currentTask = null;
    notifyListeners();
  }
}

//use page todayuser
class ShowMyTasks extends ChangeNotifier {
  List<Task> _allTasks = [];

  List<Task> get tasks => _allTasks;

  void setTasks(List<Task> tasksData) {
    _allTasks = tasksData;
    notifyListeners();
  }

  void addTask(Task task) {
    _allTasks.add(task);
    notifyListeners();
  }

  void removeTaskById(String value) {
    _allTasks.removeWhere((task) => task.taskId.toString() == value);
    notifyListeners();
  }
}

//use page homeuser
class ShowMyBoards extends ChangeNotifier {
  List<Board> _createdBoards = [];
  List<Boardgroup> _memberBoards = [];

  List<Board> get createdBoards => _createdBoards;
  List<Boardgroup> get memberBoards => _memberBoards;

  void setBoards(AllDataUserGetResponst boardData) {
    _createdBoards = boardData.board;
    _memberBoards = boardData.boardgroup;
    notifyListeners();
  }

  void addCreatedBoard(Board board) {
    _createdBoards.add(board);
    notifyListeners();
  }

  void addMemberBoard(Boardgroup board) {
    _memberBoards.add(board);
    notifyListeners();
  }

  void removeCreatedBoardById(int boardId) {
    _createdBoards.removeWhere((board) => board.boardId == boardId);
    notifyListeners();
  }

  void removeMemberBoardById(int boardId) {
    _memberBoards.removeWhere((board) => board.boardId == boardId);
    notifyListeners();
  }
}

class KeepEmailToUserPageVerifyOTP extends ChangeNotifier {
  String _email = '';
  String _password = '';
  String _ref = '';
  String _case = '';

  String get email => _email;
  String get password => _password;
  String get ref => _ref;
  String get cases => _case;

  void setEmail(String newEmail) {
    _email = newEmail;
    notifyListeners();
  }

  void setPassword(String newPassword) {
    _password = newPassword;
    notifyListeners();
  }

  void setRef(String newRef) {
    _ref = newRef;
    notifyListeners();
  }

  void setCase(String newCase) {
    _case = newCase;
    notifyListeners();
  }
}

//user page report admin
class KeepSubjectReportPageAdmin {
  String subjectReport = '';
}

//use page homeuser
class KeepIdBoard extends ChangeNotifier {
  String _idBoard = '';
  String _boardName = '';
  String _boardToken = '';

  String get idBoard => _idBoard;
  String get boardName => _boardName;
  String get boardToken => _boardToken;

  void setIdBoard(String newIdBoard) {
    _idBoard = newIdBoard;
    notifyListeners();
  }

  void setBoardName(String newBoardName) {
    _boardName = newBoardName;
    notifyListeners();
  }

  void setBoardToken(String newBoardToken) {
    _boardToken = newBoardToken;
    notifyListeners();
  }
}

//use page homeuser
class ChangeMyProfileProvider extends ChangeNotifier {
  String _name = '';
  String _profile = '';

  String get name => _name;
  String get profile => _profile;

  void setName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void setProfile(String newProfile) {
    _profile = newProfile;
    notifyListeners();
  }
}

class AppDataShareBoardFunction {
  void shareTask(
    BuildContext context,
    int boardId, {
    required Future<void> Function() loadDataAsync,
  }) async {
    var result = await FirebaseFirestore.instance
        .collection('Boards')
        .doc(boardId.toString())
        .get();
    final data = result.data();
    if (data != null) {
      final shareUrl =
          'myapp://mydayplanner-app/source?join=${data['ShareToken']}';

      var result2 = await FirebaseFirestore.instance
          .collection('Boards')
          .doc(boardId.toString())
          .collection('BoardUsers')
          .get();

      boardUsers = result2.docs.map((doc) => doc.data()).toList();
      final userIsownerboard =
          (data['CreatedBy'] ?? '') ==
          (box.read('userProfile')['userid'] ?? '');
      final boardid = data['BoardID'].toString();
      final boardName = data['BoardName'].toString();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          double height = MediaQuery.of(context).size.height;
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SizedBox(
                height: height * 0.94,
                child: Scaffold(
                  body: Container(
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
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
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
                                ...boardUsers.map((user) {
                                  final userName =
                                      user['Name'] as String? ?? 'Unknown';
                                  final userProfile =
                                      user['Profile'] as String?;
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
                                                            color: Colors
                                                                .grey[600],
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
                                                data['CreatedBy'].toString())
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
                                                            loadDataAsync,
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
                                      100 +
                                      MediaQuery.of(context).padding.bottom,
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
                              top: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _showAddUserPopup(
                                context,
                                setModalState,
                                loadDataAsync,
                                boardid,
                                boardName,
                              );
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
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  Future<void> deleteUserAssigned(
    String? userid,
    String? boardid,
    StateSetter setModalState,
    Future<void> Function() loadDataAsync,
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
      await AppDataLoadNewRefreshToken().loadNewRefreshToken();
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
      boardUsers = boardUsers
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

  Future<void> _showAddUserPopup(
    BuildContext context,
    StateSetter setModalState,
    Future<void> Function() loadDataAsync,
    String boardId,
    String boardName,
  ) async {
    // สร้าง controllers และ state variables
    final TextEditingController emailController = TextEditingController();
    final FocusNode searchFocusNode = FocusNode();
    Timer? debounceTimer;
    List<Map<String, dynamic>> searchResults = [];
    bool isLoading = false;
    bool hasSearched = false;
    bool isDialogMounted = true;
    bool isControllerDisposed = false;
    bool shouldAutoFocus = true;

    // ปรับปรุง cleanup function
    void cleanupResources() {
      if (isControllerDisposed) return;

      isDialogMounted = false;
      isControllerDisposed = true;

      // Cancel timer first
      debounceTimer?.cancel();
      debounceTimer = null;

      // Dispose controllers safely
      try {
        emailController.dispose();
      } catch (e) {
        log('Error disposing emailController: $e');
      }

      try {
        if (searchFocusNode.hasFocus) {
          searchFocusNode.unfocus();
        }
        searchFocusNode.dispose();
      } catch (e) {
        log('Error disposing searchFocusNode: $e');
      }
    }

    // function ค้นหาuser
    Future<void> searchUsers(String query, StateSetter dialogSetState) async {
      if (!isDialogMounted || isControllerDisposed) return;

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
          await AppDataLoadNewRefreshToken().loadNewRefreshToken();
          response = await http.post(
            Uri.parse("$url/user/search"),
            headers: {
              "Content-Type": "application/json; charset=utf-8",
              "Authorization": "Bearer ${box.read('accessToken')}",
            },
            body: body,
          );
        }

        if (!isDialogMounted || isControllerDisposed) return;

        if (response.statusCode == 200) {
          final List<dynamic> responseData = jsonDecode(response.body);
          dialogSetState(() {
            searchResults = responseData.cast<Map<String, dynamic>>();
            hasSearched = true;
            isLoading = false;
          });
        } else {
          log('Error searching users: ${response.statusCode}');
          dialogSetState(() {
            searchResults.clear();
            hasSearched = true;
            isLoading = false;
          });
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
      Future<void> Function() loadDataAsync,
    ) async {
      if (!isDialogMounted || isControllerDisposed) return;

      log(boardId.toString());
      log(boardName.toString());
      try {
        final user = SearchUserModel.fromMap(selectedUser);

        // ตรวจสอบก่อนส่ง
        if (!await canSendInvitation(
          box.read('userProfile')['email'],
          user.email,
          boardId.toString(),
        )) {
          if (isDialogMounted && !isControllerDisposed) {
            Get.snackbar(
              'Cannot Send',
              'Invitation already sent or user already accepted',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
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
          await AppDataLoadNewRefreshToken().loadNewRefreshToken();
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
          await loadDataAsync();
          log('Invitation sent successfully to $reciverEmail');
        } else {
          log('Failed to send invitation: ${response.statusCode}');
        }
      } catch (e) {
        if (isDialogMounted && !isControllerDisposed) {
          Get.snackbar(
            'Error',
            'Failed to send invitation: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    }

    // เลือกuser
    Future<void> onUserSelectedWithReset(
      Map<String, dynamic> user,
      BuildContext dialogContext,
      StateSetter dialogSetState,
      Future<void> Function() loadDataAsync,
    ) async {
      if (!isDialogMounted || isControllerDisposed) return;

      try {
        log('Selected user: ${user['email']}');

        // ยืนยันความต้องการก่อนดำเนินการ
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

        if (confirm != true || !isDialogMounted || isControllerDisposed) return;

        // ดำเนินการเพิ่มผู้ใช้
        await addUserToBoard(user, dialogContext, loadDataAsync);

        // แสดง success message และรีเซ็ต UI
        if (isDialogMounted && dialogContext.mounted && !isControllerDisposed) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Text('User ${user['name']} added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // เคลียร์ search results
          dialogSetState(() {
            searchResults.clear();
            hasSearched = false;
          });

          // Clear text field safely
          if (!isControllerDisposed) {
            emailController.clear();
          }

          // Focus กลับไปที่ search field (ถ้ายังสามารถทำได้)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!isControllerDisposed &&
                isDialogMounted &&
                searchFocusNode.canRequestFocus) {
              try {
                searchFocusNode.requestFocus();
              } catch (e) {
                log('Error requesting focus: $e');
              }
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
      StateSetter dialogSetState,
      Future<void> Function() loadDataAsync,
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
                  await onUserSelectedWithReset(
                    user,
                    dialogContext,
                    dialogSetState,
                    loadDataAsync,
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
      Future<void> Function() loadDataAsync,
    ) {
      final searchText = isControllerDisposed ? '' : emailController.text;

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
            dialogSetState,
            loadDataAsync,
          );
        },
      );
    }

    // แสดง dialog adduser
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            // Auto focus หลังจาก dialog แสดงแล้ว
            if (shouldAutoFocus && !isControllerDisposed) {
              shouldAutoFocus = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!isControllerDisposed &&
                    isDialogMounted &&
                    searchFocusNode.canRequestFocus) {
                  try {
                    searchFocusNode.requestFocus();
                  } catch (e) {
                    log('Error auto focusing: $e');
                  }
                }
              });
            }

            return WillPopScope(
              onWillPop: () async {
                cleanupResources();
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
                                cleanupResources();
                                Navigator.of(dialogContext).pop(false);
                              },
                              icon: Icon(Icons.close),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Search Field
                        if (!isControllerDisposed) // เช็คก่อนสร้าง TextField
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
                                  : (!isControllerDisposed &&
                                        emailController.text.isNotEmpty)
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
                            loadDataAsync,
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

    // Final cleanup หลังจาก dialog ปิด
    cleanupResources();
  }
}

class AppDataShareShowEditInfo {
  static void showEditInfo(
    BuildContext context,
    dynamic board,
    String boardToken,
    FontWeight privateFontWeight,
    FontWeight groupFontWeight, {
    String? pageSend,
    bool? menuName,
    required Future<void> Function() loadDataAsync,
  }) {
    boardListNameCtl.text = board.boardName;

    if (pageSend == 'boardShowTasks' && menuName != null && menuName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: 500), () {
          boardListNameFocusNode.requestFocus();
        });
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height;

            return WillPopScope(
              onWillPop: () async {
                Get.back();
                return false;
              },
              child: GestureDetector(
                onTap: () {
                  if (boardListNameFocusNode.hasFocus) {
                    boardListNameFocusNode.unfocus();
                  }
                },
                child: SizedBox(
                  height: height * 0.94,
                  child: Scaffold(
                    appBar: AppBar(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      foregroundColor: Colors.black,
                      centerTitle: true,
                      leading: GestureDetector(
                        onTap: () {
                          Get.back();
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
                        'List Info',
                        style: TextStyle(
                          fontSize: Get.textTheme.titleMedium!.fontSize!,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Get.back();
                            if (board.boardName != boardListNameCtl.text &&
                                boardListNameCtl.text.isNotEmpty) {
                              updateBoardName(
                                context,
                                board.boardId,
                                privateFontWeight,
                                boardListNameCtl,
                              );
                            }
                          },
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: Get.textTheme.titleMedium!.fontSize!,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4790EB),
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.02),
                      ],
                    ),
                    body: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                        child: SingleChildScrollView(
                          child: Column(
                            spacing: 10,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.03,
                                  vertical: height * 0.01,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF2F2F6),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    if (boardToken.isNotEmpty &&
                                        pageSend != 'boardShowTasks')
                                      GestureDetector(
                                        onTap: () {
                                          checkExpiresTokenBoard(board.boardId);
                                          AppDataShareBoardFunction().shareTask(
                                            context,
                                            board.boardId,
                                            loadDataAsync: loadDataAsync,
                                          );
                                        },
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.02,
                                              vertical: height * 0.005,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: Colors.white,
                                            ),
                                            child: Icon(
                                              Icons.share_outlined,
                                              size: 20,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: width * 0.02,
                                        ),
                                        child: Text(
                                          "Board Name",
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .titleMedium!
                                                .fontSize!,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: boardListNameCtl,
                                        focusNode: boardListNameFocusNode,
                                        keyboardType: TextInputType.text,
                                        cursorColor: Color(0xFF4790EB),
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .titleMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        decoration: InputDecoration(
                                          hintText: 'Board List Name',
                                          hintStyle: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .titleMedium!
                                                .fontSize!,
                                            fontWeight: FontWeight.normal,
                                            color: boardListNameCtl.text.isEmpty
                                                ? Colors.black
                                                : Colors.grey,
                                          ),
                                          suffixIcon:
                                              boardListNameFocusNode.hasFocus
                                              ? Material(
                                                  color: Colors.transparent,
                                                  child: IconButton(
                                                    onPressed: () {
                                                      boardListNameCtl.clear();
                                                    },
                                                    icon: SvgPicture.string(
                                                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M9.172 16.242 12 13.414l2.828 2.828 1.414-1.414L13.414 12l2.828-2.828-1.414-1.414L12 10.586 9.172 7.758 7.758 9.172 10.586 12l-2.828 2.828z"></path><path d="M12 22c5.514 0 10-4.486 10-10S17.514 2 12 2 2 6.486 2 12s4.486 10 10 10zm0-18c4.411 0 8 3.589 8 8s-3.589 8-8 8-8-3.589-8-8 3.589-8 8-8z"></path></svg>',
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                )
                                              : IconButton(
                                                  onPressed: null,
                                                  icon: Icon(Icons.edit_sharp),
                                                ),
                                          constraints: BoxConstraints(
                                            maxHeight: height * 0.05,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: width * 0.04,
                                            vertical: height * 0.01,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.03,
                                  vertical: height * 0.01,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF2F2F6),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: Column(
                                  spacing: 8,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Tasks",
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .titleMedium!
                                                .fontSize!,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        FutureBuilder<String>(
                                          future: findNumberOFTasks(
                                            board,
                                            groupFontWeight,
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData &&
                                                snapshot.data!.isNotEmpty) {
                                              return Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.02,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(
                                                    0xFF3B82F6,
                                                  ).withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  snapshot.data.toString(),
                                                  style: TextStyle(
                                                    fontSize: Get
                                                        .textTheme
                                                        .titleSmall!
                                                        .fontSize!,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF3B82F6),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.02,
                                                ),
                                                child: SizedBox(
                                                  width: 8,
                                                  height: 8,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.grey,
                                                      ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "ToDo",
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .titleSmall!
                                                .fontSize!,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        FutureBuilder<String>(
                                          future: findNumberOFTasksToDo(
                                            board,
                                            groupFontWeight,
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData &&
                                                snapshot.data!.isNotEmpty) {
                                              return Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.02,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(
                                                    0xFF3B82F6,
                                                  ).withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  snapshot.data.toString(),
                                                  style: TextStyle(
                                                    fontSize: Get
                                                        .textTheme
                                                        .titleSmall!
                                                        .fontSize!,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF3B82F6),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.02,
                                                ),
                                                child: SizedBox(
                                                  width: 8,
                                                  height: 8,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.grey,
                                                      ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    if (boardToken.isNotEmpty)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "InProgress",
                                            style: TextStyle(
                                              fontSize: Get
                                                  .textTheme
                                                  .titleSmall!
                                                  .fontSize!,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          FutureBuilder<String>(
                                            future: findNumberOFTasksInprogress(
                                              board,
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData &&
                                                  snapshot.data!.isNotEmpty) {
                                                return Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: width * 0.02,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Color(
                                                      0xFF3B82F6,
                                                    ).withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    snapshot.data.toString(),
                                                    style: TextStyle(
                                                      fontSize: Get
                                                          .textTheme
                                                          .titleSmall!
                                                          .fontSize!,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF3B82F6),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: width * 0.02,
                                                  ),
                                                  child: SizedBox(
                                                    width: 8,
                                                    height: 8,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.grey,
                                                        ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Complete",
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .titleSmall!
                                                .fontSize!,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                          ),
                                        ),
                                        FutureBuilder<String>(
                                          future: findNumberOFTasksComplete(
                                            board,
                                            groupFontWeight,
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData &&
                                                snapshot.data!.isNotEmpty) {
                                              return Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.02,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(
                                                    0xFF3B82F6,
                                                  ).withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  snapshot.data.toString(),
                                                  style: TextStyle(
                                                    fontSize: Get
                                                        .textTheme
                                                        .titleSmall!
                                                        .fontSize!,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF3B82F6),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.02,
                                                ),
                                                child: SizedBox(
                                                  width: 8,
                                                  height: 8,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.grey,
                                                      ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (boardToken.isNotEmpty)
                                Container(
                                  height: height * 0.3,
                                  padding: EdgeInsets.symmetric(
                                    vertical: height * 0.01,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF2F2F6),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.02,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  "Team Members",
                                                  style: TextStyle(
                                                    fontSize: Get
                                                        .textTheme
                                                        .titleMedium!
                                                        .fontSize!,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(width: width * 0.01),
                                                FutureBuilder<List>(
                                                  future: showNumberTeamMembers(
                                                    board.boardId,
                                                  ),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData &&
                                                        snapshot
                                                            .data!
                                                            .isNotEmpty) {
                                                      return Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  width * 0.02,
                                                            ),
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  Color(
                                                                    0xFF3B82F6,
                                                                  ).withOpacity(
                                                                    0.1,
                                                                  ),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                        child: Text(
                                                          snapshot.data!.length
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: Get
                                                                .textTheme
                                                                .titleSmall!
                                                                .fontSize!,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Color(
                                                              0xFF3B82F6,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  width * 0.02,
                                                            ),
                                                        child: SizedBox(
                                                          width: 8,
                                                          height: 8,
                                                          child:
                                                              CircularProgressIndicator(
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'Joined on',
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .titleSmall!
                                                    .fontSize!,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: height * 0.005),
                                      Expanded(
                                        child: FutureBuilder<List>(
                                          future: showNumberTeamMembers(
                                            board.boardId,
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData &&
                                                snapshot.data!.isNotEmpty) {
                                              return ListView.builder(
                                                itemCount:
                                                    snapshot.data!.length,
                                                itemBuilder: (context, index) {
                                                  return Padding(
                                                    padding: EdgeInsets.only(
                                                      left: width * 0.02,
                                                      right: width * 0.02,
                                                      bottom: width * 0.01,
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                width * 0.015,
                                                            vertical:
                                                                height * 0.005,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                decoration: BoxDecoration(
                                                                  border: Border.all(
                                                                    color:
                                                                        board.createdBy ==
                                                                            snapshot.data![index]['UserID']
                                                                        ? Color(
                                                                            0xFF3B82F6,
                                                                          )
                                                                        : Colors
                                                                              .transparent,
                                                                  ),
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child: ClipOval(
                                                                  child:
                                                                      snapshot.data![index]['Profile'] ==
                                                                          'none-url'
                                                                      ? Container(
                                                                          width:
                                                                              height *
                                                                              0.035,
                                                                          height:
                                                                              height *
                                                                              0.035,
                                                                          decoration: BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            color:
                                                                                Color(
                                                                                  0xFF3B82F6,
                                                                                ).withOpacity(
                                                                                  0.1,
                                                                                ),
                                                                          ),
                                                                          child: Icon(
                                                                            Icons.person,
                                                                            size:
                                                                                height *
                                                                                0.025,
                                                                            color: Color(
                                                                              0xFF979595,
                                                                            ),
                                                                          ),
                                                                        )
                                                                      : Container(
                                                                          decoration: BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            color:
                                                                                Color(
                                                                                  0xFF3B82F6,
                                                                                ).withOpacity(
                                                                                  0.1,
                                                                                ),
                                                                          ),
                                                                          child: Image.network(
                                                                            snapshot.data![index]['Profile'],
                                                                            width:
                                                                                height *
                                                                                0.035,
                                                                            height:
                                                                                height *
                                                                                0.035,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width:
                                                                    width *
                                                                    0.01,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  snapshot.data![index]['Email'].length >
                                                                          25
                                                                      ? SizedBox(
                                                                          height:
                                                                              height *
                                                                              0.025,
                                                                          width:
                                                                              width *
                                                                              0.55,
                                                                          child: Marquee(
                                                                            text:
                                                                                snapshot.data![index]['Email'],
                                                                            style: TextStyle(
                                                                              fontSize: Get.textTheme.titleSmall!.fontSize!,
                                                                              fontWeight: FontWeight.w500,
                                                                              color:
                                                                                  board.createdBy ==
                                                                                      snapshot.data![index]['UserID']
                                                                                  ? Color(
                                                                                      0xFF3B82F6,
                                                                                    )
                                                                                  : Colors.black87,
                                                                            ),
                                                                            scrollAxis:
                                                                                Axis.horizontal,
                                                                            blankSpace:
                                                                                20.0,
                                                                            velocity:
                                                                                30.0,
                                                                            pauseAfterRound: Duration(
                                                                              seconds: 1,
                                                                            ),
                                                                            startPadding:
                                                                                0,
                                                                            accelerationDuration: Duration(
                                                                              seconds: 1,
                                                                            ),
                                                                            accelerationCurve:
                                                                                Curves.linear,
                                                                            decelerationDuration: Duration(
                                                                              milliseconds: 500,
                                                                            ),
                                                                            decelerationCurve:
                                                                                Curves.easeOut,
                                                                          ),
                                                                        )
                                                                      : Text(
                                                                          snapshot
                                                                              .data![index]['Email'],
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                Get.textTheme.titleSmall!.fontSize!,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            color:
                                                                                board.createdBy ==
                                                                                    snapshot.data![index]['UserID']
                                                                                ? Color(
                                                                                    0xFF3B82F6,
                                                                                  )
                                                                                : Colors.black87,
                                                                          ),
                                                                        ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          board.createdBy ==
                                                                  snapshot
                                                                      .data![index]['UserID']
                                                              ? Text(
                                                                  ' (owner)',
                                                                  style: TextStyle(
                                                                    fontSize: Get
                                                                        .textTheme
                                                                        .titleSmall!
                                                                        .fontSize!,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Color(
                                                                      0xFF3B82F6,
                                                                    ).withOpacity(0.8),
                                                                  ),
                                                                )
                                                              : Text(
                                                                  formatDateTimeAddedAt(
                                                                    (snapshot
                                                                        .data![index]['AddedAt']),
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize: Get
                                                                        .textTheme
                                                                        .labelSmall!
                                                                        .fontSize!,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            } else {
                                              return Center(
                                                child: SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.grey,
                                                      ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              boardToken.isNotEmpty
                                  ? Align(
                                      alignment: Alignment.centerRight,
                                      child: FutureBuilder<String>(
                                        future: formatFullDateTimeGroup(
                                          board.boardId,
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData &&
                                              snapshot.data!.isNotEmpty) {
                                            return Text(
                                              'CreatedAt: ${snapshot.data!}',
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .labelMedium!
                                                    .fontSize!,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
                                              ),
                                            );
                                          } else {
                                            return Text(
                                              'Loading...',
                                              style: TextStyle(
                                                fontSize: Get
                                                    .textTheme
                                                    .labelMedium!
                                                    .fontSize!,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black45,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    )
                                  : Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'CreatedAt: ${formatFullDateTimePrivete(board.createdAt)}',
                                        style: TextStyle(
                                          fontSize: Get
                                              .textTheme
                                              .labelMedium!
                                              .fontSize!,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                              if (boardToken.isNotEmpty &&
                                  pageSend != 'boardShowTasks' &&
                                  board.createdBy !=
                                      box.read('userProfile')['userid'])
                                SizedBox(height: height * 0.07),
                              if (boardToken.isNotEmpty &&
                                  pageSend != 'boardShowTasks' &&
                                  board.createdBy !=
                                      box.read('userProfile')['userid'])
                                Material(
                                  color: Color(0xFFF2F2F6),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () {
                                      leaveBoard(
                                        context,
                                        board.boardId.toString(),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: height * 0.01,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.logout_outlined,
                                            color: Color(0xFFFF3A31),
                                          ),
                                          SizedBox(width: width * 0.01),
                                          Text(
                                            'Leave board',
                                            style: TextStyle(
                                              fontSize: Get
                                                  .textTheme
                                                  .titleMedium!
                                                  .fontSize!,
                                              fontWeight: FontWeight.normal,
                                              color: Color(0xFFFF3A31),
                                            ),
                                          ),
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void leaveBoard(BuildContext context, String boardId) async {
    final userProfiles = box.read('userProfile');
    if (userProfiles == null) return;

    url = await loadAPIEndpoint();

    Get.defaultDialog(
      title: '',
      titlePadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      barrierDismissible: false,
      contentPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.01,
      ),
      content: WillPopScope(
        onWillPop: () async => false,
        child: Column(
          children: [
            Image.asset(
              "assets/images/aleart/question.png",
              height: MediaQuery.of(context).size.height * 0.1,
              fit: BoxFit.contain,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              'Do you want to leave this board?',
              style: TextStyle(
                fontSize: Get.textTheme.titleMedium!.fontSize!,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              'Are you sure you want to leave this board?',
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
        Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                Get.back();
                Get.snackbar('Leaving...', '');
                http.Response response;
                response = await http.delete(
                  Uri.parse("$url/board/boarduser"),
                  headers: {
                    "Content-Type": "application/json; charset=utf-8",
                    "Authorization": "Bearer ${box.read('accessToken')}",
                  },
                  body: jsonEncode({
                    "board_id": boardId,
                    "user_id": userProfiles['userid'].toString(),
                  }),
                );
                if (response.statusCode == 403) {
                  await AppDataLoadNewRefreshToken().loadNewRefreshToken();
                  response = await http.delete(
                    Uri.parse("$url/board/boarduser"),
                    headers: {
                      "Content-Type": "application/json; charset=utf-8",
                      "Authorization": "Bearer ${box.read('accessToken')}",
                    },
                    body: jsonEncode({
                      "board_id": boardId,
                      "user_id": userProfiles['userid'].toString(),
                    }),
                  );
                }
                var response2 = await http.get(
                  Uri.parse("$url/user/data"),
                  headers: {
                    "Content-Type": "application/json; charset=utf-8",
                    "Authorization": "Bearer ${box.read('accessToken')}",
                  },
                );
                if (response2.statusCode == 403) {
                  await AppDataLoadNewRefreshToken().loadNewRefreshToken();
                  response = await http.get(
                    Uri.parse("$url/user/data"),
                    headers: {
                      "Content-Type": "application/json; charset=utf-8",
                      "Authorization": "Bearer ${box.read('accessToken')}",
                    },
                  );
                }
                if (response2.statusCode == 200) {
                  final newDataJson = allDataUserGetResponstFromJson(
                    response2.body,
                  );
                  box.write('userDataAll', newDataJson.toJson());
                  Get.snackbar('Successfully exited the board.', '');
                  Get.offAll(() => NavbarPage());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF007AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
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
              onPressed: () {
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                elevation: 0,
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
      ],
    );
  }

  static Future<String> findNumberOFTasks(
    dynamic boards,
    FontWeight groupFontWeight,
  ) async {
    final boardDataRaw = box.read('userDataAll');
    if (boardDataRaw == null) return '';
    final boardData = AllDataUserGetResponst.fromJson(boardDataRaw);

    if (groupFontWeight == FontWeight.w600) {
      final boardsID = boardData.boardgroup
          .where((t) => t.boardId.toString() == boards.boardId.toString())
          .toList();

      int totalTasks = 0;
      for (var i in boardsID) {
        var result = await FirebaseFirestore.instance
            .collection('Boards')
            .doc(i.boardId.toString())
            .collection('Tasks')
            .get();

        totalTasks += result.docs.length;
      }

      return totalTasks.toString();
    } else {
      String number = boardData.tasks
          .where(
            (board) => board.boardId.toString() == boards.boardId.toString(),
          )
          .toList()
          .length
          .toString();
      return number;
    }
  }

  static String formatFullDateTimePrivete(String timestamp) {
    final DateTime time = DateTime.parse(timestamp).toLocal();

    final String formatted = DateFormat(
      'EEEE, d MMMM yyyy : HH:mm',
    ).format(time);
    return formatted;
  }

  static Future<String> formatFullDateTimeGroup(int boardID) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('Boards')
        .where('BoardID', isEqualTo: boardID)
        .get();

    final data = snapshot.docs.first.data();
    final Timestamp timestamp = data['CreatedAt'];
    final DateTime localTime = timestamp.toDate().toLocal();

    return DateFormat('EEEE, d MMMM yyyy : HH:mm').format(localTime);
  }

  static String formatDateTimeAddedAt(Timestamp timestamp) {
    final DateTime time = timestamp.toDate();

    final String formatted = DateFormat('d MMMM yyyy').format(time);
    return formatted;
  }

  static Future<List> showNumberTeamMembers(int boardID) async {
    var boardUsersSnapshot = await FirebaseFirestore.instance
        .collection('Boards')
        .doc(boardID.toString())
        .collection('BoardUsers')
        .get();

    List emails = [];
    for (var doc in boardUsersSnapshot.docs) {
      emails.add(doc);
    }
    return emails;
  }

  static Future<String> findNumberOFTasksToDo(
    dynamic boards,
    FontWeight groupFontWeight,
  ) async {
    final boardDataRaw = box.read('userDataAll');
    if (boardDataRaw == null) return '';
    final boardData = AllDataUserGetResponst.fromJson(boardDataRaw);

    if (groupFontWeight == FontWeight.w600) {
      final boardsID = boardData.boardgroup
          .where((t) => t.boardId.toString() == boards.boardId.toString())
          .toList();

      int totalTasks = 0;
      for (var i in boardsID) {
        var result = await FirebaseFirestore.instance
            .collection('Boards')
            .doc(i.boardId.toString())
            .collection('Tasks')
            .get();

        final data = result.docs;
        for (var doc in data) {
          if (doc['status'] == '0') {
            totalTasks += 1;
          }
        }
      }

      return totalTasks.toString();
    } else {
      String number = boardData.tasks
          .where(
            (board) => board.boardId.toString() == boards.boardId.toString(),
          )
          .where((task) => task.status == '0')
          .toList()
          .length
          .toString();
      return number;
    }
  }

  static Future<String> findNumberOFTasksInprogress(dynamic boards) async {
    final boardDataRaw = box.read('userDataAll');
    if (boardDataRaw == null) return '';
    final boardData = AllDataUserGetResponst.fromJson(boardDataRaw);

    final boardsID = boardData.boardgroup
        .where((t) => t.boardId.toString() == boards.boardId.toString())
        .toList();

    int totalTasks = 0;
    for (var i in boardsID) {
      var result = await FirebaseFirestore.instance
          .collection('Boards')
          .doc(i.boardId.toString())
          .collection('Tasks')
          .get();

      final data = result.docs;
      for (var doc in data) {
        if (doc['status'] == '1') {
          totalTasks += 1;
        }
      }
    }

    return totalTasks.toString();
  }

  static Future<String> findNumberOFTasksComplete(
    dynamic boards,
    FontWeight groupFontWeight,
  ) async {
    final boardDataRaw = box.read('userDataAll');
    if (boardDataRaw == null) return '';
    final boardData = AllDataUserGetResponst.fromJson(boardDataRaw);

    if (groupFontWeight == FontWeight.w600) {
      final boardsID = boardData.boardgroup
          .where((t) => t.boardId.toString() == boards.boardId.toString())
          .toList();

      int totalTasks = 0;
      for (var i in boardsID) {
        var result = await FirebaseFirestore.instance
            .collection('Boards')
            .doc(i.boardId.toString())
            .collection('Tasks')
            .get();

        final data = result.docs;
        for (var doc in data) {
          if (doc['status'] == '2') {
            totalTasks += 1;
          }
        }
      }

      return totalTasks.toString();
    } else {
      String number = boardData.tasks
          .where(
            (board) => board.boardId.toString() == boards.boardId.toString(),
          )
          .where((task) => task.status == '2')
          .toList()
          .length
          .toString();
      return number;
    }
  }

  static void updateBoardName(
    BuildContext context,
    int boardId,
    FontWeight privateFontWeight,
    TextEditingController boardListNameCtl,
  ) async {
    final userDataJson = box.read('userDataAll');
    if (userDataJson == null) return;

    var existingData = AllDataUserGetResponst.fromJson(userDataJson);
    final appData = Provider.of<Appdata>(context, listen: false);

    if (privateFontWeight == FontWeight.w600) {
      final index = existingData.board.indexWhere((t) => t.boardId == boardId);
      existingData.board[index].boardName = boardListNameCtl.text.trim();
    } else {
      final index = existingData.boardgroup.indexWhere(
        (t) => t.boardId == boardId,
      );
      existingData.boardgroup[index].boardName = boardListNameCtl.text.trim();
    }
    appData.boardDatas.setBoardName(boardListNameCtl.text.trim());
    box.write('userDataAll', existingData.toJson());

    url = await loadAPIEndpoint();
    http.Response response;
    response = await http.put(
      Uri.parse("$url/board/adjust"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer ${box.read('accessToken')}",
      },
      body: jsonEncode({
        "board_id": boardId.toString(),
        "board_name": boardListNameCtl.text.trim(),
      }),
    );
    if (response.statusCode == 403) {
      await AppDataLoadNewRefreshToken().loadNewRefreshToken();
      response = await http.put(
        Uri.parse("$url/board/adjust"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
        body: jsonEncode({
          "board_id": boardId.toString(),
          "board_name": boardListNameCtl.text.trim(),
        }),
      );
    }

    if (response.statusCode == 200) {
      boardListNameCtl.clear();
    }
  }

  static Future<void> checkExpiresTokenBoard(int idBoard) async {
    url = await loadAPIEndpoint();
    final now = DateTime.now();
    final docSnapshot = await FirebaseFirestore.instance
        .collection('Boards')
        .doc(idBoard.toString())
        .get();
    final data = docSnapshot.data();
    if (data != null) {
      if ((data['ShareExpiresAt'] as Timestamp).toDate().isBefore(now)) {
        var response = await http.put(
          Uri.parse("$url/board/newtoken/$idBoard"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer ${box.read('accessToken')}",
          },
        );

        if (response.statusCode == 403) {
          await AppDataLoadNewRefreshToken().loadNewRefreshToken();
          response = await http.put(
            Uri.parse("$url/board/newtoken/$idBoard"),
            headers: {
              "Content-Type": "application/json; charset=utf-8",
              "Authorization": "Bearer ${box.read('accessToken')}",
            },
          );
        }
      }
    }
  }
}

class AppDataLoadNewRefreshToken {
  Future<void> loadNewRefreshToken() async {
    url = await loadAPIEndpoint();
    var value = await storage.read(key: 'refreshToken');
    var loadtokennew = await http.post(
      Uri.parse("$url/auth/newaccesstoken"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer $value",
      },
    );

    if (loadtokennew.statusCode == 200) {
      var reponse = jsonDecode(loadtokennew.body);
      box.write('accessToken', reponse['accessToken']);
    } else if (loadtokennew.statusCode == 403 ||
        loadtokennew.statusCode == 401) {
      Get.defaultDialog(
        title: '',
        titlePadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        barrierDismissible: false,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        content: WillPopScope(
          onWillPop: () async => false,
          child: Column(
            children: [
              Image.asset(
                "assets/images/aleart/warning.png",
                height: 80,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 10),
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
              final userEmail = currentUserProfile['email'];
              if (userEmail == null) return;

              await FirebaseFirestore.instance
                  .collection('usersLogin')
                  .doc(userEmail)
                  .update({'deviceName': FieldValue.delete()});
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
              fixedSize: Size(double.maxFinite, 15),
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
