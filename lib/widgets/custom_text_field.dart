import 'package:flutter/material.dart';

/// ============================================================
/// ARQUIVO: lib/widgets/custom_text_field.dart
/// FUNÇÃO: Campo de texto padrão do app. Hoje é um wrapper fino
///         sobre o TextField do Flutter (o estilo visual já vem
///         pronto de app_theme.dart), mas existe como componente
///         próprio para que, se amanhã você quiser adicionar um
///         comportamento comum a TODOS os campos do app (ex:
///         limite de caracteres, contador, máscara), baste mudar
///         aqui uma vez.
///
/// POSSO ALTERAR:
///   - Adicionar novos parâmetros conforme a necessidade.
///
/// DEPENDÊNCIAS:
///   - screens/subjects/add_edit_subject_screen.dart
///   - screens/study/register_study_screen.dart
/// ============================================================
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}
