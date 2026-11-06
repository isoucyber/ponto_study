import 'package:flutter_test/flutter_test.dart';
import 'package:ponto_study/domain/stats/study_stats.dart';

// Testes dos cálculos de produtividade (tempo por dia, semana, sequência, metas).
void main() {
  StudyFact f(DateTime d, int minutes, [int subject = 1]) =>
      StudyFact(startedAt: d, seconds: minutes * 60, subjectId: subject);

  test('início da semana é segunda-feira', () {
    // 6/11/2026 é sexta-feira.
    expect(startOfWeek(DateTime(2026, 11, 6, 15)), DateTime(2026, 11, 2));
    // Domingo pertence à semana iniciada na segunda anterior.
    expect(startOfWeek(DateTime(2026, 11, 8, 9)), DateTime(2026, 11, 2));
    // Segunda é o próprio início.
    expect(startOfWeek(DateTime(2026, 11, 2, 0, 1)), DateTime(2026, 11, 2));
  });

  test('soma por período respeita os limites', () {
    final facts = [
      f(DateTime(2026, 11, 1, 23, 59), 30), // domingo anterior
      f(DateTime(2026, 11, 2, 8), 60),
      f(DateTime(2026, 11, 8, 22), 45),
      f(DateTime(2026, 11, 9, 0, 0), 20), // próxima semana
    ];
    final start = DateTime(2026, 11, 2);
    expect(secondsBetween(facts, start, start.add(const Duration(days: 7))),
        105 * 60);
  });

  test('tempo por matéria', () {
    final facts = [
      f(DateTime(2026, 11, 3), 30, 1),
      f(DateTime(2026, 11, 3), 15, 2),
      f(DateTime(2026, 11, 4), 45, 1),
    ];
    final map = secondsPerSubject(
        facts, DateTime(2026, 11, 2), DateTime(2026, 11, 9));
    expect(map[1], 75 * 60);
    expect(map[2], 15 * 60);
  });

  group('sequência de estudos', () {
    final now = DateTime(2026, 11, 6, 10);

    test('conta dias seguidos até hoje', () {
      final facts = [
        f(DateTime(2026, 11, 4, 20), 30),
        f(DateTime(2026, 11, 5, 20), 30),
        f(DateTime(2026, 11, 6, 8), 30),
      ];
      expect(studyStreak(facts, now), 3);
    });

    test('se hoje ainda não estudou, vale a sequência até ontem', () {
      final facts = [
        f(DateTime(2026, 11, 4, 20), 30),
        f(DateTime(2026, 11, 5, 20), 30),
      ];
      expect(studyStreak(facts, now), 2);
    });

    test('um dia sem estudo quebra a sequência', () {
      final facts = [
        f(DateTime(2026, 11, 3, 20), 30),
        f(DateTime(2026, 11, 5, 20), 30),
      ];
      expect(studyStreak(facts, now), 1);
    });

    test('menos de 1 minuto não conta como dia estudado', () {
      final facts = [
        StudyFact(
            startedAt: DateTime(2026, 11, 6, 8), seconds: 30, subjectId: 1),
      ];
      expect(studyStreak(facts, now), 0);
    });
  });

  test('progresso de meta fica entre 0 e 1', () {
    expect(goalProgress(30 * 60, 60), 0.5);
    expect(goalProgress(120 * 60, 60), 1.0);
    expect(goalProgress(10, 0), 0);
  });

  test('média diária divide pelo número de dias do período', () {
    final now = DateTime(2026, 11, 6, 22);
    final facts = [
      f(DateTime(2026, 11, 6, 8), 70),
      f(DateTime(2026, 11, 1, 8), 70), // dentro de 7 dias (31/10 a 6/11)
      f(DateTime(2026, 10, 30, 8), 70), // fora
    ];
    expect(dailyAverage(facts, now, 7), (140 * 60) ~/ 7);
  });
}
