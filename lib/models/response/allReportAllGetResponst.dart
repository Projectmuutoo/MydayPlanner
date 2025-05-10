// To parse this JSON data, do
//
//     final allReportAllGetResponst = allReportAllGetResponstFromJson(jsonString);

import 'dart:convert';

AllReportAllGetResponst allReportAllGetResponstFromJson(String str) =>
    AllReportAllGetResponst.fromJson(json.decode(str));

String allReportAllGetResponstToJson(AllReportAllGetResponst data) =>
    json.encode(data.toJson());

class AllReportAllGetResponst {
  List<Report> reports;

  AllReportAllGetResponst({required this.reports});

  factory AllReportAllGetResponst.fromJson(Map<String, dynamic> json) =>
      AllReportAllGetResponst(
        reports: List<Report>.from(
          json["reports"].map((x) => Report.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "reports": List<dynamic>.from(reports.map((x) => x.toJson())),
  };
}

class Report {
  String category;
  String color;
  String createAt;
  String description;
  String email;
  String name;
  int reportId;

  Report({
    required this.category,
    required this.color,
    required this.createAt,
    required this.description,
    required this.email,
    required this.name,
    required this.reportId,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    category: json["Category"],
    color: json["Color"],
    createAt: json["CreateAt"],
    description: json["Description"],
    email: json["Email"],
    name: json["Name"],
    reportId: json["ReportID"],
  );

  Map<String, dynamic> toJson() => {
    "Category": category,
    "Color": color,
    "CreateAt": createAt,
    "Description": description,
    "Email": email,
    "Name": name,
    "ReportID": reportId,
  };
}
