import 'package:flutter/foundation.dart';
import '../models/semester.dart';
import '../models/course.dart';
import '../services/storage_service.dart';

class GpaProvider with ChangeNotifier {
  List<Semester> _semesters = [];
  bool _is5PointScale = true; // defaults to 5.0

  List<Semester> get semesters => _semesters;
  bool get is5PointScale => _is5PointScale;

  final StorageService _storageService = StorageService();

  Future<void> loadData() async {
    _semesters = await _storageService.loadSemesters();
    _is5PointScale = await _storageService.loadScalePreference();
    notifyListeners();
  }

  void toggleScale(bool is5Point) {
    _is5PointScale = is5Point;
    _storageService.saveScalePreference(_is5PointScale);
    notifyListeners();
  }

  void addSemester(String name) {
    _semesters.add(
      Semester(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        courses: [],
      ),
    );
    _save();
  }

  void deleteSemester(String id) {
    _semesters.removeWhere((s) => s.id == id);
    _save();
  }

  void addCourseToSemester(String semesterId, Course course) {
    final sIndex = _semesters.indexWhere((s) => s.id == semesterId);
    if (sIndex != -1) {
      _semesters[sIndex].courses.add(course);
      _save();
    }
  }

  void deleteCourse(String semesterId, String courseId) {
    final sIndex = _semesters.indexWhere((s) => s.id == semesterId);
    if (sIndex != -1) {
      _semesters[sIndex].courses.removeWhere((c) => c.id == courseId);
      _save();
    }
  }

  void updateCourse(String semesterId, Course updatedCourse) {
    final sIndex = _semesters.indexWhere((s) => s.id == semesterId);
    if (sIndex != -1) {
      final cIndex = _semesters[sIndex].courses.indexWhere(
        (c) => c.id == updatedCourse.id,
      );
      if (cIndex != -1) {
        _semesters[sIndex].courses[cIndex] = updatedCourse;
        _save();
      }
    }
  }

  void _save() {
    _storageService.saveSemesters(_semesters);
    notifyListeners();
  }

  // Calculation Logic
  int gradeToPoints(String grade) {
    grade = grade.toUpperCase();
    if (_is5PointScale) {
      switch (grade) {
        case 'A':
          return 5;
        case 'B':
          return 4;
        case 'C':
          return 3;
        case 'D':
          return 2;
        case 'E':
          return 1;
        case 'F':
        default:
          return 0;
      }
    } else {
      // 4.0 scale
      switch (grade) {
        case 'A':
          return 4;
        case 'B':
          return 3;
        case 'C':
          return 2;
        case 'D':
          return 1;
        case 'E':
        case 'F':
        default:
          return 0;
      }
    }
  }

  double calculateSemesterGPA(Semester semester) {
    int totalUnits = 0;
    int totalPoints = 0;

    for (var c in semester.courses) {
      totalUnits += c.units;
      totalPoints += (c.units * gradeToPoints(c.grade));
    }

    if (totalUnits == 0) return 0.0;
    return totalPoints / totalUnits;
  }

  double calculateCGPA() {
    int totalUnits = 0;
    int totalPoints = 0;

    for (var s in _semesters) {
      for (var c in s.courses) {
        totalUnits += c.units;
        totalPoints += (c.units * gradeToPoints(c.grade));
      }
    }

    if (totalUnits == 0) return 0.0;
    return totalPoints / totalUnits;
  }
}
