import '../../../shared/models/absence_model.dart';
import '../../../shared/models/api_response.dart';
import '../../../core/network/http_service.dart';

abstract class AbsenceRepository {
  Future<List<AbsenceModel>> getUserAbsences();
  Future<List<AbsenceModel>> getSubjectAbsences(String subjectId);
  Future<AbsenceModel> getAbsence(String id);
  Future<AbsenceModel> createAbsence(String subjectId, AbsenceModel absence);
  Future<AbsenceModel> updateAbsence(AbsenceModel absence);
  Future<void> deleteAbsence(String id);
}

class AbsenceRepositoryImpl implements AbsenceRepository {
  final HttpService _httpService = HttpService();

  @override
  Future<List<AbsenceModel>> getUserAbsences() async {
    try {
      final response = await _httpService.get('/absences');
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response,
        (json) => json as List<dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((json) => AbsenceModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(apiResponse.error ?? 'Erro ao buscar faltas');
      }
    } catch (e) {
      if (e is HttpException) {
        throw Exception('Erro ao buscar faltas: ${e.message}');
      }
      throw Exception('Erro de conexão ao buscar faltas');
    }
  }

  @override
  Future<List<AbsenceModel>> getSubjectAbsences(String subjectId) async {
    try {
      final response = await _httpService.get('/subjects/$subjectId/absences');
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response,
        (json) => json as List<dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((json) => AbsenceModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(apiResponse.error ?? 'Erro ao buscar faltas da matéria');
      }
    } catch (e) {
      if (e is HttpException) {
        throw Exception('Erro ao buscar faltas da matéria: ${e.message}');
      }
      throw Exception('Erro de conexão ao buscar faltas da matéria');
    }
  }

  @override
  Future<AbsenceModel> getAbsence(String id) async {
    try {
      final response = await _httpService.get('/absences/$id');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return AbsenceModel.fromJson(apiResponse.data!);
      } else {
        throw Exception(apiResponse.error ?? 'Erro ao buscar falta');
      }
    } catch (e) {
      if (e is HttpException) {
        throw Exception('Erro ao buscar falta: ${e.message}');
      }
      throw Exception('Erro de conexão ao buscar falta');
    }
  }

  @override
  Future<AbsenceModel> createAbsence(String subjectId, AbsenceModel absence) async {
    try {
      final response = await _httpService.post(
        '/subjects/$subjectId/absences',
        absence.toJson(),
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return AbsenceModel.fromJson(apiResponse.data!);
      } else {
        throw Exception(apiResponse.error ?? 'Erro ao registrar falta');
      }
    } catch (e) {
      if (e is ValidationException) {
        throw Exception(e.message);
      } else if (e is HttpException) {
        throw Exception('Erro ao registrar falta: ${e.message}');
      }
      throw Exception('Erro de conexão ao registrar falta');
    }
  }

  @override
  Future<AbsenceModel> updateAbsence(AbsenceModel absence) async {
    try {
      final response = await _httpService.put('/absences/${absence.id}', absence.toJson());
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return AbsenceModel.fromJson(apiResponse.data!);
      } else {
        throw Exception(apiResponse.error ?? 'Erro ao atualizar falta');
      }
    } catch (e) {
      if (e is ValidationException) {
        throw Exception(e.message);
      } else if (e is HttpException) {
        throw Exception('Erro ao atualizar falta: ${e.message}');
      }
      throw Exception('Erro de conexão ao atualizar falta');
    }
  }

  @override
  Future<void> deleteAbsence(String id) async {
    try {
      final response = await _httpService.delete('/absences/$id');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.error ?? 'Erro ao excluir falta');
      }
    } catch (e) {
      if (e is HttpException) {
        throw Exception('Erro ao excluir falta: ${e.message}');
      }
      throw Exception('Erro de conexão ao excluir falta');
    }
  }
}

// Exceções específicas para faltas
class AbsenceException implements Exception {
  final String message;
  const AbsenceException(this.message);
  
  @override
  String toString() => 'AbsenceException: $message';
}

class AbsenceValidationException extends AbsenceException {
  const AbsenceValidationException(super.message);
}
