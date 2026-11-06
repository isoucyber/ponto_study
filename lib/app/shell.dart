import 'package:flutter/material.dart';

import '../core/theme/app_themes.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/history/history_screen.dart';
import '../features/planning/planning_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/subjects/subjects_screen.dart';
import '../features/timer/timer_screen.dart';
import 'app_scope.dart';

// ============================================================
// ARQUIVO: lib/app/shell.dart
// FUNÇÃO: Estrutura de navegação principal, adaptada ao tamanho da tela:
//   - Janela larga (Windows, tablet deitado): barra lateral (sidebar).
//   - Tela estreita (celular): barra inferior com 5 itens + "Mais".
// POSSO ALTERAR: a ordem, os ícones e os nomes das seções.
// ============================================================

enum ShellTab { home, subjects, timer, planning, history, reports, settings }

/// Aba atual. Qualquer tela pode trocar de aba com:
///   shellTab.value = ShellTab.timer;
final shellTab = ValueNotifier<ShellTab>(ShellTab.home);

/// Volta para a tela principal (fecha telas abertas por cima) e troca de aba.
void goToTab(BuildContext context, ShellTab tab) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  shellTab.value = tab;
}

class _Dest {
  final ShellTab tab;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _Dest(this.tab, this.label, this.icon, this.selectedIcon);
}

const _destinations = [
  _Dest(ShellTab.home, 'Início', Icons.space_dashboard_outlined,
      Icons.space_dashboard),
  _Dest(ShellTab.subjects, 'Matérias', Icons.account_tree_outlined,
      Icons.account_tree),
  _Dest(ShellTab.timer, 'Estudar', Icons.timer_outlined, Icons.timer),
  _Dest(ShellTab.planning, 'Planejamento', Icons.calendar_month_outlined,
      Icons.calendar_month),
  _Dest(ShellTab.history, 'Histórico', Icons.history, Icons.history),
  _Dest(ShellTab.reports, 'Relatórios', Icons.insights_outlined,
      Icons.insights),
  _Dest(ShellTab.settings, 'Configurações', Icons.tune_outlined, Icons.tune),
];

/// Abas que aparecem na barra inferior do celular (o resto fica em "Mais").
const _mobileTabs = [
  ShellTab.home,
  ShellTab.subjects,
  ShellTab.timer,
  ShellTab.planning,
];

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  Widget _page(ShellTab tab) {
    switch (tab) {
      case ShellTab.home:
        return const DashboardScreen();
      case ShellTab.subjects:
        return const SubjectsScreen();
      case ShellTab.timer:
        return const TimerScreen();
      case ShellTab.planning:
        return const PlanningScreen();
      case ShellTab.history:
        return const HistoryScreen();
      case ShellTab.reports:
        return const ReportsScreen();
      case ShellTab.settings:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ShellTab>(
      valueListenable: shellTab,
      builder: (context, tab, _) {
        return LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          return wide ? _wide(context, tab) : _narrow(context, tab);
        });
      },
    );
  }

  Widget _timerIcon(BuildContext context, IconData icon) {
    final timer = AppScope.of(context).timer;
    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) => Badge(
        isLabelVisible: timer.hasActive,
        smallSize: 9,
        child: Icon(icon),
      ),
    );
  }

  Widget _icon(BuildContext context, _Dest d, bool selected) {
    final icon = selected ? d.selectedIcon : d.icon;
    return d.tab == ShellTab.timer ? _timerIcon(context, icon) : Icon(icon);
  }

  Widget _wide(BuildContext context, ShellTab tab) {
    final pal = pontoOf(context).palette;
    final extended = MediaQuery.sizeOf(context).width >= 1100;
    final profile = AppScope.of(context).settings.profile;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 220,
            selectedIndex: _destinations.indexWhere((d) => d.tab == tab),
            onDestinationSelected: (i) =>
                shellTab.value = _destinations[i].tab,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 22),
              child: extended
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      _Logo(color: pal.primary),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ponto Study',
                              style: Theme.of(context).textTheme.titleMedium),
                          if (profile != null)
                            Text('Olá, ${profile.name}',
                                style: TextStyle(
                                    color: pal.textMuted, fontSize: 12)),
                        ],
                      ),
                    ])
                  : _Logo(color: pal.primary),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: _icon(context, d, false),
                  selectedIcon: _icon(context, d, true),
                  label: Text(d.label),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: pal.border),
          Expanded(child: _page(tab)),
        ],
      ),
    );
  }

  Widget _narrow(BuildContext context, ShellTab tab) {
    final inMore = !_mobileTabs.contains(tab);
    final selected = inMore ? 4 : _mobileTabs.indexOf(tab);
    return Scaffold(
      body: inMore ? _MoreScreen(current: tab, page: _page(tab)) : _page(tab),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) {
          shellTab.value = i < 4 ? _mobileTabs[i] : ShellTab.history;
        },
        destinations: [
          for (final t in _mobileTabs)
            () {
              final d = _destinations.firstWhere((x) => x.tab == t);
              return NavigationDestination(
                icon: _icon(context, d, false),
                selectedIcon: _icon(context, d, true),
                label: d.tab == ShellTab.planning ? 'Plano' : d.label,
              );
            }(),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}

/// No celular, "Mais" mostra uma seleção rápida entre Histórico,
/// Relatórios e Configurações acima da página escolhida.
class _MoreScreen extends StatelessWidget {
  final ShellTab current;
  final Widget page;
  const _MoreScreen({required this.current, required this.page});

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SegmentedButton<ShellTab>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: ShellTab.history,
                    icon: Icon(Icons.history),
                    label: Text('Histórico')),
                ButtonSegment(
                    value: ShellTab.reports,
                    icon: Icon(Icons.insights_outlined),
                    label: Text('Relatórios')),
                ButtonSegment(
                    value: ShellTab.settings,
                    icon: Icon(Icons.tune_outlined),
                    label: Text('Ajustes')),
              ],
              selected: {current},
              onSelectionChanged: (s) => shellTab.value = s.first,
            ),
          ),
        ),
        Divider(color: pal.border, height: 12),
        Expanded(child: page),
      ],
    );
  }
}

/// Logotipo simples: um "ponto" dentro de um anel.
class _Logo extends StatelessWidget {
  final Color color;
  const _Logo({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
