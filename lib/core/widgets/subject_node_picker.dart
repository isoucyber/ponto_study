import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../features/subjects/content_tree.dart';
import '../database/database.dart';

// ============================================================
// ARQUIVO: lib/core/widgets/subject_node_picker.dart
// FUNÇÃO: Campo reutilizável "Matéria" + "Assunto/Tópico (opcional)".
//         Usado no cronômetro, no registro manual, no planejamento e
//         na edição de sessões.
// ============================================================

class SubjectNodePicker extends StatelessWidget {
  final int? subjectId;
  final int? nodeId;
  final void Function(int? subjectId, int? nodeId) onChanged;

  const SubjectNodePicker({
    super.key,
    required this.subjectId,
    required this.nodeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<List<Subject>>(
      stream: app.subjects.watchActive(),
      builder: (context, snap) {
        final subjects = snap.data ?? const <Subject>[];
        final validSubject =
            subjects.any((s) => s.id == subjectId) ? subjectId : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey('subject-$validSubject-${subjects.length}'),
              initialValue: validSubject,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Matéria'),
              hint: Text(subjects.isEmpty
                  ? 'Cadastre uma matéria primeiro'
                  : 'Escolha a matéria'),
              items: [
                for (final s in subjects)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.icon}  ${s.name}',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => onChanged(v, null),
            ),
            if (validSubject != null) ...[
              const SizedBox(height: 12),
              StreamBuilder<List<ContentNode>>(
                stream: app.subjects.watchNodes(validSubject),
                builder: (context, snap) {
                  final entries = flattenTree(snap.data ?? const []);
                  final validNode =
                      entries.any((e) => e.node.id == nodeId) ? nodeId : null;
                  return DropdownButtonFormField<int?>(
                    key: ValueKey('node-$validSubject-$validNode-${entries.length}'),
                    initialValue: validNode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Assunto ou tópico (opcional)'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Matéria inteira'),
                      ),
                      for (final e in entries)
                        DropdownMenuItem<int?>(
                          value: e.node.id,
                          child: Padding(
                            padding: EdgeInsets.only(left: 14.0 * e.depth),
                            child: Text(
                              e.node.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                    onChanged: (v) => onChanged(validSubject, v),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
