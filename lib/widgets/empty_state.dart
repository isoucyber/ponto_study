import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// ============================================================
/// ARQUIVO: lib/widgets/empty_state.dart
/// FUNÇÃO: Mensagem amigável exibida quando uma lista está vazia
///         (sem matérias, sem sessões, etc), com um ícone e um
///         texto explicando o que fazer a seguir.
///
/// POSSO ALTERAR:
///   - Ícone padrão e tamanho.
///
/// DEPENDÊNCIAS:
///   - screens/subjects/subjects_screen.dart
///   - screens/home/home_screen.dart
/// ============================================================
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: mutedColor),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}
