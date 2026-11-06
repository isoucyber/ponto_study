import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../domain/stats/study_stats.dart';
import '../subjects/content_tree.dart';
import '../timer/manual_session_screen.dart';

// ============================================================
// ARQUIVO: lib/features/history/history_screen.dart
// FUNÇÃO: Histórico de todas as sessões concluídas, agrupadas por dia,
//         com filtro por matéria, edição e exclusão.
// ============================================================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? _subjectFilter;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageScaffold(
      title: 'Histórico',
      showBack: false,
      body: StreamBuilder<List<Subject>>(
        stream: app.subjects.watchAll(),
        builder: (context, subjectSnap) {
          final subjects = subjectSnap.data ?? const <Subject>[];
          final byId = {for (final s in subjects) s.id: s};
          return StreamBuilder<List<ContentNode>>(
            stream: app.subjects.watchAllNodes(),
            builder: (context, nodeSnap) {
              final nodes = nodeSnap.data ?? const <ContentNode>[];
              return StreamBuilder<List<StudySession>>(
                stream: app.sessions.watchFinished(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final sessions = snap.data!
                      .where((s) =>
                          _subjectFilter == null ||
                          s.subjectId == _subjectFilter)
                      .toList();
                  final groups = <DateTime, List<StudySession>>{};
                  for (final s in sessions) {
                    groups.putIfAbsent(dayOf(s.startedAt), () => []).add(s);
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      ContentWidth(
                        maxWidth: 820,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<int?>(
                              initialValue: _subjectFilter,
                              decoration: const InputDecoration(
                                  labelText: 'Filtrar por matéria'),
                              items: [
                                const DropdownMenuItem<int?>(
                                    value: null, child: Text('Todas')),
                                for (final s in subjects)
                                  DropdownMenuItem<int?>(
                                      value: s.id,
                                      child: Text('${s.icon}  ${s.name}')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _subjectFilter = v),
                            ),
                            const SizedBox(height: 16),
                            if (sessions.isEmpty)
                              const EmptyState(
                                icon: Icons.history,
                                title: 'Nenhuma sessão registrada',
                                message:
                                    'Use o cronômetro ou o registro manual. '
                                    'Todas as sessões aparecem aqui.',
                              ),
                            for (final entry in groups.entries) ...[
                              _DayHeader(
                                day: entry.key,
                                seconds: entry.value
                                    .fold<int>(0, (a, s) => a + s.studySeconds),
                              ),
                              Card(
                                child: Column(children: [
                                  for (final s in entry.value)
                                    _SessionTile(
                                      session: s,
                                      subject: byId[s.subjectId],
                                      path: s.nodeId == null
                                          ? null
                                          : nodePath(nodes, s.nodeId!),
                                    ),
                                ]),
                              ),
                              const SizedBox(height: 14),
                            ],
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

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final int seconds;
  const _DayHeader({required this.day, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(children: [
        Text(
          '${formatRelativeDay(day, DateTime.now())} · ${weekdayNames[day.weekday - 1]}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(formatDuration(seconds), style: TextStyle(color: pal.textMuted)),
      ]),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final StudySession session;
  final Subject? subject;
  final String? path;
  const _SessionTile({required this.session, this.subject, this.path});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = pontoOf(context).palette;
    final s = session;
    final end = s.endedAt;
    return ListTile(
      leading: subject == null
          ? const Icon(Icons.help_outline)
          : SubjectBadge(icon: subject!.icon, colorValue: subject!.colorValue),
      title: Text(subject?.name ?? 'Matéria removida'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (path != null && path!.isNotEmpty) Text(path!),
          Text(
            '${formatTime(s.startedAt)}${end != null ? '–${formatTime(end)}' : ''}'
            ' · ${s.source == 'timer' ? 'cronômetro' : 'manual'}'
            '${s.pausedSeconds > 0 ? ' · pausas ${formatDuration(s.pausedSeconds)}' : ''}',
            style: TextStyle(color: pal.textMuted, fontSize: 12.5),
          ),
          if (s.notes.isNotEmpty)
            Text(s.notes, style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
        ],
      ),
      isThreeLine: s.notes.isNotEmpty || (path?.isNotEmpty ?? false),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(formatDuration(s.studySeconds),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ManualSessionScreen(editing: s)));
            } else if (v == 'delete') {
              final ok = await confirmDialog(
                context,
                title: 'Excluir sessão?',
                message:
                    '${formatDuration(s.studySeconds)} de ${subject?.name ?? 'estudo'} '
                    'serão removidos do histórico e dos relatórios.',
                confirmLabel: 'Excluir',
                destructive: true,
              );
              if (ok) await app.sessions.delete(s.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ]),
    );
  }
}
