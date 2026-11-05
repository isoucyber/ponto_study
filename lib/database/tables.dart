import 'package:drift/drift.dart';

/// ============================================================
/// ARQUIVO: lib/database/tables.dart
/// FUNÇÃO: Define a ESTRUTURA das tabelas do banco de dados.
///         É aqui (e só aqui) que ficam definidas as colunas que
///         existem no banco.
///
/// POSSO ALTERAR:
///   - Adicionar uma nova coluna a uma tabela existente, ou criar
///     uma nova tabela inteira (classe nova estendendo Table).
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - Remover ou renomear uma coluna que já existe. Isso quebra o
///     banco de quem já usa o app, porque os dados salvos ficam
///     "órfãos". Se precisar mudar algo assim, é preciso escrever
///     uma migration em database.dart (explico lá).
///
/// DEPENDÊNCIAS:
///   - database.dart (usa essas tabelas para gerar o banco)
///   - repositories/ (fazem as consultas usando essas colunas)
///
/// IMPORTANTE: depois de alterar este arquivo, é necessário rodar:
///   dart run build_runner build
/// para o Drift regenerar o arquivo database.g.dart.
/// ============================================================

/// Tabela de matérias (ex: Python, Java, LPA...)
class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 60)();

  // Meta de horas guardada em MINUTOS (facilita soma e evita
  // problemas de arredondamento com horas fracionadas).
  IntColumn get targetMinutes => integer()();

  // Cor guardada como o valor inteiro de Color (color.value).
  IntColumn get colorValue => integer()();

  // Ícone guardado como um emoji simples (ex: "🐍"). Isso evita
  // depender de pacotes de ícones extras nesta primeira versão.
  TextColumn get icon => text().withDefault(const Constant('📚'))();

  // 0 = baixa, 1 = normal, 2 = alta
  IntColumn get priority => integer().withDefault(const Constant(1))();

  // ARQUIVAMENTO (soft delete): "excluir" uma matéria não apaga a
  // linha do banco, só marca archived = true. A matéria some das
  // listas ativas (telas de matérias e dashboard), mas o histórico
  // de sessões continua intacto e consultável. Isso evita perder
  // dados por engano ao excluir algo que tem sessões registradas.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  // Atualizado toda vez que a matéria é editada. Usado só para
  // referência/depuração; nenhuma regra de negócio depende dele hoje.
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Tabela de sessões de estudo registradas (o "histórico").
class StudySessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Referência à matéria estudada. SEM cascade: se a matéria for
  // arquivada, as sessões continuam no banco normalmente (ela só
  // deixa de aparecer nas listas ativas). O cascade foi removido
  // porque, com soft delete, a exclusão "de verdade" (DELETE no
  // banco) não deve mais acontecer no fluxo normal do app.
  IntColumn get subjectId => integer().references(Subjects, #id)();

  DateTimeColumn get date => dateTime()();

  IntColumn get durationMinutes => integer()();

  TextColumn get content => text().withDefault(const Constant(''))();

  TextColumn get notes => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
