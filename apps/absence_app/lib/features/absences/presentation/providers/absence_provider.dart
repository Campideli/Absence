import 'package:flutter/foundation.dart';
import '../../../../shared/models/absence_model.dart';
import '../../data/absence_repository.dart';

enum LoadingState {
  initial,   // Nunca foi carregado
  loading,   // Carregando dados
  loaded,    // Dados carregados com sucesso
  error,     // Erro ao carregar
}

class AbsenceProvider extends ChangeNotifier {
      /// Remove uma ausência localmente (sem backend)
      void removeAbsenceLocally(String id) {
        _absences.removeWhere((absence) => absence.id == id);
        _subjectAbsences.removeWhere((absence) => absence.id == id);
        notifyListeners();
      }
    /// Adiciona uma ausência localmente (sem backend)
    AbsenceModel addAbsenceLocally({
      required String subjectId,
      required DateTime date,
      int quantity = 1,
      String? reason,
    }) {
      final absence = AbsenceModel.create(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        userId: '',
        subjectId: subjectId,
        date: date,
        quantity: quantity,
        reason: reason?.trim(),
      );
      _absences.add(absence);
      if (subjectId == _lastLoadedSubjectId) {
        _subjectAbsences.add(absence);
      }
      _sortAbsences();
      _sortSubjectAbsences();
      notifyListeners();
      return absence;
    }
  final AbsenceRepository _repository = AbsenceRepositoryImpl();
  
  List<AbsenceModel> _absences = [];
  List<AbsenceModel> _subjectAbsences = [];
  String? _lastLoadedSubjectId; // Cache do último subject carregado
  final Set<String> _loadedSubjectIds = {};
  LoadingState _loadingState = LoadingState.initial;
  String? _error;

  // Getters
  List<AbsenceModel> get absences => List.unmodifiable(_absences);
  List<AbsenceModel> get subjectAbsences => List.unmodifiable(_subjectAbsences);
  LoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get isInitial => _loadingState == LoadingState.initial;
  bool get hasError => _loadingState == LoadingState.error;
  bool get isLoaded => _loadingState == LoadingState.loaded;
  String? get error => _error;

