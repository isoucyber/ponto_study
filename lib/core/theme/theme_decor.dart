import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_themes.dart';

// ============================================================
// ARQUIVO: lib/core/theme/theme_decor.dart
// FUNÇÃO: Desenha a decoração de fundo de cada tema (pinheiros,
//         chuva, sol, ondas, molduras). Tudo é desenhado em código
//         (vetores), sem imagens: leve e nítido em qualquer tela.
//
// POSSO ALTERAR: opacidades, tamanhos e formas dentro de cada _paintX.
// Mantenha as opacidades baixas (≈ 0.05–0.12) para não atrapalhar a leitura.
// ============================================================

class ThemeDecoration extends StatelessWidget {
  const ThemeDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    final pt = pontoOf(context);
    if (pt.spec.decor == DecorKind.none) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _DecorPainter(pt.spec.decor, pt.palette, pt.brightness),
        ),
      ),
    );
  }
}

class _DecorPainter extends CustomPainter {
  final DecorKind kind;
  final ThemePalette pal;
  final Brightness brightness;

  _DecorPainter(this.kind, this.pal, this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case DecorKind.forest:
        _paintForest(canvas, size);
      case DecorKind.rain:
        _paintRain(canvas, size);
      case DecorKind.sunset:
        _paintSunset(canvas, size);
      case DecorKind.beach:
        _paintBeach(canvas, size);
      case DecorKind.academia:
        _paintAcademia(canvas, size);
      case DecorKind.none:
        break;
    }
  }

  // Silhuetas de pinheiros ao longo do rodapé.
  void _paintForest(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var layer = 0; layer < 2; layer++) {
      final paint = Paint()
        ..color = pal.primary.withValues(alpha: layer == 0 ? 0.05 : 0.08);
      var x = -20.0 + layer * 30;
      while (x < size.width + 40) {
        final h = 70.0 + rnd.nextDouble() * 90 - layer * 20;
        final w = h * 0.45;
        final base = size.height;
        final path = Path();
        for (var tier = 0; tier < 3; tier++) {
          final tierBase = base - tier * h * 0.28;
          final tierTop = tierBase - h * 0.5;
          final tierW = w * (1 - tier * 0.22);
          path
            ..moveTo(x - tierW / 2, tierBase)
            ..lineTo(x, tierTop)
            ..lineTo(x + tierW / 2, tierBase)
            ..close();
        }
        canvas.drawPath(path, paint);
        x += w * (0.7 + rnd.nextDouble() * 0.8);
      }
    }
  }

  // Gotas de chuva inclinadas, espalhadas de forma fixa.
  void _paintRain(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    final paint = Paint()
      ..color = pal.secondary.withValues(alpha: 0.07)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final count = (size.width * size.height / 9000).clamp(40, 260).toInt();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final len = 10 + rnd.nextDouble() * 14;
      canvas.drawLine(Offset(x, y), Offset(x - len * 0.25, y + len), paint);
    }
  }

  // Sol baixo no canto e faixas de cor de fim de tarde.
  void _paintSunset(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.86, size.height * 0.92);
    final r = math.max(size.width, size.height) * 0.55;
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        pal.primary.withValues(alpha: 0.16),
        pal.secondary.withValues(alpha: 0.07),
        pal.secondary.withValues(alpha: 0.0),
      ], stops: const [0, 0.45, 1])
          .createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, glow);
    final sun = Paint()..color = pal.primary.withValues(alpha: 0.10);
    canvas.drawCircle(center, 60, sun);
  }

  // Ondas no topo e uma faixa de areia no rodapé.
  void _paintBeach(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final paint = Paint()
        ..color = pal.primary.withValues(alpha: 0.05 + i * 0.02);
      final path = Path()..moveTo(0, 0);
      final baseY = 34.0 + i * 16;
      for (double x = 0; x <= size.width; x += 8) {
        final y = baseY + math.sin((x / 90) + i * 1.3) * 7;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, 0)
        ..close();
      canvas.drawPath(path, paint);
    }
    final sand = Paint()..color = pal.secondary.withValues(alpha: 0.07);
    final sandPath = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 10) {
      sandPath.lineTo(x, size.height - 26 - math.sin(x / 140) * 8);
    }
    sandPath
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(sandPath, sand);
  }

  // Moldura fina dupla com cantos ornamentados, como numa biblioteca.
  void _paintAcademia(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pal.primary.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final r1 = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    final r2 = r1.deflate(5);
    canvas.drawRect(r1, paint);
    canvas.drawRect(r2, paint);
    final dot = Paint()..color = pal.primary.withValues(alpha: 0.22);
    for (final c in [r1.topLeft, r1.topRight, r1.bottomLeft, r1.bottomRight]) {
      canvas.drawCircle(c, 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _DecorPainter old) =>
      old.kind != kind || old.pal != pal || old.brightness != brightness;
}
