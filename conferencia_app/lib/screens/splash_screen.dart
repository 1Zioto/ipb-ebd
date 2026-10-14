import 'package:flutter/material.dart';
import 'main_menu_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool skipWelcome;

  const SplashScreen({super.key, this.skipWelcome = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _textFadeAnimation;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Zoom out: começa ampliado (1.6) e diminui 60% até a escala final (0.64)
    _scaleAnimation = Tween<double>(begin: 1.60, end: 0.64).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Fade-in da sarça logo no início
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // Fade-in dos textos institucionais conforme a sarça recua para o fundo
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.90, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      _navigateToNext();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_navigated || !mounted) return;
    _navigated = true;

    // Abre diretamente o Menu Principal (Hub Organizador) após o splash
    const Widget nextScreen = MainMenuScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo 100% Branco solicitado
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToNext, // Toque para pular splash
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  // Conteúdo central animado
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // A SARÇA ARDENTE COM ZOOM OUT DE 60%
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF047857)
                                        .withValues(alpha: 0.12 * (1.6 - _scaleAnimation.value)),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                'assets/images/ipb-logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.church_rounded,
                                  color: Color(0xFF047857),
                                  size: 100,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // TEXTOS INSTITUCIONAIS COM FADE-IN SUAVE
                        Opacity(
                          opacity: _textFadeAnimation.value,
                          child: Column(
                            children: [
                              const Text(
                                'IGREJA PRESBITERIANA DO BRASIL',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'sans-serif',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF065F46),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFA7F3D0),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'SISTEMA INTEGRADO • MOBILE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF047857),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // INDICADOR DISCRETO INFERIOR
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF047857),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Decência e Ordem • 1 Co 14:40',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
