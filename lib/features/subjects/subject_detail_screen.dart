import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/shell.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../domain/stats/study_stats.dart';
import 'content_tree.dart';
import 'node_form.dart';
import 'subject_form.dart';

// ============================================================
// ARQUIVO: lib/features/subjects/subject_detail_screen.dart
// FUNÇÃO: Mostra uma matéria e sua árvore de Assuntos → Tópicos →
//         Subtópicos. Permite criar, editar, reorganizar (subir,
//         descer, mover para outro item) e excluir conteúdos.
// ============================================================

class SubjectDetailScreen extends StatefulWidget {
  final int subjectId;
  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final Set<int> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<Subject?>(
      stream: app.subjects.watchSubject(widget.subjectId),
      builder: (context, subjectSnap) {
        final subject = subjectSnap.data;
        if (subject == null) {
          return const PageScaffold(
            title: 'Matéria',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return PageScaffold(
          title: subject.name,
          actions: [
            IconButton(
              tooltip: 'Editar matéria',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => openSubjectForm(context, subject: subject),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => _subjectAction(v, subject),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'study', child: Text('Estudar agora')),
                PopupMenuItem(value: 'archive', child: Text('Arquivar matéria')),
              ],
            ),
            const SizedBox(width: 4),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                openNodeForm(context, subjectId: subject.id, depth: 0),
            icon: const Icon(Icons.add),
            label: const Text('Novo assunto'),
          ),
          body: StreamBuilder<List<ContentNode>>(
            stream: app.subjects.watchNodes(subject.id),
            builder: (context, nodeSnap) {
              final nodes = nodeSnap.data ?? const <ContentNode>[];
              return StreamBuilder<List<StudyFact>>(
                stream: app.sessions.watchFacts(),
                builder: (context, factSnap) {
                  final facts = (factSnap.data ?? const <StudyFact>[])
                      .where((f) => f.subjectId == subject.id)
                      .toList();
                  return _body(context, subject, nodes, facts);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, Subject subject, List<ContentNode> nodes,
      List<StudyFact> facts) {
    final pal = pontoOf(context).palette;
    final entries = flattenTree(nodes, collapsed: _collapsed);
    final total = facts.fold<int>(0, (a, f) => a + f.seconds);
    final weekStart = startOfWeek(DateTime.now());
    final week =
        secondsBetween(facts, weekStart, weekStart.add(const Duration(days: 7)));

    int nodeSeconds(int id) {
      final ids = {id, ...descendantIds(nodes, id)};
      return facts
          .where((f) => f.nodeId != null && ids.contains(f.nodeId))
          .fold<int>(0, (a, f) => a + f.seconds);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        ContentWidth(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                child: Row(children: [
                  SubjectBadge(
                      icon: subject.icon,
                      colorValue: subject.colorValue,
                      size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subject.description.isNotEmpty)
                          Text(subject.description,
                              style: TextStyle(color: pal.textMuted)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 16, runSpacing: 4, children: [
                          Text('Total: ${formatDuration(total)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Semana: ${formatDuration(week)}'),
                          if (subject.weeklyGoalMinutes > 0)
                            Text(
                                'Meta: ${formatDuration(subject.weeklyGoalMinutes * 60)}/sem.'),
                          Text('${nodes.length} itens de conteúdo'),
                        ]),
                        if (subject.weeklyGoalMinutes > 0) ...[
                          const SizedBox(height: 10),
                          ProgressLine(
                            value: goalProgress(week, subject.weeklyGoalMinutes),
                            color: Color(subject.colorValue),
                          ),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: EmptyState(
                    icon: Icons.account_tree_outlined,
                    title: 'Organize esta matéria',
                    message:
                        'Adicione assuntos (ex.: "Estruturas de repetição") e, '
                        'dentro deles, tópicos e subtópicos. A estrutura é '
                        'livre: use quantos níveis precisar.',
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (final e in entries)
                        _NodeRow(
                          entry: e,
                          collapsed: _collapsed.contains(e.node.id),
                          seconds: nodeSeconds(e.node.id),
                          onToggle: () => setState(() {
                            if (!_collapsed.remove(e.node.id)) {
                              _collapsed.add(e.node.id);
                            }
                          }),
                          onAction: (a) => _nodeAction(a, e, nodes),
                          onTap: () => _showNode(e, nodes, nodeSeconds(e.node.id)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _subjectAction(String action, Subject subject) async {
    final app = AppScope.of(context);
    if (action == 'study') {
      await _startStudy(subject.id, null);
    } else if (action == 'archive') {
      final ok = await confirmDialog(
        context,
        title: 'Arquivar "${subject.name}"?',
        message:
            'A matéria some das listas, mas todo o histórico é mantido. '
            'Você pode restaurá-la em Matérias → Arquivadas.',
        confirmLabel: 'Arquivar',
      );
      if (ok) {
        await app.subjects.setArchived(subject.id, true);
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  Future<void> _startStudy(int subjectId, int? nodeId) async {
    final timer = AppScope.of(context).timer;
    if (timer.hasActive) {
      showSnack(context, 'Já existe uma sessão em andamento.');
      goToTab(context, ShellTab.timer);
      return;
    }
    await timer.start(subjectId: subjectId, nodeId: nodeId);
    if (mounted) goToTab(context, ShellTab.timer);
  }

  Future<void> _nodeAction(
      String action, TreeEntry e, List<ContentNode> nodes) async {
    final repo = AppScope.of(context).subjects;
    final node = e.node;
    switch (action) {
      case 'child':
        await openNodeForm(context,
            subjectId: node.subjectId, parentId: node.id, depth: e.depth + 1);
      case 'edit':
        await openNodeForm(context,
            subjectId: node.subjectId, node: node, depth: e.depth);
      case 'up':
        await repo.moveNode(node, -1);
      case 'down':
        await repo.moveNode(node, 1);
      case 'move':
        await _moveTo(node, nodes);
      case 'study':
        await _startStudy(node.subjectId, node.id);
      case 'delete':
        final count = descendantIds(nodes, node.id).length;
        final ok = await confirmDialog(
          context,
          title: 'Excluir "${node.name}"?',
          message: count == 0
              ? 'O item será excluído. Sessões ligadas a ele continuam '
                  'contando para a matéria.'
              : 'O item e seus $count subitens serão excluídos. Sessões '
                  'ligadas a eles continuam contando para a matéria.',
          confirmLabel: 'Excluir',
          destructive: true,
        );
        if (ok) await repo.deleteNode(node.id);
    }
  }

  Future<void> _moveTo(ContentNode node, List<ContentNode> nodes) async {
    final blocked = {node.id, ...descendantIds(nodes, node.id)};
    final options =
        flattenTree(nodes).where((e) => !blocked.contains(e.node.id)).toList();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Mover "${node.name}" para...'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, -1),
            child: const Text('Primeiro nível (vira Assunto)'),
          ),
          for (final e in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, e.node.id),
              child: Padding(
                padding: EdgeInsets.only(left: 16.0 * e.depth),
                child: Text(e.node.name),
              ),
            ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final ok = await AppScope.of(context)
        .subjects
        .reparentNode(node, result == -1 ? null : result);
    if (!ok && mounted) {
      showSnack(context, 'Não é possível mover um item para dentro dele mesmo.');
    }
  }

  void _showNode(TreeEntry e, List<ContentNode> nodes, int seconds) {
    final node = e.node;
    final pal = pontoOf(context).palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget field(String label, String value) => value.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: pal.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    SelectableText(value),
                  ],
                ),
              );
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(levelLabel(e.depth).toUpperCase(),
                    style: TextStyle(
                        color: pal.primary,
                        fontSize: 11.5,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(nodePath(nodes, node.id),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  Chip(label: Text('Dificuldade: ${difficultyNames[node.difficulty]}')),
                  Chip(label: Text('Prioridade: ${priorityNames[node.priority]}')),
                  Chip(label: Text('Estudado: ${formatDuration(seconds)}')),
                ]),
                const SizedBox(height: 16),
                field('Descrição', node.description),
                field('Objetivo de aprendizagem', node.objective),
                field('Materiais de apoio', node.materials),
                field('Observações', node.notes),
                const SizedBox(height: 8),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _startStudy(node.subjectId, node.id);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Estudar agora'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      openNodeForm(context,
                          subjectId: node.subjectId, node: node, depth: e.depth);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      openNodeForm(context,
                          subjectId: node.subjectId,
                          parentId: node.id,
                          depth: e.depth + 1);
                    },
                    icon: const Icon(Icons.subdirectory_arrow_right),
                    label: Text('Adicionar ${levelLabel(e.depth + 1).toLowerCase()}'),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NodeRow extends StatelessWidget {
  final TreeEntry entry;
  final bool collapsed;
  final int seconds;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  const _NodeRow({
    required this.entry,
    required this.collapsed,
    required this.seconds,
    required this.onToggle,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    final node = entry.node;
    final isTop = entry.depth == 0;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: pal.border, width: isTop ? 1 : 0.5)),
        ),
        padding: EdgeInsets.only(
            left: 8 + 22.0 * entry.depth, right: 4, top: 4, bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: entry.hasChildren
                  ? IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(collapsed
                          ? Icons.chevron_right
                          : Icons.expand_more),
                      onPressed: onToggle,
                    )
                  : Icon(Icons.circle, size: 6, color: pal.textMuted),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isTop ? FontWeight.w600 : FontWeight.w400,
                      fontSize: isTop ? 15 : 14,
                    ),
                  ),
                  Text(
                    '${levelLabel(entry.depth)} · ${difficultyNames[node.difficulty]}'
                    '${seconds > 0 ? ' · ${formatDuration(seconds)}' : ''}',
                    style: TextStyle(color: pal.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Opções',
              onSelected: onAction,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'child',
                  child: Text(
                      'Adicionar ${levelLabel(entry.depth + 1).toLowerCase()}'),
                ),
                const PopupMenuItem(value: 'study', child: Text('Estudar agora')),
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(value: 'up', child: Text('Mover para cima')),
                const PopupMenuItem(value: 'down', child: Text('Mover para baixo')),
                const PopupMenuItem(value: 'move', child: Text('Mover para...')),
                const PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
