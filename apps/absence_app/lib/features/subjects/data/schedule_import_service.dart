import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/subject_model.dart';
import '../../../config/env_config.dart';

class ImportedSubject {
  final String name;
  final int maxAbsences;
  final String tp;

  ImportedSubject({
    required this.name,
    required this.maxAbsences,
    required this.tp,
  });

  SubjectModel toSubjectModel(String userId) {
    return SubjectModel.create(
      id: '',
      userId: userId,
      name: name,
      maxAbsences: maxAbsences,
    );
  }
}

class ScheduleImportService {
  static String get _baseUrl => '${EnvConfig.apiBaseUrl}/api/v1';

  Future<List<ImportedSubject>> importFromPdf(
    List<int> fileBytes,
    String filename,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final token = await user.getIdToken();
      if (token == null) {
        throw Exception('Não foi possível obter token de autenticação');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/schedule/import'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      request.headers['Authorization'] = 'Bearer $token';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subjectsList = data['subjects'] as List;
        
        return subjectsList.map((json) {
          return ImportedSubject(
            name: json['name'] as String,
            maxAbsences: json['maxAbsences'] as int? ?? 0,
            tp: json['tp'] as String? ?? '',
          );
        }).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro ao importar arquivo');
      }
    } catch (e) {
      throw Exception('Falha ao importar horário: $e');
    }
  }
}

