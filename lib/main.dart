import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_scope.dart';
import 'core/database/database.dart';

// ============================================================
// ARQUIVO: lib/main.dart
// FUNÇÃO: Ponto de partida do aplicativo. Abre o banco local,
//         carrega as preferências e inicia a interface.
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = AppServices(AppDatabase());
  await services.settings.load();
  runApp(AppScope(services: services, child: const PontoStudyApp()));
}
