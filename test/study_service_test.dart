import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponto_study/database/database.dart';
import 'package:ponto_study/repositories/study_session_repository.dart';
import 'package:ponto_study/repositories/subject_repository.dart';
import 'package:ponto_study/services/study_service.dart';
import 'package:ponto_study/services/subject_service.dart';

/// ============================================================
/// ARQUIVO: test/study_service_test.dart
/// FUNÇÃO: Testa o registro de sessões de estudo: validação de
///         duração e os totais de "hoje" / "esta semana" usados
///         no dashboard.
///
/// COMO RODAR:
///   flutter test test/study_service_test.dart
/// ============================================================
void main() {
  late AppDatabase db;
  late SubjectService subjectService;
  late StudyService studyService;
  late int subjectId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    subjectService = SubjectService(SubjectRepository(db));
    studyService = StudyService(StudySessionRepository(db));

    await subjectService.createSubject(
      name: 'Python',
      targetMinutes: 600,
      color: const Color(0xFF2F6FED),
      icon: '🐍',
      priority: 1,
    );
    subjectId = (await subjectService.watchAllSubjects().first).first.id;
  });

  tearDown(() async {
    await db.close();
  });

  test('rejeita duração zero ou negativa', () async {
    final error = await studyService.registerSession(
      subjectId: subjectId,
      date: DateTime.now(),
      durationMinutes: 0,
    );
    expect(error, isNotNull);
  });

  test('registra sessão válida com sucesso', () async {
    final error = await studyService.registerSession(
      subjectId: subjectId,
      date: DateTime.now(),
      durationMinutes: 90,
      content: 'Listas e tuplas',
    );
    expect(error, isNull);

    final sessions = await studyService.watchAllSessions().first;
    expect(sessions.length, 1);
    expect(sessions.first.durationMinutes, 90);
    expect(sessions.first.content, 'Listas e tuplas');
  });

  test('total de hoje soma só sessões de hoje', () async {
    final hoje = DateTime.now();
    final ontem = hoje.subtract(const Duration(days: 1));

    await studyService.registerSession(
      subjectId: subjectId,
      date: hoje,
      durationMinutes: 60,
    );
    await studyService.registerSession(
      subjectId: subjectId,
      date: ontem,
      durationMinutes: 999, // não deve entrar na soma de "hoje"
    );

    final totalHoje = await studyService.watchTotalMinutesToday().first;
    expect(totalHoje, 60);
  });

  group('DurationUtils.parseToMinutes via StudyService', () {
    test('converte "1h30" corretamente', () {
      expect(studyService.parseCustomDuration('1h30'), 90);
    });

    test('retorna null para texto inválido', () {
      expect(studyService.parseCustomDuration('não é tempo'), null);
    });
  });
}
