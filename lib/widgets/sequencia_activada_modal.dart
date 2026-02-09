import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reward_notification.dart';

class SequenciaActivadaModal extends StatefulWidget {
  final VoidCallback onContinue;
  final Widget Function({void Function(String)? onCodeCopied})? buildSincronicosSection;
  final String? mensajeCompletado;
  final int? cristalesGanados;
  final double? luzCuanticaAnterior;
  final double? luzCuanticaActual;
  final String? tipoAccion;

  const SequenciaActivadaModal({
    super.key,
    required this.onContinue,
    this.buildSincronicosSection,
    this.mensajeCompletado,
    this.cristalesGanados,
    this.luzCuanticaAnterior,
    this.luzCuanticaActual,
    this.tipoAccion,
  });

  @override
  State<SequenciaActivadaModal> createState() => _SequenciaActivadaModalState();
}

class _SequenciaActivadaModalState extends State<SequenciaActivadaModal>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  String? _copiedCodeMessage;
  OverlayEntry? _overlayEntry;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;
  bool _isCheckingScroll = false;

  @override
  void initState() {
    super.initState();
    
    // Controlador para el pulso del icono
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Controlador para el efecto de brillo
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    // Controlador para la animación de entrada
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Iniciar animación de entrada
    _scaleController.forward();
    
    // Configurar listener para el scroll con debounce
    _scrollController.addListener(_checkScrollPositionDebounced);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _checkScrollPosition();
      });
    });
  }

  @override
  void dispose() {
    _hideCopiedMessage();
    _pulseController.dispose();
    _glowController.dispose();
    _scaleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPositionDebounced() {
    if (_isCheckingScroll || !mounted) return;
    _isCheckingScroll = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      _isCheckingScroll = false;
      if (!mounted) return;
      _checkScrollPosition();
    });
  }

  void _checkScrollPosition() {
    if (!mounted || !_scrollController.hasClients) return;
    
    try {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final canScroll = maxScroll > 0;
      final shouldShow = canScroll && currentScroll < maxScroll - 50;
      
      if (_showScrollIndicator != shouldShow) {
        if (!mounted) return;
        setState(() {
          _showScrollIndicator = shouldShow;
        });
      }
    } catch (e) {
      // Ignorar errores si el controller ya no está disponible
      print('⚠️ Error en _checkScrollPosition: $e');
    }
  }

  void _showCopiedMessage(String codigo) {
    setState(() {
      _copiedCodeMessage = '✅ Secuencia copiada: $codigo';
    });
    
    // Ocultar el mensaje después de 2 segundos (solo si el modal sigue montado)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _copiedCodeMessage = null;
      });
    });
  }

  void _hideCopiedMessage() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    if (!mounted) return;
    setState(() {
      _copiedCodeMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final rawTextScale = mediaQuery.textScaleFactor;
    final clampedTextScale = rawTextScale.clamp(1.0, 1.25).toDouble();
    final effectiveScale = clampedTextScale;
    final isCompactWidth = mediaQuery.size.width < 360;
    final isVeryCompactWidth = mediaQuery.size.width < 330;
    final dialogPadding = EdgeInsets.all(isCompactWidth ? 24 : 32);
    final insetPadding =
        EdgeInsets.symmetric(horizontal: isVeryCompactWidth ? 8 : 20, vertical: 20);
    final titleFontSize = isCompactWidth ? 24.0 : 28.0;
    final letterSpacing = isCompactWidth ? 2.0 : 3.0;
    final messageFontSize = isCompactWidth ? 16.0 : 18.0;
    final highlightTitleSize = isCompactWidth ? 16.0 : 18.0;
    final highlightBodySize = isCompactWidth ? 14.0 : 15.0;
    final buttonPadding =
        EdgeInsets.symmetric(vertical: isCompactWidth ? 16.0 : 18.0);
    final showScrollHint = effectiveScale >= 1.15;

    return MediaQuery(
      data: mediaQuery.copyWith(textScaleFactor: clampedTextScale),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: insetPadding,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: dialogPadding,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2541),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      const Color(0xFFFFD700),
                                      Colors.white,
                                      const Color(0xFFFFD700),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ).createShader(bounds),
                                  child: Text(
                                    'SECUENCIA',
                                    style: GoogleFonts.inter(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: letterSpacing,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      const Color(0xFFFFD700),
                                      Colors.white,
                                      const Color(0xFFFFD700),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ).createShader(bounds),
                                  child: Text(
                                    'ACTIVADA',
                                    style: GoogleFonts.inter(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: letterSpacing,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.mensajeCompletado ??
                              '¡Excelente trabajo! Has completado tu sesión de repeticiones.',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: messageFontSize,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Mostrar notificación de recompensas si hay cristales ganados
                        if (widget.cristalesGanados != null && widget.cristalesGanados! > 0)
                          RewardNotification(
                            cristalesGanados: widget.cristalesGanados!,
                            luzCuanticaAnterior: widget.luzCuanticaAnterior,
                            luzCuanticaActual: widget.luzCuanticaActual,
                            tipoAccion: widget.tipoAccion ?? 'repeticion',
                          ),
                        if (widget.cristalesGanados != null && widget.cristalesGanados! > 0)
                          const SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.all(isCompactWidth ? 16 : 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFFFD700).withOpacity(0.15),
                                const Color(0xFFFFD700).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFFFFD700),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Es importante mantener la vibración',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFFFD700),
                                        fontSize: highlightTitleSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Este es un avance significativo en tu proceso de manifestación. Lo ideal es realizar sesiones de 2:00 minutos para reforzar la vibración energética.',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: highlightBodySize,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (widget.buildSincronicosSection != null)
                          widget.buildSincronicosSection!(onCodeCopied: _showCopiedMessage),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              foregroundColor: Colors.black,
                              padding: buttonPadding,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8,
                              shadowColor:
                                  const Color(0xFFFFD700).withOpacity(0.5),
                            ),
                            child: Text(
                              'Continuar',
                              style: GoogleFonts.inter(
                                fontSize: highlightTitleSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
              // Mensaje de confirmación que aparece sobre el modal
              if (_copiedCodeMessage != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 3,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _copiedCodeMessage!,
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Mensaje "Desliza hacia arriba" cuando hay contenido scrolleable
              if (_showScrollIndicator)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF1C2541).withOpacity(0.95),
                            const Color(0xFF1C2541),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up,
                            color: const Color(0xFFFFD700),
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Desliza hacia arriba',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFFD700),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

