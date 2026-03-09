class Course {
  String id;
  String code;
  int units;
  String grade; // e.g., A, B, C, D, E, F
  int? score; // Optional score input

  Course({
    required this.id,
    required this.code,
    required this.units,
    required this.grade,
    this.score,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'units': units,
    'grade': grade,
    'score': score,
  };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'],
    code: json['code'],
    units: json['units'],
    grade: json['grade'] ?? '',
    score: json['score'],
  );
}
