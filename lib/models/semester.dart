import 'course.dart';

class Semester {
  String id;
  String name; // e.g. "Year 1 - Semester 1"
  List<Course> courses;

  Semester({
    required this.id,
    required this.name,
    this.courses = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'courses': courses.map((x) => x.toJson()).toList(),
      };

  factory Semester.fromJson(Map<String, dynamic> json) => Semester(
        id: json['id'],
        name: json['name'],
        courses: List<Course>.from(json['courses'].map((x) => Course.fromJson(x))),
      );
}
