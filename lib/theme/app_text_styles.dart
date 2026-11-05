import 'package:flutter/material.dart';

/// ============================================================
/// ARQUIVO: lib/theme/app_text_styles.dart
/// FUNÇÃO: Centraliza os tamanhos e pesos de fonte usados no app.
///
/// POSSO ALTERAR:
///   - Tamanhos (fontSize), pesos (fontWeight) e espaçamentos de
///     qualquer estilo abaixo.
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - Os nomes dos estilos (title, subtitle, body...), pois as
///     telas e widgets chamam esses nomes diretamente.
///
/// DEPENDÊNCIAS:
///   - app_theme.dart
///   - widgets e screens que usam AppTextStyles.algumEstilo
/// ============================================================
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle statNumber = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
}
