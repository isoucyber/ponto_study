import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';

// ============================================================
// ARQUIVO: lib/features/subjects/subject_form.dart
// FUNÇÃO: Formulário para criar ou editar uma matéria
//         (nome, descrição, ícone, cor, prioridade e meta semanal).
// ============================================================

Future<void> openSubjectForm(BuildContext context, {Subject? subject}) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => SubjectForm(subject: subject)),
  );
}

class SubjectForm extends StatefulWidget {
  final Subject? subject;
  const SubjectForm({super.key, this.subject});

  @override
  State<SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<SubjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _icon;
  late int _color;
  late int _priority;
  late int _goalHours;
  late int _goalMinutes;

  @override
  void initState() {
    super.initState();
    final s = widget.subject;
    _name = TextEditingController(text: s?.name ?? '');
    _description = TextEditingController(text: s?.description ?? '');
    _icon = s?.icon ?? subjectIcons.first;
    _color = s?.colorValue ?? subjectColors.first.toARGB32();
    _priority = s?.priority ?? 1;
    final goal = s?.weeklyGoalMinutes ?? 0;
    _goalHours = goal ~/ 60;
    _goalMinutes = goal % 60;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = AppScope.of(context).subjects;
    final goal = _goalHours * 60 + _goalMinutes;
    final s = widget.subject;
    if (s == null) {
      await repo.createSubject(
        name: _name.text,
        description: _description.text,
        icon: _icon,
        colorValue: _color,
        priority: _priority,
        weeklyGoalMinutes: goal,
      );
    } else {
      await repo.updateSubject(
        id: s.id,
        name: _name.text,
        description: _description.text,
        icon: _icon,
        colorValue: _color,
        priority: _priority,
        weeklyGoalMinutes: goal,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    return PageScaffold(
      title: widget.subject == null ? 'Nova matéria' : 'Editar matéria',
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
                  Row(children: [
                    SubjectBadge(icon: _icon, colorValue: _color, size: 56),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _name,
                        autofocus: widget.subject == null,
                        maxLength: 80,
                        decoration:
                            const InputDecoration(labelText: 'Nome da matéria'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe um nome'
                            : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)'),
                  ),
                  const SizedBox(height: 20),
                  Text('Ícone', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final icon in subjectIcons)
                        ChoiceChip(
                          label: Text(icon, style: const TextStyle(fontSize: 18)),
                          selected: _icon == icon,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _icon = icon),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Cor', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in subjectColors)
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _color = c.toARGB32()),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _color == c.toARGB32()
                                    ? pal.text
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                  Text('Meta de estudo semanal',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _goalHours,
                        decoration: const InputDecoration(labelText: 'Horas'),
                        items: [
                          for (var h = 0; h <= 40; h++)
                            DropdownMenuItem(value: h, child: Text('$h h')),
                        ],
                        onChanged: (v) => setState(() => _goalHours = v ?? 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _goalMinutes - _goalMinutes % 15,
                        decoration: const InputDecoration(labelText: 'Minutos'),
                        items: [
                          for (final m in const [0, 15, 30, 45])
                            DropdownMenuItem(value: m, child: Text('$m min')),
                        ],
                        onChanged: (v) =>
                            setState(() => _goalMinutes = v ?? 0),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text('Use 0 h e 0 min para não definir meta.',
                      style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
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
