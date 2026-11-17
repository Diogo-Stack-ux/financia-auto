import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../color/app_colors.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../widgets/glass_card.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({
    super.key,
    required this.state,
    required this.ads,
    required this.notifications,
    required this.onContinue,
  });
  final AppState state;
  final AdsService ads;
  final NotificationService notifications;
  final VoidCallback onContinue;
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _busy = false;
  bool _trackingRequested = false;
  String? _message;

  Future<void> _notifications() async {
    setState(() => _busy = true);
    try {
      final granted = await widget.notifications.enable();
      await widget.state.setNotifications(granted);
      _message = granted
          ? 'Lembretes ativados às 9h, 14h e 19h.'
          : 'Lembretes desativados. Você pode mudar isso no perfil.';
    } catch (_) {
      _message =
          'Não foi possível ativar os lembretes. Tente novamente no perfil.';
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _tracking() async {
    setState(() => _busy = true);
    try {
      await widget.ads.requestTracking();
      _trackingRequested = true;
    } catch (_) {
      _message = 'Você pode revisar a permissão nos Ajustes do iPhone.';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Seu próximo carro.\nSua melhor escolha.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bem-vindo ao Financia Auto. Vamos deixar tudo pronto para você planejar com tranquilidade.',
                    style: TextStyle(color: AppColors.muted, height: 1.6),
                  ),
                  const SizedBox(height: 30),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.blue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Um lembrete para seus planos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Receba 3 lembretes por dia, às 9h, 14h e 19h no horário do aparelho. Você pode desativá-los no perfil.',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _busy || !NotificationService.supported
                              ? null
                              : _notifications,
                          child: Text(
                            widget.state.notificationsEnabled
                                ? 'Lembretes ativados'
                                : 'Permitir notificações',
                          ),
                        ),
                        if (!NotificationService.supported)
                          const Text(
                            'Disponível no app para Android e iOS.',
                            style: TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.privacy_tip_outlined,
                            color: AppColors.blue,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sua privacidade, sua escolha',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'O iPhone permite escolher se anúncios podem usar seu identificador para rastreamento. Essa permissão é opcional.',
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _busy || _trackingRequested
                                ? null
                                : _tracking,
                            child: Text(
                              _trackingRequested
                                  ? 'Preferência registrada'
                                  : 'Revisar permissão no iPhone',
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_message!),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : widget.onContinue,
                      child: Text(_busy ? 'Aguarde…' : 'Continuar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Você pode continuar sem conceder permissões.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
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
