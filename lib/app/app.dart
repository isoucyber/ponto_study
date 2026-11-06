import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/onboarding/onboarding_screen.dart';
import 'app_scope.dart';
import 'shell.dart';

// ============================================================
// ARQUIVO: lib/app/app.dart
// FUNÇÃO: Configura o MaterialApp (tema, idioma) e decide a primeira
//         tela: se ainda não há perfil, mostra "Como podemos chamar
//         você?"; senão, abre direto a tela principal.
// ============================================================

class PontoStudyApp extends StatelessWidget {
  const PontoStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Ponto Study',
          debugShowCheckedModeBanner: false,
          theme: settings.themeData,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: settings.profile == null
              ? const OnboardingScreen()
              : const AppShell(),
        );
      },
    );
  }
}
