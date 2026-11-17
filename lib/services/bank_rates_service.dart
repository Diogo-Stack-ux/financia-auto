import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/simulation.dart';

class BankRatesService {
  BankRatesService({this._client});
  final http.Client? _client;
  static const source = 'https://www.bcb.gov.br/estatisticas/txjuros';

  Future<List<BankRate>> fetch() async {
    final uri = Uri.https(
      'olinda.bcb.gov.br',
      '/olinda/servico/taxaJuros/versao/v2/odata/ConsultaUnificada',
      {
        '\$format': 'json',
        '\$filter': "codigoSegmento eq '1' and codigoModalidade eq '401101'",
        '\$orderby': 'InicioPeriodo desc,TaxaJurosAoMes asc',
        '\$top': '100',
      },
    );
    final response = await (_client?.get(uri) ?? http.get(uri)).timeout(
      const Duration(seconds: 18),
    );
    if (response.statusCode != 200) {
      throw Exception('Banco Central indisponível.');
    }
    final rows =
        (jsonDecode(response.body) as Map<String, dynamic>)['value'] as List;
    if (rows.isEmpty) {
      throw Exception('Nenhuma taxa disponível para esta modalidade.');
    }
    final latestPeriod = (rows.first as Map)['InicioPeriodo'].toString();
    final rates = <BankRate>[];
    for (final row in rows.cast<Map<String, dynamic>>()) {
      if (row['InicioPeriodo'].toString() != latestPeriod) continue;
      final value = double.tryParse(
        row['TaxaJurosAoMes'].toString().replaceAll(',', '.'),
      );
      if (value == null || !value.isFinite || value < 0) continue;
      rates.add(
        BankRate(
          bank: row['InstituicaoFinanceira'].toString(),
          monthlyRate: value,
          period:
              '${row['InicioPeriodo'].toString().split('T').first} a ${row['FimPeriodo'].toString().split('T').first}',
        ),
      );
    }
    if (rates.isEmpty) {
      throw Exception('As taxas recebidas não puderam ser lidas.');
    }
    rates.sort((a, b) => a.monthlyRate.compareTo(b.monthlyRate));
    return rates;
  }
}
