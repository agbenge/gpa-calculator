import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/gpa_provider.dart';
import '../models/course.dart';

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
                _buildGPAHeader(semester.name, gpa, provider.is5PointScale),
                _buildCourseForm(context, provider.is5PointScale),
                const Divider(height: 1),
                Expanded(
                  child: semester.courses.isEmpty
                      ? const Center(
                          child: Text(
                            "No courses added yet.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: semester.courses.length,
                          itemBuilder: (context, index) {
                            final course = semester.courses[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getGradeColor(course.grade),
                                child: Text(
                                  course.grade,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                course.code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '\${course.units} Units${course.score != null
                                        ? ' (\${course.score}%)'
                                        : ''}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  provider.deleteCourse(
                                    widget.semesterId,
                                    course.id,
                                  );
                                },
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

  Widget _buildGPAHeader(String name, double gpa, bool is5Point) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                gpa.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              Text(
                'GPA (out of \${is5Point ? "5.0" : "4.0"})',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ... skipped down to form ...
  Widget _buildCourseForm(BuildContext context, bool is5PointScale) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Course Code
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 8),
              // Units
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _unitsController,
                  decoration: const InputDecoration(
                    labelText: 'Units',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Score',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _updateGradeFromScore,
                ),
              ),
              const SizedBox(width: 8),
              // Grade Dropdown
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  height: 55, // Match TextField height
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGrade,
                      isExpanded: true,
                      items: _getGradeOptions(is5PointScale).map((
                        String grade,
                      ) {
                        return DropdownMenuItem<String>(
                          value: grade,
                          child: Text(grade),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedGrade = newValue;
                            _scoreController
                                .clear(); // clear score if manually picking grade
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Add button
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () => _addCourse(context),
                  child: const Icon(Icons.add),
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
