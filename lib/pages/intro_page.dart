import 'package:material_ui/material_ui.dart';

import '../color/app_colors.dart';
import '../widgets/glass_card.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key, required this.onContinue});
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.route_rounded,
                    size: 58,
                    color: AppColors.blue,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Um bom caminho\ncomeça com um plano.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Antes de pegar a chave, entenda cada número do seu financiamento.',
                  ),
                  const SizedBox(height: 30),
                  const GlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.tune_rounded,
                            color: AppColors.blue,
                          ),
                          title: Text('Simule do seu jeito'),
                          subtitle: Text(
                            'Informe renda, entrada e o carro que você quer.',
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.account_balance_outlined,
                            color: AppColors.blue,
                          ),
                          title: Text('Compare com clareza'),
                          subtitle: Text(
                            'Consulte taxas médias do Banco Central.',
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.history_rounded,
                            color: AppColors.blue,
                          ),
                          title: Text('Guarde seus planos'),
                          subtitle: Text(
                            'Volte às simulações sempre que precisar.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onContinue,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Fazer minha primeira simulação'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Sem compromisso. Sem consulta ao CPF.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
