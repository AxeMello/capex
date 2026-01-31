import 'dart:math' as math;
import 'package:flutter/material.dart';

const Color _primaryBlue = Color(0xFFD4F9FF);
const Color _accentBlue = Color(0xFF8FE3F9);
const Color _darkBlue = Color(0xFF2B7A8C);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween(begin: 0.95, end: 1.05).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  late final Animation<double> _glow = Tween(begin: 0.2, end: 0.6).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryBlue,
              _accentBlue.withValues(alpha: 0.6),
              _primaryBlue,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: _glow.value),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                            BoxShadow(
                              color: _accentBlue.withValues(alpha: _glow.value * 0.5),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),

                      // Sparkles
                      _sparkle(dx: -85, dy: -65, phase: 0.0),
                      _sparkle(dx: 90, dy: -25, phase: 0.25),
                      _sparkle(dx: -70, dy: 80, phase: 0.5),
                      _sparkle(dx: 80, dy: 85, phase: 0.75),
                      _sparkle(dx: 0, dy: -95, phase: 0.15),
                      _sparkle(dx: -95, dy: 10, phase: 0.6),

                      // Icon container
                      Transform.scale(
                        scale: _scale.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: _darkBlue.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 20,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Image.asset(
                                'assets/icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // App name
                  Text(
                    'capex',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: _darkBlue,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Scan to Sheets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _darkBlue.withValues(alpha: 0.7),
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Loading indicator
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _darkBlue.withValues(alpha: 0.6),
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

  Widget _sparkle({
    required double dx,
    required double dy,
    required double phase,
  }) {
    final t = (_c.value + phase) % 1.0;
    final opacity = (0.2 + 0.8 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)))
        .clamp(0.0, 1.0);
    final scale = 0.6 + 0.5 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: t * 1.2,
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentBlue.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 18,
                color: _darkBlue.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}