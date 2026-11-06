import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import 'content_tree.dart';

// ============================================================
// ARQUIVO: lib/features/subjects/subject_repository.dart
// FUNÇÃO: Todas as operações de banco de MATÉRIAS e da árvore de
//         ASSUNTOS/TÓPICOS/SUBTÓPICOS (tabela content_nodes).
// POSSO ALTERAR: ordenações e novos métodos de consulta.
// NÃO DEVO ALTERAR SEM ENTENDER: as transações (transaction) — elas
//   garantem que operações com vários passos gravem tudo ou nada.
// ============================================================

class SubjectUsage {
  final int sessions;
  final int seconds;
  final int nodes;
  const SubjectUsage(this.sessions, this.seconds, this.nodes);
}

class SubjectRepository {
  final AppDatabase db;
  SubjectRepository(this.db);

  // ---------------- Matérias ----------------

  Stream<List<Subject>> watchActive() => (db.select(db.subjects)
        ..where((s) => s.archived.equals(false))
        ..orderBy([
          (s) => OrderingTerm.desc(s.priority),
          (s) => OrderingTerm.asc(s.name),
        ]))
      .watch();

  Stream<List<Subject>> watchArchived() => (db.select(db.subjects)
        ..where((s) => s.archived.equals(true))
        ..orderBy([(s) => OrderingTerm.asc(s.name)]))
      .watch();

  /// Todas (inclusive arquivadas): usado para mostrar nomes no histórico.
  Stream<List<Subject>> watchAll() => db.select(db.subjects).watch();

  Stream<Subject?> watchSubject(int id) =>
      (db.select(db.subjects)..where((s) => s.id.equals(id)))
          .watchSingleOrNull();

  Future<int> createSubject({
    required String name,
    String description = '',
    String icon = '📚',
    required int colorValue,
    int priority = 1,
    int weeklyGoalMinutes = 0,
  }) {
    return db.into(db.subjects).insert(SubjectsCompanion(
          name: Value(name.trim()),
          description: Value(description.trim()),
          icon: Value(icon),
          colorValue: Value(colorValue),
          priority: Value(priority),
          weeklyGoalMinutes: Value(weeklyGoalMinutes),
        ));
  }

  Future<void> updateSubject({
    required int id,
    required String name,
    required String description,
    required String icon,
    required int colorValue,
    required int priority,
    required int weeklyGoalMinutes,
  }) async {
    await (db.update(db.subjects)..where((s) => s.id.equals(id)))
        .write(SubjectsCompanion(
      name: Value(name.trim()),
      description: Value(description.trim()),
      icon: Value(icon),
      colorValue: Value(colorValue),
      priority: Value(priority),
      weeklyGoalMinutes: Value(weeklyGoalMinutes),
    ));
  }

  Future<void> setArchived(int id, bool archived) async {
    await (db.update(db.subjects)..where((s) => s.id.equals(id)))
        .write(SubjectsCompanion(archived: Value(archived)));
  }

  /// Quanto histórico existe para a matéria (mostrado antes de excluir).
  Future<SubjectUsage> usage(int subjectId) async {
    final sessions = await (db.select(db.studySessions)
          ..where((s) => s.subjectId.equals(subjectId)))
        .get();
    final nodes = await (db.select(db.contentNodes)
          ..where((n) => n.subjectId.equals(subjectId)))
        .get();
    final seconds = sessions.fold<int>(0, (a, s) => a + s.studySeconds);
    return SubjectUsage(sessions.length, seconds, nodes.length);
  }

  /// Exclusão DEFINITIVA: apaga a matéria, sua árvore, sessões e planos.
  Future<void> deletePermanently(int id) {
    return db.transaction(() async {
      final sessionIds = await (db.select(db.studySessions)
            ..where((s) => s.subjectId.equals(id)))
          .map((s) => s.id)
          .get();
      if (sessionIds.isNotEmpty) {
        await (db.delete(db.sessionPauses)
              ..where((p) => p.sessionId.isIn(sessionIds)))
            .go();
        await (db.delete(db.studySessions)
              ..where((s) => s.subjectId.equals(id)))
            .go();
      }
      await (db.delete(db.planItems)..where((p) => p.subjectId.equals(id)))
          .go();
      await (db.delete(db.contentNodes)..where((n) => n.subjectId.equals(id)))
          .go();
      await (db.delete(db.subjects)..where((s) => s.id.equals(id))).go();
    });
  }

  // ---------------- Árvore de conteúdos ----------------

  Stream<List<ContentNode>> watchNodes(int subjectId) =>
      (db.select(db.contentNodes)
            ..where((n) => n.subjectId.equals(subjectId))
            ..orderBy([
              (n) => OrderingTerm.asc(n.position),
              (n) => OrderingTerm.asc(n.id),
            ]))
          .watch();

