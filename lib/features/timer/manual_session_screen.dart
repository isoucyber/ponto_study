import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/database/database.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/subject_node_picker.dart';

// ============================================================
// ARQUIVO: lib/features/timer/manual_session_screen.dart
// FUNÇÃO: Registrar manualmente um estudo já feito, ou editar uma
//         sessão do histórico (quando [editing] é informado).
// ============================================================

class ManualSessionScreen extends StatefulWidget {
  final StudySession? editing;
  const ManualSessionScreen({super.key, this.editing});

  @override
  State<ManualSessionScreen> createState() => _ManualSessionScreenState();
}

class _ManualSessionScreenState extends State<ManualSessionScreen> {
  int? _subjectId;
  int? _nodeId;
  late DateTime _date;
  late TimeOfDay _time;
  late int _hours;
  late int _minutes;
  late final TextEditingController _notes;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    final now = DateTime.now();
    _subjectId = e?.subjectId;
    _nodeId = e?.nodeId;
    final start = e?.startedAt ?? now.subtract(const Duration(hours: 1));
    _date = DateTime(start.year, start.month, start.day);
    _time = TimeOfDay(hour: start.hour, minute: start.minute);
    final seconds = e?.studySeconds ?? 3600;
    _hours = (seconds ~/ 3600).clamp(0, 23);
    _minutes = (seconds % 3600) ~/ 60;
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final subjectId = _subjectId;
    final total = _hours * 60 + _minutes;
    if (subjectId == null) {
      showSnack(context, 'Escolha a matéria.');
      return;
    }
    if (total <= 0) {
      showSnack(context, 'Informe a duração do estudo.');
      return;
    }
    final repo = AppScope.of(context).sessions;
    if (_isEdit) {
      await repo.updateFinished(
        id: widget.editing!.id,
        subjectId: subjectId,
        nodeId: _nodeId,
        studySeconds: total * 60,
        notes: _notes.text,
      );
    } else {
      final start = DateTime(
          _date.year, _date.month, _date.day, _time.hour, _time.minute);
      if (start.isAfter(DateTime.now())) {
        showSnack(context, 'O início não pode estar no futuro.');
        return;
      }
      await repo.addManual(
        subjectId: subjectId,
        nodeId: _nodeId,
        startedAt: start,
        minutes: total,
        notes: _notes.text,
      );
    }
    if (mounted) {
      showSnack(context, _isEdit ? 'Sessão atualizada.' : 'Estudo registrado.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: _isEdit ? 'Editar sessão' : 'Registrar estudo',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ContentWidth(
            maxWidth: 620,
            child: SectionCard(
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
                  const SizedBox(height: 16),
                  if (!_isEdit)
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event),
                          label: Text(formatDate(_date)),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setState(() => _date = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.schedule),
                          label: Text('${two(_time.hour)}:${two(_time.minute)}'),
                          onPressed: () async {
                            final t = await showTimePicker(
                                context: context, initialTime: _time);
                            if (t != null) setState(() => _time = t);
                          },
                        ),
                      ),
                    ]),
                  if (!_isEdit) const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _hours,
                        decoration: const InputDecoration(labelText: 'Horas'),
                        items: [
                          for (var h = 0; h <= 23; h++)
                            DropdownMenuItem(value: h, child: Text('$h h')),
                        ],
                        onChanged: (v) => setState(() => _hours = v ?? 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _minutes,
                        decoration: const InputDecoration(labelText: 'Minutos'),
                        items: [
                          for (var m = 0; m < 60; m++)
                            DropdownMenuItem(value: m, child: Text('$m min')),
                        ],
                        onChanged: (v) => setState(() => _minutes = v ?? 0),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                        labelText: 'Observações (opcional)'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _save,
                    child: Text(_isEdit ? 'Salvar alterações' : 'Registrar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
