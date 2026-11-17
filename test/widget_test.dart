import 'package:financia_auto/main.dart';
import 'package:financia_auto/services/app_state.dart';
import 'package:financia_auto/services/ads_service.dart';
import 'package:financia_auto/pages/simulator_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'Welcome and introduction appear once, before the main navigation',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(const FinanciaAutoApp());
      await tester.pumpAndSettle();
      expect(
        find.text('Seu próximo carro.\nSua melhor escolha.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Um bom caminho\ncomeça com um plano.'), findsOneWidget);
      await tester.ensureVisible(find.text('Fazer minha primeira simulação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fazer minha primeira simulação'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool('onboarded'),
        isTrue,
      );
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(find.text('Seu próximo plano começa aqui'), findsOneWidget);
      // Recreate the app as if it were opened a second time.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const FinanciaAutoApp());
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Continuar'), findsNothing);
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Manual calculation validates values, opens result and saves history',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final state = AppState(await SharedPreferences.getInstance());
      final ads = AdsService();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimulatorPage(state: state, ads: ads),
          ),
        ),
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '5000');
      await tester.enterText(fields.at(1), '60000');
      await tester.enterText(fields.at(2), '10000');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Usar uma taxa personalizada'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar uma taxa personalizada'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Calcular parcela'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calcular parcela'));
      await tester.pumpAndSettle();
      expect(find.text('Sua simulação'), findsOneWidget);
      await tester.ensureVisible(find.text('Salvar simulação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar simulação'));
      await tester.pumpAndSettle();
      expect(state.history, hasLength(1));
      expect(state.history.first.principal, 50000);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      ads.dispose();
    },
  );
}
