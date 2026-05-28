// lib/ui/widgets/store_app_bar.dart 
//AppBar para la pagina de catalogo, con el logo, nombre de la tienda, botones de 
//descuentos y más vendidos (solo en web), el carrito con badge y el botón de iniciar 
//sesión o cerrar sesión dependiendo del estado actual del usuario.
import 'package:flutter/material.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/auth_service.dart';

class StoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  final CartProvider cartProvider;
  final AuthService authService;
  final bool isWeb;
  final VoidCallback onSessionChanged; // Para refrescar la pantalla cuando inicien o cierren sesión

  const StoreAppBar({
    Key? key,
    required this.cartProvider,
    required this.authService,
    required this.isWeb,
    required this.onSessionChanged,
  }) : super(key: key);

  // Define la altura estándar del AppBar
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.storefront_outlined, color: Colors.blue, size: 28),
          const SizedBox(width: 8),
          const Text(
            'Mi Tienda Virtual', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
          ),
          const SizedBox(width: 40),
          if (isWeb) ...[
            TextButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.local_offer_outlined, size: 18, color: Colors.orange), 
              label: const Text('Descuentos', style: TextStyle(color: Colors.black87))
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.workspace_premium_outlined, size: 18, color: Colors.amber), 
              label: const Text('Más Vendidos', style: TextStyle(color: Colors.black87))
            ),
          ]
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      actions: [
        // Botón del Carrito con Badge
        IconButton(
          icon: Badge(
            label: Text(cartProvider.itemCount.toString()), 
            child: const Icon(Icons.shopping_cart, color: Colors.black87)
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/cart').then((_) => onSessionChanged());
          },
        ),
        const SizedBox(width: 8),
        
        // Botón Dinámico de Autenticación
        FutureBuilder<String?>(
          future: authService.getToken(),
          builder: (context, snapshot) {
            bool isLoggedIn = snapshot.hasData && snapshot.data != null;
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (isLoggedIn) {
                    await authService.logout();
                    onSessionChanged(); // Notifica el cambio de estado
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
            );
          },
        ),
      ],
    );
  }
}