  Future<List<ContentNode>> nodesOf(int subjectId) =>
      (db.select(db.contentNodes)
            ..where((n) => n.subjectId.equals(subjectId))
            ..orderBy([
              (n) => OrderingTerm.asc(n.position),
              (n) => OrderingTerm.asc(n.id),
            ]))
          .get();

  Stream<List<ContentNode>> watchAllNodes() =>
      db.select(db.contentNodes).watch();

  Future<int> createNode({
    required int subjectId,
    int? parentId,
    required String name,
    String description = '',
    String objective = '',
    String notes = '',
    String materials = '',
    int difficulty = 1,
    int priority = 1,
  }) async {
    final siblings = (await nodesOf(subjectId))
        .where((n) => n.parentId == parentId)
        .toList();
    final nextPos = siblings.isEmpty
        ? 0
        : siblings.map((n) => n.position).reduce((a, b) => a > b ? a : b) + 1;
    return db.into(db.contentNodes).insert(ContentNodesCompanion(
          subjectId: Value(subjectId),
          parentId: Value(parentId),
          name: Value(name.trim()),
          description: Value(description.trim()),
          objective: Value(objective.trim()),
          notes: Value(notes.trim()),
          materials: Value(materials.trim()),
          difficulty: Value(difficulty),
          priority: Value(priority),
          position: Value(nextPos),
        ));
  }

  Future<void> updateNode({
    required int id,
    required String name,
    required String description,
    required String objective,
    required String notes,
    required String materials,
    required int difficulty,
    required int priority,
  }) async {
    await (db.update(db.contentNodes)..where((n) => n.id.equals(id)))
        .write(ContentNodesCompanion(
      name: Value(name.trim()),
      description: Value(description.trim()),
      objective: Value(objective.trim()),
      notes: Value(notes.trim()),
      materials: Value(materials.trim()),
      difficulty: Value(difficulty),
      priority: Value(priority),
    ));
  }

  /// Exclui o item e TODOS os seus descendentes. Sessões ligadas a eles
  /// continuam existindo (passam a contar só para a matéria).
  Future<void> deleteNode(int id) {
    return db.transaction(() async {
      final node = await (db.select(db.contentNodes)
            ..where((n) => n.id.equals(id)))
          .getSingleOrNull();
      if (node == null) return;
      final all = await nodesOf(node.subjectId);
      final ids = [id, ...descendantIds(all, id)];
      await (db.update(db.studySessions)..where((s) => s.nodeId.isIn(ids)))
          .write(const StudySessionsCompanion(nodeId: Value(null)));
      await (db.update(db.planItems)..where((p) => p.nodeId.isIn(ids)))
          .write(const PlanItemsCompanion(nodeId: Value(null)));
      await (db.delete(db.contentNodes)..where((n) => n.id.isIn(ids))).go();
    });
  }

  /// Move o item para cima (delta = -1) ou para baixo (delta = +1)
  /// entre os irmãos.
  Future<void> moveNode(ContentNode node, int delta) {
    return db.transaction(() async {
      final siblings = (await nodesOf(node.subjectId))
          .where((n) => n.parentId == node.parentId)
          .toList();
      final index = siblings.indexWhere((n) => n.id == node.id);
      final target = index + delta;
      if (index < 0 || target < 0 || target >= siblings.length) return;
      final reordered = [...siblings];
      final item = reordered.removeAt(index);
      reordered.insert(target, item);
      for (var i = 0; i < reordered.length; i++) {
        await (db.update(db.contentNodes)
              ..where((n) => n.id.equals(reordered[i].id)))
            .write(ContentNodesCompanion(position: Value(i)));
      }
    });
  }

  /// Move o item para outro "pai" (null = vira Assunto de primeiro nível).
  /// Retorna false se o destino for o próprio item ou um descendente dele.
  Future<bool> reparentNode(ContentNode node, int? newParentId) async {
    final all = await nodesOf(node.subjectId);
    if (newParentId == node.id ||
        (newParentId != null &&
            descendantIds(all, node.id).contains(newParentId))) {
      return false;
    }
    final siblings = all.where((n) => n.parentId == newParentId).toList();
    final nextPos = siblings.isEmpty
        ? 0
        : siblings.map((n) => n.position).reduce((a, b) => a > b ? a : b) + 1;
    await (db.update(db.contentNodes)..where((n) => n.id.equals(node.id)))
        .write(ContentNodesCompanion(
      parentId: Value(newParentId),
      position: Value(nextPos),
    ));
    return true;
  }
}
