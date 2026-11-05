import 'dart:ui';

import 'package:drift/drift.dart';

import '../database/database.dart';
import '../repositories/subject_repository.dart';

/// Representa o progresso já calculado de uma matéria, pronto para
/// a tela exibir (evita a UI fazer conta sozinha).
class SubjectProgress {
  final Subject subject;
  final int studiedMinutes;

  SubjectProgress({required this.subject, required this.studiedMinutes});

  int get targetMinutes => subject.targetMinutes;

  int get remainingMinutes =>
      (targetMinutes - studiedMinutes).clamp(0, targetMinutes);

  /// Percentual de 0.0 a 1.0 (nunca passa de 1.0, mesmo se estudou
  /// mais que a meta).
  double get progress =>
      targetMinutes == 0 ? 0 : (studiedMinutes / targetMinutes).clamp(0, 1);

  bool get isCompleted => studiedMinutes >= targetMinutes && targetMinutes > 0;
}

/// ============================================================
/// ARQUIVO: lib/services/subject_service.dart
/// FUNÇÃO: Regras de negócio relacionadas a MATÉRIAS. É aqui que
///         "progresso", "restante" e "concluído" são calculados -
///         sempre a partir da soma real das sessões, nunca de um
///         número salvo à parte.
///
/// POSSO ALTERAR:
///   - A fórmula de progresso, se quiser mudar como ele é calculado.
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - Não mova esta lógica para dentro das telas (screens). Se
///     cada tela calcular progresso do seu próprio jeito, os
///     números podem divergir entre o dashboard e a tela de matérias.
///
/// DEPENDÊNCIAS:
///   - repositories/subject_repository.dart
///   - screens/home, screens/subjects (consomem SubjectProgress)
/// ============================================================
class SubjectService {
  final SubjectRepository _repository;

  SubjectService(this._repository);

  Stream<List<Subject>> watchAllSubjects() => _repository.watchAll();

  /// Combina a lista de matérias com o total estudado de cada uma,
  /// já pronto para a UI.
  Stream<List<SubjectProgress>> watchAllWithProgress() {
    return watchAllSubjects().asyncMap((subjects) async {
      final result = <SubjectProgress>[];
      for (final subject in subjects) {
        final minutes = await _repository.watchTotalMinutes(subject.id).first;
        result.add(SubjectProgress(subject: subject, studiedMinutes: minutes));
      }
      return result;
    });
  }

  /// Valida nome e meta. Retorna uma mensagem de erro em português
  /// se algo for inválido, ou null se estiver tudo certo.
  ///
  /// Essa validação fica aqui (e não só na tela) porque é uma REGRA
  /// DE NEGÓCIO: "matéria não pode ter nome vazio ou meta inválida"
  /// é verdade em qualquer lugar do app que crie ou edite uma
  /// matéria, não só no formulário atual.
  String? _validate({required String name, required int targetMinutes}) {
    if (name.trim().isEmpty) {
      return 'O nome da matéria não pode ficar vazio.';
    }
    if (targetMinutes <= 0) {
      return 'A meta precisa ser maior que zero.';
    }
    return null;
  }

  /// Cria uma matéria nova. Retorna uma mensagem de erro (String) se
  /// a validação falhar ou se o banco recusar a operação, ou null
  /// se deu tudo certo.
  Future<String?> createSubject({
    required String name,
    required int targetMinutes,
    required Color color,
    required String icon,
    required int priority,
  }) async {
    final validationError =
        _validate(name: name, targetMinutes: targetMinutes);
    if (validationError != null) return validationError;

    try {
      await _repository.create(SubjectsCompanion.insert(
        name: name.trim(),
        targetMinutes: targetMinutes,
        colorValue: color.toARGB32(),
        icon: Value(icon),
        priority: Value(priority),
      ));
      return null;
    } on DatabaseFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> updateSubject(Subject subject) async {
    final validationError = _validate(
      name: subject.name,
      targetMinutes: subject.targetMinutes,
    );
    if (validationError != null) return validationError;

    try {
      await _repository.update(subject.copyWith(name: subject.name.trim()));
      return null;
    } on DatabaseFailure catch (e) {
      return e.message;
    }
  }

  /// Quantas sessões e quantas horas de histórico uma matéria tem.
  /// Usado pela tela de confirmação, para avisar o que será levado
  /// junto se a matéria for excluída (arquivada).
  Future<({int sessionCount, int totalMinutes})> getUsage(int subjectId) =>
      _repository.getUsage(subjectId);

  /// "Excluir" uma matéria na verdade a arquiva — ela some das
  /// listas ativas, mas o histórico de sessões não é apagado.
  /// Retorna uma mensagem de erro em português se o banco recusar
  /// a operação, ou null se deu certo.
  Future<String?> deleteSubject(int id) async {
    try {
      await _repository.archive(id);
      return null;
    } on DatabaseFailure catch (e) {
      return e.message;
    }
  }
}
