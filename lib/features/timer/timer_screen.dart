import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/subject_node_picker.dart';
import '../subjects/content_tree.dart';
import 'manual_session_screen.dart';

// ============================================================
// ARQUIVO: lib/features/timer/timer_screen.dart
// FUNÇÃO: Cronômetro de estudos: escolher matéria/assunto, iniciar,
//         pausar, retomar, finalizar ou cancelar. Também leva ao
//         registro manual.
// ============================================================

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = AppScope.of(context).timer;
    return PageScaffold(
      title: 'Estudar',
      showBack: false,
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ManualSessionScreen())),
          icon: const Icon(Icons.edit_calendar_outlined),
          label: const Text('Registro manual'),
        ),
        const SizedBox(width: 8),
      ],
      body: ListenableBuilder(
        listenable: timer,
        builder: (context, _) => timer.hasActive
            ? _ActiveTimer(session: timer.active!)
            : const _StartPanel(),
      ),
    );
  }
}

class _StartPanel extends StatefulWidget {
  const _StartPanel();

  @override
  State<_StartPanel> createState() => _StartPanelState();
}

class _StartPanelState extends State<_StartPanel> {
  int? _subjectId;
  int? _nodeId;
  int? _plannedMinutes;
  bool _starting = false;

  Future<void> _start() async {
    final id = _subjectId;
    if (id == null || _starting) return;
    setState(() => _starting = true);
    try {
      await AppScope.of(context).timer.start(
            subjectId: id,
            nodeId: _nodeId,
            plannedSeconds:
                _plannedMinutes == null ? null : _plannedMinutes! * 60,
          );
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ContentWidth(
          maxWidth: 620,
          child: SectionCard(
            title: 'Nova sessão de estudo',
            child: Column(
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
                const SizedBox(height: 18),
                Text('Tempo planejado (opcional)',
                    style: TextStyle(color: pal.textMuted)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final m in const [null, 25, 30, 45, 60, 90, 120])
                    ChoiceChip(
                      label: Text(m == null ? 'Livre' : formatDuration(m * 60)),
                      selected: _plannedMinutes == m,
                      onSelected: (_) => setState(() => _plannedMinutes = m),
                    ),
                ]),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _subjectId == null || _starting ? null : _start,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar cronômetro'),
                ),
                const SizedBox(height: 14),
                Text(
                  'O tempo é calculado pelos horários gravados no aparelho: '
                  'você pode minimizar ou até fechar o app sem perder a sessão.',
                  style: TextStyle(color: pal.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveTimer extends StatelessWidget {
  final StudySession session;
  const _ActiveTimer({required this.session});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final timer = app.timer;
    final pal = pontoOf(context).palette;
    final study = timer.studySeconds;
    final planned = session.plannedSeconds;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ContentWidth(
          maxWidth: 620,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SessionTitle(session: session),
              const SizedBox(height: 16),
              SectionCard(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      timer.isPaused ? 'PAUSADO' : 'ESTUDANDO',
                      style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: timer.isPaused ? pal.secondary : pal.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      child: Text(
                        formatClock(study),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w300,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 18,
                      children: [
                        Text('Pausado: ${formatClock(timer.pauseSeconds)}',
                            style: TextStyle(color: pal.textMuted)),
                        Text('Sessão: ${formatClock(timer.totalSeconds)}',
                            style: TextStyle(color: pal.textMuted)),
                        Text('Início: ${formatTime(session.startedAt)}',
                            style: TextStyle(color: pal.textMuted)),
                      ],
                    ),
                    if (planned != null && planned > 0) ...[
                      const SizedBox(height: 18),
                      ProgressLine(value: study / planned),
                      const SizedBox(height: 6),
                      Text(
                        study >= planned
                            ? 'Tempo planejado atingido (${formatDuration(planned)})'
                            : 'Planejado: ${formatDuration(planned)} · '
                                'faltam ${formatDuration(planned - study)}',
                        style: TextStyle(color: pal.textMuted, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: timer.isPaused
                      ? FilledButton.icon(
                          onPressed: timer.resume,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Retomar'),
                        )
                      : FilledButton.tonalIcon(
                          onPressed: timer.pause,
                          icon: const Icon(Icons.pause_rounded),
                          label: const Text('Pausar'),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _finish(context),
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Finalizar'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final ok = await confirmDialog(
                    context,
                    title: 'Cancelar sessão?',
                    message:
                        'Nada desta sessão será registrado no histórico.',
                    confirmLabel: 'Cancelar sessão',
                    destructive: true,
                  );
                  if (ok) await timer.cancel();
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancelar sessão'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _finish(BuildContext context) async {
    final timer = AppScope.of(context).timer;
    final computedMinutes = (timer.studySeconds / 60).round();
    final minutesCtrl = TextEditingController(text: '$computedMinutes');
    final notesCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar sessão'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tempo estudado calculado: ${formatClock(timer.studySeconds)}'),
              const SizedBox(height: 14),
              TextField(
                controller: minutesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutos a registrar',
                  helperText:
                      'Ajuste se você esqueceu o cronômetro ligado.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'O que você estudou? (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar sessão'),
          ),
        ],
      ),
    );
    if (result == true) {
      final typed = int.tryParse(minutesCtrl.text.trim());
      final adjusted = (typed == null || typed == computedMinutes)
          ? null
          : (typed < 0 ? 0 : typed * 60);
      await timer.finish(adjustedStudySeconds: adjusted, notes: notesCtrl.text);
      if (context.mounted) showSnack(context, 'Sessão registrada no histórico.');
    }
    minutesCtrl.dispose();
    notesCtrl.dispose();
  }
}

/// Mostra "ícone + matéria › assunto" da sessão ativa.
class _SessionTitle extends StatelessWidget {
  final StudySession session;
  const _SessionTitle({required this.session});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = pontoOf(context).palette;
    return StreamBuilder<Subject?>(
      stream: app.subjects.watchSubject(session.subjectId),
      builder: (context, snap) {
        final s = snap.data;
        if (s == null) return const SizedBox(height: 40);
        return StreamBuilder<List<ContentNode>>(
          stream: app.subjects.watchNodes(s.id),
          builder: (context, nodeSnap) {
            final nodes = nodeSnap.data ?? const <ContentNode>[];
            final path =
                session.nodeId == null ? null : nodePath(nodes, session.nodeId!);
            return Row(children: [
              SubjectBadge(icon: s.icon, colorValue: s.colorValue, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: Theme.of(context).textTheme.titleLarge),
                    if (path != null && path.isNotEmpty)
                      Text(path, style: TextStyle(color: pal.textMuted)),
                  ],
                ),
              ),
            ]);
          },
        );
      },
    );
  }
}
