import '../../../shared/models/subject_model.dart';
import '../../../shared/models/api_response.dart';
import '../../../core/network/http_service.dart';

abstract class SubjectRepository {
  Future<List<SubjectModel>> getSubjects({String? sortBy});
  Future<SubjectModel> getSubject(String id);
  Future<SubjectModel> createSubject(SubjectModel subject);
  Future<SubjectModel> updateSubject(SubjectModel subject);
  Future<void> deleteSubject(String id);
}

class SubjectRepositoryImpl implements SubjectRepository {
  final HttpService _httpService = HttpService();

  @override
  Future<List<SubjectModel>> getSubjects({String? sortBy}) async {
    try {
      final queryParams = sortBy != null ? '?sortBy=$sortBy' : '';
      final response = await _httpService.get('/subjects$queryParams');
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response,
        (json) => json as List<dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((json) => SubjectModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(apiResponse.error ?? 'Erro ao buscar matérias');
      }
    } catch (e) {
      if (e is HttpException) {
        throw Exception('Erro ao buscar matérias: ${e.message}');
      }
      throw Exception('Erro de conexão ao buscar matérias');
    }
  }

  @override
  Future<SubjectModel> getSubject(String id) async {
    try {
      final response = await _httpService.get('/subjects/$id');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return SubjectModel.fromJson(apiResponse.data!);
      } else {
        throw Exception(apiResponse.error ?? 'Erro ao buscar matéria');
      }
    } catch (e) {
      if (e is HttpException) {
        throw Exception('Erro ao buscar matéria: ${e.message}');
      }
      throw Exception('Erro de conexão ao buscar matéria');
    }
  }

  @override
  Future<SubjectModel> createSubject(SubjectModel subject) async {
    try {
      final response = await _httpService.post('/subjects', subject.toJson());
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return SubjectModel.fromJson(apiResponse.data!);
      } else {
        throw Exception(apiResponse.error ?? 'Erro ao criar matéria');
      }
    } catch (e) {
      if (e is ValidationException) {
        throw Exception(e.message);
      } else if (e is HttpException) {
        throw Exception('Erro ao criar matéria: ${e.message}');
      }
      throw Exception('Erro de conexão ao criar matéria');
    }
  }

  @override
  Future<SubjectModel> updateSubject(SubjectModel subject) async {
    try {
      final response = await _httpService.put('/subjects/${subject.id}', subject.toJson());
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return SubjectModel.fromJson(apiResponse.data!);
      } else {
        throw Exception(apiResponse.error ?? 'Erro ao atualizar matéria');
      }
    } catch (e) {
      if (e is ValidationException) {
        throw Exception(e.message);
      } else if (e is HttpException) {
        throw Exception('Erro ao atualizar matéria: ${e.message}');
      }
      throw Exception('Erro de conexão ao atualizar matéria');
    }
  }

  @override
  Future<void> deleteSubject(String id) async {
    try {
      final response = await _httpService.delete('/subjects/$id');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.error ?? 'Erro ao excluir matéria');
      }
    } catch (e) {
      if (e is HttpException) {
        throw Exception('Erro ao excluir matéria: ${e.message}');
      }
      throw Exception('Erro de conexão ao excluir matéria');
    }
  }
}

// Exceções específicas para matérias
class SubjectException implements Exception {
  final String message;
  const SubjectException(this.message);
  
  @override
  String toString() => 'SubjectException: $message';
}

class SubjectValidationException extends SubjectException {
  const SubjectValidationException(super.message);
}
