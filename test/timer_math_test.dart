import 'package:flutter_test/flutter_test.dart';
import 'package:ponto_study/domain/timer/timer_math.dart';

// Testes do cálculo de tempo do cronômetro (sem banco e sem telas).
void main() {
  final start = DateTime(2026, 11, 6, 14, 0, 0);

  test('sem pausas: tempo estudado = agora - início', () {
    final now = start.add(const Duration(minutes: 50));
    expect(studiedSeconds(start: start, pauses: const [], now: now), 3000);
  });

  test('pausas encerradas são descontadas', () {
    final now = start.add(const Duration(hours: 1));
    final pauses = [
      PauseInterval(start.add(const Duration(minutes: 10)),
          start.add(const Duration(minutes: 15))),
      PauseInterval(start.add(const Duration(minutes: 30)),
          start.add(const Duration(minutes: 40))),
    ];
    expect(pausedSeconds(pauses, now), 15 * 60);
    expect(studiedSeconds(start: start, pauses: pauses, now: now), 45 * 60);
  });

  test('pausa em andamento conta até agora', () {
    final now = start.add(const Duration(minutes: 30));
    final pauses = [PauseInterval(start.add(const Duration(minutes: 20)))];
    expect(pausedSeconds(pauses, now), 10 * 60);
    expect(studiedSeconds(start: start, pauses: pauses, now: now), 20 * 60);
  });

  test('o tempo nunca fica negativo (relógio ajustado para trás)', () {
    final now = start.subtract(const Duration(minutes: 5));
    expect(studiedSeconds(start: start, pauses: const [], now: now), 0);
    expect(totalSessionSeconds(start, now), 0);
  });

  test('tempo total inclui as pausas', () {
    final now = start.add(const Duration(minutes: 90));
    expect(totalSessionSeconds(start, now), 90 * 60);
  });
}
