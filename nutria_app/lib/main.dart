import 'package:flutter/material.dart';
import 'widgets/nutria_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/auth_screen.dart';
import 'screens/home/root_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const NutriaApp());
}

class NutriaApp extends StatelessWidget {
  const NutriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutria',
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

class _BootstrapState extends State<_Bootstrap> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasSession = await ApiClient.instance.restoreSession();
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
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5),
        ),
      ),
    );
  }
}
