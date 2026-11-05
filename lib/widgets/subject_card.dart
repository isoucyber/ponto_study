import 'package:flutter/material.dart';

import '../services/subject_service.dart';
import '../theme/app_text_styles.dart';
import '../utils/duration_utils.dart';
import 'progress_bar.dart';

/// ============================================================
/// ARQUIVO: lib/widgets/subject_card.dart
/// FUNÇÃO: Card visual de UMA matéria, mostrando nome, ícone,
///         barra de progresso e "8h / 10h". Usado no dashboard e
///         na tela "Minhas Matérias".
///
/// POSSO ALTERAR:
///   - Layout, espaçamentos, textos, tamanho de fontes.
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - O cálculo de progresso (vem pronto de SubjectProgress,
///     que já garante que estudado/meta/percentual estão corretos).
///
/// DEPENDÊNCIAS:
///   - services/subject_service.dart (fornece o SubjectProgress)
///   - widgets/progress_bar.dart
/// ============================================================
class SubjectCard extends StatelessWidget {
  final SubjectProgress progress;
  final VoidCallback? onTap;

  const SubjectCard({super.key, required this.progress, this.onTap});

  @override
  Widget build(BuildContext context) {
    final subject = progress.subject;
    final color = Color(subject.colorValue);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(subject.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(subject.name,
                        style: AppTextStyles.subtitle,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (progress.isCompleted)
                    Icon(Icons.check_circle, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              ProgressBarWidget(progress: progress.progress, color: color),
              const SizedBox(height: 8),
              Text(
                '${DurationUtils.formatMinutes(progress.studiedMinutes)} / '
                '${DurationUtils.formatMinutes(progress.targetMinutes)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
