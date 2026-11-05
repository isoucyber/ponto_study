import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// ============================================================
/// ARQUIVO: lib/database/connection/connection_web.dart
/// FUNÇÃO: Abre o banco SQLite quando o app roda no navegador
///         (Web), usando uma versão do SQLite compilada para WASM
///         que guarda os dados no IndexedDB do navegador.
///
/// ATENÇÃO - PASSO MANUAL NECESSÁRIO:
///   Este arquivo só funciona depois que os arquivos "sqlite3.wasm"
///   e "drift_worker.js" forem copiados para a pasta web/ do
///   projeto. Isso está explicado no README.md, seção "Rodando na
///   Web". Não foi possível copiar esses arquivos automaticamente
///   aqui porque eles exigem baixar pacotes com o Flutter SDK.
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - O nome "databaseName" (é o identificador do banco dentro do
///     navegador; trocar o nome cria um banco novo vazio).
///
/// DEPENDÊNCIAS:
///   - connection.dart (escolhe este arquivo quando é Web)
/// ============================================================
QueryExecutor createConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'ponto_study',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  }));
}
