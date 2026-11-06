import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/shell.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/subject_node_picker.dart';
import '../../domain/stats/study_stats.dart';
import '../subjects/content_tree.dart';

// ============================================================
// ARQUIVO: lib/features/planning/planning_screen.dart
// FUNÇÃO: Planejamento semanal. Mostra o que foi PLANEJADO e, ao lado,
//         quanto foi REALMENTE estudado em cada dia (sessões reais).
//         Marcar uma atividade como concluída não cria horas.
// ============================================================

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  DateTime _week = startOfWeek(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final end = _week.add(const Duration(days: 7));
    final last = end.subtract(const Duration(days: 1));
    return PageScaffold(
      title: 'Planejamento',
      showBack: false,
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'copy') {
              final n = await app.plans.copyWeekToNext(_week);
              if (context.mounted) {
                showSnack(context,
                    '$n atividades copiadas para a semana seguinte.');
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
                value: 'copy', child: Text('Copiar semana para a próxima')),
          ],
        ),
        const SizedBox(width: 4),
      ],
      body: StreamBuilder<List<Subject>>(
        stream: app.subjects.watchAll(),
        builder: (context, subjectSnap) {
          final subjects = {
            for (final s in subjectSnap.data ?? const <Subject>[]) s.id: s
          };
          return StreamBuilder<List<ContentNode>>(
            stream: app.subjects.watchAllNodes(),
            builder: (context, nodeSnap) {
              final nodes = nodeSnap.data ?? const <ContentNode>[];
              return StreamBuilder<List<StudyFact>>(
                stream: app.sessions.watchFacts(),
                builder: (context, factSnap) {
                  final perDay =
                      secondsPerDay(factSnap.data ?? const <StudyFact>[]);
                  return StreamBuilder<List<PlanItem>>(
                    stream: app.plans.watchRange(_week, end),
                    builder: (context, planSnap) {
                      final items = planSnap.data ?? const <PlanItem>[];
                      final plannedMin = items.fold<int>(
                          0, (a, i) => a + i.durationMinutes);
                      final doneCount = items.where((i) => i.done).length;
                      var studied = 0;
                      for (var d = 0; d < 7; d++) {
                        studied += perDay[DateTime(
                                _week.year, _week.month, _week.day + d)] ??
                            0;
                      }
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        children: [
                          ContentWidth(
                            maxWidth: 900,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(children: [
                                  IconButton(
                                    tooltip: 'Semana anterior',
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: () => setState(() => _week =
                                        DateTime(_week.year, _week.month,
                                            _week.day - 7)),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${formatDate(_week)} a ${formatDate(last)}',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Próxima semana',
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () => setState(() => _week =
                                        DateTime(_week.year, _week.month,
                                            _week.day + 7)),
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                ResponsiveGrid(
                                  minItemWidth: 200,
                                  children: [
                                    StatTile(
                                      label: 'Planejado',
                                      value: formatDuration(plannedMin * 60),
                                      icon: Icons.event_note_outlined,
                                      caption: '${items.length} atividades',
                                    ),
                                    StatTile(
                                      label: 'Concluídas',
                                      value: '$doneCount de ${items.length}',
                                      icon: Icons.task_alt,
                                      progress: items.isEmpty
                                          ? 0
                                          : doneCount / items.length,
                                    ),
                                    StatTile(
                                      label: 'Estudado de verdade',
                                      value: formatDuration(studied),
                                      icon: Icons.timer_outlined,
                                      caption: 'soma das sessões registradas',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                for (var d = 0; d < 7; d++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _DayCard(
                                      day: DateTime(_week.year, _week.month,
                                          _week.day + d),
                                      items: items
                                          .where((i) =>
                                              dayOf(i.day) ==
                                                  DateTime(_week.year,
                                                      _week.month, _week.day + d))
                                          .toList(),
                                      subjects: subjects,
                                      nodes: nodes,
                                      studiedSeconds: perDay[DateTime(
                                              _week.year,
                                              _week.month,
                                              _week.day + d)] ??
                                          0,
                                    ),
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
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final List<PlanItem> items;
  final Map<int, Subject> subjects;
  final List<ContentNode> nodes;
  final int studiedSeconds;

  const _DayCard({
    required this.day,
    required this.items,
    required this.subjects,
    required this.nodes,
    required this.studiedSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    final today = dayOf(DateTime.now()) == day;
    final planned = items.fold<int>(0, (a, i) => a + i.durationMinutes);
    return SectionCard(
      title: '${weekdayNames[day.weekday - 1]}${today ? ' · hoje' : ''}',
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          '${formatDuration(planned * 60)} plan. · ${formatDuration(studiedSeconds)} real',
          style: TextStyle(color: pal.textMuted, fontSize: 12.5),
        ),
        IconButton(
          tooltip: 'Adicionar atividade',
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => openPlanForm(context, day: day),
        ),
      ]),
      child: items.isEmpty
          ? Text('Nada planejado.', style: TextStyle(color: pal.textMuted))
          : Column(
              children: [
                for (final item in items)
                  _PlanRow(
                    item: item,
                    subject: subjects[item.subjectId],
                    path: item.nodeId == null
                        ? null
                        : nodePath(nodes, item.nodeId!),
                  ),
              ],
            ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final PlanItem item;
  final Subject? subject;
  final String? path;

  const _PlanRow({required this.item, this.subject, this.path});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = pontoOf(context).palette;
    final s = subject;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: item.done,
            onChanged: (v) => app.plans.setDone(item.id, v ?? false),
          ),
          if (s != null) SubjectBadge(icon: s.icon, colorValue: s.colorValue, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.startTime != null ? '${item.startTime}  ' : ''}'
                  '${s?.name ?? 'Matéria removida'} — ${formatDuration(item.durationMinutes * 60)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: item.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (path != null && path!.isNotEmpty)
                  Text(path!, style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
                if (item.notes.isNotEmpty)
                  Text(item.notes,
                      style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
              ],
            ),
          ),
          if (item.priority == 2)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.priority_high, size: 18, color: pal.secondary),
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'study':
                  if (app.timer.hasActive) {
                    showSnack(context, 'Já existe uma sessão em andamento.');
                  } else {
                    await app.timer.start(
                      subjectId: item.subjectId,
                      nodeId: item.nodeId,
                      plannedSeconds: item.durationMinutes * 60,
                    );
                  }
                  if (context.mounted) goToTab(context, ShellTab.timer);
                case 'edit':
                  await openPlanForm(context, day: item.day, item: item);
                case 'delete':
                  await app.plans.delete(item.id);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'study', child: Text('Estudar agora')),
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> openPlanForm(BuildContext context,
    {required DateTime day, PlanItem? item}) {
  return showDialog(
    context: context,
    builder: (_) => _PlanFormDialog(day: day, item: item),
  );
}

class _PlanFormDialog extends StatefulWidget {
  final DateTime day;
  final PlanItem? item;
  const _PlanFormDialog({required this.day, this.item});

  @override
  State<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<_PlanFormDialog> {
  int? _subjectId;
  int? _nodeId;
  late DateTime _day;
  TimeOfDay? _time;
  late int _duration;
  late int _priority;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _subjectId = i?.subjectId;
    _nodeId = i?.nodeId;
    _day = widget.day;
    final st = i?.startTime;
    if (st != null && st.contains(':')) {
      final parts = st.split(':');
      _time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
    }
    _duration = i?.durationMinutes ?? 60;
    _priority = i?.priority ?? 1;
    _notes = TextEditingController(text: i?.notes ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final subjectId = _subjectId;
    if (subjectId == null) {
      showSnack(context, 'Escolha a matéria.');
      return;
    }
    final repo = AppScope.of(context).plans;
    final time = _time == null ? null : '${two(_time!.hour)}:${two(_time!.minute)}';
    final i = widget.item;
    if (i == null) {
      await repo.create(
        day: _day,
        subjectId: subjectId,
        nodeId: _nodeId,
        startTime: time,
        durationMinutes: _duration,
        priority: _priority,
        notes: _notes.text,
      );
    } else {
      await repo.update(
        id: i.id,
        day: _day,
        subjectId: subjectId,
        nodeId: _nodeId,
        startTime: time,
        durationMinutes: _duration,
        priority: _priority,
        notes: _notes.text,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Planejar estudo' : 'Editar atividade'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SubjectNodePicker(
                subjectId: _subjectId,
                nodeId: _nodeId,
                onChanged: (s, n) => setState(() {
                  _subjectId = s;
                  _nodeId = n;
                }),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    label: Text(formatDate(_day)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _day,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _day = d);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(_time == null
                        ? 'Sem horário'
                        : '${two(_time!.hour)}:${two(_time!.minute)}'),
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _time ?? const TimeOfDay(hour: 19, minute: 0),
                      );
                      if (t != null) setState(() => _time = t);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _duration,
                decoration: const InputDecoration(labelText: 'Duração'),
                items: [
                  for (final m in {
                    15, 30, 45, 60, 75, 90, 120, 150, 180, 240, _duration
                  }.toList()
                    ..sort())
                    DropdownMenuItem(value: m, child: Text(formatDuration(m * 60))),
                ],
                onChanged: (v) => setState(() => _duration = v ?? 60),
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: [
                  for (var i = 0; i < 3; i++)
                    ButtonSegment(value: i, label: Text(priorityNames[i])),
                ],
                selected: {_priority},
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                decoration:
                    const InputDecoration(labelText: 'Observações (opcional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}
