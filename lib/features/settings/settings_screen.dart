import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';

// ============================================================
// ARQUIVO: lib/features/settings/settings_screen.dart
// FUNÇÃO: Perfil local (nome, objetivo, metas), aparência (tema, modo
//         claro/escuro, cor de destaque) e informações sobre os dados.
// ============================================================

const appVersion = '0.1.0';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return PageScaffold(
      title: 'Configurações',
      showBack: false,
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: const [
            ContentWidth(
              maxWidth: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileSection(),
                  SizedBox(height: 16),
                  _AppearanceSection(),
                  SizedBox(height: 16),
                  _DataSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.settings.profile;
    final pal = pontoOf(context).palette;
    if (p == null) return const SizedBox.shrink();
    return SectionCard(
      title: 'Perfil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(p.avatar)),
            title: Text(p.name),
            subtitle: Text(p.objective.isEmpty ? 'Sem objetivo definido' : p.objective),
            trailing: OutlinedButton(
              onPressed: () => _editProfile(context, p),
              child: const Text('Editar'),
            ),
          ),
          const Divider(height: 24),
          Text('Metas de estudo', style: TextStyle(color: pal.textMuted)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('daily-${p.dailyGoalMinutes}'),
                initialValue: _closest(p.dailyGoalMinutes, _dailyOptions),
                decoration: const InputDecoration(labelText: 'Meta diária'),
                items: [
                  for (final m in _dailyOptions)
                    DropdownMenuItem(
                        value: m,
                        child: Text(m == 0 ? 'Sem meta' : formatDuration(m * 60))),
                ],
                onChanged: (v) => app.settingsRepo
                    .updateProfile(id: p.id, dailyGoalMinutes: v ?? 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('weekly-${p.weeklyGoalMinutes}'),
                initialValue: _closest(p.weeklyGoalMinutes, _weeklyOptions),
                decoration: const InputDecoration(labelText: 'Meta semanal'),
                items: [
                  for (final m in _weeklyOptions)
                    DropdownMenuItem(
                        value: m,
                        child: Text(m == 0 ? 'Sem meta' : formatDuration(m * 60))),
                ],
                onChanged: (v) => app.settingsRepo
                    .updateProfile(id: p.id, weeklyGoalMinutes: v ?? 0),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  static const _dailyOptions = [
    0, 30, 45, 60, 90, 120, 150, 180, 240, 300, 360, 480
  ];
  static const _weeklyOptions = [
    0, 120, 180, 300, 420, 600, 900, 1200, 1500, 1800, 2400, 3000
  ];

  static int _closest(int value, List<int> options) {
    var best = options.first;
    for (final o in options) {
      if ((o - value).abs() < (best - value).abs()) best = o;
    }
    return best;
  }

  Future<void> _editProfile(BuildContext context, Profile p) async {
    final repo = AppScope.of(context).settingsRepo;
    final name = TextEditingController(text: p.name);
    final objective = TextEditingController(text: p.objective);
    var avatar = p.avatar;
    const avatars = ['🙂', '😎', '🦉', '🦊', '🐼', '🌱', '🚀', '📘', '🎯', '🧑‍💻'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar perfil'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final a in avatars)
                    ChoiceChip(
                      label: Text(a, style: const TextStyle(fontSize: 18)),
                      selected: avatar == a,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => avatar = a),
                    ),
                ]),
                const SizedBox(height: 14),
                TextField(
                  controller: name,
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: objective,
                  decoration: const InputDecoration(
                    labelText: 'Objetivo (opcional)',
                    hintText: 'Ex.: aprender Java para o estágio',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await repo.updateProfile(
        id: p.id,
        name: name.text.trim(),
        objective: objective.text.trim(),
        avatar: avatar,
      );
    }
    name.dispose();
    objective.dispose();
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final pal = pontoOf(context).palette;
    return SectionCard(
      title: 'Aparência',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveGrid(
            minItemWidth: 250,
            spacing: 10,
            children: [
              for (final t in appThemes)
                _ThemeCard(
                  spec: t,
                  selected: settings.themeId == t.id,
                  brightness: settings.themeMode == 'light'
                      ? Brightness.light
                      : settings.themeMode == 'dark'
                          ? Brightness.dark
                          : t.natural,
                  onTap: () => settings.setTheme(t.id),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Modo', style: TextStyle(color: pal.textMuted)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'auto', label: Text('Do tema')),
              ButtonSegment(value: 'light', label: Text('Claro')),
              ButtonSegment(value: 'dark', label: Text('Escuro')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => settings.setThemeMode(s.first),
          ),
          const SizedBox(height: 18),
          Text('Cor de destaque (personalização avançada)',
              style: TextStyle(color: pal.textMuted)),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            ChoiceChip(
              label: const Text('Padrão do tema'),
              selected: settings.accentColor == null,
              onSelected: (_) => settings.setAccent(null),
            ),
            for (final c in subjectColors)
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => settings.setAccent(c.toARGB32()),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: settings.accentColor == c.toARGB32()
                          ? pal.text
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              ),
          ]),
        ],
      ),
    );
  }
}

/// Miniatura do tema: mostra o fundo, um card e a cor de destaque.
class _ThemeCard extends StatelessWidget {
  final AppThemeSpec spec;
  final bool selected;
  final Brightness brightness;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.spec,
    required this.selected,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = spec.palette(brightness);
    final current = pontoOf(context).palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? current.primary : p.border,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(spec.radius / 2),
              border: Border.all(color: p.border),
            ),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _dot(p.primary),
              const SizedBox(width: 3),
              _dot(p.secondary),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spec.name,
                    style: TextStyle(
                      color: p.text,
                      fontWeight: FontWeight.w700,
                      fontFamily: spec.headingFont,
                      fontFamilyFallback: spec.headingFallback,
                    )),
                const SizedBox(height: 2),
                Text(spec.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (selected) Icon(Icons.check_circle, color: current.primary),
        ]),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

class _DataSection extends StatelessWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    return SectionCard(
      title: 'Seus dados',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tudo fica salvo apenas neste aparelho, num banco SQLite local. '
            'Nada é enviado para a internet.',
            style: TextStyle(color: pal.textMuted),
          ),
          const SizedBox(height: 10),
          FutureBuilder<String>(
            future: databaseFilePath(),
            builder: (context, snap) => SelectableText(
              snap.data ?? '',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Backup e restauração em arquivo chegam na próxima versão '
            '(Etapa 3). Até lá, para copiar seus dados, feche o app e copie '
            'o arquivo acima.',
            style: TextStyle(color: pal.textMuted, fontSize: 12.5),
          ),
          const Divider(height: 28),
          const Text('Ponto Study $appVersion',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
