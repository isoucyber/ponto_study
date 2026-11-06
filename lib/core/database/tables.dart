import 'package:drift/drift.dart';

// ============================================================
// ARQUIVO: lib/core/database/tables.dart
// FUNÇÃO: Define a estrutura de TODAS as tabelas do banco local.
//
// POSSO ALTERAR: adicionar tabelas ou colunas novas.
// NÃO DEVO ALTERAR SEM ENTENDER: remover/renomear colunas existentes.
//   Isso exige uma migração em database.dart (schemaVersion + onUpgrade),
//   senão o app quebra para quem já tem dados salvos.
//
// REGRA DO PROJETO: guardamos apenas FATOS (o que aconteceu). Totais,
// médias, sequência de dias e progresso de metas são CALCULADOS na hora
// em lib/domain/, nunca salvos aqui.
// ============================================================

/// Perfil local (uma única linha). Não existe login.
@DataClassName('Profile')
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get objective => text().withDefault(const Constant(''))();
  TextColumn get avatar => text().withDefault(const Constant('🙂'))();
  IntColumn get dailyGoalMinutes =>
      integer().withDefault(const Constant(120))();
  IntColumn get weeklyGoalMinutes =>
      integer().withDefault(const Constant(600))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Configurações no formato chave -> valor (tema, cards ocultos...).
@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Matéria (ex.: Java, Python, ISO 27001).
@DataClassName('Subject')
class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get icon => text().withDefault(const Constant('📚'))();
  IntColumn get colorValue => integer()();
  // 0 = baixa, 1 = média, 2 = alta
  IntColumn get priority => integer().withDefault(const Constant(1))();
  // Meta de estudo semanal desta matéria, em minutos (0 = sem meta).
  IntColumn get weeklyGoalMinutes =>
      integer().withDefault(const Constant(0))();
  // "Excluir" uma matéria apenas arquiva (o histórico não se perde).
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Assuntos, tópicos e subtópicos ficam TODOS nesta tabela, em árvore.
/// parentId = null  -> item de primeiro nível (Assunto).
/// parentId = outro -> filho daquele item (Tópico, Subtópico...).
/// Assim a quantidade de níveis é livre.
@DataClassName('ContentNode')
class ContentNodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  IntColumn get parentId => integer()
      .nullable()
      .references(ContentNodes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get objective => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  // Links ou referências de materiais de apoio, um por linha.
  TextColumn get materials => text().withDefault(const Constant(''))();
  // 0 = fácil, 1 = intermediário, 2 = difícil
  IntColumn get difficulty => integer().withDefault(const Constant(1))();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  // Posição entre os "irmãos" (para reorganizar a ordem).
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Sessão de estudo (cronômetro ou registro manual).
///
/// O tempo NUNCA é contado pela tela: guardamos o horário de início e os
/// intervalos de pausa. O tempo estudado é sempre calculado a partir desses
/// horários, então minimizar ou fechar o app não perde nada.
@DataClassName('StudySession')
class StudySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer().references(Subjects, #id)();
  IntColumn get nodeId => integer()
      .nullable()
      .references(ContentNodes, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  // Preenchidos ao finalizar (tempo líquido estudado e tempo pausado).
  IntColumn get studySeconds => integer().withDefault(const Constant(0))();
  IntColumn get pausedSeconds => integer().withDefault(const Constant(0))();
  // Tempo planejado (quando a sessão nasceu de um planejamento).
  IntColumn get plannedSeconds => integer().nullable()();
  // 'running' | 'paused' | 'finished'
  TextColumn get status => text().withDefault(const Constant('finished'))();
  // 'timer' | 'manual'
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Cada pausa de uma sessão de cronômetro.
@DataClassName('SessionPause')
class SessionPauses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()
      .references(StudySessions, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
}

/// Atividade planejada. Concluir uma atividade NÃO gera horas estudadas:
/// horas só vêm de sessões reais.
@DataClassName('PlanItem')
class PlanItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Dia planejado (sempre meia-noite do dia local).
  DateTimeColumn get day => dateTime()();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  IntColumn get nodeId => integer()
      .nullable()
      .references(ContentNodes, #id, onDelete: KeyAction.setNull)();
  // Horário opcional, no formato "HH:MM".
  TextColumn get startTime => text().nullable()();
  IntColumn get durationMinutes => integer()();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
