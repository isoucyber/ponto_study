import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

// ============================================================
// ARQUIVO: lib/core/database/database.dart
// FUNÇÃO: Abre o banco SQLite local e reúne as tabelas.
//         As consultas ficam nos repositórios de cada módulo
//         (lib/features/*/..._repository.dart), não aqui.
//
// NÃO DEVO ALTERAR SEM ENTENDER:
//   - schemaVersion / migration: controlam a evolução do banco.
//     Ao adicionar uma coluna: (1) suba schemaVersion em +1 e
//     (2) escreva o passo em onUpgrade (ex.: m.addColumn(...)).
//
// O arquivo database.g.dart é GERADO automaticamente pelo comando
//   dart run build_runner build
// e nunca deve ser editado à mão.
// ============================================================

@DriftDatabase(tables: [
  Profiles,
  AppSettings,
  Subjects,
  ContentNodes,
  StudySessions,
  SessionPauses,
  PlanItems,
])
class AppDatabase extends _$AppDatabase {
  /// Banco real, salvo num arquivo do aparelho.
  AppDatabase() : super(_openConnection());

  /// Usado pelos testes automáticos (banco em memória).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        beforeOpen: (details) async {
          // Faz o SQLite realmente checar as relações entre tabelas.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// Abre (ou cria) o arquivo do banco na pasta de dados do aplicativo:
///  - Windows: C:\Users\<você>\AppData\Roaming\<empresa>\ponto_study\
///  - Android: pasta privada do app (apagada só ao desinstalar).
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'ponto_study.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        // WAL: modo de gravação mais resistente a desligamentos bruscos.
        rawDb.execute('PRAGMA journal_mode = WAL;');
      },
    );
  });
}

/// Caminho do arquivo do banco (mostrado nas Configurações).
Future<String> databaseFilePath() async {
  final dir = await getApplicationSupportDirectory();
  return p.join(dir.path, 'ponto_study.sqlite');
}
