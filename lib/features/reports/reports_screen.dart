import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../domain/stats/study_stats.dart';

// ============================================================
// ARQUIVO: lib/features/reports/reports_screen.dart
// FUNÇÃO: Relatórios de produtividade calculados a partir das sessões
//         reais: total, média diária, dias com meta batida, horas por
//         dia e por matéria, e comparação com o período anterior.
//         (Os relatórios de APRENDIZAGEM chegam com o sistema de domínio.)
// ============================================================

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageScaffold(
      title: 'Relatórios',
      showBack: false,
      body: StreamBuilder<List<Subject>>(
        stream: app.subjects.watchAll(),
        builder: (context, subjectSnap) {
          final subjects = {
            for (final s in subjectSnap.data ?? const <Subject>[]) s.id: s
          };
          return StreamBuilder<List<StudyFact>>(
            stream: app.sessions.watchFacts(),
            builder: (context, snap) =>
                _content(context, snap.data ?? const [], subjects),
          );
        },
      ),
    );
  }

  Widget _content(
      BuildContext context, List<StudyFact> facts, Map<int, Subject> subjects) {
    final pal = pontoOf(context).palette;
    final profile = AppScope.of(context).settings.profile;
    final now = DateTime.now();
    final end = dayOf(now).add(const Duration(days: 1));
    final start = DateTime(end.year, end.month, end.day - _days);
    final prevStart = DateTime(start.year, start.month, start.day - _days);

    final total = secondsBetween(facts, start, end);
    final prevTotal = secondsBetween(facts, prevStart, start);
    final perDay = secondsPerDay(facts);
    final days = [
      for (var i = 0; i < _days; i++)
        DateTime(start.year, start.month, start.day + i)
    ];
    final studiedDays = days.where((d) => (perDay[d] ?? 0) >= 60).length;
    final dailyGoal = profile?.dailyGoalMinutes ?? 0;
    final goalDays = dailyGoal <= 0
        ? null
        : days.where((d) => (perDay[d] ?? 0) >= dailyGoal * 60).length;
    final perSubject = secondsPerSubject(facts, start, end).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String comparison() {
      if (prevTotal == 0) {
        return total == 0 ? 'sem dados nos dois períodos' : 'sem estudo no período anterior';
      }
      final pct = ((total - prevTotal) / prevTotal * 100).round();
      return pct >= 0
          ? '+$pct% em relação aos $_days dias anteriores'
          : '$pct% em relação aos $_days dias anteriores';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        ContentWidth(
          maxWidth: 980,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 dias')),
                  ButtonSegment(value: 30, label: Text('30 dias')),
                  ButtonSegment(value: 90, label: Text('90 dias')),
                ],
                selected: {_days},
                onSelectionChanged: (s) => setState(() => _days = s.first),
              ),
              const SizedBox(height: 16),
              ResponsiveGrid(minItemWidth: 200, children: [
                StatTile(
                  label: 'Total estudado',
                  value: formatDuration(total),
                  icon: Icons.timer_outlined,
                  caption: comparison(),
                ),
                StatTile(
                  label: 'Média diária',
                  value: formatDuration(total ~/ _days),
                  icon: Icons.show_chart,
                  caption: 'considerando todos os $_days dias',
                ),
                StatTile(
                  label: 'Dias com estudo',
                  value: '$studiedDays de $_days',
                  icon: Icons.event_available_outlined,
                  progress: studiedDays / _days,
                ),
                StatTile(
                  label: 'Meta diária batida',
                  value: goalDays == null ? '—' : '$goalDays dias',
                  icon: Icons.flag_outlined,
                  caption: dailyGoal > 0
                      ? 'meta de ${formatDuration(dailyGoal * 60)}'
                      : 'defina uma meta em Configurações',
                ),
              ]),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Horas por dia',
                child: _DayBars(days: days, perDay: perDay),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Horas por matéria',
                child: perSubject.isEmpty
                    ? Text('Sem estudo registrado no período.',
                        style: TextStyle(color: pal.textMuted))
                    : Column(children: [
                        for (final e in perSubject)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(children: [
                              SizedBox(
                                width: 160,
                                child: Text(
                                  '${subjects[e.key]?.icon ?? '📚'} ${subjects[e.key]?.name ?? 'Matéria removida'}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: ProgressLine(
                                  value: e.value / perSubject.first.value,
                                  color: subjects[e.key] == null
                                      ? null
                                      : Color(subjects[e.key]!.colorValue),
                                  height: 10,
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 110,
                                child: Text(
                                  '${formatDuration(e.value)} · ${(e.value * 100 / (total == 0 ? 1 : total)).round()}%',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ]),
                          ),
                      ]),
              ),
              const SizedBox(height: 12),
              Text(
                'Todos os números são calculados a partir das sessões '
                'registradas. Relatórios de aprendizagem (domínio, taxa de '
                'acerto) chegam com o módulo de questões.',
                style: TextStyle(color: pal.textMuted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Gráfico de barras simples, desenhado com widgets (sem bibliotecas).
class _DayBars extends StatelessWidget {
  final List<DateTime> days;
  final Map<DateTime, int> perDay;
  const _DayBars({required this.days, required this.perDay});

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    final values = [for (final d in days) perDay[d] ?? 0];
    final max = values.fold<int>(0, (a, b) => a > b ? a : b);
    final showLabels = days.length <= 14;
    return SizedBox(
      height: 190,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(max == 0 ? '' : 'máx. ${formatDuration(max)}',
                style: TextStyle(color: pal.textMuted, fontSize: 12)),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++)
                  Expanded(
                    child: Tooltip(
                      message:
                          '${formatDate(days[i])}: ${formatDuration(values[i])}',
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: days.length > 40 ? 0.5 : 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FractionallySizedBox(
                              widthFactor: 1,
                              child: Container(
                                height: max == 0
                                    ? 2
                                    : 2 + 120 * values[i] / max,
                                decoration: BoxDecoration(
                                  color: values[i] == 0
                                      ? pal.surfaceAlt
                                      : pal.primary,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ),
                            ),
                            if (showLabels) ...[
                              const SizedBox(height: 6),
                              Text(weekdayShort[days[i].weekday - 1],
                                  style: TextStyle(
                                      color: pal.textMuted, fontSize: 11)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
