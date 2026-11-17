import 'package:material_ui/material_ui.dart';

import '../color/app_colors.dart';
import '../models/simulation.dart';
import '../services/app_state.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({
    super.key,
    required this.simulation,
    required this.state,
    this.alreadySaved = false,
  });
  final LoanSimulation simulation;
  final AppState state;
  final bool alreadySaved;
  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late bool _saved = widget.alreadySaved;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.state.save(widget.simulation);
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.state.syncMessage ?? 'Simulação salva no histórico.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.simulation;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sua simulação'),
        backgroundColor: AppColors.background,
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      tint: const Color(0xFFE0EDFF),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.blue,
                            size: 32,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'PARCELA ESTIMADA',
                            style: TextStyle(
                              letterSpacing: 2,
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              money(s.installment),
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(color: AppColors.blue),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${s.months} parcelas · ${percent(s.monthlyRate)} ao mês',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            s.bank,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            s.ratePeriod,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cada número, às claras',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          _row('Valor do veículo', money(s.vehiclePrice)),
                          _row('Entrada', money(s.downPayment)),
                          _row(
                            'Total a contratar (principal)',
                            money(s.principal),
                          ),
                          _row(
                            'Juros estimados no período',
                            money(s.interestTotal),
                          ),
                          _row('Soma das parcelas', money(s.installmentsTotal)),
                          const Divider(height: 24),
                          _row(
                            'Custo com entrada',
                            money(s.purchaseTotal),
                            bold: true,
                          ),
                          _row(
                            'Taxa efetiva anual equivalente',
                            '${percent(s.annualRate)} a.a.',
                          ),
                          _row('Veículo', '${s.condition.label} · ${s.year}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                s.withinBudget
                                    ? Icons.check_circle_outline
                                    : Icons.info_outline,
                                color: s.withinBudget
                                    ? AppColors.green
                                    : AppColors.amber,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.withinBudget
                                      ? 'Dentro da referência de orçamento'
                                      : 'Atenção ao seu orçamento',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Esta parcela representa ${percent(s.incomeRatio * 100)} da renda informada (${money(s.salary)}).',
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: s.incomeRatio.clamp(0, 1),
                              minHeight: 9,
                              color: s.withinBudget
                                  ? AppColors.green
                                  : AppColors.amber,
                              backgroundColor: AppColors.line,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Usamos 30% da renda apenas como referência de planejamento. Isso não é um critério de aprovação do banco.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Estimativa pela Tabela Price, com primeira parcela em um mês e prestações fixas. Não inclui IOF, tarifas, seguros ou outros custos; não representa o CET nem uma proposta de crédito. Ano e condição do veículo ficam registrados para a comparação, mas a elegibilidade depende da instituição.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saved || _saving ? null : _save,
                      icon: Icon(
                        _saved ? Icons.check : Icons.bookmark_border_rounded,
                      ),
                      label: Text(
                        _saved
                            ? 'Salva no histórico'
                            : _saving
                            ? 'Salvando…'
                            : 'Salvar simulação',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
