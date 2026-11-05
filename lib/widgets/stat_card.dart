import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// ============================================================
/// ARQUIVO: lib/widgets/stat_card.dart
/// FUNÇÃO: Card pequeno com um número em destaque e um rótulo,
///         usado no dashboard (ex: "Hoje: 2h30", "Meta: 3h").
///
/// POSSO ALTERAR:
///   - Cores, ícones, tamanhos.
///
/// DEPENDÊNCIAS:
///   - screens/home/home_screen.dart
/// ============================================================
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value, style: AppTextStyles.statNumber),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
