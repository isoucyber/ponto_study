import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../../domain/stats/study_stats.dart';
import '../../domain/timer/timer_math.dart';

// ============================================================
// ARQUIVO: lib/features/timer/session_repository.dart
// FUNÇÃO: Gravação das sessões de estudo: cronômetro (iniciar, pausar,
//         retomar, finalizar, cancelar) e registro manual.
//
// COMO O CRONÔMETRO É CONFIÁVEL:
//   Cada ação grava IMEDIATAMENTE no banco o horário em que aconteceu.
//   Uma sessão "em andamento" (status running/paused) sobrevive a
//   minimizar, fechar o app ou reiniciar o aparelho. Ao reabrir, o app
//   encontra a sessão e continua de onde parou.
// ============================================================

class SessionRepository {
  final AppDatabase db;
  SessionRepository(this.db);

  static const activeStatuses = ['running', 'paused'];

  /// Sessão de cronômetro em andamento (no máximo uma).
  Stream<StudySession?> watchActive() => (db.select(db.studySessions)
        ..where((s) => s.status.isIn(activeStatuses))
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
        ..limit(1))
      .watchSingleOrNull();

  Future<StudySession?> active() => (db.select(db.studySessions)
        ..where((s) => s.status.isIn(activeStatuses))
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
        ..limit(1))
      .getSingleOrNull();

  Stream<List<SessionPause>> watchPauses(int sessionId) =>
      (db.select(db.sessionPauses)
            ..where((p) => p.sessionId.equals(sessionId))
            ..orderBy([(p) => OrderingTerm.asc(p.startedAt)]))
          .watch();

  Future<List<SessionPause>> pausesOf(int sessionId) =>
      (db.select(db.sessionPauses)
            ..where((p) => p.sessionId.equals(sessionId)))
          .get();

  /// Sessões concluídas, mais recentes primeiro.
  Stream<List<StudySession>> watchFinished() => (db.select(db.studySessions)
        ..where((s) => s.status.equals('finished'))
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
      .watch();

  /// Sessões concluídas convertidas em "fatos" para os cálculos de estatística.
  Stream<List<StudyFact>> watchFacts() => watchFinished().map((list) => [
        for (final s in list)
          StudyFact(
            startedAt: s.startedAt,
            seconds: s.studySeconds,
            subjectId: s.subjectId,
            nodeId: s.nodeId,
          ),
      ]);

  /// Inicia o cronômetro. Lança erro se já houver uma sessão ativa.
  Future<int> start({
    required int subjectId,
    int? nodeId,
    int? plannedSeconds,
    DateTime? now,
  }) {
    return db.transaction(() async {
      if (await active() != null) {
        throw StateError('Já existe uma sessão em andamento.');
      }
      return db.into(db.studySessions).insert(StudySessionsCompanion(
            subjectId: Value(subjectId),
            nodeId: Value(nodeId),
            startedAt: Value(now ?? DateTime.now()),
            plannedSeconds: Value(plannedSeconds),
            status: const Value('running'),
            source: const Value('timer'),
          ));
    });
  }

  Future<void> pause(int sessionId, {DateTime? now}) {
    return db.transaction(() async {
      final open = await _openPause(sessionId);
      if (open != null) return; // já está pausada
      await db.into(db.sessionPauses).insert(SessionPausesCompanion(
            sessionId: Value(sessionId),
            startedAt: Value(now ?? DateTime.now()),
          ));
      await _setStatus(sessionId, 'paused');
    });
  }

  Future<void> resume(int sessionId, {DateTime? now}) {
    return db.transaction(() async {
      final open = await _openPause(sessionId);
      if (open != null) {
        await (db.update(db.sessionPauses)..where((p) => p.id.equals(open.id)))
            .write(SessionPausesCompanion(endedAt: Value(now ?? DateTime.now())));
      }
      await _setStatus(sessionId, 'running');
    });
  }

  /// Calcula o tempo estudado de uma sessão ativa até [now].
  Future<int> liveStudySeconds(StudySession s, {DateTime? now}) async {
    final pauses = await pausesOf(s.id);
    return studiedSeconds(
      start: s.startedAt,
      pauses: [for (final p in pauses) PauseInterval(p.startedAt, p.endedAt)],
      now: now ?? DateTime.now(),
    );
  }

  /// Finaliza a sessão. [adjustedStudySeconds] permite corrigir o tempo
  /// (ex.: o app ficou aberto depois que você parou de estudar).
  Future<void> finish(
    int sessionId, {
    int? adjustedStudySeconds,
    String notes = '',
    DateTime? now,
  }) {
    final end = now ?? DateTime.now();
    return db.transaction(() async {
      final open = await _openPause(sessionId);
      if (open != null) {
        await (db.update(db.sessionPauses)..where((p) => p.id.equals(open.id)))
            .write(SessionPausesCompanion(endedAt: Value(end)));
      }
      final session = await (db.select(db.studySessions)
            ..where((s) => s.id.equals(sessionId)))
          .getSingle();
      final pauses = await pausesOf(sessionId);
      final intervals = [
        for (final p in pauses) PauseInterval(p.startedAt, p.endedAt)
      ];
      final paused = pausedSeconds(intervals, end);
      final studied =
          studiedSeconds(start: session.startedAt, pauses: intervals, now: end);
      await (db.update(db.studySessions)
            ..where((s) => s.id.equals(sessionId)))
          .write(StudySessionsCompanion(
        endedAt: Value(end),
        pausedSeconds: Value(paused),
        studySeconds: Value(adjustedStudySeconds ?? studied),
        status: const Value('finished'),
        notes: Value(notes.trim()),
      ));
    });
  }

  /// Cancela a sessão ativa: nada é registrado.
  Future<void> cancel(int sessionId) {
    return db.transaction(() async {
      await (db.delete(db.sessionPauses)
            ..where((p) => p.sessionId.equals(sessionId)))
          .go();
      await (db.delete(db.studySessions)..where((s) => s.id.equals(sessionId)))
          .go();
    });
  }

  /// Registro manual de um estudo já feito.
  Future<int> addManual({
    required int subjectId,
    int? nodeId,
    required DateTime startedAt,
    required int minutes,
    String notes = '',
  }) {
    return db.into(db.studySessions).insert(StudySessionsCompanion(
          subjectId: Value(subjectId),
          nodeId: Value(nodeId),
          startedAt: Value(startedAt),
          endedAt: Value(startedAt.add(Duration(minutes: minutes))),
          studySeconds: Value(minutes * 60),
          status: const Value('finished'),
          source: const Value('manual'),
          notes: Value(notes.trim()),
        ));
  }

  /// Edita uma sessão concluída (matéria, assunto, tempo e observação).
  Future<void> updateFinished({
    required int id,
    required int subjectId,
    int? nodeId,
    required int studySeconds,
    required String notes,
  }) async {
    await (db.update(db.studySessions)..where((s) => s.id.equals(id)))
        .write(StudySessionsCompanion(
      subjectId: Value(subjectId),
      nodeId: Value(nodeId),
      studySeconds: Value(studySeconds),
      notes: Value(notes.trim()),
    ));
  }

  Future<void> delete(int id) => cancel(id);

  Future<SessionPause?> _openPause(int sessionId) =>
      (db.select(db.sessionPauses)
            ..where((p) => p.sessionId.equals(sessionId) & p.endedAt.isNull())
            ..limit(1))
          .getSingleOrNull();

  Future<void> _setStatus(int sessionId, String status) async {
    await (db.update(db.studySessions)..where((s) => s.id.equals(sessionId)))
        .write(StudySessionsCompanion(status: Value(status)));
  }
}
