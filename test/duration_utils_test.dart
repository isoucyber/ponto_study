import 'package:flutter_test/flutter_test.dart';
import 'package:ponto_study/utils/duration_utils.dart';

/// ============================================================
/// ARQUIVO: test/duration_utils_test.dart
/// FUNÇÃO: Testa a conversão de texto <-> minutos, que é uma das
///         partes mais importantes do app (se ela errar, todos os
///         totais do dashboard ficam errados).
///
/// COMO RODAR:
///   flutter test test/duration_utils_test.dart
///   (ou "flutter test" para rodar TODOS os testes do projeto)
/// ============================================================
void main() {
  group('DurationUtils.formatMinutes', () {
    test('0 minutos vira "0min"', () {
      expect(DurationUtils.formatMinutes(0), '0min');
    });

    test('minutos menores que 1 hora mostram só "Xmin"', () {
      expect(DurationUtils.formatMinutes(45), '45min');
    });

    test('horas exatas mostram "Xh"', () {
      expect(DurationUtils.formatMinutes(120), '2h');
    });

    test('horas com minutos mostram "XhYY"', () {
      expect(DurationUtils.formatMinutes(90), '1h30');
    });
  });

  group('DurationUtils.parseToMinutes', () {
    test('"1h30" vira 90', () {
      expect(DurationUtils.parseToMinutes('1h30'), 90);
    });

    test('"1h" vira 60', () {
      expect(DurationUtils.parseToMinutes('1h'), 60);
    });

    test('"2 horas" vira 120', () {
      expect(DurationUtils.parseToMinutes('2 horas'), 120);
    });

    test('"1 hora" vira 60', () {
      expect(DurationUtils.parseToMinutes('1 hora'), 60);
    });

    test('"30min" vira 30', () {
      expect(DurationUtils.parseToMinutes('30min'), 30);
    });

    test('"30 minutos" vira 30', () {
      expect(DurationUtils.parseToMinutes('30 minutos'), 30);
    });

    test('"30" (só número) vira 30', () {
      expect(DurationUtils.parseToMinutes('30'), 30);
    });

    test('texto inválido retorna null', () {
      expect(DurationUtils.parseToMinutes('abacate'), null);
    });

    test('texto vazio retorna null', () {
      expect(DurationUtils.parseToMinutes(''), null);
    });
  });
}
