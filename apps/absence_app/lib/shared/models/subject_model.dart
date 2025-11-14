import 'package:json_annotation/json_annotation.dart';
import 'class_schedule_model.dart';

part 'subject_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.maxAbsences,
    required this.createdAt,
    required this.updatedAt,
    this.currentAbsences = 0,
    this.absencePercentage = 0.0,
    this.remainingAbsences = 0,
    this.status = 'safe',
    this.classSchedules = const [],
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) => _$SubjectModelFromJson(json);

  factory SubjectModel.create({
    required String id,
    required String userId,
    required String name,
    required int maxAbsences,
    List<ClassScheduleModel> classSchedules = const [],
  }) {
    final now = DateTime.now();
    return SubjectModel(
      id: id,
      userId: userId,
      name: name,
      maxAbsences: maxAbsences,
      currentAbsences: 0,
      absencePercentage: 0.0,
      remainingAbsences: maxAbsences,
      status: 'safe',
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
  final double absencePercentage;
  final int remainingAbsences;
  final String status;
  final List<ClassScheduleModel> classSchedules;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$SubjectModelToJson(this);

  SubjectModel copyWith({
    String? id,
    String? userId,
    String? name,
    int? maxAbsences,
    int? currentAbsences,
    double? absencePercentage,
    int? remainingAbsences,
    String? status,
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
      absencePercentage: absencePercentage ?? this.absencePercentage,
      remainingAbsences: remainingAbsences ?? this.remainingAbsences,
      status: status ?? this.status,
      classSchedules: classSchedules ?? this.classSchedules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Retorna a porcentagem de faltas (0-100)
  /// Nota: Agora vem do backend, mantido como getter para compatibilidade
  double get absencePercentageComputed => absencePercentage;

  /// Retorna o número de faltas restantes
  /// Nota: Agora vem do backend, mantido como getter para compatibilidade  
  int get remainingAbsencesComputed => remainingAbsences;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          maxAbsences == other.maxAbsences &&
          currentAbsences == other.currentAbsences &&
          absencePercentage == other.absencePercentage &&
          remainingAbsences == other.remainingAbsences &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      maxAbsences.hashCode ^
      currentAbsences.hashCode ^
      absencePercentage.hashCode ^
      remainingAbsences.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'SubjectModel(id: $id, userId: $userId, name: $name, maxAbsences: $maxAbsences, '
        'currentAbsences: $currentAbsences, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
