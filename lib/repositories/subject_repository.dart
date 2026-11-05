import '../database/database.dart';

/// ============================================================
/// ARQUIVO: lib/repositories/subject_repository.dart
/// FUNÇÃO: Ponte simples entre o AppDatabase e o SubjectService.
///         Só repassa CRUD puro, SEM regra de negócio (regra de
///         negócio fica no service).
///
/// POSSO ALTERAR:
///   - Adicionar novos métodos de consulta simples.
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - Não deveria haver cálculos aqui (ex: "progresso em %").
///     Isso é responsabilidade do SubjectService.
///
/// DEPENDÊNCIAS:
///   - database/database.dart (de onde vêm os dados)
///   - services/subject_service.dart (quem usa este repositório)
/// ============================================================
class SubjectRepository {
  final AppDatabase _db;

  SubjectRepository(this._db);

  Stream<List<Subject>> watchAll() => _db.watchAllSubjects();

  Future<int> create(SubjectsCompanion subject) => _db.insertSubject(subject);

  Future<bool> update(Subject subject) => _db.updateSubject(subject);

  /// "Excluir" = arquivar. Veja a explicação em database.dart /
  /// tables.dart (coluna "archived") para o motivo de não ser um
  /// DELETE de verdade.
  Future<int> archive(int id) => _db.archiveSubject(id);

  Future<({int sessionCount, int totalMinutes})> getUsage(int subjectId) =>
      _db.getSubjectUsage(subjectId);

  Stream<int> watchTotalMinutes(int subjectId) =>
      _db.watchTotalMinutesForSubject(subjectId);
}
