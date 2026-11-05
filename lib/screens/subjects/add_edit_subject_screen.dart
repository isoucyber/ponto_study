import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../services/subject_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/duration_utils.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// ============================================================
/// ARQUIVO: lib/screens/subjects/add_edit_subject_screen.dart
/// FUNÇÃO: Formulário para criar uma matéria nova ou editar uma
///         já existente (nome, meta, cor, ícone, prioridade).
///
/// POSSO ALTERAR:
///   - Lista de ícones disponíveis (linha "icons").
///   - Textos e layout do formulário.
///
/// DEPENDÊNCIAS:
///   - services/subject_service.dart
/// ============================================================
class AddEditSubjectScreen extends StatefulWidget {
  final SubjectService subjectService;
  final Subject? existing;

  const AddEditSubjectScreen({
    super.key,
    required this.subjectService,
    this.existing,
  });

  @override
  State<AddEditSubjectScreen> createState() => _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends State<AddEditSubjectScreen> {
  final _nameController = TextEditingController();
  final _targetHoursController = TextEditingController(text: '10');

  static const icons = ['📚', '💻', '🧠', '🎯', '📝', '🔐', '🐍', '☕'];
  String _selectedIcon = icons.first;
  String _selectedColorName = AppColors.palette.keys.first;
  int _priority = 1; // 0 baixa, 1 normal, 2 alta

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final subject = widget.existing;
    if (subject != null) {
      _nameController.text = subject.name;
      _targetHoursController.text = (subject.targetMinutes / 60).toString();
      _selectedIcon = subject.icon;
      _priority = subject.priority;
      _selectedColorName = AppColors.palette.entries
          .firstWhere(
            (e) => e.value.toARGB32() == subject.colorValue,
            orElse: () => AppColors.palette.entries.first,
          )
          .key;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetHoursController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final hours = double.tryParse(
      _targetHoursController.text.trim().replaceAll(',', '.'),
    );

    // Validação de formato do campo de horas (número mesmo). A
    // validação de REGRA DE NEGÓCIO (nome vazio, meta <= 0) é feita
    // de novo dentro do SubjectService — aqui só garantimos que o
    // texto digitado é um número válido antes de converter.
    if (hours == null) {
      _showError('Digite um número válido para a meta.');
      return;
    }

    final color = AppColors.palette[_selectedColorName]!;
    final targetMinutes = (hours * 60).round();

    String? error;
    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        name: name,
        targetMinutes: targetMinutes,
        colorValue: color.toARGB32(),
        icon: _selectedIcon,
        priority: _priority,
      );
      error = await widget.subjectService.updateSubject(updated);
    } else {
      error = await widget.subjectService.createSubject(
        name: name,
        targetMinutes: targetMinutes,
        color: color,
        icon: _selectedIcon,
        priority: _priority,
      );
    }

    if (error != null) {
      _showError(error);
      return;
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final subjectId = widget.existing!.id;

    // Busca quanto de histórico essa matéria já acumulou, para
    // avisar exatamente o que está em jogo antes de confirmar.
    final usage = await widget.subjectService.getUsage(subjectId);

    final message = usage.sessionCount == 0
        ? 'Esta matéria ainda não tem sessões registradas. Deseja excluí-la?'
        : 'Esta matéria tem ${usage.sessionCount} sessão(ões) registrada(s) '
            '(${DurationUtils.formatMinutes(usage.totalMinutes)} de estudo). '
            'O histórico NÃO será apagado — a matéria só deixará de '
            'aparecer nas suas listas ativas. Continuar?';

    if (!mounted) return;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Excluir matéria?',
      message: message,
    );

    if (confirmed != true) return;

    final error = await widget.subjectService.deleteSubject(subjectId);
    if (error != null) {
      if (mounted) _showError(error);
      return;
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar matéria' : 'Nova matéria'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Nome da matéria',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _targetHoursController,
            label: 'Meta (em horas)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),
          const Text('Prioridade'),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Baixa')),
              ButtonSegment(value: 1, label: Text('Normal')),
              ButtonSegment(value: 2, label: Text('Alta')),
            ],
            selected: {_priority},
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
          const SizedBox(height: 20),
          const Text('Cor'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: AppColors.palette.entries.map((entry) {
              final selected = entry.key == _selectedColorName;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorName = entry.key),
                child: CircleAvatar(
                  radius: selected ? 20 : 16,
                  backgroundColor: entry.value,
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Ícone'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: icons.map((icon) {
              final selected = icon == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.palette[_selectedColorName]!
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          CustomButton(
            label: _isEditing ? 'Salvar alterações' : 'Criar matéria',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
