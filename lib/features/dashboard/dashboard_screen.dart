import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/shell.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../domain/stats/study_stats.dart';
import '../settings/settings_controller.dart';
import '../subjects/subject_form.dart';
import '../timer/manual_session_screen.dart';

// ============================================================
// ARQUIVO: lib/features/dashboard/dashboard_screen.dart
// FUNÇÃO: Tela inicial. Resume o dia e a semana com base nos registros
//         reais. Os cards podem ser ocultados em "Personalizar".
// POSSO ALTERAR: a ordem dos cards dentro de _content().
// ============================================================

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageScaffold(
      title: 'Início',
      showBack: false,
      actions: [
        TextButton.icon(
          onPressed: () => _customize(context),
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: const Text('Personalizar'),
        ),
        const SizedBox(width: 8),
      ],
      body: ListenableBuilder(
        listenable: app.settings,
        builder: (context, _) => StreamBuilder<List<Subject>>(
          stream: app.subjects.watchActive(),
          builder: (context, subjectSnap) {
            final subjects = subjectSnap.data ?? const <Subject>[];
            return StreamBuilder<List<StudySession>>(
              stream: app.sessions.watchFinished(),
              builder: (context, sessionSnap) {
                final sessions = sessionSnap.data ?? const <StudySession>[];
                return StreamBuilder<List<ContentNode>>(
                  stream: app.subjects.watchAllNodes(),
                  builder: (context, nodeSnap) {
                    final today = dayOf(DateTime.now());
                    return StreamBuilder<List<PlanItem>>(
                      stream: app.plans.watchRange(
                          today, today.add(const Duration(days: 1))),
                      builder: (context, planSnap) => _content(
                        context,
                        subjects: subjects,
                        sessions: sessions,
                        nodeCount: (nodeSnap.data ?? const []).length,
                        planToday: planSnap.data ?? const <PlanItem>[],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context, {
    required List<Subject> subjects,
    required List<StudySession> sessions,
    required int nodeCount,
    required List<PlanItem> planToday,
  }) {
    final app = AppScope.of(context);
    final settings = app.settings;
    final profile = settings.profile;
    final pal = pontoOf(context).palette;
    final now = DateTime.now();
    final facts = [
      for (final s in sessions)
        StudyFact(
            startedAt: s.startedAt,
            seconds: s.studySeconds,
            subjectId: s.subjectId,
            nodeId: s.nodeId)
    ];
    final today = dayOf(now);
    final todaySec =
        secondsBetween(facts, today, today.add(const Duration(days: 1)));
    final weekStart = startOfWeek(now);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekSec = secondsBetween(facts, weekStart, weekEnd);
    final streak = studyStreak(facts, now);
    final dailyGoal = profile?.dailyGoalMinutes ?? 0;
    final weeklyGoal = profile?.weeklyGoalMinutes ?? 0;
    final subjectById = {for (final s in subjects) s.id: s};
    bool show(String id) => settings.isCardVisible(id);

    final hour = now.hour;
    final greeting = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';

    final stats = <Widget>[
      if (show(DashboardCards.today))
        StatTile(
          label: 'Hoje',
          value: formatDuration(todaySec),
          icon: Icons.today_outlined,
          caption: dailyGoal > 0
              ? 'meta diária ${formatDuration(dailyGoal * 60)}'
              : 'sem meta diária',
          progress: dailyGoal > 0 ? goalProgress(todaySec, dailyGoal) : null,
        ),
      if (show(DashboardCards.week))
        StatTile(
          label: 'Esta semana',
          value: formatDuration(weekSec),
          icon: Icons.date_range_outlined,
          caption: weeklyGoal > 0
              ? 'meta semanal ${formatDuration(weeklyGoal * 60)}'
              : 'sem meta semanal',
          progress: weeklyGoal > 0 ? goalProgress(weekSec, weeklyGoal) : null,
        ),
      if (show(DashboardCards.streak))
        StatTile(
          label: 'Sequência',
          value: '$streak ${streak == 1 ? 'dia' : 'dias'}',
          icon: Icons.local_fire_department_outlined,
          caption: todaySec >= 60
              ? 'você já estudou hoje'
              : 'estude hoje para manter',
        ),
      if (show(DashboardCards.subjects))
        StatTile(
          label: 'Matérias',
          value: '${subjects.length}',
          icon: Icons.account_tree_outlined,
          caption: '$nodeCount assuntos e tópicos',
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('$greeting, ${profile?.name ?? ''}',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(formatLongDate(now), style: TextStyle(color: pal.textMuted)),
              const SizedBox(height: 16),
              _ActiveBanner(subjects: subjectById),
              if (subjects.isEmpty) ...[
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Comece cadastrando uma matéria',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Depois organize assuntos e tópicos, use o cronômetro '
                        'e planeje a semana.',
                        style: TextStyle(color: pal.textMuted),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => openSubjectForm(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Criar matéria'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (stats.isNotEmpty) ...[
                ResponsiveGrid(minItemWidth: 210, children: stats),
                const SizedBox(height: 16),
              ],
              Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton.icon(
                  onPressed: () => goToTab(context, ShellTab.timer),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Estudar agora'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ManualSessionScreen())),
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('Registrar estudo'),
                ),
                OutlinedButton.icon(
                  onPressed: () => goToTab(context, ShellTab.planning),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Planejar semana'),
                ),
              ]),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, c) {
                final left = <Widget>[
                  if (show(DashboardCards.plannedToday))
                    _PlannedToday(items: planToday, subjects: subjectById),
                  if (show(DashboardCards.subjectsWeek))
                    _SubjectsWeek(
                      subjects: subjects,
                      perSubject: secondsPerSubject(facts, weekStart, weekEnd),
                    ),
                ];
                final right = <Widget>[
                  if (show(DashboardCards.recentSessions))
                    _RecentSessions(
                        sessions: sessions.take(6).toList(),
                        subjects: subjectById),
                ];
                Widget column(List<Widget> items) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final w in items) ...[w, const SizedBox(height: 16)],
                      ],
                    );
                if (c.maxWidth >= 760) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: column(left)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: column(right)),
                    ],
                  );
                }
                return column([...left, ...right]);
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _customize(BuildContext context) {
    final settings = AppScope.of(context).settings;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => ListenableBuilder(
        listenable: settings,
        builder: (context, _) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Escolha o que aparece no Início'),
              ),
              for (final e in DashboardCards.all.entries)
                SwitchListTile(
                  title: Text(e.value),
                  value: settings.isCardVisible(e.key),
                  onChanged: (v) => settings.setCardVisible(e.key, v),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  final Map<int, Subject> subjects;
  const _ActiveBanner({required this.subjects});

  @override
  Widget build(BuildContext context) {
    final timer = AppScope.of(context).timer;
    final pal = pontoOf(context).palette;
    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) {
        final s = timer.active;
        if (s == null) return const SizedBox.shrink();
        final subject = subjects[s.subjectId];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: pal.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(pontoOf(context).spec.radius),
            child: ListTile(
              onTap: () => goToTab(context, ShellTab.timer),
              leading: Icon(
                  timer.isPaused ? Icons.pause_circle : Icons.timer,
                  color: pal.primary),
              title: Text(
                  '${timer.isPaused ? 'Sessão pausada' : 'Estudando agora'}'
                  '${subject != null ? ': ${subject.name}' : ''}'),
              subtitle: Text(formatClock(timer.studySeconds)),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        );
      },
    );
  }
}

class _PlannedToday extends StatelessWidget {
  final List<PlanItem> items;
  final Map<int, Subject> subjects;
  const _PlannedToday({required this.items, required this.subjects});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = pontoOf(context).palette;
    return SectionCard(
      title: 'Planejado para hoje',
      trailing: TextButton(
        onPressed: () => goToTab(context, ShellTab.planning),
        child: const Text('Ver semana'),
      ),
      child: items.isEmpty
          ? Text('Nenhuma atividade planejada para hoje.',
              style: TextStyle(color: pal.textMuted))
          : Column(
              children: [
                for (final i in items)
                  Row(children: [
                    Checkbox(
                      value: i.done,
                      onChanged: (v) => app.plans.setDone(i.id, v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        '${i.startTime ?? ''} ${subjects[i.subjectId]?.name ?? ''}'
                        ' — ${formatDuration(i.durationMinutes * 60)}',
                        style: TextStyle(
                          decoration:
                              i.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ]),
              ],
            ),
    );
  }
}

class _SubjectsWeek extends StatelessWidget {
  final List<Subject> subjects;
  final Map<int, int> perSubject;
  const _SubjectsWeek({required this.subjects, required this.perSubject});

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    final rows = subjects.where((s) => (perSubject[s.id] ?? 0) > 0).toList()
      ..sort((a, b) => (perSubject[b.id] ?? 0).compareTo(perSubject[a.id] ?? 0));
    final max = rows.isEmpty ? 1 : (perSubject[rows.first.id] ?? 1);
    return SectionCard(
      title: 'Matérias na semana',
      child: rows.isEmpty
          ? Text('Nenhum estudo registrado nesta semana.',
              style: TextStyle(color: pal.textMuted))
          : Column(
              children: [
                for (final s in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      SizedBox(
                        width: 140,
                        child: Text('${s.icon} ${s.name}',
                            overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        child: ProgressLine(
                          value: (perSubject[s.id] ?? 0) / max,
                          color: Color(s.colorValue),
                          height: 10,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 72,
                        child: Text(formatDuration(perSubject[s.id] ?? 0),
                            textAlign: TextAlign.right),
                      ),
                    ]),
                  ),
              ],
            ),
    );
  }
}

class _RecentSessions extends StatelessWidget {
  final List<StudySession> sessions;
  final Map<int, Subject> subjects;
  const _RecentSessions({required this.sessions, required this.subjects});

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    final now = DateTime.now();
    return SectionCard(
      title: 'Últimas sessões',
      trailing: TextButton(
        onPressed: () => goToTab(context, ShellTab.history),
        child: const Text('Histórico'),
      ),
      child: sessions.isEmpty
          ? Text('Suas sessões aparecerão aqui.',
              style: TextStyle(color: pal.textMuted))
          : Column(
              children: [
                for (final s in sessions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Text(subjects[s.subjectId]?.icon ?? '📚'),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subjects[s.subjectId]?.name ?? 'Matéria arquivada',
                                overflow: TextOverflow.ellipsis),
                            Text(
                              '${formatRelativeDay(s.startedAt, now)} · ${formatTime(s.startedAt)}',
                              style: TextStyle(color: pal.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(formatDuration(s.studySeconds),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ],
            ),
    );
  }
}
