import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/semester.dart';
import '../models/course.dart';
import '../services/storage_service.dart';
import '../services/google_drive_service.dart';

class GpaProvider with ChangeNotifier {
  List<Semester> _semesters = [];
  bool _is5PointScale = true; // defaults to 5.0

  List<Semester> get semesters => _semesters;
  bool get is5PointScale => _is5PointScale;

  final StorageService _storageService = StorageService();
  final GoogleDriveService _googleDriveService = GoogleDriveService();

  bool _isSyncing = false;
  bool _isDriveConnected = false;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  bool get isDriveConnected => _isDriveConnected;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<void> loadData() async {
    _semesters = await _storageService.loadSemesters();
    _is5PointScale = await _storageService.loadScalePreference();
    _isDriveConnected = await _googleDriveService.isSignedIn();
    notifyListeners();
  }

  Future<void> signInToDrive() async {
    final account = await _googleDriveService.signIn();
    if (account != null) {
      _isDriveConnected = true;
      notifyListeners();
      await syncWithDrive();
    }
  }

  Future<void> signOutFromDrive() async {
    await _googleDriveService.signOut();
    _isDriveConnected = false;
    notifyListeners();
  }

  Future<void> syncWithDrive() async {
    if (_isSyncing || !_isDriveConnected) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final localData = jsonEncode({
        'semesters': _semesters.map((s) => s.toJson()).toList(),
        'is5PointScale': _is5PointScale,
        'lastModified': DateTime.now().toIso8601String(),
      });

      final success = await _googleDriveService.uploadData(localData);
      if (success) {
        _lastSyncTime = DateTime.now();
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void toggleScale(bool is5Point) {
    _is5PointScale = is5Point;
    _storageService.saveScalePreference(_is5PointScale);
    notifyListeners();
    syncWithDrive();
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
    syncWithDrive();
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

  String getClassOfDegree() {
    final cgpa = calculateCGPA();
    if (cgpa == 0.0) return "N/A";

    if (_is5PointScale) {
      if (cgpa >= 4.50) return "First Class";
      if (cgpa >= 3.50) return "Second Class Upper";
      if (cgpa >= 2.40) return "Second Class Lower";
      if (cgpa >= 1.50) return "Third Class";
      if (cgpa >= 1.00) return "Pass";
      return "Fail";
    } else {
      // 4.0 scale
      if (cgpa >= 3.50) return "First Class / Distinction";
      if (cgpa >= 3.00) return "Second Class Upper";
      if (cgpa >= 2.00) return "Second Class Lower";
      if (cgpa >= 1.00) return "Third Class";
      return "Fail";
    }
  }

  int getTotalRegisteredUnits() {
    int total = 0;
    for (var s in _semesters) {
      for (var c in s.courses) {
        total += c.units;
      }
    }
    return total;
  }

  int getTotalPassedUnits() {
    int total = 0;
    for (var s in _semesters) {
      for (var c in s.courses) {
        if (gradeToPoints(c.grade) > 0) {
          total += c.units;
        }
      }
    }
    return total;
  }

  int getSemesterRegisteredUnits(Semester semester) {
    int total = 0;
    for (var c in semester.courses) {
      total += c.units;
    }
    return total;
  }

  int getSemesterPassedUnits(Semester semester) {
    int total = 0;
    for (var c in semester.courses) {
      if (gradeToPoints(c.grade) > 0) {
        total += c.units;
      }
    }
    return total;
  }
}
