import 'package:flutter/material.dart';

// ============================================================
// ARQUIVO: lib/core/theme/app_themes.dart
// FUNÇÃO: Central de temas. Cada tema é um "pacote" de cores (modo
//         escuro e claro), raio de borda, sombras, fonte e um tipo de
//         decoração de fundo (desenhada em lib/core/theme/theme_decor.dart).
//
// POSSO ALTERAR: as cores (#RRGGBB), raios, fontes e descrições.
//   Para criar um tema novo, copie um AppThemeSpec, mude o id e
//   adicione na lista `appThemes` no fim do arquivo.
// NÃO DEVO ALTERAR SEM ENTENDER: os ids ('dark_forest', ...). Eles
//   ficam salvos nas configurações do usuário.
// ============================================================

/// Tipo de decoração de fundo de cada tema.
enum DecorKind { forest, rain, sunset, beach, academia, none }

/// Cores de um tema em um modo (claro ou escuro).
class ThemePalette {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color primary;
  final Color secondary;
  final Color text;
  final Color textMuted;
  final Color border;

  const ThemePalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.primary,
    required this.secondary,
    required this.text,
    required this.textMuted,
    required this.border,
  });

  ThemePalette withPrimary(Color c) => ThemePalette(
        background: background,
        surface: surface,
        surfaceAlt: surfaceAlt,
        primary: c,
        secondary: secondary,
        text: text,
        textMuted: textMuted,
        border: border,
      );
}

/// Definição completa de um tema.
class AppThemeSpec {
  final String id;
  final String name;
  final String description;
  final ThemePalette dark;
  final ThemePalette light;
  final double radius;
  final bool shadows;
  final String? headingFont;
  final List<String> headingFallback;
  final DecorKind decor;

  /// Modo "natural" do tema (usado quando o usuário escolhe "Automático").
  final Brightness natural;

  const AppThemeSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.dark,
    required this.light,
    required this.radius,
    required this.decor,
    this.shadows = false,
    this.headingFont,
    this.headingFallback = const [],
    this.natural = Brightness.dark,
  });

  ThemePalette palette(Brightness b) => b == Brightness.dark ? dark : light;
}

/// Extensão que deixa a paleta e a decoração acessíveis em qualquer tela:
///   final pt = Theme.of(context).extension<PontoTheme>()!;
class PontoTheme extends ThemeExtension<PontoTheme> {
  final AppThemeSpec spec;
  final ThemePalette palette;
  final Brightness brightness;

  const PontoTheme({
    required this.spec,
    required this.palette,
    required this.brightness,
  });

  @override
  PontoTheme copyWith({
    AppThemeSpec? spec,
    ThemePalette? palette,
    Brightness? brightness,
  }) =>
      PontoTheme(
        spec: spec ?? this.spec,
        palette: palette ?? this.palette,
        brightness: brightness ?? this.brightness,
      );

  @override
  PontoTheme lerp(ThemeExtension<PontoTheme>? other, double t) {
    if (other is! PontoTheme) return this;
    return t < 0.5 ? this : other;
  }
}

Color _c(int argb) => Color(argb);

const _forest = AppThemeSpec(
  id: 'dark_forest',
  name: 'Dark Forest',
  description: 'Floresta à noite: verdes profundos e tons naturais.',
  radius: 18,
  decor: DecorKind.forest,
  dark: ThemePalette(
    background: Color(0xFF0F1A14),
    surface: Color(0xFF17261D),
    surfaceAlt: Color(0xFF1F3326),
    primary: Color(0xFF7FA36B),
    secondary: Color(0xFFC2B280),
    text: Color(0xFFE6EDE3),
    textMuted: Color(0xFF9DB09A),
    border: Color(0xFF2C4434),
  ),
  light: ThemePalette(
    background: Color(0xFFEEF2EA),
    surface: Color(0xFFF8FAF5),
    surfaceAlt: Color(0xFFE2EADB),
    primary: Color(0xFF4F7A3E),
    secondary: Color(0xFF8A7442),
    text: Color(0xFF1D2A20),
    textMuted: Color(0xFF5B6E5C),
    border: Color(0xFFCBD8C3),
  ),
);

const _rain = AppThemeSpec(
  id: 'rainy_day',
  name: 'Rainy Day',
  description: 'Dia chuvoso: azuis acinzentados e atmosfera aconchegante.',
  radius: 14,
  decor: DecorKind.rain,
  dark: ThemePalette(
    background: Color(0xFF1C2430),
    surface: Color(0xFF263040),
    surfaceAlt: Color(0xFF2E3A4D),
    primary: Color(0xFF7FA7C9),
    secondary: Color(0xFFA9B8C9),
    text: Color(0xFFE3E9F0),
    textMuted: Color(0xFF9AA8B8),
    border: Color(0xFF3A475B),
  ),
  light: ThemePalette(
    background: Color(0xFFE9EDF1),
    surface: Color(0xFFF6F8FA),
    surfaceAlt: Color(0xFFDDE3EA),
    primary: Color(0xFF4A6F91),
    secondary: Color(0xFF6E7F92),
    text: Color(0xFF1E2833),
    textMuted: Color(0xFF5C6B7B),
    border: Color(0xFFC7D0DA),
  ),
);

