import 'package:flutter/material.dart';
import '../data/mock_auth_repository.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../validar_correo.dart';
import '../widgets/custom_button.dart';
import '../widgets/gradient_background.dart';
import '../widgets/tooth_logo.dart';
import 'admin_dashboard.dart';
import 'patient_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authRepository = const MockAuthRepository()});
  final MockAuthRepository authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _hidePassword = true;
  UserRole _selectedRole = UserRole.patient;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials({required bool administrator}) {
    setState(() {
      _selectedRole = administrator ? UserRole.administrator : UserRole.patient;
      _emailController.text = administrator ? 'admin@test.com' : 'paciente@test.com';
      _passwordController.text = administrator ? 'Admin123' : 'Paciente123';
      _errorMessage = null;
    });
  }

  void _signIn() {
    final email = _emailController.text.trim();
    if (!validarCorreo(email)) {
      setState(() => _errorMessage = 'Ingresa un correo electrónico válido.');
      return;
    }
    final user = widget.authRepository.authenticate(
      email: email, password: _passwordController.text);
    if (user == null) {
      setState(() => _errorMessage = 'Correo o contraseña incorrectos.');
      return;
    }
    setState(() => _errorMessage = null);
    // El rol autenticado decide el acceso, nunca el selector visual.
    final Widget dashboard = user.role == UserRole.administrator
        ? AdminDashboard(user: user) : PatientDashboard(user: user);
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => dashboard), (route) => false);
  }

  Widget _roleButton(UserRole role, String label, IconData icon) {
    final selected = role == _selectedRole;
    return Expanded(child: Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _fillDemoCredentials(administrator: role == UserRole.administrator),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20,
                color: selected ? AppTheme.primaryBlue : AppTheme.textMuted),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.primaryBlue : AppTheme.textSecondary)),
          ]),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: GradientBackground(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Center(child: Hero(tag: 'tooth_logo', child: ToothLogo(size: 90))),
          const SizedBox(height: 16),
          const Text('Clínica Dental Sonrisas', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(28), boxShadow: AppTheme.cardShadow),
            child: AutofillGroup(child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Iniciar Sesión', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                const Text('Ingresa tus credenciales para continuar',
                    textAlign: TextAlign.center),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    _roleButton(UserRole.patient, 'Paciente', Icons.person_rounded),
                    _roleButton(UserRole.administrator, 'Administrador', Icons.medical_services_rounded),
                  ])),
                const SizedBox(height: 20),
                const Text('Correo electrónico', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  key: const ValueKey('emailField'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  autocorrect: false,
                  decoration: const InputDecoration(hintText: 'ejemplo@correo.com',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted))),
                const SizedBox(height: 16),
                const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  key: const ValueKey('passwordField'),
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    hintText: 'Ingresa tu contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted),
                    suffixIcon: IconButton(
                      tooltip: _hidePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.textMuted)))),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Semantics(liveRegion: true, child: Text(_errorMessage!,
                      style: const TextStyle(color: AppTheme.errorRed))),
                ],
                const SizedBox(height: 24),
                CustomButton(key: const ValueKey('loginButton'),
                    text: 'Iniciar sesión', onPressed: _signIn),
              ],
            )),
          ),
          const SizedBox(height: 20),
          const Text('Cuentas de demostración', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
            TextButton.icon(onPressed: () => _fillDemoCredentials(administrator: false),
                icon: const Icon(Icons.person_outline), label: const Text('Usar paciente')),
            TextButton.icon(onPressed: () => _fillDemoCredentials(administrator: true),
                icon: const Icon(Icons.admin_panel_settings_outlined), label: const Text('Usar administrador')),
          ]),
        ]),
      ),
    ))),
  );
}
