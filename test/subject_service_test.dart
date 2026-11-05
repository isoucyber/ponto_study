import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponto_study/database/database.dart';
import 'package:ponto_study/repositories/study_session_repository.dart';
import 'package:ponto_study/repositories/subject_repository.dart';
import 'package:ponto_study/services/study_service.dart';
import 'package:ponto_study/services/subject_service.dart';

/// ============================================================
/// ARQUIVO: test/subject_service_test.dart
/// FUNÇÃO: Testa as regras de negócio de MATÉRIAS: validação ao
///         criar/editar, cálculo de progresso, e o comportamento
///         de "excluir" (que na verdade arquiva, sem apagar o
///         histórico de sessões).
///
/// Cada teste cria um banco SQLite EM MEMÓRIA do zero (ninguém usa
/// o banco real do seu computador), então os testes não interferem
/// entre si nem com seus dados de verdade.
///
/// COMO RODAR:
///   flutter test test/subject_service_test.dart
/// ============================================================
void main() {
  late AppDatabase db;
  late SubjectService subjectService;
  late StudyService studyService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    subjectService = SubjectService(SubjectRepository(db));
    studyService = StudyService(StudySessionRepository(db));
  });

  tearDown(() async {
    await db.close();
  });

  group('criação de matéria', () {
    test('rejeita nome vazio', () async {
      final error = await subjectService.createSubject(
        name: '',
        targetMinutes: 60,
        color: const Color(0xFF2F6FED),
        icon: '📚',
        priority: 1,
      );
      expect(error, isNotNull);
    });

    test('rejeita meta zero ou negativa', () async {
      final error = await subjectService.createSubject(
        name: 'Python',
        targetMinutes: 0,
        color: const Color(0xFF2F6FED),
        icon: '🐍',
        priority: 1,
      );
      expect(error, isNotNull);
    });

    test('cria com sucesso quando os dados são válidos', () async {
      final error = await subjectService.createSubject(
        name: 'Python',
        targetMinutes: 600,
        color: const Color(0xFF2F6FED),
        icon: '🐍',
        priority: 1,
      );
      expect(error, isNull);

      final subjects = await subjectService.watchAllSubjects().first;
      expect(subjects.length, 1);
      expect(subjects.first.name, 'Python');
    });
  });

  group('cálculo de progresso', () {
    test('soma corretamente várias sessões registradas', () async {
      await subjectService.createSubject(
        name: 'Python',
        targetMinutes: 1200, // meta de 20h
        color: const Color(0xFF2F6FED),
        icon: '🐍',
        priority: 1,
      );
      final subject = (await subjectService.watchAllSubjects().first).first;

      // Sessões: 1h + 1h30 + 2h + 30min = 5h = 300 minutos
      for (final minutes in [60, 90, 120, 30]) {
        final error = await studyService.registerSession(
          subjectId: subject.id,
          date: DateTime(2026, 9, 1),
          durationMinutes: minutes,
        );
        expect(error, isNull);
      }

      final progressList = await subjectService.watchAllWithProgress().first;
      final progress = progressList.first;

      expect(progress.studiedMinutes, 300); // 5h
      expect(progress.remainingMinutes, 900); // 15h restantes
      expect(progress.progress, closeTo(0.25, 0.0001)); // 25%
      expect(progress.isCompleted, false);
    });
  });

  group('exclusão de matéria (arquivamento)', () {
    test('matéria some da lista ativa, mas sessões continuam no banco',
        () async {
      await subjectService.createSubject(
        name: 'Java',
        targetMinutes: 600,
        color: const Color(0xFF2E9E5B),
        icon: '☕',
        priority: 1,
      );
      final subject = (await subjectService.watchAllSubjects().first).first;

      await studyService.registerSession(
        subjectId: subject.id,
        date: DateTime(2026, 9, 1),
        durationMinutes: 45,
      );

      final error = await subjectService.deleteSubject(subject.id);
      expect(error, isNull);

      // A matéria não aparece mais na lista ativa...
      final activeSubjects = await subjectService.watchAllSubjects().first;
      expect(activeSubjects, isEmpty);

      // ...mas a sessão de estudo dela continua existindo no banco.
      final sessions =
          await studyService.watchSessionsOfSubject(subject.id).first;
      expect(sessions.length, 1);
      expect(sessions.first.durationMinutes, 45);
    });
  });
}
