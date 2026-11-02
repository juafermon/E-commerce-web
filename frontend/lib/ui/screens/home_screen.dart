// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/auth_service.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final CartProvider cartProvider;

  const HomeScreen({super.key, required this.cartProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  String? _username;

  bool _hoverStore = false;
  bool _hoverServices = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    widget.cartProvider.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    widget.cartProvider.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkAuthStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    final user = await _authService.getCurrentUsername();
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _username = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 850;

    return Scaffold(
      backgroundColor: AppColors.marfil,
      appBar: _buildTopBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header Section con Espacio Destacado para el Logo
            _buildHeroHeader(isWide),

            // Main Selection Hub (Tienda Cuidado Personal vs Servicios Spa/Masajes)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? AppSpacing.space12 : AppSpacing.space4,
                vertical: AppSpacing.space6,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildStoreCard()),
                            const SizedBox(width: AppSpacing.space8),
                            Expanded(child: _buildServicesCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildStoreCard(),
                            const SizedBox(height: AppSpacing.space6),
                            _buildServicesCard(),
                          ],
                        ),
                ),
              ),
            ),

            // Pilares de Bienestar y Calidad Relaxbell
            _buildValueSection(isWide),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.blanco,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const Border(
        bottom: BorderSide(color: AppColors.arena, width: 1),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ═══════════════════════════════════════
          // ESPACIO RESERVADO PARA EL LOGO
          // ═══════════════════════════════════════
          _buildLogoPlaceholderCompact(),

          const SizedBox(width: AppSpacing.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RELAXBELL',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w700,
                  color: AppColors.carbon,
                  fontSize: 19,
                  letterSpacing: 1.5,
                ),
              ),
              const Text(
                'Cuidado Personal & Spa',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.cobreOscuro,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Botón a Tienda de Productos
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/catalog'),
          icon: const Icon(Icons.spa_outlined, size: 18, color: AppColors.cobreOscuro),
          label: const Text('Productos', style: TextStyle(color: AppColors.carbon, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: AppSpacing.space1),

        // Botón a Masajes y Servicios
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/services'),
          icon: const Icon(Icons.self_improvement_outlined, size: 18, color: AppColors.champagne),
          label: const Text('Masajes & Servicios', style: TextStyle(color: AppColors.carbon, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: AppSpacing.space2),

        // Carrito con Badge Contador
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.carbon),
              tooltip: 'Ver Carrito de Compras',
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
            if (widget.cartProvider.itemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.cobreOscuro,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '${widget.cartProvider.itemCount}',
                    style: const TextStyle(
                      color: AppColors.blanco,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: AppSpacing.space2),

        // Estado de usuario
        if (_isLoggedIn) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.marfil,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.arena),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.cobreOscuro),
                const SizedBox(width: 6),
                Text(
                  _username ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.carbon,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 18, color: AppColors.grisCalido),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await _authService.logout();
              _checkAuthStatus();
            },
          ),
        ] else ...[
          TextButton(
            onPressed: () async {
              await Navigator.pushNamed(context, '/login');
              _checkAuthStatus();
            },
            child: const Text(
              'Iniciar Sesión',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.cobreOscuro),
            ),
          ),
        ],

        const SizedBox(width: AppSpacing.space4),
      ],
    );
  }

  // ──────────────────────────────────────────
  // ESPACIO PARA LOGO COMPACTO (EN APPBAR)
  // ──────────────────────────────────────────
  Widget _buildLogoPlaceholderCompact() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.marfil,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.champagne.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.spa_rounded,
            color: AppColors.cobreOscuro,
            size: 22,
          ),
          Positioned(
            bottom: 2,
            child: Text(
              'RELAX',
              style: TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.w900,
                color: AppColors.carbon,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // HERO HEADER CON ESPACIO DESTACADO PARA LOGO
  // ──────────────────────────────────────────
  Widget _buildHeroHeader(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.space12 : AppSpacing.space4,
        vertical: isWide ? AppSpacing.space12 : AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.blanco,
            AppColors.marfil,
            const Color(0xFFF0EBE1),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            children: [
              // ══════════════════════════════════════════════
              // RECUADRO DESTACADO EN BLANCO PARA EL LOGO
              // ══════════════════════════════════════════════
              _buildProminentLogoSpot(),

              const SizedBox(height: AppSpacing.space4),

              // Chip de Bienvenida Spa & Cuidado Personal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.champagne.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.champagne.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.cobreOscuro, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Bienestar Integral • Belleza Natural • Terapia Holística',
                      style: TextStyle(
                        color: AppColors.carbon,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Título Principal Relaxbell
              Text(
                'Armonía para tu cuerpo, mente y piel',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: isWide ? 44 : 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.carbon,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Subtítulo
              Text(
                'En Relaxbell fusionamos fórmulas botánicas para el cuidado diario de tu piel (cremas regeneradoras, protectores labiales nutritivos) con terapias de bienestar profundo como masajes relajantes y la técnica clínica AromaTouch®.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWide ? 16 : 14,
                  height: 1.6,
                  color: AppColors.grisCalido,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // MARCO DESTACADO RESERVADO PARA EL LOGO
  // ──────────────────────────────────────────
  Widget _buildProminentLogoSpot() {
    return Container(
      width: 140,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.champagne.withValues(alpha: 0.5),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cobreOscuro.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.spa_rounded,
            color: AppColors.champagne.withValues(alpha: 0.15),
            size: 54,
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.cobreOscuro,
                size: 26,
              ),
              SizedBox(height: 4),
              Text(
                'Espacio para Logo',
                style: TextStyle(
                  color: AppColors.carbon,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Relaxbell',
                style: TextStyle(
                  color: AppColors.cobreOscuro,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // TARJETA 1: TIENDA (PRODUCTOS DE CUIDADO PERSONAL)
  // ──────────────────────────────────────────
  Widget _buildStoreCard() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverStore = true),
      onExit: (_) => setState(() => _hoverStore = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/catalog'),
        child: AnimatedContainer(
          duration: AppTransitions.duration,
          curve: AppTransitions.curve,
          transform: Matrix4.translationValues(0.0, _hoverStore ? -6.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: AppColors.blanco,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hoverStore ? AppColors.cobreOscuro : AppColors.arena,
              width: _hoverStore ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _hoverStore
                    ? AppColors.cobreOscuro.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _hoverStore ? 24 : 10,
                offset: Offset(0, _hoverStore ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con degradado Carbón & Cobre Oscuro
              Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.carbon, Color(0xFF382E28), AppColors.cobreOscuro],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.blanco.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'CUIDADO PERSONAL & BELLEZA',
                            style: TextStyle(
                              color: AppColors.blanco,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.blanco.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: AppColors.blanco, size: 20),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.sanitizer_outlined, color: AppColors.blanco, size: 36),
                        const SizedBox(width: 14),
                        Text(
                          'Tienda',
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.blanco,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenido descriptivo y lista de características
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fórmulas que consienten tu piel',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.carbon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Encuentra cremas hidratantes de extracto botánico, protectores labiales nutritivos con mantecas naturales y aceites esenciales para tu rutina diaria de cuidado.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grisCalido,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bullets de características
                    _buildFeatureItem(Icons.check_circle_rounded, 'Cremas faciales y corporales hidratantes y nutritivas', AppColors.cobreOscuro),
                    const SizedBox(height: 10),
                    _buildFeatureItem(Icons.check_circle_rounded, 'Bálsamos y protectores labiales con activos naturales', AppColors.cobreOscuro),
                    const SizedBox(height: 10),
                    _buildFeatureItem(Icons.check_circle_rounded, 'Aceites esenciales y lociones botánicas con stock real', AppColors.cobreOscuro),

                    const SizedBox(height: 28),

                    // Botón de Acción Principal
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/catalog'),
                        icon: const Icon(Icons.spa_outlined, size: 20),
                        label: const Text(
                          'Ver Productos Relaxbell',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.carbon,
                          foregroundColor: AppColors.blanco,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          elevation: _hoverStore ? 4 : 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // TARJETA 2: SERVICIOS (MASAJES Y AROMATOUCH)
  // ──────────────────────────────────────────
  Widget _buildServicesCard() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverServices = true),
      onExit: (_) => setState(() => _hoverServices = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/services'),
        child: AnimatedContainer(
          duration: AppTransitions.duration,
          curve: AppTransitions.curve,
          transform: Matrix4.translationValues(0.0, _hoverServices ? -6.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: AppColors.blanco,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hoverServices ? AppColors.champagne : AppColors.arena,
              width: _hoverServices ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _hoverServices
                    ? AppColors.champagne.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _hoverServices ? 24 : 10,
                offset: Offset(0, _hoverServices ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con degradado Champagne & Tierra cálido
              Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C2723), Color(0xFF4A3E36), AppColors.champagne],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.blanco.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TERAPIAS & SPA RELAJANTE',
                            style: TextStyle(
                              color: AppColors.blanco,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.blanco.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: AppColors.blanco, size: 20),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.self_improvement_rounded, color: AppColors.blanco, size: 36),
                        const SizedBox(width: 14),
                        Text(
                          'Servicios',
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.blanco,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenido descriptivo y lista de características
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masajes & Técnica AromaTouch®',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.carbon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Renueva tu energía y libera la carga muscular acumulada. Experimenta nuestra técnica AromaTouch con aceites esenciales de grado puro y masajes descontracturantes.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grisCalido,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bullets de características
                    _buildFeatureItem(Icons.check_circle_rounded, 'Técnica AromaTouch® para reducir estrés y restaurar equilibrio', AppColors.cobreOscuro),
                    const SizedBox(height: 10),
                    _buildFeatureItem(Icons.check_circle_rounded, 'Masajes relajantes, terapéuticos y descontracturantes', AppColors.cobreOscuro),
                    const SizedBox(height: 10),
                    _buildFeatureItem(Icons.check_circle_rounded, 'Ambiente de aromaterapia y atención personalizada', AppColors.cobreOscuro),

                    const SizedBox(height: 28),

                    // Botón de Acción Principal
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/services'),
                        icon: const Icon(Icons.spa, size: 20),
                        label: const Text(
                          'Conocer Masajes y Terapias',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cobreOscuro,
                          foregroundColor: AppColors.blanco,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          elevation: _hoverServices ? 4 : 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.carbon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueSection(bool isWide) {
    return Container(
      width: double.infinity,
      color: AppColors.blanco,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.space12 : AppSpacing.space4,
        vertical: AppSpacing.space12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'La Experiencia Relaxbell',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.carbon,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              const Text(
                'Compromiso con tu salud, belleza natural y bienestar integral',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grisCalido,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              isWide
                  ? const Row(
                      children: [
                        Expanded(
                          child: _ValueCard(
                            icon: Icons.eco_outlined,
                            iconColor: AppColors.cobreOscuro,
                            title: 'Ingredientes Botánicos',
                            description: 'Fórmulas puras y naturales sin parabenos agresivos, ideales para todo tipo de piel.',
                          ),
                        ),
                        SizedBox(width: AppSpacing.space6),
                        Expanded(
                          child: _ValueCard(
                            icon: Icons.air_rounded,
                            iconColor: AppColors.champagne,
                            title: 'Técnica AromaTouch®',
                            description: 'Protocolo clínico con 8 aceites esenciales certificados para reducir el estrés físico y mental.',
                          ),
                        ),
                        SizedBox(width: AppSpacing.space6),
                        Expanded(
                          child: _ValueCard(
                            icon: Icons.favorite_outline_rounded,
                            iconColor: AppColors.cobreOscuro,
                            title: 'Atención Holística',
                            description: 'Terapeutas dedicados a personalizar cada masaje y asesorarte en tu rutina de cuidado.',
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      children: [
                        _ValueCard(
                          icon: Icons.eco_outlined,
                          iconColor: AppColors.cobreOscuro,
                          title: 'Ingredientes Botánicos',
                          description: 'Fórmulas puras y naturales sin parabenos agresivos, ideales para todo tipo de piel.',
                        ),
                        SizedBox(height: AppSpacing.space4),
                        _ValueCard(
                          icon: Icons.air_rounded,
                          iconColor: AppColors.champagne,
                          title: 'Técnica AromaTouch®',
                          description: 'Protocolo clínico con 8 aceites esenciales certificados para reducir el estrés físico y mental.',
                        ),
                        SizedBox(height: AppSpacing.space4),
                        _ValueCard(
                          icon: Icons.favorite_outline_rounded,
                          iconColor: AppColors.cobreOscuro,
                          title: 'Atención Holística',
                          description: 'Terapeutas dedicados a personalizar cada masaje y asesorarte en tu rutina de cuidado.',
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: AppColors.carbon,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Text(
              'RELAXBELL',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.blanco,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cuidado Personal • Cremas & Protectores • Masajes & Técnica AromaTouch',
              style: TextStyle(
                color: AppColors.arena,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '© ${DateTime.now().year} Relaxbell. Todos los derechos reservados.',
              style: const TextStyle(
                color: AppColors.grisCalido,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _ValueCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.marfil,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.arena),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.carbon,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.grisCalido,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

