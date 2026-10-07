import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/tooth_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'patient/patient_main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  List<String> _validationErrors = const [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

  void _handleRegister() {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Cuenta creada exitosamente! Bienvenido a Clínica Dental'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const PatientMainScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppTheme.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Tooth Logo
              const Hero(
                tag: 'register_tooth_logo',
                child: ToothLogo(size: 80),
              ),
              const SizedBox(height: 20),

              // White Card Container matching Figma Screen 3
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
                        'Crear Cuenta',
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
                        'Regístrate para agendar tus citas dentales',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Full Name
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Nombre completo',
                      hintText: 'Ej. María Moreno',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Correo electrónico',
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'Teléfono de contacto',
                      hintText: '442 000 0000',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Contraseña',
                      hintText: 'Mínimo 6 caracteres',
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
                    const SizedBox(height: 24),

                    if (_validationErrors.isNotEmpty) ...[
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
                      const SizedBox(height: 12),
                    ],

                    // Register Button
                    CustomButton(
                      text: 'Registrarse',
                      onPressed: _handleRegister,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bottom login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Ya tienes una cuenta? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Inicia sesión',
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
