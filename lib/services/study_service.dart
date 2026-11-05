import 'package:drift/drift.dart';

import '../database/database.dart';
import '../repositories/study_session_repository.dart';
import '../utils/duration_utils.dart';

/// ============================================================
/// ARQUIVO: lib/services/study_service.dart
/// FUNÇÃO: Regras de negócio relacionadas a REGISTRO DE ESTUDO
///         (criar sessão, validar duração, totais do dashboard).
///
/// POSSO ALTERAR:
///   - Validações (ex: exigir duração mínima de 1 minuto).
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - A conversão de tempo continua centralizada em
///     utils/duration_utils.dart. Não duplique essa lógica aqui.
///
/// DEPENDÊNCIAS:
///   - repositories/study_session_repository.dart
///   - screens/study/register_study_screen.dart
///   - screens/home/home_screen.dart (totais de hoje/semana)
/// ============================================================
class StudyService {
  final StudySessionRepository _repository;

  StudyService(this._repository);

  Stream<List<StudySession>> watchAllSessions() => _repository.watchAll();

  Stream<List<StudySession>> watchSessionsOfSubject(int subjectId) =>
      _repository.watchOfSubject(subjectId);

  Stream<int> watchTotalMinutesToday() => _repository.watchTotalMinutesToday();

  Stream<int> watchTotalMinutesThisWeek() =>
      _repository.watchTotalMinutesThisWeek();

  /// Registra uma nova sessão de estudo.
  /// Retorna uma mensagem de erro (String) se algo for inválido,
  /// ou null se deu tudo certo.
  Future<String?> registerSession({
    required int subjectId,
    required DateTime date,
    required int durationMinutes,
    String content = '',
    String notes = '',
  }) async {
    if (durationMinutes <= 0) {
      return 'A duração precisa ser maior que zero.';
    }

    try {
      await _repository.create(StudySessionsCompanion.insert(
        subjectId: subjectId,
        date: date,
        durationMinutes: durationMinutes,
        content: Value(content),
        notes: Value(notes),
      ));
      return null;
    } on DatabaseFailure catch (e) {
      return e.message;
    }
  }

  /// Exclui uma sessão. Retorna uma mensagem de erro em português se
  /// o banco recusar, ou null se deu certo.
  Future<String?> deleteSession(int id) async {
    try {
      await _repository.delete(id);
      return null;
    } on DatabaseFailure catch (e) {
      return e.message;
    }
  }

  /// Facilita registrar usando texto livre (ex: "1h30") vindo do
  /// campo "tempo personalizado" da tela de registro.
  int? parseCustomDuration(String text) => DurationUtils.parseToMinutes(text);
}
