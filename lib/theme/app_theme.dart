import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ============================================================
/// ARQUIVO: lib/theme/app_theme.dart
/// FUNÇÃO: Monta os objetos ThemeData (claro e escuro) que o
///         MaterialApp usa. É aqui que as cores de app_colors.dart
///         se transformam em botões, cards, AppBar, etc.
///
/// POSSO ALTERAR:
///   - O valor de "borderRadius" abaixo, para mudar o arredondamento
///     de botões e cards no app inteiro.
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - A estrutura geral do ThemeData (isso pode quebrar widgets
///     em várias telas ao mesmo tempo).
///
/// DEPENDÊNCIAS:
///   - main.dart (usa AppTheme.light e AppTheme.dark no MaterialApp)
/// ============================================================
class AppTheme {
  AppTheme._();

  // Arredondamento padrão de cards e botões. Troque aqui para
  // deixar o app com "cantos" mais ou menos arredondados.
  static const double borderRadius = 16;

  static ThemeData get light => _build(
        background: AppColors.backgroundLight,
        surface: AppColors.surfaceLight,
        textPrimary: AppColors.textPrimaryLight,
        textSecondary: AppColors.textSecondaryLight,
        brightness: Brightness.light,
      );

  static ThemeData get dark => _build(
        background: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        textPrimary: AppColors.textPrimaryDark,
        textSecondary: AppColors.textSecondaryDark,
        brightness: Brightness.dark,
      );

  static ThemeData _build({
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      ),
    );
  }
}
