// lib/ui/widgets/store_app_bar.dart 
// AppBar para la página de catálogo, con el logo, nombre de la tienda, 
// el carrito con badge numérico y el bloque dinámico de autenticación (Login/Register/Logout).

import 'package:flutter/material.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/auth_service.dart';

class StoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  final CartProvider cartProvider;
  final AuthService authService;
  final bool isWeb;
  final VoidCallback onSessionChanged; // Para refrescar el catálogo al cambiar el estado de autenticación

  const StoreAppBar({
    Key? key,
    required this.cartProvider,
    required this.authService,
    required this.isWeb,
    required this.onSessionChanged,
  }) : super(key: key);

  // Define la altura estándar del AppBar en Flutter
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      // Línea sutil inferior para separar el AppBar del contenido del catálogo
      shape: Border(
        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      title: InkWell(
        onTap: () {
          // Permite recargar o volver a la raíz del catálogo al presionar el título/logo
          Navigator.pushNamedAndRemoveUntil(context, '/catalog', (route) => false);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              const Text(
                'Mi Tienda Virtual', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Colors.black87,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Secciones extras visibles únicamente si se ejecuta en formato Web
        if (isWeb) ...[
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.local_offer_outlined, size: 18, color: Colors.black54),
            label: const Text('Descuentos', style: TextStyle(color: Colors.black87)),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.trending_up, size: 18, color: Colors.black54),
            label: const Text('Más Vendidos', style: TextStyle(color: Colors.black87)),
          ),
          const SizedBox(width: 16),
        ],

        // 1. Botón del Carrito con Badge Contador reactivo
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
              onPressed: () {
                // Navega al carrito y refresca el catálogo al regresar (por si se modificó algo)
                Navigator.pushNamed(context, '/cart').then((_) => onSessionChanged());
              },
            ),
            // Escucha en tiempo real los cambios del CartProvider sin redibujar todo el AppBar
            AnimatedBuilder(
              animation: cartProvider,
              builder: (context, child) {
                if (cartProvider.itemCount == 0) return const SizedBox.shrink();
                return Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center, // CORREGIDO: Corrección de tipo Alignment -> TextAlign
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(width: 12),
        
        // 2. Botón Dinámico de Autenticación (Login / Registro / Logout)
        FutureBuilder<String?>(
          future: authService.getToken(),
          builder: (context, snapshot) {
            final bool isLoggedIn = snapshot.hasData && snapshot.data != null;
            
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SI NO está logueado, se muestra el botón secundario de Registrarse
                  if (!isLoggedIn) ...[
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register').then((_) => onSessionChanged());
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Registrarse'),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Botón principal (Iniciar Sesión / Salir)
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (isLoggedIn) {
                        await authService.logout();
                        onSessionChanged(); // Notifica el cierre de sesión para limpiar estados
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sesión cerrada correctamente.')),
                        );
                      } else {
                        Navigator.pushNamed(context, '/login').then((_) => onSessionChanged());
                      }
                    },
                    icon: Icon(isLoggedIn ? Icons.logout : Icons.login, size: 16),
                    label: Text(isLoggedIn ? 'Salir' : 'Iniciar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLoggedIn ? Colors.grey[200] : Colors.blue, 
                      foregroundColor: isLoggedIn ? Colors.black87 : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}