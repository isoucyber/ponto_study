import 'package:flutter/material.dart';

import '../../services/subject_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/subject_card.dart';
import 'add_edit_subject_screen.dart';

/// ============================================================
/// ARQUIVO: lib/screens/subjects/subjects_screen.dart
/// FUNÇÃO: Lista todas as matérias cadastradas, com botão para
///         adicionar uma nova e opção de editar/excluir.
///
/// POSSO ALTERAR:
///   - Layout da lista, textos, ordenação visual.
///
/// DEPENDÊNCIAS:
///   - services/subject_service.dart
///   - screens/subjects/add_edit_subject_screen.dart
/// ============================================================
class SubjectsScreen extends StatelessWidget {
  final SubjectService subjectService;

  const SubjectsScreen({super.key, required this.subjectService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas matérias')),
      body: StreamBuilder<List<SubjectProgress>>(
        stream: subjectService.watchAllWithProgress(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              message:
                  'Nenhuma matéria cadastrada ainda.\nToque no + para adicionar a primeira.',
              icon: Icons.menu_book_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final progress = items[index];
              return SubjectCard(
                progress: progress,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AddEditSubjectScreen(
                      subjectService: subjectService,
                      existing: progress.subject,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                AddEditSubjectScreen(subjectService: subjectService),
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
