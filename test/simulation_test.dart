import 'package:financia_auto/models/simulation.dart';
import 'package:financia_auto/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Price installment matches an independently calculated reference', () {
    // 50,000 financed at 1.8% monthly over 48 months.
    expect(
      LoanSimulation.calculateInstallment(50000, 1.8, 48),
      closeTo(1564.46605772452, .00001),
    );
    expect(LoanSimulation.calculateInstallment(12000, 0, 12), 1000);
  });
  test('Invalid loan inputs are rejected', () {
    expect(
      () => LoanSimulation.calculateInstallment(0, 2, 48),
      throwsArgumentError,
    );
    expect(
      () => LoanSimulation.calculateInstallment(1000, -1, 48),
      throwsArgumentError,
    );
    expect(
      () => LoanSimulation.calculateInstallment(1000, 2, 0),
      throwsArgumentError,
    );
    expect(
      () => LoanSimulation.calculateInstallment(double.nan, 2, 48),
      throwsArgumentError,
    );
  });
  test('Brazilian money parsing rejects ambiguous or malformed amounts', () {
    expect(parseAmount('65.000,50'), 65000.5);
    expect(parseAmount('65000'), 65000);
    expect(parseAmount('1,80'), 1.8);
    expect(parseAmount('1.8'), isNull);
    expect(parseAmount(''), isNull);
    expect(parseAmount('-1'), isNull);
    expect(parseAmount('1,2,3'), isNull);
  });
  test('Result totals and persisted fields remain consistent', () {
    final simulation = LoanSimulation(
      id: 'test',
      createdAt: DateTime(2026, 11, 16),
      salary: 5000,
      vehiclePrice: 60000,
      downPayment: 10000,
      year: 2024,
      condition: VehicleCondition.used,
      months: 48,
      monthlyRate: 1.8,
      bank: 'Personalizada',
      ratePeriod: 'Informada pelo usuário',
    );
    expect(simulation.principal, 50000);
    expect(simulation.purchaseTotal, simulation.installmentsTotal + 10000);
    expect(
      simulation.interestTotal,
      closeTo(simulation.installmentsTotal - 50000, .001),
    );
    expect(simulation.withinBudget, isFalse);
    expect(
      LoanSimulation.fromJson(simulation.toJson()).toJson(),
      simulation.toJson(),
    );
  });
}
