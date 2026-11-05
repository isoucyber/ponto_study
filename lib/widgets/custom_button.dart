import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// ============================================================
/// ARQUIVO: lib/widgets/custom_button.dart
/// FUNÇÃO: Botão padrão do app (usa o estilo já definido em
///         app_theme.dart, mas com um "+ ícone" opcional).
///
/// POSSO ALTERAR:
///   - Ícone padrão, espaçamento interno.
///
/// DEPENDÊNCIAS:
///   - Usado em várias telas (screens/)
/// ============================================================
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label, style: AppTextStyles.button),
        ],
      ),
    );
  }
}
