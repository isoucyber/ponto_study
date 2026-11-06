import 'package:flutter/material.dart';

import '../theme/app_themes.dart';
import '../theme/theme_decor.dart';

// ============================================================
// ARQUIVO: lib/core/widgets/common.dart
// FUNÇÃO: Componentes visuais reutilizados em todas as telas.
//         Mudar o visual de um card ou de uma tela vazia aqui muda o
//         app inteiro, mantendo tudo consistente.
// ============================================================

/// Estrutura padrão de página: barra de título + decoração do tema + conteúdo.
class PageScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showBack;

  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        automaticallyImplyLeading: showBack,
      ),
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          const Positioned.fill(child: ThemeDecoration()),
          Positioned.fill(child: body),
        ],
      ),
    );
  }
}

/// Limita a largura do conteúdo em telas grandes e aplica margens.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ContentWidth({super.key, required this.child, this.maxWidth = 1100});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Card com título opcional.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(pontoOf(context).spec.radius);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Row(children: [
                  Expanded(
                    child: Text(title!,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (trailing != null) trailing!,
                ]),
                const SizedBox(height: 12),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador grande (número + rótulo), usado no Dashboard.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final double? progress;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: pal.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: pal.textMuted, fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!,
                style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
          ],
          if (progress != null) ...[
            const SizedBox(height: 10),
            ProgressLine(value: progress!),
          ],
        ],
      ),
    );
  }
}

/// Barra de progresso fina e arredondada.
class ProgressLine extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  const ProgressLine(
      {super.key, required this.value, this.color, this.height = 7});

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: height,
        backgroundColor: pal.surfaceAlt,
        color: color ?? pal.primary,
      ),
    );
  }
}

/// Tela vazia amigável, com ação sugerida.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: pal.primary.withValues(alpha: 0.8)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: pal.textMuted)),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ícone da matéria (emoji dentro de um círculo da cor da matéria).
class SubjectBadge extends StatelessWidget {
  final String icon;
  final int colorValue;
  final double size;
  const SubjectBadge(
      {super.key, required this.icon, required this.colorValue, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Text(icon, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}

/// Pergunta de confirmação. Retorna true se o usuário confirmar.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Layout em grade que se adapta à largura (1 a 4 colunas).
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 220,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / minItemWidth).floor().clamp(1, 4);
      final itemWidth = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children)
            SizedBox(width: itemWidth, child: child),
        ],
      );
    });
  }
}
