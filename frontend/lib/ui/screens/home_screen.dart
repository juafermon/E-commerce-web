// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/auth_service.dart';

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
      backgroundColor: const Color(0xFFFDFBF9), // Tono cálido marfil / cashmere spa
      appBar: _buildTopBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header Section con Espacio Destacado para el Logo
            _buildHeroHeader(isWide),

            // Main Selection Hub (Tienda Cuidado Personal vs Servicios Spa/Masajes)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48.0 : 20.0,
                vertical: 24.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildStoreCard()),
                            const SizedBox(width: 32),
                            Expanded(child: _buildServicesCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildStoreCard(),
                            const SizedBox(height: 24),
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
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(
        bottom: BorderSide(color: const Color(0xFFF1EBE4), width: 1),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ═══════════════════════════════════════
          // ESPACIO RESERVADO PARA EL LOGO
          // ═══════════════════════════════════════
          _buildLogoPlaceholderCompact(),

          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RELAXBELL',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E1065),
                  fontSize: 19,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Cuidado Personal & Spa',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFBE185D).withValues(alpha: 0.9),
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
          icon: const Icon(Icons.spa_outlined, size: 18, color: Color(0xFFBE185D)),
          label: const Text('Productos', style: TextStyle(color: Color(0xFFBE185D), fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 4),

        // Botón a Masajes y Servicios
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/services'),
          icon: const Icon(Icons.self_improvement_outlined, size: 18, color: Color(0xFF0D9488)),
          label: const Text('Masajes & Servicios', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),

        // Carrito con Badge Contador
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF475569)),
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
                    color: Color(0xFFBE185D),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '${widget.cartProvider.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: 8),

        // Estado de usuario
        if (_isLoggedIn) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFBCFE8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 16, color: Color(0xFFBE185D)),
                const SizedBox(width: 6),
                Text(
                  _username ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBE185D),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 18, color: Colors.grey),
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
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFBE185D)),
            ),
          ),
        ],

        const SizedBox(width: 16),
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
        color: const Color(0xFFFDF2F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF472B6).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Icono representativo provisional mientras se integra el archivo de imagen
          const Icon(
            Icons.spa_rounded,
            color: Color(0xFFBE185D),
            size: 22,
          ),
          // Indicador para desarrollo
          Positioned(
            bottom: 2,
            child: Text(
              'LOGO',
              style: TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFBE185D).withValues(alpha: 0.7),
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
        horizontal: isWide ? 40.0 : 20.0,
        vertical: isWide ? 44.0 : 28.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            const Color(0xFFFDF2F8).withValues(alpha: 0.5),
            const Color(0xFFF0FDFA).withValues(alpha: 0.3),
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

              const SizedBox(height: 20),

              // Chip de Bienvenida Spa & Cuidado Personal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFBE185D).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFBE185D).withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFBE185D), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Bienestar Integral • Belleza Natural • Terapia Holística',
                      style: TextStyle(
                        color: Color(0xFFBE185D),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Título Principal Relaxbell
              Text(
                'Armonía para tu cuerpo, mente y piel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWide ? 42 : 28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E1B4B),
                  height: 1.15,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 14),

              // Subtítulo
              Text(
                'En Relaxbell fusionamos fórmulas botánicas para el cuidado diario de tu piel (cremas regeneradoras, protectores labiales nutritivos) con terapias de bienestar profundo como masajes relajantes y la técnica clínica AromaTouch®.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWide ? 16 : 14,
                  height: 1.6,
                  color: const Color(0xFF4B5563),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF472B6).withValues(alpha: 0.6),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBE185D).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo suave con icono floral
          Icon(
            Icons.spa_rounded,
            color: const Color(0xFFFDF2F8),
            size: 54,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: const Color(0xFFBE185D).withValues(alpha: 0.7),
                size: 26,
              ),
              const SizedBox(height: 4),
              const Text(
                'Espacio para Logo',
                style: TextStyle(
                  color: Color(0xFFBE185D),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Relaxbell',
                style: TextStyle(
                  color: const Color(0xFF2E1065).withValues(alpha: 0.6),
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
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0.0, _hoverStore ? -8.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hoverStore ? const Color(0xFFBE185D) : const Color(0xFFF1EBE4),
              width: _hoverStore ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _hoverStore
                    ? const Color(0xFFBE185D).withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _hoverStore ? 28 : 12,
                offset: Offset(0, _hoverStore ? 12 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con degradado Rose / Magenta Spa
              Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF831843), Color(0xFFBE185D), Color(0xFFF472B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
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
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'CUIDADO PERSONAL & BELLEZA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(Icons.sanitizer_outlined, color: Colors.white, size: 36),
                        SizedBox(width: 14),
                        Text(
                          'Tienda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
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
                    const Text(
                      'Fórmulas que consienten tu piel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Encuentra cremas hidratantes de extracto botánico, protectores labiales nutritivos con mantecas naturales y aceites esenciales para tu rutina diaria de cuidado.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bullets de características
                    _buildFeatureItem(Icons.check_circle_rounded, 'Cremas faciales y corporales hidratantes y nutritivas', const Color(0xFFBE185D)),
                    const SizedBox(height: 10),
                    _buildFeatureItem(Icons.check_circle_rounded, 'Bálsamos y protectores labiales con activos naturales', const Color(0xFFBE185D)),
                    const SizedBox(height: 10),
                    _buildFeatureItem(Icons.check_circle_rounded, 'Aceites esenciales y lociones botánicas con stock real', const Color(0xFFBE185D)),

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
                          backgroundColor: const Color(0xFFBE185D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0.0, _hoverServices ? -8.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hoverServices ? const Color(0xFF0D9488) : const Color(0xFFF1EBE4),
              width: _hoverServices ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _hoverServices
                    ? const Color(0xFF0D9488).withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _hoverServices ? 28 : 12,
                offset: Offset(0, _hoverServices ? 12 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con degradado Teal / Eucalipto Spa
              Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF115E59), Color(0xFF0D9488), Color(0xFF2DD4BF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
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
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TERAPIAS & SPA RELAJANTE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(Icons.self_improvement_rounded, color: Colors.white, size: 36),
                        SizedBox(width: 14),
                        Text(
                          'Servicios',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
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
                    const Text(
                      'Masajes & Técnica AromaTouch®',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Renueva tu energía y libera la carga muscular acumulada. Experimenta nuestra técnica AromaTouch con aceites esenciales de grado puro y masajes descontracturantes.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bullets de características
                    _buildFeatureItem(Icons.check_circle_rounded, 'Técnica AromaTouch® para reducir estrés y restaurar equilibrio', const Color(0xFF0D9488)),
                    const SizedBox(height: 10),
                    _buildFeatureItem(Icons.check_circle_rounded, 'Masajes relajantes, terapéuticos y descontracturantes', const Color(0xFF0D9488)),
                    const SizedBox(height: 10),
                    _buildFeatureItem(Icons.check_circle_rounded, 'Ambiente de aromaterapia y atención personalizada', const Color(0xFF0D9488)),

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
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueSection(bool isWide) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48.0 : 20.0,
        vertical: 48.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text(
                'La Experiencia Relaxbell',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Compromiso con tu salud, belleza natural y bienestar integral',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 36),
              isWide
                  ? const Row(
                      children: [
                        Expanded(
                          child: _ValueCard(
                            icon: Icons.eco_rounded,
                            iconColor: Color(0xFF059669),
                            title: 'Ingredientes Botánicos',
                            description: 'Fórmulas puras y naturales sin parabenos agresivos, ideales para todo tipo de piel.',
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _ValueCard(
                            icon: Icons.air_rounded,
                            iconColor: Color(0xFFBE185D),
                            title: 'Técnica AromaTouch®',
                            description: 'Protocolo clínico con 8 aceites esenciales certificados para reducir el estrés físico y mental.',
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _ValueCard(
                            icon: Icons.favorite_rounded,
                            iconColor: Color(0xFFD97706),
                            title: 'Atención Holística',
                            description: 'Terapeutas dedicados a personalizar cada masaje y asesorarte en tu rutina de cuidado.',
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      children: [
                        _ValueCard(
                          icon: Icons.eco_rounded,
                          iconColor: Color(0xFF059669),
                          title: 'Ingredientes Botánicos',
                          description: 'Fórmulas puras y naturales sin parabenos agresivos, ideales para todo tipo de piel.',
                        ),
                        SizedBox(height: 16),
                        _ValueCard(
                          icon: Icons.air_rounded,
                          iconColor: Color(0xFFBE185D),
                          title: 'Técnica AromaTouch®',
                          description: 'Protocolo clínico con 8 aceites esenciales certificados para reducir el estrés físico y mental.',
                        ),
                        SizedBox(height: 16),
                        _ValueCard(
                          icon: Icons.favorite_rounded,
                          iconColor: Color(0xFFD97706),
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
      color: const Color(0xFF1E1B4B),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            const Text(
              'RELAXBELL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cuidado Personal • Cremas & Protectores • Masajes & Técnica AromaTouch',
              style: TextStyle(
                color: Color(0xFFC7D2FE),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '© ${DateTime.now().year} Relaxbell. Todos los derechos reservados.',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
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
        color: const Color(0xFFFDFBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1EBE4)),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
