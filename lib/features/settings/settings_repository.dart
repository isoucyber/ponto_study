import 'package:drift/drift.dart';

import '../../core/database/database.dart';

// ============================================================
// ARQUIVO: lib/features/settings/settings_repository.dart
// FUNÇÃO: Lê e grava o perfil local e as configurações (chave -> valor).
// ============================================================

class SettingsRepository {
  final AppDatabase db;
  SettingsRepository(this.db);

  Future<Profile?> profile() =>
      (db.select(db.profiles)..limit(1)).getSingleOrNull();

  Stream<Profile?> watchProfile() =>
      (db.select(db.profiles)..limit(1)).watchSingleOrNull();

  /// Cria o perfil na primeira abertura (só o nome é pedido).
  Future<void> createProfile(String name) async {
    await db.into(db.profiles).insert(ProfilesCompanion(name: Value(name)));
  }

  Future<void> updateProfile({
    required int id,
    String? name,
    String? objective,
    String? avatar,
    int? dailyGoalMinutes,
    int? weeklyGoalMinutes,
  }) async {
    await (db.update(db.profiles)..where((p) => p.id.equals(id))).write(
      ProfilesCompanion(
        name: name == null ? const Value.absent() : Value(name),
        objective: objective == null ? const Value.absent() : Value(objective),
        avatar: avatar == null ? const Value.absent() : Value(avatar),
        dailyGoalMinutes: dailyGoalMinutes == null
            ? const Value.absent()
            : Value(dailyGoalMinutes),
        weeklyGoalMinutes: weeklyGoalMinutes == null
            ? const Value.absent()
            : Value(weeklyGoalMinutes),
      ),
    );
  }

  Future<Map<String, String>> allSettings() async {
    final rows = await db.select(db.appSettings).get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<void> setSetting(String key, String value) async {
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion(key: Value(key), value: Value(value)),
        );
  }

  Future<void> removeSetting(String key) async {
    await (db.delete(db.appSettings)..where((s) => s.key.equals(key))).go();
  }
}