const _sunset = AppThemeSpec(
  id: 'sunset',
  name: 'Sunset',
  description: 'Pôr do sol: laranja, rosa e roxo em degradês suaves.',
  radius: 20,
  shadows: true,
  decor: DecorKind.sunset,
  dark: ThemePalette(
    background: Color(0xFF2A1B2E),
    surface: Color(0xFF3A2540),
    surfaceAlt: Color(0xFF47304E),
    primary: Color(0xFFF28C5A),
    secondary: Color(0xFFE86A92),
    text: Color(0xFFF7E9EE),
    textMuted: Color(0xFFC9A9B8),
    border: Color(0xFF563A5C),
  ),
  light: ThemePalette(
    background: Color(0xFFFFF1E8),
    surface: Color(0xFFFFF9F5),
    surfaceAlt: Color(0xFFFBE3D6),
    primary: Color(0xFFD9653A),
    secondary: Color(0xFFC94C7A),
    text: Color(0xFF3A2234),
    textMuted: Color(0xFF7D5F70),
    border: Color(0xFFF0CDBE),
  ),
);

const _beach = AppThemeSpec(
  id: 'beach',
  name: 'Beach',
  description: 'Praia: azul oceano, areia e branco.',
  radius: 22,
  shadows: true,
  natural: Brightness.light,
  decor: DecorKind.beach,
  light: ThemePalette(
    background: Color(0xFFF5EFE4),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEDE3D0),
    primary: Color(0xFF1F7A99),
    secondary: Color(0xFFE0A96D),
    text: Color(0xFF1C3540),
    textMuted: Color(0xFF5F7480),
    border: Color(0xFFDCCFB8),
  ),
  dark: ThemePalette(
    background: Color(0xFF0E2230),
    surface: Color(0xFF15303F),
    surfaceAlt: Color(0xFF1C3C4D),
    primary: Color(0xFF4FB3CF),
    secondary: Color(0xFFE0B47D),
    text: Color(0xFFE6F1F5),
    textMuted: Color(0xFF93B0BC),
    border: Color(0xFF25495B),
  ),
);

const _academia = AppThemeSpec(
  id: 'dark_academia',
  name: 'Dark Academia',
  description: 'Biblioteca clássica: madeira, pergaminho e dourado-velho.',
  radius: 6,
  decor: DecorKind.academia,
  headingFont: 'Georgia',
  headingFallback: ['Noto Serif', 'serif'],
  dark: ThemePalette(
    background: Color(0xFF1B1612),
    surface: Color(0xFF2A221B),
    surfaceAlt: Color(0xFF362C23),
    primary: Color(0xFFC9A66B),
    secondary: Color(0xFF8C5A3C),
    text: Color(0xFFEFE6D2),
    textMuted: Color(0xFFB3A48A),
    border: Color(0xFF4A3C2E),
  ),
  light: ThemePalette(
    background: Color(0xFFEFE6D2),
    surface: Color(0xFFF7F1E3),
    surfaceAlt: Color(0xFFE5D8BD),
    primary: Color(0xFF7A5230),
    secondary: Color(0xFF9C7A3C),
    text: Color(0xFF2B2118),
    textMuted: Color(0xFF6B5A45),
    border: Color(0xFFD2C2A0),
  ),
);

const _minimal = AppThemeSpec(
  id: 'minimal',
  name: 'Minimalista',
  description: 'Poucas cores, fundo limpo, foco total na leitura.',
  radius: 10,
  natural: Brightness.light,
  decor: DecorKind.none,
  light: ThemePalette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF7F7F7),
    surfaceAlt: Color(0xFFEEEEEE),
    primary: Color(0xFF2F6FED),
    secondary: Color(0xFF6B7280),
    text: Color(0xFF111111),
    textMuted: Color(0xFF666666),
    border: Color(0xFFE3E3E3),
  ),
  dark: ThemePalette(
    background: Color(0xFF18191B),
    surface: Color(0xFF222326),
    surfaceAlt: Color(0xFF2B2D31),
    primary: Color(0xFF6E9BFF),
    secondary: Color(0xFF9AA0A6),
    text: Color(0xFFEDEDED),
    textMuted: Color(0xFFA0A0A0),
    border: Color(0xFF34363A),
  ),
);

