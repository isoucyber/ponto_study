import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponto_study/app/app.dart';
import 'package:ponto_study/app/app_scope.dart';
import 'package:ponto_study/core/database/database.dart';

// Teste de interface: abre o app do zero, informa o nome na primeira
// tela e confirma que a tela principal aparece com a saudação.
void main() {
  testWidgets('primeira abertura pede o nome e abre o Início', (tester) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final services = AppServices(db);
    await tester.runAsync(() => services.settings.load());

    await tester.pumpWidget(
        AppScope(services: services, child: const PontoStudyApp()));
    await tester.pump();

    expect(find.text('Como podemos chamar você?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Arthur');
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Começar'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(services.settings.profile?.name, 'Arthur');
    expect(find.textContaining('Arthur'), findsWidgets);
    expect(find.text('Matérias'), findsWidgets);

    // Desmonta a interface e fecha o banco para não deixar timers pendentes.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      services.timer.dispose();
      await db.close();
    });
    await tester.pump(const Duration(seconds: 1));
  });
}
