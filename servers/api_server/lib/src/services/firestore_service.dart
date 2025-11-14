import 'package:api_server/src/models/absence_model.dart';
import 'package:api_server/src/models/subject_model.dart';
import 'package:api_server/src/models/user_model.dart';
import 'package:api_server/src/services/firebase_service.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:logging/logging.dart';

class FirestoreService {
  static final Logger _logger = Logger('FirestoreService');
  
  // Collections names
  static const String _usersCollection = 'users';
  static const String _subjectsCollection = 'subjects';
  static const String _absencesCollection = 'absences';

  // Subject operations
  static Future<List<SubjectModel>> getUserSubjects(String userId, {String? sortBy}) async {
    try {
      final firestore = FirebaseService.firestore;
      final collection = firestore.collection(_subjectsCollection);
      final query = collection.where('userId', WhereFilter.equal, userId);
      final querySnapshot = await query.get();

      // OTIMIZAÇÃO: Buscar todas as faltas do usuário de uma vez
      final subjectIds = querySnapshot.docs.map((doc) => doc.id).toList();
      final absencesBySubject = await _getAbsencesBySubjects(subjectIds);

      final subjects = <SubjectModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          
          // Usar o cache de faltas já carregadas
          final currentAbsences = absencesBySubject[doc.id] ?? 0;
          data['currentAbsences'] = currentAbsences;
          
          subjects.add(SubjectModel.fromJson(data));
        } catch (e) {
          _logger.warning('Error parsing subject document ${doc.id}: $e');
        }
      }
      
      // Ordenar conforme solicitado
      _sortSubjects(subjects, sortBy);
      
      // Debug: Log da ordenação aplicada
      _logger.info('📊 GET /subjects retornando ${subjects.length} subjects com sortBy=$sortBy:');
      for (var i = 0; i < subjects.length; i++) {
        final s = subjects[i];
        _logger.info('  ${i + 1}. ${s.name} - ${s.currentAbsences}/${s.maxAbsences} (${s.absencePercentage.toStringAsFixed(1)}%) - ${s.status}');
      }
      
