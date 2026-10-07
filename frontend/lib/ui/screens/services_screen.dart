// lib/ui/screens/services_screen.dart
import 'package:flutter/material.dart';
import '../../data/services/cart_provider.dart';

class ServicesScreen extends StatelessWidget {
  final CartProvider cartProvider;

  const ServicesScreen({super.key, required this.cartProvider});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: const Color(0xFFF1EBE4), width: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B)),
          tooltip: 'Volver al Inicio',
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.self_improvement_rounded, color: Color(0xFF0D9488), size: 22),
            ),
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
                    fontSize: 17,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Terapias & Masajes de Bienestar',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0D9488),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botón directo a Inicio
          TextButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            icon: const Icon(Icons.home_outlined, size: 18, color: Color(0xFF475569)),
            label: const Text('Inicio', style: TextStyle(color: Color(0xFF475569))),
          ),
          const SizedBox(width: 4),

          // Botón directo a Tienda de Productos
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/catalog'),
            icon: const Icon(Icons.spa_outlined, size: 18),
            label: const Text('Ver Productos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBE185D),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Banner de Terapias Relaxbell
            _buildHero(isWide),

            // Catálogo de Servicios en Grid
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48.0 : 20.0,
                vertical: 36.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Menú de Terapias y Masajes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Elige la experiencia ideal para tu bienestar. Agenda tu cita y nuestros terapeutas te brindarán una sesión personalizada.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 28),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 1;
                          if (constraints.maxWidth > 950) {
                            crossAxisCount = 3;
                          } else if (constraints.maxWidth > 600) {
                            crossAxisCount = 2;
                          }

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: isWide ? 1.05 : 1.15,
                            children: [
                              _ServiceCard(
                                icon: Icons.air_rounded,
                                color: const Color(0xFF0D9488),
                                title: 'Técnica AromaTouch®',
                                description: 'Aplicación clínica de 8 aceites esenciales puros a lo largo de la columna y pies para reducir estrés, reforzar defensas y calmar inflamación.',
                                badge: 'ESTRELLA RELAXBELL',
                                onAction: () => _openContactModal(context, 'Técnica AromaTouch®'),
                              ),
                              _ServiceCard(
                                icon: Icons.spa_rounded,
                                color: const Color(0xFFBE185D),
                                title: 'Masaje Relajante & Antiestrés',
                                description: 'Técnica suave y rítmica con aceites botánicos templados para liberar tensiones, reducir el cortisol y promover el descanso profundo.',
                                badge: 'MÁS POPULAR',
                                onAction: () => _openContactModal(context, 'Masaje Relajante & Antiestrés'),
                              ),
                              _ServiceCard(
                                icon: Icons.fitness_center_rounded,
                                color: const Color(0xFFB45309),
                                title: 'Masaje Descontracturante',
                                description: 'Presión media a profunda enfocada en nudos musculares de espalda, cuello y lumbares, aliviando contracturas persistentes.',
                                badge: 'ALIVIO INTENSO',
                                onAction: () => _openContactModal(context, 'Masaje Descontracturante'),
                              ),
                              _ServiceCard(
                                icon: Icons.face_retouching_natural_rounded,
                                color: const Color(0xFF7C3AED),
                                title: 'Facial Hidratante & Labial',
                                description: 'Nutrición facial con cremas botánicas antiedad, drenaje linfático facial y bálsamo protector intensivo para labios sedosos.',
                                badge: 'CUIDADO INTEGRAL',
                                onAction: () => _openContactModal(context, 'Facial Hidratante & Labial'),
                              ),
                              _ServiceCard(
                                icon: Icons.auto_awesome_rounded,
                                color: const Color(0xFFE11D48),
                                title: 'Ritual Corporal de Bienestar',
                                description: 'Exfoliación suave, mascarilla nutritiva e hidratación corporal completa con cremas enriquecidas y aromaterapia.',
                                badge: 'RENOVACIÓN TOTAL',
                                onAction: () => _openContactModal(context, 'Ritual Corporal de Bienestar'),
                              ),
                              _ServiceCard(
                                icon: Icons.hearing_rounded,
                                color: const Color(0xFF0284C7),
                                title: 'Masaje Craneofacial & Podal',
                                description: 'Estipulación de puntos clave en cabeza, rostro y pies para aliviar migrañas, estrés visual y pesadez del día a día.',
                                badge: 'DESCONEXIÓN RÁPIDA',
                                onAction: () => _openContactModal(context, 'Masaje Craneofacial & Podal'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Call to Action Banner hacia la Tienda
            _buildCtaBanner(context, isWide),

            // Footer
            Container(
              width: double.infinity,
              color: const Color(0xFF1E1B4B),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Center(
                child: Text(
                  '© ${DateTime.now().year} Relaxbell. Cuidado personal y bienestar holístico.',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isWide) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF115E59), Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48.0 : 20.0,
        vertical: isWide ? 56.0 : 36.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'RELAXBELL SPA & BIENESTAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Terapias de Masajes & Técnica AromaTouch®',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWide ? 38 : 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Desconéctate de la rutina y regálale a tu cuerpo el cuidado que merece con manos expertas, aceites esenciales puros y productos botánicos de la más alta calidad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFCCFBF1),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCtaBanner(BuildContext context, bool isWide) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isWide ? 48.0 : 20.0,
        vertical: 24.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Container(
            padding: EdgeInsets.all(isWide ? 40 : 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF831843), Color(0xFFBE185D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBE185D).withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isWide
                ? Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Deseas llevar el cuidado Relaxbell a tu hogar?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Explora nuestras cremas hidratantes, bálsamos labiales nutritivos y aceites en la tienda en línea.',
                              style: TextStyle(color: Color(0xFFFCE7F3), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/catalog'),
                        icon: const Icon(Icons.spa_outlined),
                        label: const Text('Comprar Productos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFBE185D),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿Deseas llevar el cuidado Relaxbell a tu hogar?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Explora nuestras cremas hidratantes, bálsamos labiales nutritivos y aceites en la tienda en línea.',
                        style: TextStyle(color: Color(0xFFFCE7F3), fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/catalog'),
                          icon: const Icon(Icons.spa_outlined),
                          label: const Text('Comprar Productos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFBE185D),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _openContactModal(BuildContext context, String serviceName) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF0D9488)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Agendar: $serviceName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Déjanos tus datos de contacto y fecha preferida. Una terapeuta de Relaxbell se comunicará para confirmar tu cita y responder cualquier consulta.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tu nombre completo',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: contactCtrl,
                  decoration: InputDecoration(
                    labelText: 'Teléfono o WhatsApp',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Fecha/hora deseada o detalles especiales',
                    hintText: 'Ej: Sábado en la tarde, tengo tensión en cuello...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('¡Solicitud para "$serviceName" enviada! En breve te contactaremos para confirmar tu cita en Relaxbell.'),
                  backgroundColor: const Color(0xFF0D9488),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Solicitar Agendamiento'),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onAction;

  const _ServiceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.badge,
    required this.onAction,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered ? widget.color : const Color(0xFFF1EBE4),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: _isHovered ? 20 : 8,
              offset: Offset(0, _isHovered ? 8 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 28),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.badge,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.color,
                  side: BorderSide(color: widget.color.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Agendar Sesión', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
