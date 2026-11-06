import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../domain/stats/study_stats.dart';
import 'subject_detail_screen.dart';
import 'subject_form.dart';

// ============================================================
// ARQUIVO: lib/features/subjects/subjects_screen.dart
// FUNÇÃO: Lista das matérias ativas, com tempo da semana, meta semanal
//         e quantidade de assuntos. Também dá acesso às arquivadas.
// ============================================================

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageScaffold(
      title: 'Matérias',
      showBack: false,
      actions: [
        IconButton(
          tooltip: 'Matérias arquivadas',
          icon: const Icon(Icons.inventory_2_outlined),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ArchivedSubjectsScreen())),
        ),
        const SizedBox(width: 8),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openSubjectForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova matéria'),
      ),
      body: StreamBuilder<List<Subject>>(
        stream: app.subjects.watchActive(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final subjects = snap.data!;
          if (subjects.isEmpty) {
            return EmptyState(
              icon: Icons.account_tree_outlined,
              title: 'Nenhuma matéria ainda',
              message:
                  'Crie sua primeira matéria (ex.: Java) e depois organize '
                  'assuntos, tópicos e subtópicos dentro dela.',
              actionLabel: 'Criar matéria',
              onAction: () => openSubjectForm(context),
            );
          }
          return StreamBuilder<List<StudyFact>>(
            stream: app.sessions.watchFacts(),
            builder: (context, factSnap) {
              final facts = factSnap.data ?? const <StudyFact>[];
              return StreamBuilder<List<ContentNode>>(
                stream: app.subjects.watchAllNodes(),
                builder: (context, nodeSnap) {
                  final nodes = nodeSnap.data ?? const <ContentNode>[];
                  final weekStart = startOfWeek(DateTime.now());
                  final weekEnd = weekStart.add(const Duration(days: 7));
                  final perSubject =
                      secondsPerSubject(facts, weekStart, weekEnd);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      ContentWidth(
                        child: ResponsiveGrid(
                          minItemWidth: 320,
                          children: [
                            for (final s in subjects)
                              _SubjectCard(
                                subject: s,
                                weekSeconds: perSubject[s.id] ?? 0,
                                nodeCount: nodes
                                    .where((n) => n.subjectId == s.id)
                                    .length,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final int weekSeconds;
  final int nodeCount;

  const _SubjectCard({
    required this.subject,
    required this.weekSeconds,
    required this.nodeCount,
  });

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    final goal = subject.weeklyGoalMinutes;
    return SectionCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SubjectDetailScreen(subjectId: subject.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SubjectBadge(icon: subject.icon, colorValue: subject.colorValue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '$nodeCount ${nodeCount == 1 ? 'item' : 'itens'} · '
                      'prioridade ${priorityNames[subject.priority].toLowerCase()}',
                      style: TextStyle(color: pal.textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: pal.textMuted),
            ],
          ),
          if (subject.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(subject.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: pal.textMuted)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Semana: ${formatDuration(weekSeconds)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (goal > 0)
                Text('meta ${formatDuration(goal * 60)}',
                    style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
            ],
          ),
          if (goal > 0) ...[
            const SizedBox(height: 8),
            ProgressLine(
              value: goalProgress(weekSeconds, goal),
              color: Color(subject.colorValue),
            ),
          ],
        ],
      ),
    );
  }
}

/// Matérias arquivadas: podem ser restauradas ou excluídas de vez.
class ArchivedSubjectsScreen extends StatelessWidget {
  const ArchivedSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageScaffold(
      title: 'Matérias arquivadas',
      body: StreamBuilder<List<Subject>>(
        stream: app.subjects.watchArchived(),
        builder: (context, snap) {
          final list = snap.data ?? const <Subject>[];
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nada arquivado',
              message:
                  'Matérias arquivadas somem das listas, mas o histórico '
                  'delas é mantido e elas podem ser restauradas aqui.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final s in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    child: Row(children: [
                      SubjectBadge(icon: s.icon, colorValue: s.colorValue),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s.name)),
                      TextButton(
                        onPressed: () => app.subjects.setArchived(s.id, false),
                        child: const Text('Restaurar'),
                      ),
                      IconButton(
                        tooltip: 'Excluir definitivamente',
                        icon: const Icon(Icons.delete_forever_outlined),
                        onPressed: () async {
                          final usage = await app.subjects.usage(s.id);
                          if (!context.mounted) return;
                          final ok = await confirmDialog(
                            context,
                            title: 'Excluir "${s.name}" para sempre?',
                            message:
                                'Serão apagados ${usage.nodes} itens de conteúdo, '
                                '${usage.sessions} sessões '
                                '(${formatDuration(usage.seconds)}) e os planejamentos '
                                'desta matéria. Esta ação não pode ser desfeita.',
                            confirmLabel: 'Excluir',
                            destructive: true,
                          );
                          if (ok) await app.subjects.deletePermanently(s.id);
                        },
                      ),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
