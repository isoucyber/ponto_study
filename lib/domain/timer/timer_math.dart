// ============================================================
// ARQUIVO: lib/domain/timer/timer_math.dart
// FUNÇÃO: Cálculos de tempo do cronômetro. São funções "puras":
//         recebem horários e devolvem segundos. Não conhecem telas
//         nem banco, por isso são fáceis de testar (test/timer_math_test.dart).
//
// IDEIA CENTRAL: o tempo estudado é sempre
//     (agora - início) - (soma das pausas)
// Nunca contamos "tiques" na tela. Assim, se o app for minimizado,
// fechado ou o Android encerrá-lo, o tempo continua correto.
// ============================================================

/// Um intervalo de pausa. [end] nulo = pausa ainda em andamento.
class PauseInterval {
  final DateTime start;
  final DateTime? end;

  const PauseInterval(this.start, [this.end]);
}

/// Total de segundos pausados até [now].
int pausedSeconds(List<PauseInterval> pauses, DateTime now) {
  var total = 0;
  for (final pause in pauses) {
    final end = pause.end ?? now;
    final seconds = end.difference(pause.start).inSeconds;
    if (seconds > 0) total += seconds;
  }
  return total;
}

/// Segundos efetivamente estudados entre [start] e [now], descontando pausas.
int studiedSeconds({
  required DateTime start,
  required List<PauseInterval> pauses,
  required DateTime now,
}) {
  final total = now.difference(start).inSeconds;
  final result = total - pausedSeconds(pauses, now);
  return result < 0 ? 0 : result;
}

/// Tempo total da sessão (estudo + pausas).
int totalSessionSeconds(DateTime start, DateTime now) {
  final s = now.difference(start).inSeconds;
  return s < 0 ? 0 : s;
}
