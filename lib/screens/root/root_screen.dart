import 'package:flutter/material.dart';

import '../../services/study_service.dart';
import '../../services/subject_service.dart';
import '../home/home_screen.dart';
import '../subjects/subjects_screen.dart';

/// ============================================================
/// ARQUIVO: lib/screens/root/root_screen.dart
/// FUNÇÃO: Decide o tipo de navegação de acordo com o tamanho da
///         tela: NavigationBar (embaixo) em telas estreitas
///         (celular) e NavigationRail (barra lateral) em telas
///         largas (Windows/Web desktop).
///
///         Este é o ÚNICO lugar do projeto onde essa decisão é
///         tomada - não duplique essa lógica em outras telas.
///
/// POSSO ALTERAR:
///   - O valor "700" (breakpoint) para mudar quando a barra
///     lateral aparece no lugar da navegação inferior.
///   - A lista de "destinations" para adicionar/remover abas
///     (lembre-se de adicionar a tela correspondente também).
///
/// DEPENDÊNCIAS:
///   - screens/home/home_screen.dart, screens/subjects/subjects_screen.dart
/// ============================================================
class RootScreen extends StatefulWidget {
  final SubjectService subjectService;
  final StudyService studyService;

  const RootScreen({
    super.key,
    required this.subjectService,
    required this.studyService,
  });

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  // Breakpoint: acima disso, usamos layout "desktop" com sidebar.
  static const double _desktopBreakpoint = 700;

  List<Widget> get _pages => [
        HomeScreen(
          subjectService: widget.subjectService,
          studyService: widget.studyService,
        ),
        SubjectsScreen(subjectService: widget.subjectService),
      ];

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
    NavigationDestination(
        icon: Icon(Icons.menu_book_outlined), label: 'Matérias'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= _desktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
