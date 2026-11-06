import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/database/database.dart';
import '../../core/theme/app_themes.dart';
import 'settings_repository.dart';

// ============================================================
// ARQUIVO: lib/features/settings/settings_controller.dart
// FUNÇÃO: Mantém em memória o perfil e as preferências (tema, modo
//         claro/escuro, cor de destaque, cards ocultos do Dashboard)
//         e avisa as telas quando algo muda (ChangeNotifier).
//         Toda alteração é gravada no banco na mesma hora.
// ============================================================

/// Identificadores dos cards do Dashboard (usados para ocultar/mostrar).
class DashboardCards {
  static const today = 'today';
  static const week = 'week';
  static const streak = 'streak';
  static const subjects = 'subjects';
  static const plannedToday = 'planned_today';
  static const recentSessions = 'recent_sessions';
  static const subjectsWeek = 'subjects_week';

  static const all = <String, String>{
    today: 'Tempo de hoje e meta diária',
    week: 'Tempo da semana e meta semanal',
    streak: 'Sequência de estudos',
    subjects: 'Quantidade de matérias e assuntos',
    plannedToday: 'Planejado para hoje',
    subjectsWeek: 'Matérias na semana',
    recentSessions: 'Últimas sessões',
  };
}

class SettingsController extends ChangeNotifier {
  final SettingsRepository repo;
  SettingsController(this.repo);

  Profile? profile;
  String themeId = 'dark_forest';
  // 'auto' (modo natural do tema) | 'light' | 'dark'
  String themeMode = 'auto';
  int? accentColor;
  Set<String> hiddenCards = {};
  bool loaded = false;

  StreamSubscription<Profile?>? _sub;

  Future<void> load() async {
    profile = await repo.profile();
    final s = await repo.allSettings();
    themeId = s['theme_id'] ?? themeId;
    themeMode = s['theme_mode'] ?? themeMode;
    accentColor = int.tryParse(s['accent_color'] ?? '');
    final hidden = s['hidden_cards'] ?? '';
    hiddenCards = hidden.isEmpty ? {} : hidden.split(',').toSet();
    loaded = true;
    _sub = repo.watchProfile().listen((p) {
      profile = p;
      notifyListeners();
    });
    notifyListeners();
  }

  AppThemeSpec get spec => themeById(themeId);

  Brightness get brightness {
    switch (themeMode) {
      case 'light':
        return Brightness.light;
      case 'dark':
        return Brightness.dark;
      default:
        return spec.natural;
    }
  }

  ThemeData get themeData => buildThemeData(spec, brightness,
      accent: accentColor == null ? null : Color(accentColor!));

  Future<void> setTheme(String id) async {
    themeId = id;
    notifyListeners();
    await repo.setSetting('theme_id', id);
  }

  Future<void> setThemeMode(String mode) async {
    themeMode = mode;
    notifyListeners();
    await repo.setSetting('theme_mode', mode);
  }

  Future<void> setAccent(int? color) async {
    accentColor = color;
    notifyListeners();
    if (color == null) {
      await repo.removeSetting('accent_color');
    } else {
      await repo.setSetting('accent_color', '$color');
    }
  }

  bool isCardVisible(String id) => !hiddenCards.contains(id);

  Future<void> setCardVisible(String id, bool visible) async {
    if (visible) {
      hiddenCards.remove(id);
    } else {
      hiddenCards.add(id);
    }
    notifyListeners();
    await repo.setSetting('hidden_cards', hiddenCards.join(','));
  }

  Future<void> createProfile(String name) async {
    await repo.createProfile(name.trim());
    profile = await repo.profile();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
