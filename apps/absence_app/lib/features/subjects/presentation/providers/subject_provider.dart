import 'package:flutter/foundation.dart';
import '../../../../shared/models/subject_model.dart';
import '../../../../shared/models/class_schedule_model.dart';
import '../../data/subject_repository.dart';

enum LoadingState {
  initial,   // Nunca foi carregado
  loading,   // Carregando dados
  loaded,    // Dados carregados com sucesso
  error,     // Erro ao carregar
}

class SubjectProvider extends ChangeNotifier {
  final SubjectRepository _repository = SubjectRepositoryImpl();
  
  List<SubjectModel> _subjects = [];
  LoadingState _loadingState = LoadingState.initial;
  String? _error;
  SubjectModel? _selectedSubject;
  String _currentSortBy = 'proximity'; // Armazena o tipo de ordenação atual

  // Getters
  List<SubjectModel> get subjects => List.unmodifiable(_subjects);
  LoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get isInitial => _loadingState == LoadingState.initial;
  bool get hasError => _loadingState == LoadingState.error;
  bool get isLoaded => _loadingState == LoadingState.loaded;
  String? get error => _error;
  SubjectModel? get selectedSubject => _selectedSubject;

  /// Retorna as matérias ordenadas por proximidade ao limite (maior porcentagem primeiro)
  /// Garante ordenação correta mesmo que tenha sido carregado com outro critério
  List<SubjectModel> get subjectsByProximity {
    // Cria cópia da lista e ordena por proximidade
    final sorted = List<SubjectModel>.from(_subjects);
    sorted.sort((a, b) {
      // Primeiro por status (danger > warning > safe)
      final statusOrder = {'danger': 0, 'warning': 1, 'safe': 2};
      final statusCompare = (statusOrder[a.status] ?? 3).compareTo(statusOrder[b.status] ?? 3);
      if (statusCompare != 0) return statusCompare;
      
      // Depois por porcentagem (maior primeiro)
      final percentCompare = b.absencePercentage.compareTo(a.absencePercentage);
      if (percentCompare != 0) return percentCompare;
      
      // Por último por nome
      return a.name.compareTo(b.name);
    });
    return List.unmodifiable(sorted);
  }

