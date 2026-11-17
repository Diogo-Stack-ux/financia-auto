import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);
String money(num value) => _currency.format(value);
String percent(num value) =>
    '${value.toStringAsFixed(2).replaceAll('.', ',')}%';
String shortDate(DateTime date) =>
    DateFormat('dd/MM/yyyy · HH:mm', 'pt_BR').format(date);

/// The form uses Brazilian notation: 1.234,56 or 1234,56.
double? parseAmount(String text) {
  final cleaned = text.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (!RegExp(r'^\d+(?:\.\d{3})*(?:,\d{1,2})?$').hasMatch(cleaned)) return null;
  final value = double.tryParse(
    cleaned.replaceAll('.', '').replaceAll(',', '.'),
  );
  return value != null && value.isFinite ? value : null;
}
