import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'color/app_colors.dart';
import 'pages/home_page.dart';
import 'pages/intro_page.dart';
import 'pages/welcome_page.dart';
import 'services/ads_service.dart';
import 'services/app_state.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'widgets/glass_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const FinanciaAutoApp());
}

class FinanciaAutoApp extends StatelessWidget {
  const FinanciaAutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
        surface: AppColors.white,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    final body = GoogleFonts.soraTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
    return MaterialApp(
      title: 'Financia Auto',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: base.copyWith(
        textTheme: body.copyWith(
          headlineLarge: GoogleFonts.poppins(
            fontSize: 34,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 27,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: .8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white.withValues(alpha: .92),
          indicatorColor: AppColors.blue.withValues(alpha: .12),
        ),
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();
  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  AppState? _state;
  final _ads = AdsService();
  final _notifications = NotificationService();
  String? _error;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await FirebaseService.initialize();
      final state = AppState(preferences);
      if (!mounted) {
        state.dispose();
        return;
      }
      setState(() {
        _state = state;
        _step = state.hasOnboarded ? 2 : 0;
      });
      if (state.hasOnboarded) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(_ads.initialize()),
        );
      }
      if (state.notificationsEnabled) {
        try {
          await _notifications.scheduleDaily();
        } catch (_) {
          await state.setNotifications(false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível abrir os dados do aplicativo.',
        );
      }
    }
  }

  @override
  void dispose() {
    _state?.dispose();
    _ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null) {
      return Scaffold(
        body: AppBackground(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 80,
                  color: AppColors.blue,
                ),
                const SizedBox(height: 18),
                Text(
                  'financia auto',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text('Seu próximo passo começa aqui.'),
                const SizedBox(height: 30),
                if (_error == null)
                  const CircularProgressIndicator()
                else ...[
                  Text(_error!),
                  TextButton(
                    onPressed: () {
                      setState(() => _error = null);
                      _initialize();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    if (_step == 0) {
      return WelcomePage(
        state: _state!,
        ads: _ads,
        notifications: _notifications,
        onContinue: () => setState(() => _step = 1),
      );
    }
    if (_step == 1) {
      return IntroPage(
        onContinue: () async {
          try {
            await _state!.finishOnboarding();
            if (!mounted) return;
            setState(() => _step = 2);
            unawaited(_ads.initialize());
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Não foi possível salvar. Tente novamente.'),
                ),
              );
            }
          }
        },
      );
    }
    return HomePage(state: _state!, ads: _ads, notifications: _notifications);
  }
}
