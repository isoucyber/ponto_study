import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../../domain/stats/study_stats.dart';

// ============================================================
// ARQUIVO: lib/features/planning/plan_repository.dart
// FUNÇÃO: Atividades planejadas por dia. Marcar como concluída NÃO
//         cria horas estudadas — horas só vêm de sessões reais.
// ============================================================

class PlanRepository {
  final AppDatabase db;
  PlanRepository(this.db);

  /// Atividades com dia entre [from] (inclusive) e [to] (exclusive).
  Stream<List<PlanItem>> watchRange(DateTime from, DateTime to) =>
      (db.select(db.planItems)
            ..where((p) =>
                p.day.isBiggerOrEqualValue(from) & p.day.isSmallerThanValue(to))
            ..orderBy([
              (p) => OrderingTerm.asc(p.day),
              (p) => OrderingTerm.asc(p.startTime),
              (p) => OrderingTerm.desc(p.priority),
            ]))
          .watch();

  Future<int> create({
    required DateTime day,
    required int subjectId,
    int? nodeId,
    String? startTime,
    required int durationMinutes,
    int priority = 1,
    String notes = '',
  }) {
    return db.into(db.planItems).insert(PlanItemsCompanion(
          day: Value(dayOf(day)),
          subjectId: Value(subjectId),
          nodeId: Value(nodeId),
          startTime: Value(startTime),
          durationMinutes: Value(durationMinutes),
          priority: Value(priority),
          notes: Value(notes.trim()),
        ));
  }

  Future<void> update({
    required int id,
    required DateTime day,
    required int subjectId,
    int? nodeId,
    String? startTime,
    required int durationMinutes,
    required int priority,
    required String notes,
  }) async {
    await (db.update(db.planItems)..where((p) => p.id.equals(id)))
        .write(PlanItemsCompanion(
      day: Value(dayOf(day)),
      subjectId: Value(subjectId),
      nodeId: Value(nodeId),
      startTime: Value(startTime),
      durationMinutes: Value(durationMinutes),
      priority: Value(priority),
      notes: Value(notes.trim()),
    ));
  }

  Future<void> setDone(int id, bool done) async {
    await (db.update(db.planItems)..where((p) => p.id.equals(id)))
        .write(PlanItemsCompanion(done: Value(done)));
  }

  Future<void> delete(int id) async {
    await (db.delete(db.planItems)..where((p) => p.id.equals(id))).go();
  }

  /// Copia as atividades da semana de [fromWeek] para a semana seguinte.
  Future<int> copyWeekToNext(DateTime fromWeek) async {
    final start = startOfWeek(fromWeek);
    final end = start.add(const Duration(days: 7));
    final items = await (db.select(db.planItems)
          ..where((p) =>
              p.day.isBiggerOrEqualValue(start) & p.day.isSmallerThanValue(end)))
        .get();
    await db.transaction(() async {
      for (final i in items) {
        await create(
          day: DateTime(i.day.year, i.day.month, i.day.day + 7),
          subjectId: i.subjectId,
          nodeId: i.nodeId,
          startTime: i.startTime,
          durationMinutes: i.durationMinutes,
          priority: i.priority,
          notes: i.notes,
        );
      }
    });
    return items.length;
  }
}
