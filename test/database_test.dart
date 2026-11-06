import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponto_study/core/database/database.dart';
import 'package:ponto_study/features/planning/plan_repository.dart';
import 'package:ponto_study/features/settings/settings_repository.dart';
import 'package:ponto_study/features/subjects/content_tree.dart';
import 'package:ponto_study/features/subjects/subject_repository.dart';
import 'package:ponto_study/features/timer/session_repository.dart';

// Testes de persistência com um banco SQLite em memória:
// matérias, hierarquia de conteúdos, cronômetro, registro manual,
// planejamento e perfil.
void main() {
  late AppDatabase db;
  late SubjectRepository subjects;
  late SessionRepository sessions;
  late PlanRepository plans;
  late SettingsRepository settings;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    subjects = SubjectRepository(db);
    sessions = SessionRepository(db);
    plans = PlanRepository(db);
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  Future<int> newSubject([String name = 'Java']) =>
      subjects.createSubject(name: name, colorValue: 0xFF7FA36B);

  group('Perfil e configurações', () {
    test('cria perfil só com o nome e mantém metas padrão', () async {
      expect(await settings.profile(), isNull);
      await settings.createProfile('Arthur');
      final p = await settings.profile();
      expect(p!.name, 'Arthur');
      expect(p.dailyGoalMinutes, 120);
      await settings.updateProfile(id: p.id, name: 'Arthur B.', dailyGoalMinutes: 90);
      final p2 = await settings.profile();
      expect(p2!.name, 'Arthur B.');
      expect(p2.dailyGoalMinutes, 90);
    });

    test('configurações chave/valor são sobrescritas', () async {
      await settings.setSetting('theme_id', 'sunset');
      await settings.setSetting('theme_id', 'beach');
      expect((await settings.allSettings())['theme_id'], 'beach');
    });
  });

  group('Matérias', () {
    test('criar, editar e arquivar', () async {
      final id = await newSubject();
      await subjects.updateSubject(
        id: id,
        name: 'Java SE',
        description: 'Linguagem',
        icon: '☕',
        colorValue: 1,
        priority: 2,
        weeklyGoalMinutes: 300,
      );
      final active = await subjects.watchActive().first;
      expect(active.single.name, 'Java SE');
      expect(active.single.weeklyGoalMinutes, 300);

      await subjects.setArchived(id, true);
      expect(await subjects.watchActive().first, isEmpty);
      expect((await subjects.watchArchived().first).single.id, id);
    });

    test('exclusão definitiva apaga árvore, sessões e planos', () async {
      final id = await newSubject();
      await subjects.createNode(subjectId: id, name: 'Arrays');
      await sessions.addManual(
          subjectId: id, startedAt: DateTime(2026, 11, 1, 10), minutes: 30);
      await plans.create(
          day: DateTime(2026, 11, 2), subjectId: id, durationMinutes: 60);
      await subjects.deletePermanently(id);
      expect(await db.select(db.subjects).get(), isEmpty);
      expect(await db.select(db.contentNodes).get(), isEmpty);
      expect(await db.select(db.studySessions).get(), isEmpty);
      expect(await db.select(db.planItems).get(), isEmpty);
    });
  });

  group('Hierarquia Assunto → Tópico → Subtópico', () {
    test('monta a árvore com profundidade e ordem', () async {
      final s = await newSubject();
      final loops = await subjects.createNode(subjectId: s, name: 'Repetição');
      final arrays = await subjects.createNode(subjectId: s, name: 'Arrays');
      final forNode =
          await subjects.createNode(subjectId: s, parentId: loops, name: 'for');
      await subjects.createNode(
          subjectId: s, parentId: forNode, name: 'for aninhado');
      await subjects.createNode(subjectId: s, parentId: loops, name: 'while');

      final flat = flattenTree(await subjects.nodesOf(s));
      expect(flat.map((e) => '${e.depth}:${e.node.name}').toList(), [
        '0:Repetição',
        '1:for',
        '2:for aninhado',
        '1:while',
        '0:Arrays',
      ]);
      expect(levelLabel(0), 'Assunto');
      expect(levelLabel(1), 'Tópico');
      expect(levelLabel(2), 'Subtópico');

      final nodes = await subjects.nodesOf(s);
      final deep = nodes.firstWhere((n) => n.name == 'for aninhado');
      expect(nodePath(nodes, deep.id), 'Repetição › for › for aninhado');
      expect(descendantIds(nodes, loops).length, 3);
      expect(arrays, isNot(loops));
    });

    test('recolher um item esconde os filhos', () async {
      final s = await newSubject();
      final a = await subjects.createNode(subjectId: s, name: 'A');
      await subjects.createNode(subjectId: s, parentId: a, name: 'A1');
      final flat =
          flattenTree(await subjects.nodesOf(s), collapsed: {a});
      expect(flat.map((e) => e.node.name), ['A']);
      expect(flat.single.hasChildren, isTrue);
    });

    test('reordenar irmãos', () async {
      final s = await newSubject();
      await subjects.createNode(subjectId: s, name: 'A');
      await subjects.createNode(subjectId: s, name: 'B');
      await subjects.createNode(subjectId: s, name: 'C');
      var nodes = await subjects.nodesOf(s);
      await subjects.moveNode(nodes.firstWhere((n) => n.name == 'C'), -1);
      nodes = await subjects.nodesOf(s);
      expect(flattenTree(nodes).map((e) => e.node.name), ['A', 'C', 'B']);
    });

    test('mover para outro pai e impedir ciclos', () async {
      final s = await newSubject();
      final a = await subjects.createNode(subjectId: s, name: 'A');
      final b = await subjects.createNode(subjectId: s, name: 'B');
      final a1 = await subjects.createNode(subjectId: s, parentId: a, name: 'A1');
      var nodes = await subjects.nodesOf(s);
      final nodeA = nodes.firstWhere((n) => n.id == a);
      // A não pode ir para dentro do próprio filho.
      expect(await subjects.reparentNode(nodeA, a1), isFalse);
      // A vai para dentro de B.
      expect(await subjects.reparentNode(nodeA, b), isTrue);
      nodes = await subjects.nodesOf(s);
      expect(flattenTree(nodes).map((e) => '${e.depth}:${e.node.name}'),
          ['0:B', '1:A', '2:A1']);
    });

    test('excluir item apaga descendentes e preserva sessões', () async {
      final s = await newSubject();
      final a = await subjects.createNode(subjectId: s, name: 'A');
      final a1 = await subjects.createNode(subjectId: s, parentId: a, name: 'A1');
      await sessions.addManual(
          subjectId: s,
          nodeId: a1,
          startedAt: DateTime(2026, 11, 1, 10),
          minutes: 40);
      await subjects.deleteNode(a);
      expect(await subjects.nodesOf(s), isEmpty);
      final list = await sessions.watchFinished().first;
      expect(list.single.nodeId, isNull);
      expect(list.single.studySeconds, 40 * 60);
    });
  });

  group('Cronômetro', () {
    test('iniciar, pausar, retomar e finalizar descontando a pausa', () async {
      final s = await newSubject();
      final t0 = DateTime(2026, 11, 6, 14, 0);
      final id = await sessions.start(subjectId: s, now: t0);
      expect((await sessions.active())!.status, 'running');

      await sessions.pause(id, now: t0.add(const Duration(minutes: 20)));
      expect((await sessions.active())!.status, 'paused');
      await sessions.resume(id, now: t0.add(const Duration(minutes: 30)));
      await sessions.finish(id, now: t0.add(const Duration(minutes: 60)), notes: 'for');

      expect(await sessions.active(), isNull);
      final done = (await sessions.watchFinished().first).single;
      expect(done.studySeconds, 50 * 60);
      expect(done.pausedSeconds, 10 * 60);
      expect(done.source, 'timer');
      expect(done.notes, 'for');
    });

    test('finalizar enquanto pausado fecha a pausa', () async {
      final s = await newSubject();
      final t0 = DateTime(2026, 11, 6, 8);
      final id = await sessions.start(subjectId: s, now: t0);
      await sessions.pause(id, now: t0.add(const Duration(minutes: 25)));
      await sessions.finish(id, now: t0.add(const Duration(minutes: 40)));
      final done = (await sessions.watchFinished().first).single;
      expect(done.studySeconds, 25 * 60);
      expect(done.pausedSeconds, 15 * 60);
    });

    test('ajuste manual do tempo ao finalizar', () async {
      final s = await newSubject();
      final t0 = DateTime(2026, 11, 6, 8);
      final id = await sessions.start(subjectId: s, now: t0);
      await sessions.finish(id,
          now: t0.add(const Duration(hours: 5)), adjustedStudySeconds: 3600);
      expect((await sessions.watchFinished().first).single.studySeconds, 3600);
    });

    test('não permite duas sessões ativas', () async {
      final s = await newSubject();
      await sessions.start(subjectId: s);
      expect(() => sessions.start(subjectId: s), throwsA(isA<StateError>()));
    });

    test('a sessão ativa sobrevive (fica no banco) e o tempo é recalculado',
        () async {
      final s = await newSubject();
      final t0 = DateTime(2026, 11, 6, 8);
      await sessions.start(subjectId: s, now: t0);
      // Simula o app sendo fechado e reaberto: buscamos de novo no banco.
      final recovered = await sessions.active();
      expect(recovered, isNotNull);
      final secs = await sessions.liveStudySeconds(recovered!,
          now: t0.add(const Duration(minutes: 42)));
      expect(secs, 42 * 60);
    });

    test('cancelar não registra nada', () async {
      final s = await newSubject();
      final id = await sessions.start(subjectId: s);
      await sessions.pause(id);
      await sessions.cancel(id);
      expect(await db.select(db.studySessions).get(), isEmpty);
      expect(await db.select(db.sessionPauses).get(), isEmpty);
    });
  });

  group('Registro manual e histórico', () {
    test('registro manual e edição', () async {
      final s = await newSubject();
      final id = await sessions.addManual(
          subjectId: s, startedAt: DateTime(2026, 11, 5, 19), minutes: 90);
      var done = (await sessions.watchFinished().first).single;
      expect(done.studySeconds, 90 * 60);
      expect(done.endedAt, DateTime(2026, 11, 5, 20, 30));
      await sessions.updateFinished(
          id: id, subjectId: s, studySeconds: 45 * 60, notes: 'revisão');
      done = (await sessions.watchFinished().first).single;
      expect(done.studySeconds, 45 * 60);
      expect(done.notes, 'revisão');
    });
  });

  group('Planejamento', () {
    test('concluir atividade não cria horas estudadas', () async {
      final s = await newSubject();
      final id = await plans.create(
          day: DateTime(2026, 11, 9, 15), subjectId: s, durationMinutes: 90);
      await plans.setDone(id, true);
      final items = await plans
          .watchRange(DateTime(2026, 11, 9), DateTime(2026, 11, 10))
          .first;
      expect(items.single.done, isTrue);
      expect(items.single.day, DateTime(2026, 11, 9));
      expect(await sessions.watchFinished().first, isEmpty);
    });

    test('copiar semana para a seguinte', () async {
      final s = await newSubject();
      await plans.create(
          day: DateTime(2026, 11, 2), subjectId: s, durationMinutes: 60);
      await plans.create(
          day: DateTime(2026, 11, 4), subjectId: s, durationMinutes: 30);
      expect(await plans.copyWeekToNext(DateTime(2026, 11, 3)), 2);
      final next = await plans
          .watchRange(DateTime(2026, 11, 9), DateTime(2026, 11, 16))
          .first;
      expect(next.map((p) => p.day.day).toList(), [9, 11]);
    });
  });

  test('chaves estrangeiras estão ativas', () async {
    expect(
      () => db.into(db.contentNodes).insert(const ContentNodesCompanion(
            subjectId: Value(999),
            name: Value('órfão'),
          )),
      throwsA(anything),
    );
  });
}
