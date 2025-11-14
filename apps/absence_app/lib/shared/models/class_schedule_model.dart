import 'package:json_annotation/json_annotation.dart';

part 'class_schedule_model.g.dart';

/// Representa um horário de aula em um dia da semana específico
@JsonSerializable()
class ClassScheduleModel {
  const ClassScheduleModel({
    required this.weekday,
    required this.startTime,
  });

  factory ClassScheduleModel.fromJson(Map<String, dynamic> json) => 
      _$ClassScheduleModelFromJson(json);

  /// Dia da semana (1 = Segunda, 2 = Terça, ..., 6 = Sábado)
  final int weekday;
  
  /// Horário de início da aula no formato "HH:mm" (ex: "19:30")
  final String startTime;

  Map<String, dynamic> toJson() => _$ClassScheduleModelToJson(this);

  ClassScheduleModel copyWith({
    int? weekday,
    String? startTime,
  }) {
    return ClassScheduleModel(
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassScheduleModel &&
          runtimeType == other.runtimeType &&
          weekday == other.weekday &&
          startTime == other.startTime;

  @override
  int get hashCode => weekday.hashCode ^ startTime.hashCode;

  @override
  String toString() => 
      'ClassScheduleModel(weekday: $weekday, startTime: $startTime)';
}
