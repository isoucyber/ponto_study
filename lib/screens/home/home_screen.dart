import 'package:flutter/material.dart';

import '../../services/study_service.dart';
import '../../services/subject_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/duration_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/subject_card.dart';
import '../study/register_study_screen.dart';

/// ============================================================
/// ARQUIVO: lib/screens/home/home_screen.dart
/// FUNÇÃO: Tela inicial (Dashboard). Mostra horas de hoje, da
///         semana e a lista de matérias com progresso.
///
/// POSSO ALTERAR:
///   - Textos, layout dos cards, ordem das seções.
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - As chamadas a subjectService/studyService (é daqui que vêm
///     os números corretos).
///
/// DEPENDÊNCIAS:
///   - services/subject_service.dart, services/study_service.dart
///   - widgets/stat_card.dart, widgets/subject_card.dart
/// ============================================================
class HomeScreen extends StatelessWidget {
  final SubjectService subjectService;
  final StudyService studyService;

  const HomeScreen({
    super.key,
    required this.subjectService,
    required this.studyService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Olá! 👋', style: AppTextStyles.title),
            const SizedBox(height: 4),
            const Text('Bom estudo hoje.', style: AppTextStyles.body),
            const SizedBox(height: 20),

            // --- Cards de estatística (hoje / semana) ---
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  StreamBuilder<int>(
                    stream: studyService.watchTotalMinutesToday(),
                    builder: (context, snapshot) => StatCard(
                      label: 'Hoje',
                      value: DurationUtils.formatMinutes(snapshot.data ?? 0),
                      icon: Icons.today,
                      color: AppColors.primary,
                    ),
                  ),
                  StreamBuilder<int>(
                    stream: studyService.watchTotalMinutesThisWeek(),
                    builder: (context, snapshot) => StatCard(
                      label: 'Esta semana',
                      value: DurationUtils.formatMinutes(snapshot.data ?? 0),
                      icon: Icons.calendar_view_week,
                      color: AppColors.success,
                    ),
                  ),
                  StreamBuilder<List<dynamic>>(
                    stream: subjectService.watchAllSubjects(),
                    builder: (context, snapshot) => StatCard(
                      label: 'Matérias',
                      value: '${snapshot.data?.length ?? 0}',
                      icon: Icons.menu_book,
                      color: AppColors.warning,
                    ),
                  ),
                  StreamBuilder<List<SubjectProgress>>(
                    stream: subjectService.watchAllWithProgress(),
                    builder: (context, snapshot) {
                      final completed = (snapshot.data ?? [])
                          .where((p) => p.isCompleted)
                          .length;
                      return StatCard(
                        label: 'Metas batidas',
                        value: '$completed',
                        icon: Icons.emoji_events,
                        color: AppColors.danger,
                      );
                    },
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),
            const Text('Minhas matérias', style: AppTextStyles.subtitle),
            const SizedBox(height: 12),

            StreamBuilder<List<SubjectProgress>>(
              stream: subjectService.watchAllWithProgress(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const EmptyState(
                    message:
                        'Você ainda não tem matérias cadastradas.\n'
                        'Vá até "Matérias" para adicionar a primeira.',
                    icon: Icons.menu_book_outlined,
                  );
                }
                return LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  return GridView.count(
                    crossAxisCount: isWide ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.6,
                    children: items
                        .map((p) => SubjectCard(progress: p))
                        .toList(),
                  );
                });
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RegisterStudyScreen(
              subjectService: subjectService,
              studyService: studyService,
            ),
          ));
        },
        icon: const Icon(Icons.add),
        label: const Text('Registrar estudo'),
      ),
    );
  }
}
