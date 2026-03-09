import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/gpa_provider.dart';
import '../models/course.dart';
import '../models/semester.dart';

class SemesterScreen extends StatefulWidget {
  final String semesterId;
  const SemesterScreen({super.key, required this.semesterId});

  @override
  State<SemesterScreen> createState() => _SemesterScreenState();
}

class _SemesterScreenState extends State<SemesterScreen> {
  final _codeController = TextEditingController();
  final _unitsController = TextEditingController();
  final _scoreController = TextEditingController();
  String _selectedGrade = 'A';
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSavingImage = false;

  void _addCourse(BuildContext context) {
    if (_codeController.text.isEmpty || _unitsController.text.isEmpty) return;

    final units = int.tryParse(_unitsController.text);
    if (units == null || units <= 0) return;

    int? finalScore;
    if (_scoreController.text.isNotEmpty) {
      finalScore = int.tryParse(_scoreController.text);
    }

    final newCourse = Course(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: _codeController.text.toUpperCase(),
      units: units,
      grade: _selectedGrade,
      score: finalScore,
    );

    Provider.of<GpaProvider>(
      context,
      listen: false,
    ).addCourseToSemester(widget.semesterId, newCourse);

    _codeController.clear();
    _unitsController.clear();
    _scoreController.clear();
    setState(() {
      _selectedGrade = 'A';
    });
    FocusScope.of(context).unfocus();
  }

  void _updateGradeFromScore(String value) {
    if (value.isEmpty) {
      setState(() {
        _selectedGrade = 'A';
      });
      return;
    }
    final score = int.tryParse(value);
    if (score == null) return;

    String newGrade = _selectedGrade;
    if (score >= 70) {
      newGrade = 'A';
    } else if (score >= 60)
      newGrade = 'B';
    else if (score >= 50)
      newGrade = 'C';
    else if (score >= 45)
      newGrade = 'D';
    else if (score >= 40)
      newGrade = 'E';
    else
      newGrade = 'F';

    if (newGrade != _selectedGrade) {
      setState(() {
        _selectedGrade = newGrade;
      });
    }
  }

  Future<void> _pickPhysicalCopyImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await showDialog<XFile?>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add Physical Copy'),
            content: const Text(
              'Do you want to take a photo of your transcript or upload from gallery?',
            ),
            actions: [
              TextButton(
                child: const Text('Camera'),
                onPressed: () async {
                  Navigator.pop(
                    context,
                    await picker.pickImage(source: ImageSource.camera),
                  );
                },
              ),
              TextButton(
                child: const Text('Gallery'),
                onPressed: () async {
                  Navigator.pop(
                    context,
                    await picker.pickImage(source: ImageSource.gallery),
                  );
                },
              ),
            ],
          );
        },
      );

      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Physical copy saved locally!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to get image')));
    }
  }

  Future<void> _captureAndSave() async {
    setState(() => _isSavingImage = true);
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        // gal automatically requests permission and saves
        await Gal.putImageBytes(
          image,
          name: "GPA_Snap_\${DateTime.now().millisecondsSinceEpoch}",
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved to Gallery!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error saving snapshot')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Semester Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.document_scanner),
              tooltip: 'Add Physical Copy',
              onPressed: _pickPhysicalCopyImage,
            ),
            if (_isSavingImage)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.camera_alt),
                tooltip: 'Snap & Save',
                onPressed: _captureAndSave,
              ),
          ],
        ),
        body: Consumer<GpaProvider>(
          builder: (context, provider, child) {
            final semester = provider.semesters.firstWhere(
              (s) => s.id == widget.semesterId,
              orElse: () => throw Exception('Semester not found'),
            );
            final gpa = provider.calculateSemesterGPA(semester);

            return Column(
              children: [
                _buildGPAHeader(semester, gpa, provider),
                _buildCourseForm(context, provider.is5PointScale),
                const Divider(height: 1),
                Expanded(
                  child: semester.courses.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.library_books_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No courses added yet.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: semester.courses.length,
                          itemBuilder: (context, index) {
                            final course = semester.courses[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(
                                      course.grade,
                                    ).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      course.grade,
                                      style: TextStyle(
                                        color: _getGradeColor(course.grade),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  course.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${course.units} Units${course.score != null ? ' • ${course.score}%' : ''}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    provider.deleteCourse(
                                      widget.semesterId,
                                      course.id,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGPAHeader(Semester semester, double gpa, GpaProvider provider) {
    final int regUnits = provider.getSemesterRegisteredUnits(semester);
    final int passedUnits = provider.getSemesterPassedUnits(semester);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  semester.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Registered: $regUnits',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Passed: $passedUnits',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurple.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  gpa.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  'GPA (${provider.is5PointScale ? "5.0" : "4.0"})',
                  style: TextStyle(
                    color: Colors.deepPurple.shade300,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... skipped down to form ...
  Widget _buildCourseForm(BuildContext context, bool is5PointScale) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Course',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Course Code
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Course Code',
                    hintText: 'e.g. MTH 101',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 12),
              // Units
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _unitsController,
                  decoration: InputDecoration(
                    labelText: 'Units',
                    hintText: 'e.g. 3',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Score
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _scoreController,
                  decoration: InputDecoration(
                    labelText: 'Score (%)',
                    hintText: 'Optional',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _updateGradeFromScore,
                ),
              ),
              const SizedBox(width: 12),
              // Grade Dropdown
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 56, // Match standard TextField height
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGrade,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.deepPurple,
                      ),
                      items: _getGradeOptions(is5PointScale).map((
                        String grade,
                      ) {
                        return DropdownMenuItem<String>(
                          value: grade,
                          child: Text(
                            grade,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedGrade = newValue;
                            _scoreController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Add button
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurpleAccent.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _addCourse(context),
                  icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  tooltip: 'Add Course',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _getGradeOptions(bool is5Point) {
    if (is5Point) {
      return ['A', 'B', 'C', 'D', 'E', 'F'];
    } else {
      return ['A', 'B', 'C', 'D', 'F'];
    }
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.brown;
      case 'E':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
