// lib/ui/widgets/store_app_bar.dart 
// AppBar para la página de catálogo, con el logo, nombre de la tienda, 
// el carrito con badge numérico y el bloque dinámico de autenticación (Login/Register/Logout).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/wishlist_provider.dart';
import '../theme/app_colors.dart';

class StoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  final CartProvider cartProvider;
  final WishlistProvider wishlistProvider;
  final AuthService authService;
  final bool isWeb;
  final VoidCallback onSessionChanged;

  const StoreAppBar({
    super.key,
    required this.cartProvider,
    required this.wishlistProvider,
    required this.authService,
    required this.isWeb,
    required this.onSessionChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.blanco,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(
        bottom: BorderSide(
          color: AppColors.arena.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      title: InkWell(
        onTap: () {
          Navigator.pushNamedAndRemoveUntil(context, '/catalog', (route) => false);
        },
        borderRadius: AppRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space1,
            vertical: AppSpacing.space1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.marfil,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(
                    color: AppColors.champagne.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: AppColors.cobreOscuro,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RELAXBELL',
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.w800,
                      color: AppColors.carbon,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Cuidado Personal & Bienestar',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w500,
                      color: AppColors.grisCalido,
                      fontSize: 10,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isWeb) ...[
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            icon: const Icon(Icons.home_outlined, size: 18, color: AppColors.carbon),
            label: Text(
              'Inicio',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.carbon,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space1),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/services'),
            icon: const Icon(
              Icons.miscellaneous_services_outlined,
              size: 18,
              color: AppColors.cobreOscuro,
            ),
            label: Text(
              'Servicios',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.cobreOscuro,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
        ],

        // 1. Botón de Wishlist con Badge contador reactivo
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.favorite_border_rounded,
                color: AppColors.cobreOscuro,
              ),
              tooltip: 'Mi lista de deseos',
              onPressed: () {
                Navigator.pushNamed(context, '/wishlist').then((_) => onSessionChanged());
              },
            ),
            AnimatedBuilder(
              animation: wishlistProvider,
              builder: (context, child) {
                if (wishlistProvider.count == 0) return const SizedBox.shrink();
                return Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.cobreOscuro,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    child: Text(
                      '${wishlistProvider.count}',
                      style: const TextStyle(
                        color: AppColors.blanco,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        // 2. Botón del Carrito con Badge Contador reactivo
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.carbon,
              ),
              tooltip: 'Carrito de compras',
              onPressed: () {
                Navigator.pushNamed(context, '/cart').then((_) => onSessionChanged());
              },
            ),
            AnimatedBuilder(
              animation: cartProvider,
              builder: (context, child) {
                if (cartProvider.itemCount == 0) return const SizedBox.shrink();
                return Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.cobreOscuro,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: AppColors.blanco,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.space2),

        // 3. Botón Dinámico de Autenticación (Login / Registro / Logout)
        FutureBuilder<String?>(
          future: authService.getToken(),
          builder: (context, snapshot) {
            final bool isLoggedIn = snapshot.hasData && snapshot.data != null;

            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isLoggedIn) ...[
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register').then((_) => onSessionChanged());
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.cobreOscuro,
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      child: const Text('Registrarse'),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                  ],

                  ElevatedButton.icon(
                    onPressed: () async {
                      if (isLoggedIn) {
                        final messenger = ScaffoldMessenger.of(context);
                        await authService.logout();
                        onSessionChanged();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Sesión cerrada correctamente.'),
                            backgroundColor: AppColors.carbon,
                          ),
                        );
                      } else {
                        Navigator.pushNamed(context, '/login').then((_) => onSessionChanged());
                      }
                    },
                    icon: Icon(
                      isLoggedIn ? Icons.logout : Icons.login,
                      size: 15,
                    ),
                    label: Text(
                      isLoggedIn ? 'Salir' : 'Iniciar Sesión',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLoggedIn ? AppColors.marfil : AppColors.carbon,
                      foregroundColor: isLoggedIn ? AppColors.carbon : AppColors.blanco,
                      elevation: 0,
                      side: isLoggedIn
                          ? const BorderSide(color: AppColors.arena, width: 1.0)
                          : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space2,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMd,
                      ),
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