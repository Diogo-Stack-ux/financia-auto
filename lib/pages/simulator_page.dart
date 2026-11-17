import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../color/app_colors.dart';
import '../models/simulation.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../services/bank_rates_service.dart';
import '../utils/formatters.dart';
import '../widgets/ad_banner.dart';
import '../widgets/glass_card.dart';
import 'result_page.dart';

class SimulatorPage extends StatefulWidget {
  const SimulatorPage({super.key, required this.state, required this.ads});
  final AppState state;
  final AdsService ads;
  @override
  State<SimulatorPage> createState() => _SimulatorPageState();
}

class _SimulatorPageState extends State<SimulatorPage> {
  final _form = GlobalKey<FormState>();
  final _salary = TextEditingController();
  final _price = TextEditingController();
  final _entry = TextEditingController(text: '0');
  final _year = TextEditingController(text: '${DateTime.now().year}');
  final _customRate = TextEditingController(text: '1,80');
  VehicleCondition _condition = VehicleCondition.nearlyNew;
  int _months = 48;
  bool _custom = false, _loading = false, _withinBudget = false;
  String _bankSearch = '';
  String? _error;
  List<BankRate>? _rates;
  List<LoanSimulation>? _comparisons;
  DateTime? _queriedAt;

  @override
  void dispose() {
    for (final controller in [_salary, _price, _entry, _year, _customRate]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _invalidate() {
    if (_comparisons != null || _error != null) {
      setState(() {
        _comparisons = null;
        _error = null;
      });
    }
  }

  LoanSimulation _simulation(BankRate rate, int index) {
    final now = DateTime.now();
    return LoanSimulation(
      id: '${now.microsecondsSinceEpoch}_$index',
      createdAt: now,
      salary: parseAmount(_salary.text)!,
      vehiclePrice: parseAmount(_price.text)!,
      downPayment: parseAmount(_entry.text)!,
      year: int.parse(_year.text),
      condition: _condition,
      months: _months,
      monthlyRate: rate.monthlyRate,
      bank: rate.bank,
      ratePeriod: rate.period,
    );
  }

  Future<void> _compare({bool refresh = false}) async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_custom) {
      final result = _simulation(
        BankRate(
          bank: 'Taxa personalizada',
          monthlyRate: parseAmount(_customRate.text)!,
          period: 'Informada por você · não verificada pelo banco',
        ),
        0,
      );
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ResultPage(simulation: result, state: widget.state),
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _comparisons = null;
    });
    try {
      if (_rates == null || refresh) {
        _rates = await BankRatesService().fetch();
        _queriedAt = DateTime.now();
      }
      if (!mounted) return;
      setState(
        () => _comparisons = [
          for (var i = 0; i < _rates!.length; i++) _simulation(_rates![i], i),
        ],
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível consultar as taxas do Banco Central. Tente novamente ou use uma taxa personalizada.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _positive(String? text) {
    final amount = parseAmount(text ?? '');
    if (amount == null || amount <= 0) {
      return 'Informe um valor maior que zero (ex.: 5.000,00).';
    }
    if (amount > 100000000) return 'Use um valor de até R\$ 100 milhões.';
    return null;
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    children: [
      GlassCard(
        tint: const Color(0xFFE9F2FF),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'MENOS DÚVIDAS. MAIS CAMINHOS.',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1,
                          color: AppColors.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Seu carro novo\ncomeça no planejamento.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Compare parcelas e entenda quanto você vai pagar antes de decidir.',
                      style: TextStyle(color: AppColors.muted, height: 1.6),
                    ),
                  ],
                ),
              ),
              if (constraints.maxWidth > 650)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Transform.rotate(
                    angle: -.08,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .7),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.directions_car_filled_rounded,
                        size: 92,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      GlassCard(
        child: Form(
          key: _form,
          onChanged: _invalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vamos encontrar seu caminho',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Preencha os valores para comparar cenários.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 600;
                  final width = wide
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 18,
                    children: [
                      SizedBox(
                        width: width,
                        child: _amount(
                          _salary,
                          'Sua renda mensal',
                          '5.000,00',
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _amount(
                          _price,
                          'Valor do veículo',
                          '65.000,00',
                          Icons.directions_car_outlined,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _amount(
                          _entry,
                          'Valor da entrada',
                          '15.000,00',
                          Icons.savings_outlined,
                          validator: (value) {
                            final amount = parseAmount(value ?? '');
                            if (amount == null || amount < 0) {
                              return 'Informe uma entrada válida (zero é permitido).';
                            }
                            final price = parseAmount(_price.text);
                            if (price != null && amount >= price) {
                              return 'A entrada deve ser menor que o valor do veículo.';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: TextFormField(
                          enabled: !_loading,
                          controller: _year,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Ano de fabricação',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (value) {
                            final year = int.tryParse(value ?? '');
                            final now = DateTime.now().year;
                            if (year == null || year < 1950 || year > now + 1) {
                              return 'Informe um ano entre 1950 e ${now + 1}.';
                            }
                            if (_condition == VehicleCondition.newCar &&
                                year < now - 1) {
                              return 'Para zero km, use um ano a partir de ${now - 1}.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'Condição do veículo',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: VehicleCondition.values
                    .map(
                      (condition) => ChoiceChip(
                        label: Text(condition.label),
                        selected: _condition == condition,
                        onSelected: _loading
                            ? null
                            : (_) {
                                setState(() => _condition = condition);
                                _invalidate();
                              },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              const Text(
                'Em quantos meses?',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [12, 24, 36, 48, 60, 72]
                    .map(
                      (months) => ChoiceChip(
                        label: Text('${months}x'),
                        selected: months == _months,
                        onSelected: _loading
                            ? null
                            : (_) {
                                setState(() => _months = months);
                                _invalidate();
                              },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Usar uma taxa personalizada',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: const Text(
                  'Já recebeu uma taxa do banco?',
                  style: TextStyle(fontSize: 11),
                ),
                value: _custom,
                onChanged: _loading
                    ? null
                    : (value) {
                        setState(() => _custom = value);
                        _invalidate();
                      },
              ),
              if (_custom)
                TextFormField(
                  enabled: !_loading,
                  controller: _customRate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Taxa de juros mensal',
                    suffixText: '% a.m.',
                  ),
                  validator: (text) {
                    final value = parseAmount(text ?? '');
                    if (value == null || value < 0 || value > 20) {
                      return 'Informe uma taxa entre 0 e 20% ao mês.';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _compare,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.calculate_outlined),
                  label: Text(
                    _loading
                        ? 'Consultando Banco Central…'
                        : _custom
                        ? 'Calcular parcela'
                        : 'Comparar parcelas',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Simulação sem consulta ao CPF. Não solicita nem contrata crédito.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: GlassCard(
            child: Column(
              children: [
                const Icon(Icons.cloud_off_outlined, color: AppColors.muted),
                const SizedBox(height: 12),
                Text(_error!),
                TextButton(
                  onPressed: () => _compare(refresh: true),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      if (_comparisons != null) ..._results(context),
      const SizedBox(height: 22),
      const GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: AppColors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Compare o custo total, além da parcela. Um prazo maior pode reduzir o pagamento mensal e aumentar os juros totais.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
      AdBanner(ads: widget.ads),
    ],
  );

  Widget _amount(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    FormFieldValidator<String>? validator,
  }) => TextFormField(
    enabled: !_loading,
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
      LengthLimitingTextInputFormatter(16),
    ],
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: 'R\$ ',
      prefixIcon: Icon(icon),
    ),
    validator: validator ?? _positive,
  );

  List<Widget> _results(BuildContext context) {
    final visible = _comparisons!
        .where(
          (s) =>
              (!_withinBudget || s.withinBudget) &&
              s.bank.toLowerCase().contains(_bankSearch.toLowerCase()),
        )
        .toList();
    return [
      const SizedBox(height: 28),
      Text(
        'Compare com calma.',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        'Taxas médias do Banco Central · período ${_comparisons!.first.ratePeriod}',
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      const SizedBox(height: 6),
      Text(
        'Consultado em ${shortDate(_queriedAt!)}. As taxas variam por cliente; bancos de montadoras podem ter condições específicas.',
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.muted,
          height: 1.6,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        decoration: const InputDecoration(
          labelText: 'Buscar instituição',
          prefixIcon: Icon(Icons.search_rounded),
        ),
        onChanged: (value) => setState(() => _bankSearch = value),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: _withinBudget,
        title: const Text(
          'Parcelas de até 30% da renda',
          style: TextStyle(fontSize: 13),
        ),
        subtitle: const Text(
          'Referência de orçamento; não indica aprovação.',
          style: TextStyle(fontSize: 11),
        ),
        onChanged: (value) => setState(() => _withinBudget = value),
      ),
      const Text(
        'Ano e condição do veículo são registrados. O Banco Central não informa regras de elegibilidade por veículo. IOF, tarifas e seguros não estão incluídos.',
        style: TextStyle(fontSize: 11, height: 1.6, color: AppColors.muted),
      ),
      const SizedBox(height: 16),
      if (visible.isEmpty)
        const GlassCard(
          child: Text(
            'Nenhum resultado para estes filtros. Você pode aumentar a entrada, rever o valor do veículo ou ajustar o prazo.',
          ),
        ),
      for (final s in visible)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.bank, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parcela estimada',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          money(s.installment),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.blue),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Taxa média mensal',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                        Text('${percent(s.monthlyRate)} a.m.'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${percent(s.incomeRatio * 100)} da renda · total das parcelas ${money(s.installmentsTotal)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ResultPage(simulation: s, state: widget.state),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Ver simulação completa'),
                ),
              ],
            ),
          ),
        ),
      TextButton.icon(
        onPressed: () async {
          final opened = await launchUrl(
            Uri.parse(BankRatesService.source),
            mode: LaunchMode.externalApplication,
          );
          if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Não foi possível abrir o site do Banco Central.',
                ),
              ),
            );
          }
        },
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: const Text('Consultar fonte: Banco Central'),
      ),
      TextButton(
        onPressed: () => _compare(refresh: true),
        child: const Text('Atualizar taxas'),
      ),
    ];
  }
}
