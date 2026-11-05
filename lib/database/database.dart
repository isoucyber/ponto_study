import 'package:drift/drift.dart';
import 'connection/connection.dart';
import 'tables.dart';

part 'database.g.dart';

/// Erro "amigável" de banco de dados: qualquer falha ao ler ou
/// gravar vira uma mensagem em português que a tela pode mostrar
/// direto num SnackBar, sem expor a exceção técnica original ao
/// usuário (ela ainda fica disponível em [cause], para debug).
class DatabaseFailure implements Exception {
  final String message;
  final Object cause;

  DatabaseFailure(this.message, this.cause);

  @override
  String toString() => message;
}

/// ============================================================
/// ARQUIVO: lib/database/database.dart
/// FUNÇÃO: Classe principal do banco de dados. Reúne as tabelas
///         (Subjects, StudySessions) e define as consultas SQL
///         que o resto do app usa.
///
/// POSSO ALTERAR:
///   - Adicionar novos métodos de consulta (novas funções nesta
///     classe), seguindo o padrão dos que já existem.
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - "schemaVersion" e "migration": controlam a evolução do
///     banco. Se você adicionar uma coluna nova em tables.dart no
///     futuro, precisa: (1) aumentar schemaVersion em +1 e (2)
///     adicionar um "onUpgrade" dentro de "migration" descrevendo
///     como migrar dados antigos (ex: m.addColumn(subjects, subjects.novaColuna)).
///     Sem isso, o app quebra para quem já tem dados salvos.
///     Como o app ainda não foi publicado para ninguém, a versão
///     atual continua sendo 1 — mas a estrutura abaixo já está
///     pronta para quando a versão 2 existir.
///
/// DEPENDÊNCIAS:
///   - repositories/ (usam AppDatabase para ler/escrever dados)
///
/// LEMBRETE: sempre que este arquivo ou tables.dart for alterado,
/// rode:  dart run build_runner build
/// Isso gera (ou atualiza) o arquivo database.g.dart automaticamente.
/// Você NUNCA deve editar database.g.dart manualmente.
/// ============================================================
@DriftDatabase(tables: [Subjects, StudySessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(connect());

  /// Construtor usado SÓ pelos testes automatizados (pasta test/),
  /// para abrir o banco num executor específico (ex: em memória,
  /// sem gravar nada em disco). O app de verdade sempre usa o
  /// construtor de cima, AppDatabase(), que conecta no arquivo real.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        // Modelo para quando schemaVersion virar 2, 3, etc.
        // Exemplo (não executa hoje, é só referência):
        //
        // onUpgrade: (m, from, to) async {
        //   if (from < 2) {
        //     await m.addColumn(subjects, subjects.algumaColunaNova);
        //   }
        // },
        beforeOpen: (details) async {
          // Garante que chaves estrangeiras (subjectId -> Subjects)
          // sejam realmente verificadas pelo SQLite.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Envolve qualquer operação de banco e traduz falhas técnicas
  /// em uma mensagem amigável em português. Usado por todos os
  /// métodos abaixo para que a UI nunca receba uma exceção "crua".
  Future<T> _guard<T>(String friendlyMessage, Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw DatabaseFailure(friendlyMessage, e);
    }
  }

  // ---------- MATÉRIAS ----------

  /// Stream = "fluxo" de dados que atualiza automaticamente a tela
  /// sempre que uma matéria for adicionada, editada, arquivada ou
  /// desarquivada. Só traz matérias ATIVAS (archived = false).
  Stream<List<Subject>> watchAllSubjects() {
    return (select(subjects)
          ..where((s) => s.archived.equals(false))
          ..orderBy([(s) => OrderingTerm.desc(s.priority)]))
        .watch();
  }

  Future<int> insertSubject(SubjectsCompanion subject) {
    return _guard('Não foi possível salvar a matéria.', () {
      return into(subjects).insert(subject);
    });
  }

  Future<bool> updateSubject(Subject subject) {
    return _guard('Não foi possível atualizar a matéria.', () {
      return update(subjects).replace(
        subject.copyWith(updatedAt: DateTime.now()),
      );
    });
  }

  /// "Excluir" uma matéria, na prática, apenas a marca como
  /// arquivada (archived = true). O histórico de sessões dela
  /// continua intacto no banco — veja a explicação completa em
  /// tables.dart, no comentário da coluna "archived".
  Future<int> archiveSubject(int id) {
    return _guard('Não foi possível excluir a matéria.', () {
      return (update(subjects)..where((s) => s.id.equals(id))).write(
        SubjectsCompanion(
          archived: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Conta quantas sessões e quantos minutos uma matéria já tem
  /// registrados. Usado pela tela de confirmação de exclusão, para
  /// avisar exatamente quanto de histórico está em jogo.
  Future<({int sessionCount, int totalMinutes})> getSubjectUsage(
      int subjectId) {
    return _guard('Não foi possível consultar o histórico da matéria.',
        () async {
      final totalMinutes = studySessions.durationMinutes.sum();
      final sessionCount = studySessions.id.count();
      final query = selectOnly(studySessions)
        ..addColumns([totalMinutes, sessionCount])
        ..where(studySessions.subjectId.equals(subjectId));
      final row = await query.getSingle();
      return (
        sessionCount: row.read(sessionCount) ?? 0,
        totalMinutes: row.read(totalMinutes) ?? 0,
      );
    });
  }

  // ---------- SESSÕES DE ESTUDO ----------

  Stream<List<StudySession>> watchSessionsOfSubject(int subjectId) {
    return (select(studySessions)
          ..where((s) => s.subjectId.equals(subjectId))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  Stream<List<StudySession>> watchAllSessions() {
    return (select(studySessions)
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  Future<int> insertSession(StudySessionsCompanion session) {
    return _guard('Não foi possível registrar a sessão de estudo.', () {
      return into(studySessions).insert(session);
    });
  }

  Future<int> deleteSession(int id) {
    return _guard('Não foi possível excluir a sessão.', () {
      return (delete(studySessions)..where((s) => s.id.equals(id))).go();
    });
  }

  /// Soma o total de minutos estudados de UMA matéria. É essa
  /// consulta que garante que o progresso é sempre calculado a
  /// partir das sessões reais, nunca um número "guardado à parte"
  /// que poderia ficar desatualizado.
  Stream<int> watchTotalMinutesForSubject(int subjectId) {
    final totalMinutes = studySessions.durationMinutes.sum();
    final query = selectOnly(studySessions)
      ..addColumns([totalMinutes])
      ..where(studySessions.subjectId.equals(subjectId));
    return query.map((row) => row.read(totalMinutes) ?? 0).watchSingle();
  }

  /// Soma total de minutos estudados HOJE, considerando todas as
  /// matérias. Usado no dashboard.
  Stream<int> watchTotalMinutesToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final totalMinutes = studySessions.durationMinutes.sum();
    final query = selectOnly(studySessions)
      ..addColumns([totalMinutes])
      ..where(studySessions.date.isBiggerOrEqualValue(startOfDay) &
          studySessions.date.isSmallerThanValue(endOfDay));
    return query.map((row) => row.read(totalMinutes) ?? 0).watchSingle();
  }

  /// Soma total de minutos estudados NESTA SEMANA (segunda a domingo).
  Stream<int> watchTotalMinutesThisWeek() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek =
        startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final totalMinutes = studySessions.durationMinutes.sum();
    final query = selectOnly(studySessions)
      ..addColumns([totalMinutes])
      ..where(studySessions.date.isBiggerOrEqualValue(startOfWeek) &
          studySessions.date.isSmallerThanValue(endOfWeek));
    return query.map((row) => row.read(totalMinutes) ?? 0).watchSingle();
  }
}
