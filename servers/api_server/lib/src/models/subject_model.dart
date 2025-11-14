import 'package:api_server/src/models/class_schedule_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subject_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.maxAbsences,
    required this.currentAbsences,
    required this.createdAt,
    required this.updatedAt,
    this.classSchedules = const [],
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) => _$SubjectModelFromJson(json);

  factory SubjectModel.create({
    required String id,
    required String userId,
    required String name,
    required int maxAbsences,
    int currentAbsences = 0,
    List<ClassScheduleModel> classSchedules = const [],
  }) {
    final now = DateTime.now();
    return SubjectModel(
      id: id,
      userId: userId,
      name: name,
      maxAbsences: maxAbsences,
      currentAbsences: currentAbsences,
      classSchedules: classSchedules,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String userId;
  final String name;
  final int maxAbsences;
  final int currentAbsences;
  final List<ClassScheduleModel> classSchedules;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Retorna a porcentagem de faltas (0-100)
  double get absencePercentage {
    if (maxAbsences == 0) return 0;
    return (currentAbsences / maxAbsences) * 100;
  }

  /// Retorna o número de faltas restantes
  int get remainingAbsences => maxAbsences - currentAbsences;

  /// Retorna o status baseado na porcentagem: "safe" | "warning" | "danger"
  String get status {
    if (absencePercentage >= 80) return 'danger';
    if (absencePercentage >= 50) return 'warning';
    return 'safe';
  }

  Map<String, dynamic> toJson() {
    final json = _$SubjectModelToJson(this);
    // Adicionar campos computados ao JSON
    json['absencePercentage'] = absencePercentage;
    json['remainingAbsences'] = remainingAbsences;
    json['status'] = status;
    return json;
  }

  SubjectModel copyWith({
    String? id,
    String? userId,
    String? name,
    int? maxAbsences,
    int? currentAbsences,
    List<ClassScheduleModel>? classSchedules,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      maxAbsences: maxAbsences ?? this.maxAbsences,
      currentAbsences: currentAbsences ?? this.currentAbsences,
      classSchedules: classSchedules ?? this.classSchedules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SubjectModel(id: $id, name: $name, maxAbsences: $maxAbsences, currentAbsences: $currentAbsences)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubjectModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
