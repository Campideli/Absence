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
  final AbsenceRepository _repository = AbsenceRepositoryImpl();
  
  List<AbsenceModel> _absences = [];
  List<AbsenceModel> _subjectAbsences = [];
  String? _lastLoadedSubjectId; // Cache do último subject carregado
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
    // Se já temos todas as faltas do usuário, filtra localmente
    if (!forceReload && _absences.isNotEmpty && _lastLoadedSubjectId == subjectId) {
      // Cache hit! Apenas filtra os dados que já temos
      _subjectAbsences = _absences.where((a) => a.subjectId == subjectId).toList();
      _sortSubjectAbsences();
      return; // Retorna instantaneamente sem chamada ao backend!
    }
    
    // Se temos todas as faltas mas é um subject diferente, filtra localmente
    if (!forceReload && _absences.isNotEmpty) {
      _subjectAbsences = _absences.where((a) => a.subjectId == subjectId).toList();
      _lastLoadedSubjectId = subjectId;
      _sortSubjectAbsences();
      notifyListeners();
      return; // Retorna instantaneamente!
    }
    
    // Caso contrário, carrega do backend
    _setLoadingState(LoadingState.loading);
    _clearError();
    
    try {
      _subjectAbsences = await _repository.getSubjectAbsences(subjectId);
      _lastLoadedSubjectId = subjectId;
      _sortSubjectAbsences();
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
      
      // Adiciona às listas locais
      _absences.add(createdAbsence);
      _sortAbsences();
      
      // Se estamos visualizando faltas desta matéria, adiciona também
      if (_subjectAbsences.isNotEmpty && 
          _subjectAbsences.first.subjectId == subjectId) {
        _subjectAbsences.add(createdAbsence);
        _sortSubjectAbsences();
      }
      
      // Notifica callback para atualizar o SubjectProvider otimisticamente
      onAbsenceCreated?.call(subjectId, quantity);
      
      // NÃO notifica listeners aqui - callback já atualiza SubjectProvider otimisticamente
      // notifyListeners();
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

      final updatedAbsence = await _repository.updateAbsence(absence);
      
      // Atualiza na lista geral
      final index = _absences.indexWhere((a) => a.id == absence.id);
      if (index != -1) {
        _absences[index] = updatedAbsence;
        _sortAbsences();
      }
      
      // Atualiza na lista da matéria se aplicável
      final subjectIndex = _subjectAbsences.indexWhere((a) => a.id == absence.id);
      if (subjectIndex != -1) {
        _subjectAbsences[subjectIndex] = updatedAbsence;
        _sortSubjectAbsences();
      }
      
      // Notifica callback para atualizar o SubjectProvider otimisticamente
      onAbsenceUpdated?.call(absence.subjectId, oldQuantity, updatedAbsence.quantity);
      
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
      
      await _repository.deleteAbsence(id);
      
      // Remove das listas locais
      _absences.removeWhere((absence) => absence.id == id);
      _subjectAbsences.removeWhere((absence) => absence.id == id);
      
      // Notifica callback para atualizar o SubjectProvider otimisticamente
      onAbsenceDeleted?.call(absence.subjectId, absence.quantity);
      
      // NÃO notifica listeners aqui - callback já atualiza SubjectProvider otimisticamente
      // notifyListeners(); 
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
    return _absences.any((a) => a.subjectId == subjectId);
  }

  /// Limpa os dados
  void clear() {
    _absences.clear();
    _subjectAbsences.clear();
    _lastLoadedSubjectId = null;
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
