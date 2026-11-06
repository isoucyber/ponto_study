import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/database/database.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import 'content_tree.dart';

// ============================================================
// ARQUIVO: lib/features/subjects/node_form.dart
// FUNÇÃO: Criar ou editar um Assunto, Tópico ou Subtópico:
//         nome, descrição, objetivo de aprendizagem, dificuldade,
//         prioridade, materiais de apoio e observações.
// ============================================================

Future<void> openNodeForm(
  BuildContext context, {
  required int subjectId,
  int? parentId,
  int depth = 0,
  ContentNode? node,
}) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => NodeForm(
      subjectId: subjectId,
      parentId: parentId,
      depth: depth,
      node: node,
    ),
  ));
}

class NodeForm extends StatefulWidget {
  final int subjectId;
  final int? parentId;
  final int depth;
  final ContentNode? node;

  const NodeForm({
    super.key,
    required this.subjectId,
    this.parentId,
    this.depth = 0,
    this.node,
  });

  @override
  State<NodeForm> createState() => _NodeFormState();
}

class _NodeFormState extends State<NodeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _objective;
  late final TextEditingController _materials;
  late final TextEditingController _notes;
  late int _difficulty;
  late int _priority;

  @override
  void initState() {
    super.initState();
    final n = widget.node;
    _name = TextEditingController(text: n?.name ?? '');
    _description = TextEditingController(text: n?.description ?? '');
    _objective = TextEditingController(text: n?.objective ?? '');
    _materials = TextEditingController(text: n?.materials ?? '');
    _notes = TextEditingController(text: n?.notes ?? '');
    _difficulty = n?.difficulty ?? 1;
    _priority = n?.priority ?? 1;
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _objective, _materials, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = AppScope.of(context).subjects;
    final n = widget.node;
    if (n == null) {
      await repo.createNode(
        subjectId: widget.subjectId,
        parentId: widget.parentId,
        name: _name.text,
        description: _description.text,
        objective: _objective.text,
        materials: _materials.text,
        notes: _notes.text,
        difficulty: _difficulty,
        priority: _priority,
      );
    } else {
      await repo.updateNode(
        id: n.id,
        name: _name.text,
        description: _description.text,
        objective: _objective.text,
        materials: _materials.text,
        notes: _notes.text,
        difficulty: _difficulty,
        priority: _priority,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final label = levelLabel(widget.depth);
    return PageScaffold(
      title: widget.node == null ? 'Novo $label' : 'Editar $label',
      actions: [
        TextButton(onPressed: _save, child: const Text('Salvar')),
        const SizedBox(width: 8),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ContentWidth(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    autofocus: widget.node == null,
                    maxLength: 120,
                    decoration: InputDecoration(labelText: 'Nome do $label'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe um nome'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 5,
                    decoration:
                        const InputDecoration(labelText: 'Descrição (opcional)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _objective,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Objetivo de aprendizagem (opcional)',
                      hintText: 'Ex.: saber usar laços aninhados para percorrer matrizes',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Dificuldade',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: [
                      for (var i = 0; i < 3; i++)
                        ButtonSegment(
                            value: i, label: Text(difficultyNames[i])),
                    ],
                    selected: {_difficulty},
                    onSelectionChanged: (s) =>
                        setState(() => _difficulty = s.first),
                  ),
                  const SizedBox(height: 16),
                  Text('Prioridade',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: [
                      for (var i = 0; i < 3; i++)
                        ButtonSegment(value: i, label: Text(priorityNames[i])),
                    ],
                    selected: {_priority},
                    onSelectionChanged: (s) =>
                        setState(() => _priority = s.first),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _materials,
                    minLines: 2,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Materiais de apoio (opcional)',
                      hintText: 'Links, livros, capítulos... um por linha',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    minLines: 2,
                    maxLines: 8,
                    decoration:
                        const InputDecoration(labelText: 'Observações (opcional)'),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(onPressed: _save, child: const Text('Salvar')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
