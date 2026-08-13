import 'package:flutter/material.dart';
import 'widgets/nutria_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/auth_screen.dart';
import 'screens/home/root_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';
import 'widgets/concentric_rings.dart';
import 'widgets/glow_backdrop.dart';

void main() {
  runApp(const NutriaApp());
}

class NutriaApp extends StatelessWidget {
  const NutriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FRfit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // En desktop/web centra el contenido a un ancho de celular en vez de
      // estirar el layout mobile-first a todo el ancho de la ventana.
      builder: (context, child) {
        return ColoredBox(
          color: AppColors.bg,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: child,
            ),
          ),
        );
      },
      home: const _Bootstrap(),
    );
  }
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconFade;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    // El ícono entra ya a tamaño final (sin escala) para que continúe la
    // splash nativa de Android sin "salto" — solo el texto se anima, y entra
    // un poco después para no competir con el ícono por la atención.
    _iconFade = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4, curve: Curves.easeOut));
    _textFade = CurvedAnimation(parent: _controller, curve: const Interval(0.35, 1, curve: Curves.easeOut));
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Corren en paralelo con la animación de entrada — pero le damos a la
    // splash un mínimo de tiempo en pantalla para que no sea un parpadeo
    // cuando restaurar la sesión es instantáneo (datos locales).
    final results = await Future.wait([
      ApiClient.instance.restoreSession(),
      Future.delayed(const Duration(milliseconds: 900)),
    ]);
    final hasSession = results[0] as bool;
    if (!mounted) return;

    if (!hasSession) {
      Navigator.of(context).pushReplacement(nutriaRoute(const AuthScreen()));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      nutriaRoute(onboardingDone ? const RootShell() : const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _iconFade,
              child: GlowBackdrop(
                spread: 1.3,
                child: ConcentricRings(
                  // Tamaño cercano al ícono grande que ya muestra la splash
                  // nativa de Android antes de esto — así no se ve un salto.
                  size: 176,
                  strokeWidth: 15,
                  gap: 19,
                  rings: const [
                    RingData(progress: 1, color: AppColors.accent),
                    RingData(progress: 0.75, color: AppColors.accent70),
                    RingData(progress: 0.5, color: AppColors.accent40),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeTransition(
              opacity: _textFade,
              child: const Text(
                'FRfit',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
