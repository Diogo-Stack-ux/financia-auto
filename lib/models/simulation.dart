import 'dart:math' as math;

enum VehicleCondition {
  newCar('Zero km'),
  nearlyNew('Seminovo'),
  used('Usado');

  const VehicleCondition(this.label);
  final String label;
}

class BankRate {
  const BankRate({
    required this.bank,
    required this.monthlyRate,
    required this.period,
  });
  final String bank;
  final double monthlyRate;
  final String period;
}

class LoanSimulation {
  const LoanSimulation({
    required this.id,
    required this.createdAt,
    required this.salary,
    required this.vehiclePrice,
    required this.downPayment,
    required this.year,
    required this.condition,
    required this.months,
    required this.monthlyRate,
    required this.bank,
    required this.ratePeriod,
  });

  final String id;
  final DateTime createdAt;
  final double salary, vehiclePrice, downPayment, monthlyRate;
  final int year, months;
  final VehicleCondition condition;
  final String bank, ratePeriod;

  double get principal => vehiclePrice - downPayment;
  double get installment =>
      calculateInstallment(principal, monthlyRate, months);
  double get installmentsTotal => installment * months;
  double get interestTotal => math.max(0, installmentsTotal - principal);
  double get purchaseTotal => installmentsTotal + downPayment;
  double get incomeRatio => installment / salary;
  double get annualRate => (math.pow(1 + monthlyRate / 100, 12) - 1) * 100;
  bool get withinBudget => incomeRatio <= .30;

  static double calculateInstallment(
    double principal,
    double monthlyRate,
    int months,
  ) {
    if (!principal.isFinite ||
        principal <= 0 ||
        !monthlyRate.isFinite ||
        monthlyRate < 0 ||
        months <= 0) {
      throw ArgumentError('Valor, taxa ou prazo inválido.');
    }
    if (monthlyRate == 0) return principal / months;
    final rate = monthlyRate / 100;
    return principal * rate / (1 - math.pow(1 + rate, -months));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'salary': salary,
    'vehiclePrice': vehiclePrice,
    'downPayment': downPayment,
    'year': year,
    'condition': condition.name,
    'months': months,
    'monthlyRate': monthlyRate,
    'bank': bank,
    'ratePeriod': ratePeriod,
  };

  factory LoanSimulation.fromJson(Map<String, dynamic> json) => LoanSimulation(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    salary: (json['salary'] as num).toDouble(),
    vehiclePrice: (json['vehiclePrice'] as num).toDouble(),
    downPayment: (json['downPayment'] as num).toDouble(),
    year: json['year'] as int,
    condition: VehicleCondition.values.byName(json['condition'] as String),
    months: json['months'] as int,
    monthlyRate: (json['monthlyRate'] as num).toDouble(),
    bank: json['bank'] as String,
    ratePeriod: json['ratePeriod'] as String,
  );
}