      return subjects;
    } catch (e) {
      _logger.severe('Error getting user subjects: $e');
      return [];
    }
  }

  /// Busca todas as faltas de múltiplas matérias de uma vez (otimizado)
  static Future<Map<String, int>> _getAbsencesBySubjects(List<String> subjectIds) async {
    if (subjectIds.isEmpty) return {};
    
    try {
      final firestore = FirebaseService.firestore;
      final absencesBySubject = <String, int>{};
      
      // Firestore whereIn tem limite de 10 itens, então fazemos em batches se necessário
      // Mas uma abordagem mais eficiente é buscar todas as absences do usuário
      // Como não temos userId aqui, vamos buscar todas as absences desses subjects
      
      // Para cada subject, fazer query (ainda mais rápido que antes pois processamos em paralelo)
      final futures = subjectIds.map((subjectId) async {
        final absencesQuery = firestore
            .collection(_absencesCollection)
            .where('subjectId', WhereFilter.equal, subjectId);
        
        final absencesSnapshot = await absencesQuery.get();
        
        var total = 0;
        for (final doc in absencesSnapshot.docs) {
          final data = doc.data();
          total += (data['quantity'] as int?) ?? 0;
        }
        
        return MapEntry(subjectId, total);
      });
      
      final results = await Future.wait(futures);
      
      for (final entry in results) {
        absencesBySubject[entry.key] = entry.value;
      }
      
      return absencesBySubject;
    } catch (e) {
      _logger.warning('Error getting absences by subjects: $e');
      return {};
    }
  }

  /// Calcula o total de faltas de uma matéria somando as quantities
  static Future<int> _calculateCurrentAbsences(String subjectId) async {
    try {
      final firestore = FirebaseService.firestore;
      final absencesQuery = firestore
          .collection(_absencesCollection)
          .where('subjectId', WhereFilter.equal, subjectId);
      
      final absencesSnapshot = await absencesQuery.get();
      
      var totalAbsences = 0;
      for (final doc in absencesSnapshot.docs) {
        final data = doc.data();
        totalAbsences += (data['quantity'] as int?) ?? 0;
      }
      
      return totalAbsences;
    } catch (e) {
      _logger.warning('Error calculating current absences for subject $subjectId: $e');
      return 0;
    }
  }

  /// Ordena a lista de matérias conforme o critério
  static void _sortSubjects(List<SubjectModel> subjects, String? sortBy) {
    _logger.info('🔍 _sortSubjects chamado com sortBy=$sortBy');
    
    switch (sortBy) {
      case 'proximity':
        _logger.info('📊 Aplicando ordenação por proximity');
        
        // Log ANTES da ordenação
        _logger.info('ANTES da ordenação:');
        for (var i = 0; i < subjects.length && i < 5; i++) {
          final s = subjects[i];
          _logger.info('  ${i + 1}. ${s.name} - ${s.absencePercentage.toStringAsFixed(1)}% - ${s.status}');
        }
        
        // Ordena por proximidade ao limite de faltas
        subjects.sort((a, b) {
          // Primeiro por status (danger > warning > safe)
          final statusOrder = {'danger': 0, 'warning': 1, 'safe': 2};
          final statusA = statusOrder[a.status] ?? 3;
          final statusB = statusOrder[b.status] ?? 3;
          final statusCompare = statusA.compareTo(statusB);
          if (statusCompare != 0) return statusCompare;
          
          // Depois por porcentagem (maior primeiro)
          final percentCompare = b.absencePercentage.compareTo(a.absencePercentage);
          if (percentCompare != 0) return percentCompare;
          
          // Por último por nome
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        
        // Log DEPOIS da ordenação
        _logger.info('DEPOIS da ordenação:');
        for (var i = 0; i < subjects.length && i < 5; i++) {
          final s = subjects[i];
          _logger.info('  ${i + 1}. ${s.name} - ${s.absencePercentage.toStringAsFixed(1)}% - ${s.status}');
        }
        break;
      case 'name':
        subjects.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'date':
        subjects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        // Por padrão, ordenar por data de criação (mais antigas primeiro)
        subjects.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  static Future<SubjectModel?> getSubject(String subjectId) async {
    try {
      final firestore = FirebaseService.firestore;
      final doc = await firestore
          .collection(_subjectsCollection)
          .doc(subjectId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = Map<String, dynamic>.from(doc.data() ?? {});
      data['id'] = doc.id;
      
      // Calcular currentAbsences
      final currentAbsences = await _calculateCurrentAbsences(subjectId);
      data['currentAbsences'] = currentAbsences;
      
      return SubjectModel.fromJson(data);
    } catch (e) {
      _logger.severe('Error getting subject: $e');
      return null;
    }
  }

  static Future<String?> createSubject(SubjectModel subject) async {
    try {
      final firestore = FirebaseService.firestore;
      final collection = firestore.collection(_subjectsCollection);
      
      // Converter para Map e remover campos não persistidos
      final data = subject.toJson();
      data.remove('id'); // ID será gerado automaticamente
      data.remove('currentAbsences'); // Calculado dinamicamente
      data.remove('absencePercentage'); // Calculado dinamicamente
      data.remove('remainingAbsences'); // Calculado dinamicamente
      data.remove('status'); // Calculado dinamicamente
      
      final docRef = await collection.add(data);
      
      _logger.info('Created subject: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.severe('Error creating subject: $e');
      return null;
    }
  }

  static Future<bool> updateSubject(SubjectModel subject) async {
    try {
      final firestore = FirebaseService.firestore;
      final data = subject.toJson();
      
      // Remover campos não persistidos
      data.remove('id'); // Não incluir o ID nos dados
      data.remove('currentAbsences'); // Calculado dinamicamente
      data.remove('absencePercentage'); // Calculado dinamicamente
      data.remove('remainingAbsences'); // Calculado dinamicamente
      data.remove('status'); // Calculado dinamicamente
      
      await firestore
          .collection(_subjectsCollection)
          .doc(subject.id)
          .update(data);
      
      _logger.info('Updated subject: ${subject.id}');
      return true;
    } catch (e) {
      _logger.severe('Error updating subject: $e');
      return false;
    }
  }

  static Future<bool> deleteSubject(String subjectId) async {
    try {
      final firestore = FirebaseService.firestore;
      
      // Primeiro, deletar todas as faltas desta matéria
      final absencesQuery = firestore
          .collection(_absencesCollection)
          .where('subjectId', WhereFilter.equal, subjectId);
      
      final absencesSnapshot = await absencesQuery.get();
      
      for (final doc in absencesSnapshot.docs) {
        await firestore.collection(_absencesCollection).doc(doc.id).delete();
      }
      
      // Depois deletar a matéria
      await firestore.collection(_subjectsCollection).doc(subjectId).delete();
      
      _logger.info('Deleted subject and related absences: $subjectId');
      return true;
    } catch (e) {
      _logger.severe('Error deleting subject: $e');
      return false;
    }
  }

  // Absence operations
  static Future<List<AbsenceModel>> getSubjectAbsences(String subjectId) async {
    try {
      final firestore = FirebaseService.firestore;
      final query = firestore
          .collection(_absencesCollection)
          .where('subjectId', WhereFilter.equal, subjectId);
      
      final querySnapshot = await query.get();

      final absences = <AbsenceModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          absences.add(AbsenceModel.fromJson(data));
        } catch (e) {
          _logger.warning('Error parsing absence document ${doc.id}: $e');
        }
      }
      
      // Ordenar por data
      absences.sort((a, b) => b.date.compareTo(a.date));
      
      return absences;
    } catch (e) {
      _logger.severe('Error getting subject absences: $e');
      return [];
    }
  }

  static Future<List<AbsenceModel>> getUserAbsences(String userId) async {
    try {
      final firestore = FirebaseService.firestore;
      final query = firestore
          .collection(_absencesCollection)
          .where('userId', WhereFilter.equal, userId);
      
      final querySnapshot = await query.get();

      final absences = <AbsenceModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          absences.add(AbsenceModel.fromJson(data));
        } catch (e) {
          _logger.warning('Error parsing absence document ${doc.id}: $e');
        }
      }
      
      // Ordenar por data
      absences.sort((a, b) => b.date.compareTo(a.date));
      
      return absences;
    } catch (e) {
      _logger.severe('Error getting user absences: $e');
      return [];
    }
  }

  static Future<AbsenceModel?> getAbsence(String absenceId) async {
    try {
      final firestore = FirebaseService.firestore;
      final doc = await firestore
          .collection(_absencesCollection)
          .doc(absenceId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = Map<String, dynamic>.from(doc.data() ?? {});
      data['id'] = doc.id;
      return AbsenceModel.fromJson(data);
    } catch (e) {
      _logger.severe('Error getting absence: $e');
      return null;
    }
  }

  static Future<String?> createAbsence(AbsenceModel absence) async {
    try {
      final firestore = FirebaseService.firestore;
      
      // Criar a falta
      final collection = firestore.collection(_absencesCollection);
      final data = absence.toJson();
      data.remove('id');
      
      final docRef = await collection.add(data);
      
      _logger.info('Created absence: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.severe('Error creating absence: $e');
      return null;
    }
  }

  static Future<bool> updateAbsence(AbsenceModel absence) async {
    try {
      final firestore = FirebaseService.firestore;
      final data = absence.toJson();
      data.remove('id');
      
      await firestore
          .collection(_absencesCollection)
          .doc(absence.id)
          .update(data);
      
      _logger.info('Updated absence: ${absence.id}');
      return true;
    } catch (e) {
      _logger.severe('Error updating absence: $e');
      return false;
    }
  }

  static Future<bool> deleteAbsence(String absenceId) async {
    try {
      final firestore = FirebaseService.firestore;
      
      // Deletar a falta
      await firestore.collection(_absencesCollection).doc(absenceId).delete();
      
      _logger.info('Deleted absence: $absenceId');
      return true;
    } catch (e) {
      _logger.severe('Error deleting absence: $e');
      return false;
    }
  }

  // User operations (se necessário)
  static Future<UserModel?> getUser(String userId) async {
    try {
      final firestore = FirebaseService.firestore;
      final doc = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = Map<String, dynamic>.from(doc.data() ?? {});
      data['id'] = doc.id;
      return UserModel.fromJson(data);
    } catch (e) {
      _logger.severe('Error getting user: $e');
      return null;
    }
  }

  static Future<String?> createUser(UserModel user) async {
    try {
      final firestore = FirebaseService.firestore;
      final data = user.toJson();
      data.remove('id');
      
      await firestore.collection(_usersCollection).doc(user.id).set(data);
      
      _logger.info('Created user: ${user.id}');
      return user.id;
    } catch (e) {
      _logger.severe('Error creating user: $e');
      return null;
    }
  }
}
