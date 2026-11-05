import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// ============================================================
/// ARQUIVO: lib/database/connection/connection_native.dart
/// FUNÇÃO: Abre o arquivo .sqlite no disco quando o app roda no
///         Android ou no Windows (qualquer plataforma "nativa").
///
/// POSSO ALTERAR:
///   - O nome do arquivo do banco ('ponto_study.sqlite').
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - A lógica de localização da pasta (getApplicationDocumentsDirectory).
///
/// DEPENDÊNCIAS:
///   - connection.dart (escolhe este arquivo quando NÃO é Web)
/// ============================================================
QueryExecutor createConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'ponto_study.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
