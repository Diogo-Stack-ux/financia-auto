import 'dart:convert';

import 'package:financia_auto/services/bank_rates_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'Queries PF vehicle credit and only returns the latest period, sorted',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, endsWith('/ConsultaUnificada'));
        expect(
          request.url.queryParameters['\$filter'],
          "codigoSegmento eq '1' and codigoModalidade eq '401101'",
        );
        return http.Response(
          jsonEncode({
            'value': [
              {
                'InicioPeriodo': '2026-10-26',
                'FimPeriodo': '2026-10-30',
                'InstituicaoFinanceira': 'Banco B',
                'TaxaJurosAoMes': 2.1,
              },
              {
                'InicioPeriodo': '2026-10-26',
                'FimPeriodo': '2026-10-30',
                'InstituicaoFinanceira': 'Banco A',
                'TaxaJurosAoMes': 0,
              },
              {
                'InicioPeriodo': '2026-10-26',
                'FimPeriodo': '2026-10-30',
                'InstituicaoFinanceira': 'Inválido',
                'TaxaJurosAoMes': -1,
              },
              {
                'InicioPeriodo': '2026-10-19',
                'FimPeriodo': '2026-10-23',
                'InstituicaoFinanceira': 'Antigo',
                'TaxaJurosAoMes': 1.5,
              },
            ],
          }),
          200,
        );
      });
      final rates = await BankRatesService(client: client).fetch();
      expect(rates.map((r) => r.bank), ['Banco A', 'Banco B']);
      expect(rates.first.period, '2026-10-26 a 2026-10-30');
      client.close();
    },
  );

  test('An API error never becomes fabricated offers', () async {
    final client = MockClient((_) async => http.Response('Unavailable', 503));
    await expectLater(
      BankRatesService(client: client).fetch(),
      throwsException,
    );
    client.close();
  });
}
