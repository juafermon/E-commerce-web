// lib/ui/screens/login_screen.dart
// Pantalla de Login estilizada con la paleta de lujo Relaxbell:
// Fondo Marfil, tarjeta central en Blanco con bordes Arena, tipografía Playfair Display y botones en Carbón.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/auth_service.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, llena todos los campos'),
          backgroundColor: AppColors.carbon,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _authService.login(username, password);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bienvenido a Relaxbell!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacementNamed(context, '/catalog');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales incorrectas'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.marfil,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.carbon),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space6,
            vertical: AppSpacing.space4,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space8),
              decoration: BoxDecoration(
                color: AppColors.blanco,
                borderRadius: AppRadius.borderMd,
                border: Border.all(
                  color: AppColors.arena.withValues(alpha: 0.7),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.carbon.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / Ícono
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.marfil,
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(
                        color: AppColors.champagne.withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      size: 28,
                      color: AppColors.cobreOscuro,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Título Playfair Display
                  Text(
                    'Iniciar Sesión',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.carbon,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    'Accede a tu cuenta de Relaxbell',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.grisCalido,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space6),

                  // Campo de Usuario
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.grisCalido),
                      filled: true,
                      fillColor: AppColors.marfil,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: const BorderSide(color: AppColors.arena),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Campo de Contraseña
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.grisCalido),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.grisCalido,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                      filled: true,
                      fillColor: AppColors.marfil,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: const BorderSide(color: AppColors.arena),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space6),

                  // Botón de Ingresar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderMd,
                        ),
                        backgroundColor: AppColors.carbon,
                        foregroundColor: AppColors.blanco,
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.blanco,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Iniciar Sesión',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Separador 'o'
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
                        child: Text(
                          'o',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.grisCalido,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Botón de Crear Cuenta
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pushNamed(context, '/register'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderMd,
                        ),
                        side: const BorderSide(color: AppColors.arena),
                        foregroundColor: AppColors.carbon,
                      ),
                      child: Text(
                        'Crear una Cuenta',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
