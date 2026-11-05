import 'package:flutter/material.dart';

/// ============================================================
/// ARQUIVO: lib/theme/app_colors.dart
/// FUNÇÃO: Centraliza TODAS as cores usadas no aplicativo.
///
/// POSSO ALTERAR:
///   - Os valores de cada cor abaixo (ex: trocar [primary] de azul
///     para roxo). Essa é a forma correta de trocar a cor principal
///     do app inteiro.
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - Os NOMES das variáveis (primary, background, etc). Vários
///     outros arquivos (app_theme.dart, widgets) dependem desses
///     nomes existirem.
///
/// DEPENDÊNCIAS (quem usa este arquivo):
///   - app_theme.dart (monta o ThemeData claro/escuro com essas cores)
///   - todos os widgets em lib/widgets/
/// ============================================================
class AppColors {
  AppColors._();

  // Cor principal do app. TROQUE AQUI para mudar o tema inteiro.
  static const Color primary = Color(0xFF2F6FED); // azul

  // Paleta de cores que o usuário pode escolher para o app ou para
  // uma matéria específica (tela "Nova matéria" e "Personalização").
  static const Map<String, Color> palette = {
    'Azul': Color(0xFF2F6FED),
    'Roxo': Color(0xFF7C4DFF),
    'Verde': Color(0xFF2E9E5B),
    'Laranja': Color(0xFFFF8A34),
    'Vermelho': Color(0xFFE5484D),
    'Rosa': Color(0xFFEC5D9C),
    'Azul-claro': Color(0xFF35B4E0),
  };

  // --- Tema claro ---
  static const Color backgroundLight = Color(0xFFF7F8FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1B1D22);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // --- Tema escuro ---
  static const Color backgroundDark = Color(0xFF121317);
  static const Color surfaceDark = Color(0xFF1D1F24);
  static const Color textPrimaryDark = Color(0xFFF2F3F5);
  static const Color textSecondaryDark = Color(0xFFA0A4AC);

  // Cores de apoio (usadas em barras de progresso, avisos, etc)
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFFFA726);
  static const Color danger = Color(0xFFE5484D);
}
