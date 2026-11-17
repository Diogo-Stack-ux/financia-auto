import 'package:material_ui/material_ui.dart';

import '../color/app_colors.dart';
import '../services/app_state.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';
import 'result_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.state, required this.onSimulate});
  final AppState state;
  final VoidCallback onSimulate;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Seus planos,\nsempre por perto.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            '${state.history.length} simulações salvas ${state.user == null ? 'neste aparelho' : 'na sua conta'}',
            style: const TextStyle(color: AppColors.muted),
          ),
          if (state.syncMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(state.syncMessage!),
            ),
          const SizedBox(height: 24),
          if (state.history.isEmpty)
            GlassCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AppColors.blue,
                    size: 52,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seu próximo plano começa aqui',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Salve uma simulação para comparar os valores depois.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onSimulate,
                    child: const Text('Simular agora'),
                  ),
                ],
              ),
            ),
          for (final simulation in state.history)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_car_outlined,
                          color: AppColors.blue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${simulation.condition.label} · ${simulation.year}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Excluir simulação',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Excluir simulação?'),
                                content: const Text(
                                  'Ela será removida do seu histórico.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            try {
                              await state.remove(simulation);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Não foi possível excluir. Verifique a conexão e tente novamente.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      shortDate(simulation.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${money(simulation.installment)} / mês',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: AppColors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${simulation.months}x · ${simulation.bank}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ResultPage(
                            simulation: simulation,
                            state: state,
                            alreadySaved: true,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Ver detalhes'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