  /// Carrega todas as matérias do usuário
  Future<void> loadSubjects({String? sortBy}) async {
    _setLoadingState(LoadingState.loading);
    _clearError();
    
    try {
      _subjects = await _repository.getSubjects(sortBy: sortBy);
      _currentSortBy = sortBy ?? 'name'; // Armazena o tipo de ordenação
      _setLoadingState(LoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
      _setLoadingState(LoadingState.error);
    }
  }

  /// Carrega matérias ordenadas por proximidade ao limite
  Future<void> loadSubjectsByProximity() async {
    await loadSubjects(sortBy: 'proximity');
  }

  /// Reordena as matérias já carregadas por proximidade (sem fazer nova requisição)
  void sortByProximity() {
    _currentSortBy = 'proximity';
    _sortSubjects();
    notifyListeners();
  }

  /// Carrega uma matéria específica
  Future<void> loadSubject(String id) async {
    _setLoadingState(LoadingState.loading);
    _clearError();
    
    try {
      _selectedSubject = await _repository.getSubject(id);
      _setLoadingState(LoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
      _setLoadingState(LoadingState.error);
    }
  }

  /// Cria uma nova matéria
  Future<bool> createSubject({
    required String name,
    required int maxAbsences,
    List<ClassScheduleModel> classSchedules = const [],
  }) async {
    _clearError();
    
    try {
      // Validações locais
      if (name.trim().isEmpty) {
        throw Exception('Nome da matéria é obrigatório');
      }
      if (maxAbsences <= 0) {
        throw Exception('Número máximo de faltas deve ser maior que zero');
      }
      if (maxAbsences > 100) {
        throw Exception('Número máximo de faltas não pode exceder 100');
      }

      final subject = SubjectModel.create(
        id: '', // ID será ignorado e substituído pelo backend
        userId: '', // Será preenchido pelo backend
        name: name.trim(),
        maxAbsences: maxAbsences,
        classSchedules: classSchedules,
      );

      final createdSubject = await _repository.createSubject(subject);
      _subjects.add(createdSubject);
      _sortSubjects();
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Atualiza uma matéria existente
  Future<bool> updateSubject(SubjectModel subject) async {
    _clearError();
    
    try {
      // Validações locais
      if (subject.name.trim().isEmpty) {
        throw Exception('Nome da matéria é obrigatório');
      }
      if (subject.maxAbsences <= 0) {
        throw Exception('Número máximo de faltas deve ser maior que zero');
      }
      if (subject.maxAbsences > 100) {
        throw Exception('Número máximo de faltas não pode exceder 100');
      }
      if (subject.currentAbsences > subject.maxAbsences) {
        throw Exception(
          'Número atual de faltas não pode ser maior que o máximo permitido'
        );
      }

      final updatedSubject = await _repository.updateSubject(subject);
      final index = _subjects.indexWhere((s) => s.id == subject.id);
      
      if (index != -1) {
        _subjects[index] = updatedSubject;
        _sortSubjects();
        notifyListeners();
      }
      
      if (_selectedSubject?.id == subject.id) {
        _selectedSubject = updatedSubject;
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Exclui uma matéria
  Future<bool> deleteSubject(String id) async {
    _clearError();
    
    try {
      await _repository.deleteSubject(id);
      _subjects.removeWhere((subject) => subject.id == id);
      notifyListeners();
      
      if (_selectedSubject?.id == id) {
        _selectedSubject = null;
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Atualiza otimisticamente o contador de faltas de uma matéria
  /// Evita ter que recarregar todas as matérias do backend
  void incrementAbsenceCount(String subjectId, int quantity) {
    final index = _subjects.indexWhere((s) => s.id == subjectId);
    if (index != -1) {
      final subject = _subjects[index];
      final newCurrentAbsences = subject.currentAbsences + quantity;
      final newAbsencePercentage = subject.maxAbsences == 0 
          ? 0.0 
          : (newCurrentAbsences / subject.maxAbsences) * 100;
      final newRemainingAbsences = subject.maxAbsences - newCurrentAbsences;
      
      // Determinar novo status
      String newStatus = 'safe';
      if (newAbsencePercentage >= 80) {
        newStatus = 'danger';
      } else if (newAbsencePercentage >= 50) {
        newStatus = 'warning';
      }
      
      _subjects[index] = subject.copyWith(
        currentAbsences: newCurrentAbsences,
        absencePercentage: newAbsencePercentage,
        remainingAbsences: newRemainingAbsences,
        status: newStatus,
      );
      
      _sortSubjects();
      notifyListeners();
    }
  }

  /// Atualiza otimisticamente ao REMOVER faltas de uma matéria
  /// Evita ter que recarregar todas as matérias do backend
  void decrementAbsenceCount(String subjectId, int quantity) {
    final index = _subjects.indexWhere((s) => s.id == subjectId);
    if (index != -1) {
      final subject = _subjects[index];
      final newCurrentAbsences = (subject.currentAbsences - quantity).clamp(0, subject.maxAbsences);
      final newAbsencePercentage = subject.maxAbsences == 0 
          ? 0.0 
          : (newCurrentAbsences / subject.maxAbsences) * 100;
      final newRemainingAbsences = subject.maxAbsences - newCurrentAbsences;
      
      // Determinar novo status
      String newStatus = 'safe';
      if (newAbsencePercentage >= 80) {
        newStatus = 'danger';
      } else if (newAbsencePercentage >= 50) {
        newStatus = 'warning';
      }
      
      _subjects[index] = subject.copyWith(
        currentAbsences: newCurrentAbsences,
        absencePercentage: newAbsencePercentage,
        remainingAbsences: newRemainingAbsences,
        status: newStatus,
      );
      
      _sortSubjects();
      notifyListeners();
    }
  }

  /// Limpa os dados
  void clear() {
    _subjects.clear();
    _selectedSubject = null;
    _error = null;
    _loadingState = LoadingState.initial;
    notifyListeners();
  }

  /// Ordena as matérias de acordo com o critério atual
  void _sortSubjects() {
    if (_currentSortBy == 'proximity') {
      // Ordena por porcentagem de faltas (maior primeiro) - matérias em perigo no topo
      _subjects.sort((a, b) {
        // Primeiro por status (danger > warning > safe)
        final statusOrder = {'danger': 0, 'warning': 1, 'safe': 2};
        final statusCompare = (statusOrder[a.status] ?? 3).compareTo(statusOrder[b.status] ?? 3);
        if (statusCompare != 0) return statusCompare;
        
        // Depois por porcentagem (maior primeiro)
        final percentCompare = b.absencePercentage.compareTo(a.absencePercentage);
        if (percentCompare != 0) return percentCompare;
        
        // Por último por nome
        return a.name.compareTo(b.name);
      });
    } else {
      // Ordenação padrão por nome
      _subjects.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  void _setLoadingState(LoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
