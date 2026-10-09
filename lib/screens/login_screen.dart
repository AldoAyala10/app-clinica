import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/tooth_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../state/app_state.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'doctor/doctor_main_screen.dart';
import 'patient/patient_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.doctor;
  List<String> _validationErrors = const [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );

    return emailRegex.hasMatch(trimmedEmail);
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final errors = <String>[];

    if (!_isValidEmail(email)) {
      errors.add('Ingresa un correo electrónico válido.');
    }

    if (password.trim().length < 6) {
      errors.add('La contraseña debe tener al menos 6 caracteres.');
    }

    setState(() {
      _validationErrors = errors;
    });

    if (errors.isNotEmpty) {
      return;
    }

    setState(() => _isLoading = true);
    final UserRole role;
    try {
      role = await AuthService.instance.signIn(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _validationErrors = [e.message];
        });
      }
      return;
    }

    if (role != _selectedRole) {
      await AuthService.instance.signOut();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _validationErrors = [
            role == UserRole.doctor
                ? 'Esta cuenta es de doctor. Selecciona "Doctor".'
                : 'Esta cuenta es de paciente. Selecciona "Paciente".',
          ];
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (role == UserRole.doctor) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DoctorMainScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PatientMainScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text;
    if (!_isValidEmail(email)) {
      setState(() {
        _validationErrors = [
          'Escribe tu correo arriba para enviarte el enlace de recuperación.',
        ];
      });
      return;
    }

    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _validationErrors = const []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Te enviamos un correo para restablecer tu contraseña.',
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _validationErrors = [e.message]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Tooth Logo
              const Hero(tag: 'login_tooth_logo', child: ToothLogo(size: 90)),
              const SizedBox(height: 24),

              // White Card Container matching Figma Screen 2
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Ingresa tus credenciales para continuar',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Role Selector Toggle (Doctor vs Patient)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRole = UserRole.doctor;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedRole == UserRole.doctor
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _selectedRole == UserRole.doctor
                                      ? AppTheme.softShadow
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.medical_services_rounded,
                                      size: 16,
                                      color: _selectedRole == UserRole.doctor
                                          ? AppTheme.primaryBlue
                                          : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Doctor',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedRole == UserRole.doctor
                                            ? AppTheme.primaryBlue
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRole = UserRole.patient;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedRole == UserRole.patient
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _selectedRole == UserRole.patient
                                      ? AppTheme.softShadow
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 16,
                                      color: _selectedRole == UserRole.patient
                                          ? AppTheme.primaryBlue
                                          : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Paciente',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedRole == UserRole.patient
                                            ? AppTheme.primaryBlue
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Correo electrónico',
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Contraseña',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_validationErrors.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ..._validationErrors.map(
                        (error) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            error,
                            style: const TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    CustomButton(
                      text: 'Iniciar Sesión',
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Bottom register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿No tienes una cuenta? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
