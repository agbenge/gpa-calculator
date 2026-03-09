import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/semester.dart';

class StorageService {
  static const String keySemesters = 'gpa_semesters';
  static const String keyScale = 'gpa_scale_5';

  Future<void> saveSemesters(List<Semester> semesters) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> items = semesters.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(keySemesters, items);
  }

  Future<List<Semester>> loadSemesters() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? items = prefs.getStringList(keySemesters);
    if (items == null) return [];
    return items.map((s) => Semester.fromJson(jsonDecode(s))).toList();
  }

  Future<void> saveScalePreference(bool is5Point) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyScale, is5Point);
  }

  Future<bool> loadScalePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyScale) ?? true; // Default to 5.0 scale
  }
}
