import 'package:flutter/material.dart';
import '../../widgets/nutria_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../home/root_shell.dart';
import '../onboarding/onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  Future<void> _submit() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completá usuario y contraseña.');
      return;
    }
    // El mínimo real de 8 caracteres (y el resto de la política) lo valida
    // el servidor — acá solo evitamos un viaje al backend obvio.
    if (!_isLogin && password.length < 8) {
      setState(() => _error = 'La contraseña tiene que tener al menos 8 caracteres.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final error = _isLogin
        ? await ApiClient.instance.login(username, password)
        : await ApiClient.instance.register(username, password, email: _emailCtrl.text.trim());

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      nutriaRoute(onboardingDone ? const RootShell() : const OnboardingScreen()),
    );
  }

  Future<void> _showForgotPasswordSheet() async {
    final emailCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (sheetContext) {
        bool sending = false;
        String? result;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recuperar contraseña', style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Escribí el email con el que te registraste — te mandamos un link para elegir una contraseña nueva.',
                  style: Theme.of(sheetContext).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                _Field(controller: emailCtrl, label: 'Email', icon: Icons.mail_outline),
                if (result != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(result!, style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: sending
                        ? null
                        : () async {
                            final email = emailCtrl.text.trim();
                            if (email.isEmpty) return;
                            setSheetState(() => sending = true);
                            final message = await ApiClient.instance.requestPasswordReset(email);
                            setSheetState(() {
                              sending = false;
                              result = message;
                            });
                          },
                    child: sending
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Mandar link'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // LayoutBuilder + ConstrainedBox(minHeight) en vez de Padding+Column
      // directo: con el teclado abierto (sobre todo en registro, con el
      // campo de email de más) el contenido no entraba y desbordaba abajo.
      // Así se centra igual cuando entra, y scrollea cuando no.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.accentGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 26, offset: const Offset(0, 10))],
                ),
                alignment: Alignment.center,
                child: const Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(_isLogin ? 'Bienvenido de nuevo' : 'Creá tu cuenta', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(
                _isLogin ? 'Entrá para seguir tu progreso' : 'Empecemos a armar tu plan',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              _Field(controller: _userCtrl, label: 'Usuario', icon: Icons.person_outline),
              if (!_isLogin) ...[
                const SizedBox(height: AppSpacing.sm),
                _Field(controller: _emailCtrl, label: 'Email (para recuperar tu cuenta)', icon: Icons.mail_outline),
              ],
              const SizedBox(height: AppSpacing.sm),
              _Field(controller: _passCtrl, label: 'Contraseña', icon: Icons.lock_outline, obscure: true),
              if (_isLogin) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading ? null : _showForgotPasswordSheet,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                    child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: const TextStyle(color: AppColors.warn, fontSize: 12)),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isLogin ? 'Entrar' : 'Crear cuenta'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin ? '¿No tenés cuenta? Creá una' : '¿Ya tenés cuenta? Entrá',
                    style: const TextStyle(color: AppColors.accent, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, required this.icon, this.obscure = false});
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.accent)),
      ),
    );
  }
}
