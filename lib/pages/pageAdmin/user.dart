import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:mydayplanner/config/config.dart';
import 'package:mydayplanner/models/response/allUserGetResponse.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mydayplanner/pages/pageAdmin/secondPage/manageUser.dart';
import 'package:mydayplanner/shared/appData.dart';
import 'package:shimmer/shimmer.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // 📦 Storage
  var box = GetStorage();
  final ScrollController _latestLoginController = ScrollController();
  // 📊 Integer Variables
  int itemCount = 1;
  int loginCount = 0;
  int disableCount = 0;
  int deleteCount = 0;
  List<AllUserGetResponse> responseGetAlluser = [];
  List<Map<String, dynamic>> matchingLogins = [];
  List<Map<String, dynamic>> inactiveLogins = [];
  List<Map<String, dynamic>> deleteLogins = [];

  bool isTyping = true;
  bool isLoadings = true;
  bool showShimmer = true;
  Timer? _debounce;
  // 🔮 Future
  late Future<void> loadData;

  late String url;
  Future<String> loadAPIEndpoint() async {
    var config = await Configuration.getConfig();
    return config['apiEndpoint'];
  }

  @override
  void initState() {
    super.initState();

    startRepeatingTask();
    loadData = loadDataAsync();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void startRepeatingTask() {
    _debounce = Timer.periodic(Duration(seconds: 5), (timer) async {
      await compareUsers();
      getLatestLogin();
      setState(() {});
    });
  }

  Future<http.Response> loadAllUser() async {
    url = await loadAPIEndpoint();
    var responseAllUser = await http.get(
      Uri.parse("$url/user/alluser"),
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
      await AppDataLoadNewRefreshToken().loadNewRefreshToken();
      result = await loadAllUser();
    }

    if (result.statusCode == 200) {
      responseGetAlluser = allUserGetResponseFromJson(result.body);
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
              itemCount = responseGetAlluser.isEmpty
                  ? 1
                  : responseGetAlluser.length;
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Users',
                                style: TextStyle(
                                  fontSize:
                                      Get.textTheme.headlineMedium!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Latest login now: $loginCount',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleLarge!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height:
                                (height * 0.01 * 2 +
                                    height * 0.025 +
                                    height * 0.006) *
                                6,
                            child: Scrollbar(
                              thumbVisibility: true,
                              controller: _latestLoginController,
                              child: SingleChildScrollView(
                                physics: AlwaysScrollableScrollPhysics(),
                                controller: _latestLoginController,
                                child: Column(
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
                                      : getLatestLogin().map((data) {
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: height * 0.005,
                                              right: getLatestLogin().length > 3
                                                  ? width * 0.02
                                                  : 0.0,
                                            ),
                                            child: Material(
                                              color: Color(0xFFF2F2F6),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: InkWell(
                                                onTap: () {},
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  width: width,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: width * 0.03,
                                                    vertical: height * 0.01,
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
                                                      data['email'].length > 25
                                                          ? SizedBox(
                                                              height:
                                                                  height *
                                                                  0.025,
                                                              width:
                                                                  width * 0.45,
                                                              child: Marquee(
                                                                text:
                                                                    data['email'],
                                                                style: TextStyle(
                                                                  fontSize: Get
                                                                      .textTheme
                                                                      .titleSmall!
                                                                      .fontSize!,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                ),
                                                                scrollAxis: Axis
                                                                    .horizontal,
                                                                blankSpace:
                                                                    20.0,
                                                                velocity: 30.0,
                                                                pauseAfterRound:
                                                                    Duration(
                                                                      seconds:
                                                                          1,
                                                                    ),
                                                                startPadding: 0,
                                                                accelerationDuration:
                                                                    Duration(
                                                                      seconds:
                                                                          1,
                                                                    ),
                                                                accelerationCurve:
                                                                    Curves
                                                                        .linear,
                                                                decelerationDuration:
                                                                    Duration(
                                                                      milliseconds:
                                                                          500,
                                                                    ),
                                                                decelerationCurve:
                                                                    Curves
                                                                        .easeOut,
                                                              ),
                                                            )
                                                          : Text(
                                                              data['email'],
                                                              style: TextStyle(
                                                                fontSize: Get
                                                                    .textTheme
                                                                    .titleSmall!
                                                                    .fontSize!,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                              ),
                                                            ),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            timeAgo(
                                                              data['updated_at'],
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: Get
                                                                  .textTheme
                                                                  .labelMedium!
                                                                  .fontSize!,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color: Colors
                                                                  .black54,
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
                                        }).toList(),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          Row(
                            children: [
                              Text(
                                'Manage users',
                                style: TextStyle(
                                  fontSize: Get.textTheme.titleLarge!.fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        SvgPicture.string(
                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zM4 12c0-1.846.634-3.542 1.688-4.897l11.209 11.209A7.946 7.946 0 0 1 12 20c-4.411 0-8-3.589-8-8zm14.312 4.897L7.103 5.688A7.948 7.948 0 0 1 12 4c4.411 0 8 3.589 8 8a7.954 7.954 0 0 1-1.688 4.897z"></path></svg>',
                                          width: width * 0.04,
                                          height: height * 0.04,
                                          fit: BoxFit.contain,
                                          color: Colors.orange,
                                        ),
                                        Text(
                                          disableCount.toString(),
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .headlineMedium!
                                                .fontSize!,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black38,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Disable',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .titleMedium!
                                                .fontSize!,
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
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        SvgPicture.string(
                                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m21.706 5.292-2.999-2.999A.996.996 0 0 0 18 2H6a.996.996 0 0 0-.707.293L2.294 5.292A.994.994 0 0 0 2 6v13c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V6a.994.994 0 0 0-.294-.708zM6.414 4h11.172l1 1H5.414l1-1zM4 19V7h16l.002 12H4z"></path><path d="M14 9h-4v3H7l5 5 5-5h-3z"></path></svg>',
                                          width: width * 0.04,
                                          height: height * 0.04,
                                          fit: BoxFit.contain,
                                          color: Colors.black54,
                                        ),
                                        Text(
                                          deleteCount.toString(),
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .headlineMedium!
                                                .fontSize!,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black38,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontSize: Get
                                                .textTheme
                                                .titleMedium!
                                                .fontSize!,
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
                        ],
                      ),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Get.to(() => ManageuserPage());
                            },
                            style: ElevatedButton.styleFrom(
                              fixedSize: Size(width, height * 0.05),
                              backgroundColor: Colors.grey,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M16 2H8C4.691 2 2 4.691 2 8v13a1 1 0 0 0 1 1h13c3.309 0 6-2.691 6-6V8c0-3.309-2.691-6-6-6zm4 14c0 2.206-1.794 4-4 4H4V8c0-2.206 1.794-4 4-4h8c2.206 0 4 1.794 4 4v8z"></path><path d="M7 14.987v1.999h1.999l5.529-5.522-1.998-1.998zm8.47-4.465-1.998-2L14.995 7l2 1.999z"></path></svg>',
                                ),
                                SizedBox(width: width * 0.02),
                                Text(
                                  'Manage',
                                  style: TextStyle(
                                    fontSize:
                                        Get.textTheme.titleMedium!.fontSize!,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                        ],
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
    final firestoreSnapshot = await FirebaseFirestore.instance
        .collection('usersLogin')
        .get();

    matchingLogins.clear();
    inactiveLogins.clear();
    deleteLogins.clear();
    loginCount = 0;
    disableCount = 0;
    deleteCount = 0;

    for (var doc in firestoreSnapshot.docs) {
      var email = doc.id;
      var data = doc.data();
      var login = data['login'];
      var updatedAt = data['updated_at'].toDate();
      var active = data['active'];

      var matchedUser = responseGetAlluser.firstWhereOrNull(
        (u) =>
            u.email == email &&
            u.email.toLowerCase() != 'mydayplanner.noreply@gmail.com',
      );

      if (matchedUser != null && login == 1) {
        matchingLogins.add({
          'email': email,
          'updated_at': updatedAt.toIso8601String(),
        });
        loginCount++;
      }
      if (matchedUser != null && active == "0") {
        inactiveLogins.add({
          'email': email,
          'active': active,
          'updated_at': updatedAt.toIso8601String(),
        });
        disableCount++;
      }
      if (matchedUser != null && active == "2") {
        deleteLogins.add({
          'email': email,
          'active': active,
          'updated_at': updatedAt.toIso8601String(),
        });
        deleteCount++;
      }
    }

    responseGetAlluser = responseGetAlluser
        .where(
          (user) =>
              matchingLogins.any((m) => m['email'] == user.email) ||
              inactiveLogins.any((i) => i['email'] == user.email) ||
              deleteLogins.any((j) => j['email'] == user.email),
        )
        .toList();
  }

  List<Map<String, dynamic>> getLatestLogin() {
    matchingLogins.sort((a, b) {
      final aDate = DateTime.parse(a['updated_at']);
      final bDate = DateTime.parse(b['updated_at']);
      return bDate.compareTo(aDate);
    });

    return matchingLogins;
  }

  List<Map<String, dynamic>> getLatestUserInActive() {
    inactiveLogins.sort((a, b) {
      final aDate = DateTime.parse(a['updated_at']);
      final bDate = DateTime.parse(b['updated_at']);
      return bDate.compareTo(aDate);
    });

    return inactiveLogins;
  }

  List<Map<String, dynamic>> getLatestUserDelete() {
    deleteLogins.sort((a, b) {
      final aDate = DateTime.parse(a['updated_at']);
      final bDate = DateTime.parse(b['updated_at']);
      return bDate.compareTo(aDate);
    });

    return deleteLogins;
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
}
