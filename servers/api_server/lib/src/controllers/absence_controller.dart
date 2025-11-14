import 'dart:convert';

import 'package:api_server/src/middleware/auth_middleware.dart';
import 'package:api_server/src/models/absence_model.dart';
import 'package:api_server/src/models/api_response.dart';
import 'package:api_server/src/services/firestore_service.dart';
import 'package:api_server/src/services/input_sanitizer.dart';
import 'package:api_server/src/utils/date_validator.dart';
import 'package:shelf/shelf.dart';

class AbsenceController {

  // GET /subjects/:subjectId/absences - Listar faltas de uma matéria
  static Future<Response> getSubjectAbsences(Request request) async {
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
      
      final subjectId = request.url.pathSegments[request.url.pathSegments.length - 2];
      
      // SECURITY: Validar que o subject pertence ao usuário antes de listar absences
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
      
      final absences = await FirestoreService.getSubjectAbsences(subjectId);
      
      return Response.ok(
        jsonEncode(ApiResponse.success(
          data: absences.map((a) => a.toJson()).toList(),
          message: 'Absences retrieved successfully',
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(ApiResponse.error(
          message: 'Failed to retrieve absences',
          code: 500,
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // POST /subjects/:subjectId/absences - Criar nova falta
  static Future<Response> createAbsence(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(
          401,
          body: jsonEncode(ApiResponse.error(
            message: 'Usuário não autenticado',
            code: 401,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final subjectId = request.url.pathSegments[request.url.pathSegments.length - 2];
      
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // SECURITY: Validar e normalizar data para UTC
      final dateStr = data['date'] as String;
      String? validationError;
      final parsedDate = DateValidator.validateAndNormalize(
        dateStr,
        onError: () => validationError = 'Invalid date format or out of allowed range',
      );
      
      if (parsedDate == null) {
        return Response(
          422,
          body: jsonEncode(ApiResponse.error(
            message: validationError ?? 'Invalid date',
            code: 422,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // SECURITY: Validar quantity
      var quantity = 1;
      if (data['quantity'] != null) {
        quantity = data['quantity'] as int;
        if (quantity < 1 || quantity > 10) {
          return Response(
            422,
            body: jsonEncode(ApiResponse.error(
              message: 'Quantity must be between 1 and 10',
              code: 422,
            ).toJson((data) => data)),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      // SECURITY: Sanitizar e validar reason (opcional)
      String? sanitizedReason;
      if (data['reason'] != null) {
        sanitizedReason = InputSanitizer.sanitizeAndValidate(
          data['reason'] as String?,
          500,
          minLength: 0,
          required: false,
        );
        
        // Se reason foi fornecida mas é inválida após sanitização
        if (data['reason'] != null && sanitizedReason == null) {
          return Response(
            422,
            body: jsonEncode(ApiResponse.error(
              message: 'Razão inválida ou muito longa (máximo 500 caracteres)',
              code: 422,
            ).toJson((data) => data)),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      final absence = AbsenceModel.create(
        id: '', // ID será gerado pelo Firestore
        userId: userId,
        subjectId: subjectId,
        date: parsedDate,
        quantity: quantity,
        reason: sanitizedReason,
      );

      final absenceId = await FirestoreService.createAbsence(absence);
      if (absenceId == null) {
        return Response(
          500,
          body: jsonEncode(ApiResponse.error(
            message: 'Failed to create absence',
            code: 500,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Retornar a falta com o ID correto do Firestore
      // Nota: currentAbsences agora é calculado dinamicamente no GET /subjects
      final createdAbsence = absence.copyWith(id: absenceId);

      return Response(
        201,
        body: jsonEncode(ApiResponse.success(
          data: createdAbsence.toJson(),
          message: 'Absence created successfully',
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(ApiResponse.error(
          message: 'Failed to create absence',
          code: 500,
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // GET /absences/:id - Obter falta específica
  static Future<Response> getAbsence(Request request) async {
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
      
      final absenceId = request.url.pathSegments.last;
      
      final absence = await FirestoreService.getAbsence(absenceId);
      if (absence == null) {
        return Response.notFound(
          jsonEncode(ApiResponse.error(
            message: 'Absence not found',
            code: 404,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // SECURITY: Validar ownership antes de retornar dados
      if (absence.userId != userId) {
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
          data: absence.toJson(),
          message: 'Absence retrieved successfully',
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(ApiResponse.error(
          message: 'Failed to retrieve absence',
          code: 500,
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // PUT /absences/:id - Atualizar falta
  static Future<Response> updateAbsence(Request request) async {
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
      
      final absenceId = request.url.pathSegments.last;
      
      final absence = await FirestoreService.getAbsence(absenceId);
      if (absence == null) {
        return Response.notFound(
          jsonEncode(ApiResponse.error(
            message: 'Absence not found',
            code: 404,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // SECURITY: Validar ownership antes de permitir modificação
      if (absence.userId != userId) {
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

      var updatedAbsence = absence;

      if (data.containsKey('date')) {
        // SECURITY: Validar e normalizar data para UTC ao atualizar
        final dateStr = data['date'] as String;
        String? validationError;
        final parsedDate = DateValidator.validateAndNormalize(
          dateStr,
          onError: () => validationError = 'Invalid date format or out of allowed range',
        );
        
        if (parsedDate == null) {
          return Response(
            422,
            body: jsonEncode(ApiResponse.error(
              message: validationError ?? 'Invalid date',
              code: 422,
            ).toJson((data) => data)),
            headers: {'Content-Type': 'application/json'},
          );
        }
        
        updatedAbsence = updatedAbsence.copyWith(date: parsedDate);
      }

      if (data.containsKey('reason')) {
        // SECURITY: Sanitizar e validar reason
        final sanitizedReason = InputSanitizer.sanitizeAndValidate(
          data['reason'] as String?,
          500,
          minLength: 0,
          required: false,
        );
        
        if (data['reason'] != null && sanitizedReason == null) {
          return Response(
            422,
            body: jsonEncode(ApiResponse.error(
              message: 'Razão inválida ou muito longa (máximo 500 caracteres)',
              code: 422,
            ).toJson((data) => data)),
            headers: {'Content-Type': 'application/json'},
          );
        }
        
        updatedAbsence = updatedAbsence.copyWith(reason: sanitizedReason);
      }

      // SECURITY: Validar e atualizar quantity se fornecido
      if (data.containsKey('quantity')) {
        final newQuantity = data['quantity'] as int;
        if (newQuantity < 1 || newQuantity > 10) {
          return Response(
            422,
            body: jsonEncode(ApiResponse.error(
              message: 'Quantity must be between 1 and 10',
              code: 422,
            ).toJson((data) => data)),
            headers: {'Content-Type': 'application/json'},
          );
        }
        
        // Nota: currentAbsences agora é calculado dinamicamente no GET /subjects
        updatedAbsence = updatedAbsence.copyWith(quantity: newQuantity);
      }

      updatedAbsence = updatedAbsence.copyWith(updatedAt: DateTime.now());

      final success = await FirestoreService.updateAbsence(updatedAbsence);
      if (!success) {
        return Response(
          500,
          body: jsonEncode(ApiResponse.error(
            message: 'Failed to update absence',
            code: 500,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(ApiResponse.success(
          data: updatedAbsence.toJson(),
          message: 'Absence updated successfully',
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(ApiResponse.error(
          message: 'Failed to update absence',
          code: 500,
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // DELETE /absences/:id - Deletar falta
  static Future<Response> deleteAbsence(Request request) async {
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
      
      final absenceId = request.url.pathSegments.last;
      
      // SECURITY: Validar ownership antes de permitir deleção
      final absence = await FirestoreService.getAbsence(absenceId);
      if (absence == null) {
        return Response.notFound(
          jsonEncode(ApiResponse.error(
            message: 'Absence not found',
            code: 404,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      if (absence.userId != userId) {
        return Response(
          403,
          body: jsonEncode(ApiResponse.error(
            message: 'Access denied',
            code: 403,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final success = await FirestoreService.deleteAbsence(absenceId);
      if (!success) {
        return Response(
          500,
          body: jsonEncode(ApiResponse.error(
            message: 'Failed to delete absence',
            code: 500,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Nota: currentAbsences agora é calculado dinamicamente no GET /subjects

      return Response.ok(
        jsonEncode(ApiResponse.success(
          data: <String, dynamic>{},
          message: 'Absence deleted successfully',
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(ApiResponse.error(
          message: 'Failed to delete absence',
          code: 500,
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // GET /absences - Listar todas as faltas do usuário
  static Future<Response> getUserAbsences(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(
          401,
          body: jsonEncode(ApiResponse.error(
            message: 'Usuário não autenticado',
            code: 401,
          ).toJson((data) => data)),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final absences = await FirestoreService.getUserAbsences(userId);
      
      return Response.ok(
        jsonEncode(ApiResponse.success(
          data: absences.map((a) => a.toJson()).toList(),
          message: 'User absences retrieved successfully',
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(ApiResponse.error(
          message: 'Failed to retrieve user absences',
          code: 500,
        ).toJson((data) => data)),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