/// Lista de temas disponíveis (a ordem aparece nas Configurações).
const List<AppThemeSpec> appThemes = [
  _forest,
  _rain,
  _sunset,
  _beach,
  _academia,
  _minimal,
];

AppThemeSpec themeById(String? id) =>
    appThemes.firstWhere((t) => t.id == id, orElse: () => _forest);

/// Escolhe texto claro ou escuro para ficar legível sobre [bg].
Color onColor(Color bg) =>
    bg.computeLuminance() > 0.45 ? const Color(0xFF15120F) : Colors.white;

/// Monta o ThemeData do Flutter a partir de um tema do Ponto Study.
/// [accent] permite a personalização avançada (cor de destaque própria).
ThemeData buildThemeData(AppThemeSpec spec, Brightness b, {Color? accent}) {
  var pal = spec.palette(b);
  if (accent != null) pal = pal.withPrimary(accent);

  final scheme = ColorScheme.fromSeed(seedColor: pal.primary, brightness: b)
      .copyWith(
    primary: pal.primary,
    onPrimary: onColor(pal.primary),
    primaryContainer: Color.alphaBlend(
        pal.primary.withValues(alpha: 0.22), pal.surface),
    onPrimaryContainer: pal.text,
    secondary: pal.secondary,
    onSecondary: onColor(pal.secondary),
    surface: pal.surface,
    onSurface: pal.text,
    onSurfaceVariant: pal.textMuted,
    outline: pal.border,
    outlineVariant: pal.border,
    surfaceContainerLowest: pal.background,
    surfaceContainerLow: pal.surface,
    surfaceContainer: pal.surface,
    surfaceContainerHigh: pal.surfaceAlt,
    surfaceContainerHighest: pal.surfaceAlt,
  );

  final radius = BorderRadius.circular(spec.radius);
  final smallRadius = BorderRadius.circular(spec.radius * 0.6);

  final baseText = (b == Brightness.dark
          ? Typography.material2021().white
          : Typography.material2021().black)
      .apply(bodyColor: pal.text, displayColor: pal.text);

  TextStyle? heading(TextStyle? s) => spec.headingFont == null
      ? s?.copyWith(fontWeight: FontWeight.w600)
      : s?.copyWith(
          fontFamily: spec.headingFont,
          fontFamilyFallback: spec.headingFallback,
          fontWeight: FontWeight.w600,
        );

  final textTheme = baseText.copyWith(
    headlineMedium: heading(baseText.headlineMedium),
    headlineSmall: heading(baseText.headlineSmall),
    titleLarge: heading(baseText.titleLarge),
    titleMedium: heading(baseText.titleMedium),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: pal.background,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: pal.surface,
      elevation: spec.shadows ? 3 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: pal.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: pal.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: pal.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: smallRadius,
        borderSide: BorderSide(color: pal.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: smallRadius,
        borderSide: BorderSide(color: pal.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: smallRadius,
        borderSide: BorderSide(color: pal.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: smallRadius),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: smallRadius),
        side: BorderSide(color: pal.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: pal.surface,
      indicatorColor: pal.primary.withValues(alpha: 0.24),
      height: 68,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: pal.surface,
      indicatorColor: pal.primary.withValues(alpha: 0.24),
    ),
    dividerTheme: DividerThemeData(color: pal.border, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: pal.surface,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: pal.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(spec.radius)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: pal.surfaceAlt,
      side: BorderSide(color: pal.border),
      shape: RoundedRectangleBorder(borderRadius: smallRadius),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    extensions: [PontoTheme(spec: spec, palette: pal, brightness: b)],
  );
}

/// Atalho: PontoTheme do contexto atual.
PontoTheme pontoOf(BuildContext context) =>
    Theme.of(context).extension<PontoTheme>()!;

/// Paleta de cores sugeridas para matérias.
const subjectColors = <Color>[
  Color(0xFF7FA36B),
  Color(0xFF4FB3CF),
  Color(0xFF6E9BFF),
  Color(0xFFB388FF),
  Color(0xFFE86A92),
  Color(0xFFF28C5A),
  Color(0xFFE0B44F),
  Color(0xFFC9A66B),
  Color(0xFF4DB6AC),
  Color(0xFF90A4AE),
  Color(0xFFEF5350),
  Color(0xFF8D6E63),
];

/// Ícones (emoji) sugeridos para matérias.
const subjectIcons = <String>[
  '📚', '💻', '☕', '🐍', '🧮', '🔐', '🌐', '🧪', '📐', '🧠',
  '📝', '🎨', '🎵', '🌍', '⚙️', '📊', '🗂️', '🔬', '📖', '🏛️',
];

// Usado para evitar warnings de função não usada em algumas plataformas.
Color colorFromInt(int v) => _c(v);
