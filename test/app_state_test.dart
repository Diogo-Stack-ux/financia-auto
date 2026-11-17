import 'package:financia_auto/models/simulation.dart';
import 'package:financia_auto/services/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'History survives reopening, prevents duplicates and supports removal',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final state = AppState(prefs);
      final simulation = LoanSimulation(
        id: 'saved',
        createdAt: DateTime(2026),
        salary: 4000,
        vehiclePrice: 40000,
        downPayment: 10000,
        year: 2024,
        condition: VehicleCondition.used,
        months: 36,
        monthlyRate: 1.5,
        bank: 'Personalizada',
        ratePeriod: 'Manual',
      );
      await state.save(simulation);
      await state.save(simulation);
      final reopened = AppState(prefs);
      expect(reopened.history, hasLength(1));
      expect(reopened.history.first.toJson(), simulation.toJson());
      await reopened.remove(reopened.history.first);
      final empty = AppState(prefs);
      expect(empty.history, isEmpty);
      state.dispose();
      reopened.dispose();
      empty.dispose();
    },
  );

  test(
    'A damaged record does not erase valid history or onboarding state',
    () async {
      SharedPreferences.setMockInitialValues({
        'history_guest': ['invalid json'],
      });
      final state = AppState(await SharedPreferences.getInstance());
      expect(state.history, isEmpty);
      await state.finishOnboarding();
      expect(state.hasOnboarded, isTrue);
      state.dispose();
    },
  );
}
