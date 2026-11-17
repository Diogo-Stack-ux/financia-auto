import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../color/app_colors.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../widgets/glass_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.state,
    required this.notifications,
    required this.ads,
  });
  final AppState state;
  final NotificationService notifications;
  final AdsService ads;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false, _busy = false, _obscure = true;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _authError(FirebaseAuthException error) => switch (error.code) {
    'email-already-in-use' =>
      'Este e-mail já está cadastrado. Entre na sua conta.',
    'weak-password' => 'Escolha uma senha mais forte.',
    'invalid-email' => 'Confira o endereço de e-mail.',
    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' => 'E-mail ou senha incorretos.',
    'network-request-failed' => 'Verifique sua conexão e tente novamente.',
    'too-many-requests' =>
      'Muitas tentativas. Aguarde um pouco e tente novamente.',
    'operation-not-allowed' =>
      'Ative o login por e-mail e senha no console Firebase.',
    _ => 'Não foi possível entrar. Tente novamente.',
  };

  Future<void> _authenticate() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_register) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _email.text.trim(),
              password: _password.text,
            );
        await credential.user!.updateDisplayName(_name.text.trim());
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .set({
                'name': _name.text.trim(),
                'email': _email.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
          _message = 'Conta criada. Seu perfil está pronto.';
        } catch (_) {
          _message = 'Conta criada. Não foi possível salvar seu perfil na nuvem agora.';
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      _password.clear();
    } on FirebaseAuthException catch (error) {
      _message = _authError(error);
    } catch (_) {
      _message = 'Não foi possível concluir. Tente novamente.';
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _message = 'Preencha seu e-mail para recuperar a senha.');
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _message = 'Se o e-mail estiver cadastrado, você receberá as instruções de recuperação.';
    } on FirebaseAuthException catch (error) {
      _message = _authError(error);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _toggleNotifications(bool enabled) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (enabled) {
        final granted = await widget.notifications.enable();
        await widget.state.setNotifications(granted);
        if (!granted) _message = 'Permissão não concedida. Você pode habilitá-la nas configurações do aparelho.';
      } else {
        await widget.notifications.disable();
        await widget.state.setNotifications(false);
      }
    } catch (_) {
      _message = 'Não foi possível alterar os lembretes. Tente novamente.';
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _editName(User user) async {
    final controller = TextEditingController(text: user.displayName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como podemos chamar você?'),
        content: TextField(
          controller: controller,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Seu nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 2) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    // The dialog's route may still be animating out; its controller is short-lived.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (value == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await user.updateDisplayName(value);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': value,
        'email': user.email,
      }, SetOptions(merge: true));
      _message = 'Nome atualizado.';
    } catch (_) {
      _message = 'Não foi possível salvar o perfil na nuvem. Tente novamente.';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) {
      final user = widget.state.user;
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Um espaço\npara seus planos.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFE3EDFF),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.blue,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ??
                      (user == null ? 'Bem-vindo, visitante' : 'Sua conta'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ??
                      'Simule e salve seu histórico neste dispositivo.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (user != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _editName(user),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar nome'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            try {
                              await FirebaseAuth.instance.signOut();
                              _message = null;
                            } catch (_) {
                              _message =
                                  'Não foi possível sair. Tente novamente.';
                            }
                            if (mounted) setState(() => _busy = false);
                          },
                    child: const Text('Sair da conta'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (user == null)
            GlassCard(
              child: FirebaseService.ready
                  ? Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _register
                                ? 'Crie sua conta'
                                : 'Entre para sincronizar',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'As simulações do visitante ficam neste aparelho. A conta tem seu próprio histórico.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_register) ...[
                            TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              maxLength: 60,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                              ),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 2
                                  ? 'Informe seu nome.'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (value) =>
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(value?.trim() ?? '')
                                ? 'Informe um e-mail válido.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: [
                              _register
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                (value?.length ?? 0) < (_register ? 8 : 1)
                                ? (_register
                                      ? 'Use pelo menos 8 caracteres.'
                                      : 'Informe sua senha.')
                                : null,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _busy ? null : _authenticate,
                            child: Text(
                              _busy
                                  ? 'Aguarde…'
                                  : _register
                                  ? 'Criar conta'
                                  : 'Entrar',
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _register = !_register;
                                    _message = null;
                                  }),
                            child: Text(
                              _register
                                  ? 'Já tenho uma conta'
                                  : 'Ainda não tenho uma conta',
                            ),
                          ),
                          if (!_register)
                            TextButton(
                              onPressed: _busy ? null : _resetPassword,
                              child: const Text('Esqueci minha senha'),
                            ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cloud_outlined, color: AppColors.blue),
                        const SizedBox(height: 12),
                        Text(
                          'Sua conta, em breve',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          FirebaseService.error ?? 'O acesso à conta ainda não está disponível nesta versão. Você pode usar o simulador e salvar o histórico no aparelho.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            height: 1.6,
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
                  'Do seu jeito',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Lembretes diários',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    NotificationService.supported
                        ? 'Às 9h, 14h e 19h · horário do aparelho'
                        : 'Disponíveis no Android e iOS',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: widget.state.notificationsEnabled,
                  onChanged: _busy || !NotificationService.supported
                      ? null
                      : _toggleNotifications,
                ),
                if (AdsService.supported)
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            try {
                              await widget.ads.privacyOptions();
                            } catch (_) {
                              if (mounted) {
                                setState(
                                  () => _message = 'Não foi possível abrir as opções de anúncios.',
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                    label: const Text('Preferências de anúncios'),
                  ),
                const Divider(),
                const Text(
                  'Sobre suas informações',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'O histórico inclui os valores de renda e veículo informados. No modo visitante ele fica neste dispositivo. Ao entrar, as novas simulações salvas também são enviadas para sua conta. Você pode excluir cada simulação no histórico.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_message!, style: const TextStyle(fontSize: 13)),
            ),
          if (widget.state.syncMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(widget.state.syncMessage!),
            ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Financia Auto · 1.0.0',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        ],
      );
    },
  );
}
