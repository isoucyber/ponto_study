import '../database/database.dart';

/// ============================================================
/// ARQUIVO: lib/repositories/study_session_repository.dart
/// FUNÇÃO: Ponte simples entre o AppDatabase e o StudyService para
///         tudo relacionado a SESSÕES DE ESTUDO (histórico).
///
/// POSSO ALTERAR:
///   - Adicionar novos métodos de consulta simples.
///
/// DEPENDÊNCIAS:
///   - database/database.dart
///   - services/study_service.dart
/// ============================================================
class StudySessionRepository {
  final AppDatabase _db;

  StudySessionRepository(this._db);

  Stream<List<StudySession>> watchAll() => _db.watchAllSessions();

  Stream<List<StudySession>> watchOfSubject(int subjectId) =>
      _db.watchSessionsOfSubject(subjectId);

  Future<int> create(StudySessionsCompanion session) =>
      _db.insertSession(session);

  Future<int> delete(int id) => _db.deleteSession(id);

  Stream<int> watchTotalMinutesToday() => _db.watchTotalMinutesToday();

  Stream<int> watchTotalMinutesThisWeek() => _db.watchTotalMinutesThisWeek();
}
