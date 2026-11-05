import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../services/study_service.dart';
import '../../services/subject_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state.dart';

/// ============================================================
/// ARQUIVO: lib/screens/study/register_study_screen.dart
/// FUNÇÃO: Formulário para registrar uma sessão de estudo:
///         escolher matéria, duração (botões rápidos ou texto
///         personalizado), conteúdo e observação.
///
/// POSSO ALTERAR:
///   - Lista de durações rápidas (quickDurations).
///   - Textos e layout.
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - A conversão de texto personalizado usa
///     studyService.parseCustomDuration, que já sabe interpretar
///     "1h30", "30min", "2 horas" etc. Não duplique essa lógica aqui.
///
/// DEPENDÊNCIAS:
///   - services/study_service.dart, services/subject_service.dart
/// ============================================================
class RegisterStudyScreen extends StatefulWidget {
  final SubjectService subjectService;
  final StudyService studyService;

  const RegisterStudyScreen({
    super.key,
    required this.subjectService,
    required this.studyService,
  });

  @override
  State<RegisterStudyScreen> createState() => _RegisterStudyScreenState();
}

class _RegisterStudyScreenState extends State<RegisterStudyScreen> {
  static const quickDurations = [15, 30, 45, 60, 90, 120];

  Subject? _selectedSubject;
  int? _selectedMinutes;
  final _customDurationController = TextEditingController();
  final _contentController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _customDurationController.dispose();
    _contentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedSubject == null) {
      _showError('Escolha uma matéria.');
      return;
    }

    int? minutes = _selectedMinutes;
    if (_customDurationController.text.trim().isNotEmpty) {
      minutes = widget.studyService
          .parseCustomDuration(_customDurationController.text);
      if (minutes == null) {
        _showError('Não entendi o tempo digitado. Tente "1h30" ou "45min".');
        return;
      }
    }

    if (minutes == null) {
      _showError('Escolha ou digite um tempo de estudo.');
      return;
    }

    final error = await widget.studyService.registerSession(
      subjectId: _selectedSubject!.id,
      date: _date,
      durationMinutes: minutes,
      content: _contentController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (error != null) {
      _showError(error);
      return;
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar estudo')),
      body: StreamBuilder<List<Subject>>(
        stream: widget.subjectService.watchAllSubjects(),
        builder: (context, snapshot) {
          final subjects = snapshot.data ?? [];
          if (subjects.isEmpty) {
            return const EmptyState(
              message: 'Cadastre uma matéria antes de registrar um estudo.',
              icon: Icons.menu_book_outlined,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Matéria'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((s) {
                  final selected = s.id == _selectedSubject?.id;
                  return ChoiceChip(
                    label: Text('${s.icon} ${s.name}'),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedSubject = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Tempo estudado'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickDurations.map((m) {
                  final label = m < 60 ? '${m}min' : '${m ~/ 60}h${m % 60 == 0 ? '' : m % 60}';
                  final selected = m == _selectedMinutes;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedMinutes = m;
                      _customDurationController.clear();
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _customDurationController,
                label: 'Ou digite um tempo personalizado (ex: 1h30)',
                onChanged: (_) => setState(() => _selectedMinutes = null),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _contentController,
                label: 'O que você estudou?',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                label: 'Observação (opcional)',
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              CustomButton(label: 'Salvar sessão', onPressed: _save),
            ],
          );
        },
      ),
    );
  }
}
