// lib/ui/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Controladores de texto
  //final _fullNameController = TextEditingController();
  final _documentController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  ///final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedDocType = 'CC';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _docTypes = ['CC', 'CE', 'NIT', 'Pasaporte'];

  // Validación de Password (Mínimo una Mayúscula, una Minúscula y un Carácter Especial)
  bool _validatePasswordStructure(String value) {
    String pattern = r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[!@#\$&*~]).{1,}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(value);
  }

  // Validación de Email estándar
  bool _validateEmailStructure(String value) {
    String pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(value);
  }

// Modifica únicamente la función '_handleRegister' dentro de '_RegisterScreenState'

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Invocación limpia vinculando los controladores al servicio actualizado
      bool success = await _authService.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        id_type: _selectedDocType,
        doc_number: _documentController.text.trim(),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro exitoso! Ya puedes iniciar sesión.'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500), // Centrado y responsivo en web
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Crea tu Cuenta',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                 /* // 1. Nombre Completo
                  TextFormField(
                    controller: _fullNameController,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),*/

                  // 2. Tipo de Documento e Identificación (En fila)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedDocType,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: _docTypes.map((String type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedDocType = value!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _documentController,
                          maxLength: 15,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Solo números
                          decoration: const InputDecoration(
                            labelText: 'Documento',
                            border: OutlineInputBorder(),
                            counterText: "", // Oculta contador por estética en fila
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
                  const SizedBox(height: 16),

                  // 3. Usuario (Username)
                  TextFormField(
                    controller: _usernameController,
                    maxLength: 15,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de Usuario',
                      prefixIcon: Icon(Icons.account_circle_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // 4. Password con validaciones avanzadas solicitadas
                  TextFormField(
                    controller: _passwordController,
                    maxLength: 20,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
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
                  const SizedBox(height: 16),

                  // 5. Email con Validación
                  TextFormField(
                    controller: _emailController,
                    maxLength: 30,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'Campo requerido';
                      if (!_validateEmailStructure(v)) return 'Formato de correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 6. Celular (Sólo números)
                 /* TextFormField(
                    controller: _phoneController,
                    maxLength: 15,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Celular',
                      prefixIcon: Icon(Icons.phone_android),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),*/

                  // 7. Dirección
                  TextFormField(
                    controller: _addressController,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de Envío',
                      prefixIcon: Icon(Icons.home_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 24),

                  // Botón de Enviar Formulario
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Registrarme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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