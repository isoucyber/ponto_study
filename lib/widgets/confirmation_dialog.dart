import 'package:flutter/material.dart';

/// ============================================================
/// ARQUIVO: lib/widgets/confirmation_dialog.dart
/// FUNÇÃO: Caixa de confirmação reutilizável para qualquer ação
///         destrutiva (excluir matéria, excluir sessão, etc).
///         Mostra título, mensagem e dois botões: cancelar/confirmar.
///
/// POSSO ALTERAR:
///   - Textos padrão dos botões ("Cancelar" / "Confirmar").
///   - Cor do botão de confirmação (hoje usa a cor de erro do tema).
///
/// COMO USAR:
///   final confirmou = await ConfirmationDialog.show(
///     context,
///     title: 'Excluir matéria?',
///     message: 'Esta matéria tem 12 sessões registradas (8h30). '
///         'O histórico não será apagado, mas ela deixará de '
///         'aparecer nas suas listas. Continuar?',
///   );
///   if (confirmou == true) { ... }
///
/// DEPENDÊNCIAS:
///   - screens/subjects/add_edit_subject_screen.dart
///   - screens/study/register_study_screen.dart (ao excluir sessão)
/// ============================================================
class ConfirmationDialog {
  ConfirmationDialog._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Excluir',
    String cancelLabel = 'Cancelar',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
