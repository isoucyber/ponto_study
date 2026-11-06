// ============================================================
// ARQUIVO: lib/domain/stats/study_stats.dart
// FUNÇÃO: Cálculos de produtividade a partir das sessões reais:
//         tempo por dia, por semana, por matéria, sequência de dias
//         e progresso de metas. Nada disso é salvo no banco: é sempre
//         recalculado a partir dos registros, então nunca fica
//         desatualizado.
// ============================================================

/// Um "fato" mínimo de estudo: quando começou, quanto durou, de qual matéria.
class StudyFact {
  final DateTime startedAt;
  final int seconds;
  final int subjectId;
  final int? nodeId;

  const StudyFact({
    required this.startedAt,
    required this.seconds,
    required this.subjectId,
    this.nodeId,
  });
}

/// Meia-noite do dia de [d] (horário local).
DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Segunda-feira (meia-noite) da semana de [d].
DateTime startOfWeek(DateTime d) {
  final day = dayOf(d);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// Soma de segundos de estudo com início em [from] <= data < [to].
int secondsBetween(Iterable<StudyFact> facts, DateTime from, DateTime to) {
  var total = 0;
  for (final f in facts) {
    if (!f.startedAt.isBefore(from) && f.startedAt.isBefore(to)) {
      total += f.seconds;
    }
  }
  return total;
}

/// Segundos estudados em cada dia.
Map<DateTime, int> secondsPerDay(Iterable<StudyFact> facts) {
  final map = <DateTime, int>{};
  for (final f in facts) {
    final d = dayOf(f.startedAt);
    map[d] = (map[d] ?? 0) + f.seconds;
  }
  return map;
}

/// Segundos estudados por matéria no período [from, to).
Map<int, int> secondsPerSubject(
    Iterable<StudyFact> facts, DateTime from, DateTime to) {
  final map = <int, int>{};
  for (final f in facts) {
    if (!f.startedAt.isBefore(from) && f.startedAt.isBefore(to)) {
      map[f.subjectId] = (map[f.subjectId] ?? 0) + f.seconds;
    }
  }
  return map;
}

/// Sequência de dias seguidos com pelo menos [minSeconds] de estudo.
///
/// Se hoje ainda não houve estudo, a sequência que terminou ontem
/// continua valendo (o dia ainda não acabou).
int studyStreak(Iterable<StudyFact> facts, DateTime now,
    {int minSeconds = 60}) {
  final perDay = secondsPerDay(facts);
  bool studied(DateTime d) => (perDay[d] ?? 0) >= minSeconds;

  var day = dayOf(now);
  if (!studied(day)) {
    day = day.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (studied(day)) {
    streak++;
    // Usar DateTime(y, m, d - 1) evita erros com horário de verão.
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}

/// Progresso de uma meta entre 0.0 e 1.0 (meta 0 = sem meta = 0).
double goalProgress(int doneSeconds, int goalMinutes) {
  if (goalMinutes <= 0) return 0;
  final p = doneSeconds / (goalMinutes * 60);
  if (p < 0) return 0;
  return p > 1 ? 1 : p;
}

/// Média diária em segundos no período de [days] dias terminando hoje.
int dailyAverage(Iterable<StudyFact> facts, DateTime now, int days) {
  if (days <= 0) return 0;
  final end = dayOf(now).add(const Duration(days: 1));
  final start = DateTime(end.year, end.month, end.day - days);
  return secondsBetween(facts, start, end) ~/ days;
}
