import 'package:flutter/material.dart';

/// ============================================================
/// ARQUIVO: lib/widgets/progress_bar.dart
/// FUNÇÃO: Barra de progresso arredondada e colorida, usada nos
///         cards de matéria e no dashboard.
///
/// POSSO ALTERAR:
///   - Altura da barra (height) e arredondamento (borderRadius).
///
/// DEPENDÊNCIAS:
///   - widgets/subject_card.dart, screens/home/home_screen.dart
/// ============================================================
class ProgressBarWidget extends StatelessWidget {
  final double progress; // de 0.0 a 1.0
  final Color color;
  final double height;

  const ProgressBarWidget({
    super.key,
    required this.progress,
    required this.color,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: progress.clamp(0, 1),
        minHeight: height,
        backgroundColor: color.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