  /// Carrega todas as faltas do usuário
  Future<void> loadUserAbsences() async {
    _setLoadingState(LoadingState.loading);
    _clearError();
    
    try {
      _absences = await _repository.getUserAbsences();
      _sortAbsences();
      _setLoadingState(LoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
      _setLoadingState(LoadingState.error);
    }
  }

  /// Carrega faltas de uma matéria específica
  /// OTIMIZADO: Usa cache se já temos todas as faltas carregadas
  Future<void> loadSubjectAbsences(String subjectId, {bool forceReload = false}) async {
    // Sempre sincroniza com backend e descarta dados locais
    _setLoadingState(LoadingState.loading);
    _clearError();

    try {
      // Carrega do backend
      _subjectAbsences = await _repository.getSubjectAbsences(subjectId);
      _lastLoadedSubjectId = subjectId;

      // Remove todas as faltas locais (IDs começando com 'local_') e todas as faltas da matéria
      _absences.removeWhere((a) => a.subjectId == subjectId || a.id.startsWith('local_'));
      _absences.addAll(_subjectAbsences);
      _sortAbsences();
      _sortSubjectAbsences();
      // Marca como carregado, mesmo que não tenha faltas
      _loadedSubjectIds.add(subjectId);
      _setLoadingState(LoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
      _setLoadingState(LoadingState.error);
    }
  }

  /// Registra uma nova falta
  Future<bool> createAbsence({
    required String subjectId,
    required DateTime date,
    int quantity = 1,
    String? reason,
    Function(String subjectId, int quantity)? onAbsenceCreated,
  }) async {
    _clearError();
    
    try {
      // Validações locais
      if (reason != null && reason.trim().length > 500) {
        throw Exception('Motivo não pode exceder 500 caracteres');
      }

      if (quantity < 1 || quantity > 10) {
        throw Exception('Quantidade deve estar entre 1 e 10');
      }

      final absence = AbsenceModel.create(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // Será preenchido pelo backend
        subjectId: subjectId,
        date: date,
        quantity: quantity,
        reason: reason?.trim(),
      );

      final createdAbsence = await _repository.createAbsence(subjectId, absence);

      // Remove a falta local correspondente (por data, quantidade e id local)
      _absences.removeWhere((a) =>
        a.subjectId == subjectId &&
        a.date == date &&
        a.quantity == quantity &&
        a.id.startsWith('local_')
      );
      _subjectAbsences.removeWhere((a) =>
        a.subjectId == subjectId &&
        a.date == date &&
        a.quantity == quantity &&
        a.id.startsWith('local_')
      );

      // Adiciona às listas locais o dado real do backend
      _absences.add(createdAbsence);
      _sortAbsences();

      if (_subjectAbsences.isNotEmpty && _subjectAbsences.first.subjectId == subjectId) {
        _subjectAbsences.add(createdAbsence);
        _sortSubjectAbsences();
      }

      onAbsenceCreated?.call(subjectId, quantity);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Atualiza uma falta existente
  Future<bool> updateAbsence(
    AbsenceModel absence, {
    Function(String subjectId, int oldQuantity, int newQuantity)? onAbsenceUpdated,
  }) async {
    _clearError();
    
    try {
      // Validações locais
      if (absence.reason != null && absence.reason!.trim().length > 500) {
        throw Exception('Motivo não pode exceder 500 caracteres');
      }

      // Armazena quantidade antiga para callback
      final oldAbsence = _absences.firstWhere(
        (a) => a.id == absence.id,
        orElse: () => absence,
      );
      final oldQuantity = oldAbsence.quantity;

      // Atualização otimista: atualiza localmente antes do backend
      final index = _absences.indexWhere((a) => a.id == absence.id);
      if (index != -1) {
        _absences[index] = absence;
        _sortAbsences();
      }
      final subjectIndex = _subjectAbsences.indexWhere((a) => a.id == absence.id);
      if (subjectIndex != -1) {
        _subjectAbsences[subjectIndex] = absence;
        _sortSubjectAbsences();
      }
      onAbsenceUpdated?.call(absence.subjectId, oldQuantity, absence.quantity);

      // Chama backend em segundo plano
      Future.microtask(() async {
        try {
          final updatedAbsence = await _repository.updateAbsence(absence);
          // Atualiza localmente com o dado real do backend (caso tenha mudado algo)
          final idx = _absences.indexWhere((a) => a.id == updatedAbsence.id);
          if (idx != -1) {
            _absences[idx] = updatedAbsence;
            _sortAbsences();
          }
          final subjIdx = _subjectAbsences.indexWhere((a) => a.id == updatedAbsence.id);
          if (subjIdx != -1) {
            _subjectAbsences[subjIdx] = updatedAbsence;
            _sortSubjectAbsences();
          }
        } catch (e) {
          // Erros serão corrigidos na próxima sincronização
        }
      });

      // NÃO notifica listeners aqui - callback já atualiza SubjectProvider otimisticamente
      // notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Exclui uma falta
  Future<bool> deleteAbsence(
    String id, {
    Function(String subjectId, int quantity)? onAbsenceDeleted,
  }) async {
    _clearError();
    
    try {
      // Armazena dados da falta antes de deletar para callback
      final absence = _absences.firstWhere(
        (a) => a.id == id,
        orElse: () => _subjectAbsences.firstWhere((a) => a.id == id),
      );

      // Remoção otimista: remove localmente antes do backend
      _absences.removeWhere((a) => a.id == id);
      _subjectAbsences.removeWhere((a) => a.id == id);
      onAbsenceDeleted?.call(absence.subjectId, absence.quantity);

      // Chama backend em segundo plano
      Future.microtask(() async {
        try {
          await _repository.deleteAbsence(id);
        } catch (e) {
          // Erros serão corrigidos na próxima sincronização
        }
      });

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Obtém faltas de uma matéria LOCALMENTE (sem chamada ao backend)
  /// Útil para dialogs que só precisam visualizar dados já carregados
  List<AbsenceModel> getSubjectAbsencesLocally(String subjectId) {
    if (_absences.isEmpty) return [];
    return _absences.where((a) => a.subjectId == subjectId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Verifica se já temos faltas carregadas para uma matéria
  bool hasSubjectAbsencesLoaded(String subjectId) {
    return _loadedSubjectIds.contains(subjectId);
  }

  /// Limpa os dados
  void clear() {
    _absences.clear();
    _subjectAbsences.clear();
    _lastLoadedSubjectId = null;
    _loadedSubjectIds.clear();
    _error = null;
    _loadingState = LoadingState.initial;
    notifyListeners();
  }

  /// Ordena faltas por data (mais recentes primeiro)
  void _sortAbsences() {
    _absences.sort((a, b) => b.date.compareTo(a.date));
  }

  /// Ordena faltas da matéria por data (mais recentes primeiro)
  void _sortSubjectAbsences() {
    _subjectAbsences.sort((a, b) => b.date.compareTo(a.date));
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
