import 'package:flutter/material.dart';

import 'database/database.dart';
import 'repositories/study_session_repository.dart';
import 'repositories/subject_repository.dart';
import 'screens/root/root_screen.dart';
import 'services/study_service.dart';
import 'services/subject_service.dart';
import 'theme/app_theme.dart';

/// ============================================================
/// ARQUIVO: lib/main.dart
/// FUNÇÃO: Ponto de entrada do aplicativo. Cria o banco de dados
///         UMA vez, monta os repositórios e serviços, e inicia o
///         MaterialApp com o tema claro/escuro.
///
/// POSSO ALTERAR:
///   - O título do app (parâmetro "title" do MaterialApp).
///   - themeMode inicial (ThemeMode.system troca sozinho com o SO).
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - A ordem de criação (database -> repository -> service) não
///     deve ser invertida, pois cada camada depende da anterior.
///
/// DEPENDÊNCIAS: todo o resto do app depende, direta ou
/// indiretamente, deste arquivo ser executado primeiro.
/// ============================================================
void main() {
  final database = AppDatabase();

  final subjectService = SubjectService(SubjectRepository(database));
  final studyService = StudyService(StudySessionRepository(database));

  runApp(PontoStudyApp(
    subjectService: subjectService,
    studyService: studyService,
  ));
}

class PontoStudyApp extends StatelessWidget {
  final SubjectService subjectService;
  final StudyService studyService;

  const PontoStudyApp({
    super.key,
    required this.subjectService,
    required this.studyService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ponto Study',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: RootScreen(
        subjectService: subjectService,
        studyService: studyService,
      ),
    );
  }
}
