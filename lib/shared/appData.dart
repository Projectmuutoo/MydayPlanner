import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/response/allDataUserGetResponst.dart';
import 'package:http/http.dart' as http;
import 'package:mydayplanner/pages/pageMember/detailBoards/tasksDetail.dart';
import 'package:mydayplanner/splash.dart';

Map<String, dynamic> combinedData = {};
var box = GetStorage();
final FlutterSecureStorage storage = FlutterSecureStorage();
final GoogleSignIn googleSignIn = GoogleSignIn.instance;
late String url;

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
  void shareTask(BuildContext context, int boardId) async {
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

      final boardUsers = result2.docs.map((doc) => doc.data()).toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.94,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                              final userProfile = user['Profile'] as String?;
                              final userEmail = user['Email'] as String? ?? '';

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
                                                        color: Colors.grey[600],
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
    }
  }

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
          await loadNewRefreshToken(context);
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

    // ตรวจสอบข้อมูลบนtextfield
    void onSearchChanged(String value, StateSetter dialogSetState) {
      if (isControllerDisposed || !isDialogMounted) return;

      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (isDialogMounted && !isControllerDisposed) {
          searchUsers(value, dialogSetState);
        }
      });
    }

    Future<bool> canSendInvitation(
      String inviterEmail,
      String inviteeEmail,
      String boardId,
    ) async {
      try {
        // ตรวจสอบว่ามีคำเชิญที่ยังรออยู่หรือถูก Accept แล้วหรือไม่
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
        final boardId = combinedData['task']['boardID'];
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
        } catch (e) {
          Get.snackbar(
            'Error',
            'Failed to send invitation: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
        log(user.email);
      } catch (e) {
        log(e.toString());
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
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
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
      final bool isVerified = user['is_verify'] == '1';
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
    final result = await showDialog<bool>(
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

  Future<void> loadNewRefreshToken(BuildContext context) async {
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

      final responseAll = await http.get(
        Uri.parse("$url/user/data"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer ${box.read('accessToken')}",
        },
      );
      if (responseAll.statusCode == 200) {
        final response2 = allDataUserGetResponstFromJson(responseAll.body);
        box.write('userDataAll', response2.toJson());
      }
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
