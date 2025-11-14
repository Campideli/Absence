import 'dart:convert';

import 'package:api_server/src/middleware/auth_middleware.dart';
import 'package:api_server/src/models/api_response.dart';
import 'package:api_server/src/models/class_schedule_model.dart';
import 'package:api_server/src/models/subject_model.dart';
import 'package:api_server/src/services/firestore_service.dart';
import 'package:api_server/src/services/input_sanitizer.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

class SubjectController {

  // GET /subjects - Listar matérias do usuário
  static Future<Response> listSubjects(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(
          401,
          body: jsonEncode(ApiResponse.errorToJson(
            'Usuário não autenticado',
            401,
          )),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Obter query parameter sortBy
      final sortBy = request.url.queryParameters['sortBy'];
      
      final subjects = await FirestoreService.getUserSubjects(userId, sortBy: sortBy);
      
      return Response.ok(
        jsonEncode(ApiResponse.successListToJson(
          subjects.map((s) => s.toJson()).toList(),
          'Subjects retrieved successfully',
        )),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(ApiResponse.errorToJson(
          'Failed to retrieve subjects',
          500,
        )),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // POST /subjects - Criar nova matéria
  static Future<Response> createSubject(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(
          401,
          body: jsonEncode(ApiResponse.errorToJson(
            'Usuário não autenticado',
            401,
          )),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // SECURITY: Sanitizar e validar input de string
      final sanitizedName = InputSanitizer.sanitizeAndValidate(
        data['name'] as String?,
        100,
        minLength: 1,
      );
      
      if (sanitizedName == null) {
        return Response(
          422,
          body: jsonEncode(ApiResponse.errorToJson(
            'Nome inválido ou fora dos limites (1-100 caracteres)',
            422,
          )),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Parse classSchedules se fornecido
      final classSchedules = <ClassScheduleModel>[];
      if (data['classSchedules'] != null) {
        final schedulesData = data['classSchedules'] as List<dynamic>;
        for (final scheduleData in schedulesData) {
          try {
            classSchedules.add(
              ClassScheduleModel.fromJson(scheduleData as Map<String, dynamic>)
            );
          } catch (e) {
            // Ignorar horários inválidos mas continuar
          }
        }
      }

      final subject = SubjectModel.create(
        id: '', // ID será gerado pelo Firestore
        userId: userId,
        name: sanitizedName,
        maxAbsences: data['maxAbsences'] as int,
        classSchedules: classSchedules,
      );

      final subjectId = await FirestoreService.createSubject(subject);
      if (subjectId == null) {
        return Response(
          500,
          body: jsonEncode(ApiResponse.errorToJson(
            'Failed to create subject',
            500,
          )),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Retornar a matéria com o ID correto do Firestore
      final createdSubject = subject.copyWith(id: subjectId);

      return Response(
        201,
        body: jsonEncode(ApiResponse.successToJson(
          createdSubject.toJson(),
          'Subject created successfully',
        )),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      final logger = Logger('SubjectController');
      logger.severe('Error creating subject', e);
      return Response.internalServerError(
        body: jsonEncode(ApiResponse.errorToJson(
          'Failed to create subject',
          500,
        )),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // GET /subjects/:id - Obter matéria específica
  static Future<Response> getSubject(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(
          401,
          body: jsonEncode(ApiResponse.errorToJson(
            'Usuário não autenticado',
            401,
          )),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final subjectId = request.url.pathSegments.last;
      
      final subject = await FirestoreService.getSubject(subjectId);
      if (subject == null) {
        return Response.notFound(
          jsonEncode(ApiResponse.error(
            message: 'Subject not found',
            code: 404,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // SECURITY: Validar ownership antes de retornar dados
      if (subject.userId != userId) {
        return Response(
          403,
          body: jsonEncode(ApiResponse.error(
            message: 'Access denied',
            code: 403,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(ApiResponse.success(
          data: subject.toJson(),
          message: 'Subject retrieved successfully',
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(ApiResponse.error(
          message: 'Failed to retrieve subject',
          code: 500,
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // PUT /subjects/:id - Atualizar matéria
  static Future<Response> updateSubject(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(
          401,
          body: jsonEncode(ApiResponse.errorToJson(
            'Usuário não autenticado',
            401,
          )),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final subjectId = request.url.pathSegments.last;
      
      final subject = await FirestoreService.getSubject(subjectId);
      if (subject == null) {
        return Response.notFound(
          jsonEncode(ApiResponse.error(
            message: 'Subject not found',
            code: 404,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // SECURITY: Validar ownership antes de permitir modificação
      if (subject.userId != userId) {
        return Response(
          403,
          body: jsonEncode(ApiResponse.error(
            message: 'Access denied',
            code: 403,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      var updatedSubject = subject;

      if (data.containsKey('name')) {
        // SECURITY: Sanitizar e validar input
        final sanitizedName = InputSanitizer.sanitizeAndValidate(
          data['name'] as String?,
          100,
          minLength: 1,
        );
        
        if (sanitizedName == null) {
          return Response(
            422,
            body: jsonEncode(ApiResponse.error(
              message: 'Nome inválido ou fora dos limites (1-100 caracteres)',
              code: 422,
            ).toJson((data) => data)),
            headers: {'Content-Type': 'application/json'},
          );
        }
        
        updatedSubject = updatedSubject.copyWith(name: sanitizedName);
      }

      if (data.containsKey('maxAbsences')) {
        updatedSubject = updatedSubject.copyWith(maxAbsences: data['maxAbsences'] as int);
      }

      if (data.containsKey('classSchedules')) {
        final classSchedules = <ClassScheduleModel>[];
        final schedulesData = data['classSchedules'] as List<dynamic>;
        for (final scheduleData in schedulesData) {
          try {
            classSchedules.add(
              ClassScheduleModel.fromJson(scheduleData as Map<String, dynamic>)
            );
          } catch (e) {
            // Ignorar horários inválidos mas continuar
          }
        }
        updatedSubject = updatedSubject.copyWith(classSchedules: classSchedules);
      }

      updatedSubject = updatedSubject.copyWith(updatedAt: DateTime.now());

      final success = await FirestoreService.updateSubject(updatedSubject);
      if (!success) {
        return Response(
          500,
          body: jsonEncode(ApiResponse.error(
            message: 'Failed to update subject',
            code: 500,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(ApiResponse.success(
          data: updatedSubject.toJson(),
          message: 'Subject updated successfully',
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(ApiResponse.error(
          message: 'Failed to update subject',
          code: 500,
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // DELETE /subjects/:id - Deletar matéria
  static Future<Response> deleteSubject(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(
          401,
          body: jsonEncode(ApiResponse.errorToJson(
            'Usuário não autenticado',
            401,
          )),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final subjectId = request.url.pathSegments.last;
      
      // SECURITY: Validar ownership antes de permitir deleção
      final subject = await FirestoreService.getSubject(subjectId);
      if (subject == null) {
        return Response.notFound(
          jsonEncode(ApiResponse.error(
            message: 'Subject not found',
            code: 404,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      if (subject.userId != userId) {
        return Response(
          403,
          body: jsonEncode(ApiResponse.error(
            message: 'Access denied',
            code: 403,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final success = await FirestoreService.deleteSubject(subjectId);
      if (!success) {
        return Response(
          500,
          body: jsonEncode(ApiResponse.error(
            message: 'Failed to delete subject',
            code: 500,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(ApiResponse.success(
          data: <String, dynamic>{},
          message: 'Subject deleted successfully',
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(ApiResponse.error(
          message: 'Failed to delete subject',
          code: 500,
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
