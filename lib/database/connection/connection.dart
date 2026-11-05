import 'package:drift/drift.dart';

import 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart' as impl;

/// ============================================================
/// ARQUIVO: lib/database/connection/connection.dart
/// FUNÇÃO: Decide automaticamente, em tempo de COMPILAÇÃO, qual
///         arquivo de conexão usar:
///           - Se está compilando para Web  -> connection_web.dart
///           - Se está compilando para outra plataforma
///             (Android/Windows/Linux/macOS) -> connection_native.dart
///
///         Essa troca acontece sozinha, você não precisa fazer
///         nada manualmente ao mudar de plataforma.
///
/// NÃO DEVO ALTERAR:
///   - Este arquivo raramente precisa ser tocado. Se quiser mudar
///     COMO o banco é aberto, altere connection_native.dart ou
///     connection_web.dart, não este.
///
/// DEPENDÊNCIAS:
///   - database.dart (chama connect() para abrir o banco)
/// ============================================================
QueryExecutor connect() => impl.createConnection();
