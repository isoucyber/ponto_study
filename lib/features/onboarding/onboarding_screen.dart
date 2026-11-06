import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_decor.dart';

// ============================================================
// ARQUIVO: lib/features/onboarding/onboarding_screen.dart
// FUNÇÃO: Primeira abertura do app. Pede apenas o nome, sem e-mail,
//         senha ou internet. Depois disso, o app abre direto na tela
//         principal (o nome pode ser trocado nas Configurações).
// ============================================================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    await AppScope.of(context).settings.createProfile(name);
  }

  @override
  Widget build(BuildContext context) {
    final pal = pontoOf(context).palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ThemeDecoration()),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: pal.primary, width: 4),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                            color: pal.primary, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('Bem-vindo ao Ponto Study', style: text.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Organize suas matérias, registre seu tempo e acompanhe '
                      'quanto você realmente domina cada conteúdo. Tudo fica '
                      'salvo neste aparelho.',
                      style: TextStyle(color: pal.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 32),
                    Text('Como podemos chamar você?', style: text.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLength: 60,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Seu nome'),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _controller.text.trim().isEmpty || _saving
                            ? null
                            : _save,
                        child: const Text('Começar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
