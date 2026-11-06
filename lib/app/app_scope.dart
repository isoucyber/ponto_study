import 'package:flutter/widgets.dart';

import '../core/database/database.dart';
import '../features/planning/plan_repository.dart';
import '../features/settings/settings_controller.dart';
import '../features/settings/settings_repository.dart';
import '../features/subjects/subject_repository.dart';
import '../features/timer/session_repository.dart';
import '../features/timer/timer_controller.dart';

// ============================================================
// ARQUIVO: lib/app/app_scope.dart
// FUNÇÃO: "Caixa de ferramentas" do app. Cria o banco, os repositórios
//         e os controladores UMA vez e os entrega para qualquer tela:
//             final app = AppScope.of(context);
//             app.subjects.watchActive() ...
//
// Para adicionar um módulo novo: crie o repositório dele e
// adicione um campo aqui.
// ============================================================

class AppServices {
  final AppDatabase db;
  final SettingsRepository settingsRepo;
  final SubjectRepository subjects;
  final SessionRepository sessions;
  final PlanRepository plans;
  final SettingsController settings;
  final TimerController timer;

  AppServices._(
    this.db,
    this.settingsRepo,
    this.subjects,
    this.sessions,
    this.plans,
    this.settings,
    this.timer,
  );

  factory AppServices(AppDatabase db) {
    final settingsRepo = SettingsRepository(db);
    final sessions = SessionRepository(db);
    return AppServices._(
      db,
      settingsRepo,
      SubjectRepository(db),
      sessions,
      PlanRepository(db),
      SettingsController(settingsRepo),
      TimerController(sessions),
    );
  }
}

class AppScope extends InheritedWidget {
  final AppServices services;

  const AppScope({super.key, required this.services, required super.child});

  static AppServices of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado na árvore de widgets.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.services != services;
}
