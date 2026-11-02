// lib/ui/screens/register_screen.dart
// Pantalla de Registro con estética de lujo Relaxbell:
// Fondo Marfil, contenedor en Blanco con bordes Arena, títulos en Playfair Display y botón de acción en Carbón.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/auth_service.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _documentController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedDocType = 'CC';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _docTypes = ['CC', 'CE', 'NIT', 'Pasaporte'];

  @override
  void dispose() {
    _documentController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _validatePasswordStructure(String value) {
    String pattern = r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[!@#\$&*~]).{1,}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(value);
  }

  bool _validateEmailStructure(String value) {
    String pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(value);
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      bool success = await _authService.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        idType: _selectedDocType,
        docNumber: _documentController.text.trim(),
      );

      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Ya puedes iniciar sesión.'),
            backgroundColor: AppColors.success,
          ),
        );
        navigator.pushReplacementNamed('/login');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.marfil,
      appBar: AppBar(
        title: Text(
          'Registro',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.carbon,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.blanco,
        foregroundColor: AppColors.carbon,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: AppColors.arena.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space6,
            vertical: AppSpacing.space8,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crea tu Cuenta',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.carbon,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    'Únete a la experiencia de cuidado personal Relaxbell',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.grisCalido,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.space6),

                  // Tipo de Documento e Identificación
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedDocType,
                          decoration: InputDecoration(
                            labelText: 'Tipo',
                            filled: true,
                            fillColor: AppColors.marfil,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.borderMd,
                              borderSide: const BorderSide(color: AppColors.arena),
                            ),
                          ),
                          items: _docTypes.map((String type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedDocType = value!),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _documentController,
                          maxLength: 15,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Documento',
                            counterText: "",
                            filled: true,
                            fillColor: AppColors.marfil,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.borderMd,
                              borderSide: const BorderSide(color: AppColors.arena),
                            ),
                          ),
                          validator: (v) {
                            if (v!.isEmpty) return 'Requerido';
                            if (v.length > 15) return 'Máx 15 dígitos';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Usuario
                  TextFormField(
                    controller: _usernameController,
                    maxLength: 15,
                    decoration: InputDecoration(
                      labelText: 'Nombre de Usuario',
                      prefixIcon: const Icon(Icons.account_circle_outlined, color: AppColors.grisCalido),
                      filled: true,
                      fillColor: AppColors.marfil,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: const BorderSide(color: AppColors.arena),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Contraseña
                  TextFormField(
                    controller: _passwordController,
                    maxLength: 20,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.grisCalido),
                      filled: true,
                      fillColor: AppColors.marfil,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: const BorderSide(color: AppColors.arena),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.grisCalido,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'Campo requerido';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      if (!_validatePasswordStructure(v)) {
                        return 'Debe incluir Mayúscula, Minúscula y un carácter especial (!@#\$&*~)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    maxLength: 30,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.grisCalido),
                      filled: true,
                      fillColor: AppColors.marfil,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: const BorderSide(color: AppColors.arena),
                      ),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'Campo requerido';
                      if (!_validateEmailStructure(v)) return 'Formato de correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Dirección
                  TextFormField(
                    controller: _addressController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: 'Dirección de Envío',
                      prefixIcon: const Icon(Icons.home_outlined, color: AppColors.grisCalido),
                      filled: true,
                      fillColor: AppColors.marfil,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: const BorderSide(color: AppColors.arena),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: AppSpacing.space6),

                  // Botón de Enviar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.carbon,
                      foregroundColor: AppColors.blanco,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMd,
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.blanco,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Registrarme',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
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