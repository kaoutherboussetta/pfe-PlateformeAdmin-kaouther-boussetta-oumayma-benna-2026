import 'package:flutter/material.dart';

double _safeOpacity(double value) => value.clamp(0.0, 1.0);

/// Halo pulsant autour de la position (style orange navigation).
class PulsatingLocationIndicator extends StatefulWidget {
  final double radius;
  final Color color;
  final Duration animationDuration;

  const PulsatingLocationIndicator({
    super.key,
    this.radius = 30,
    this.color = const Color(0xFFE65100),
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulsatingLocationIndicator> createState() => _PulsatingLocationIndicatorState();
}

class _PulsatingLocationIndicatorState extends State<PulsatingLocationIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final size = widget.radius * 2 * _scaleAnimation.value;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(_safeOpacity(0.3 * _opacityAnimation.value)),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 10 * _scaleAnimation.value,
                      spreadRadius: 2 * _scaleAnimation.value,
                    ),
                  ],
                ),
              ),
              Container(
                width: widget.radius * 0.4,
                height: widget.radius * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color,
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Flash élastique au démarrage de la navigation.
class AnimatedLocationMarker extends StatelessWidget {
  final bool isFlashing;
  final VoidCallback? onAnimationComplete;

  const AnimatedLocationMarker({
    super.key,
    required this.isFlashing,
    this.onAnimationComplete,
  });

  static const Color _orange = Color(0xFFE65100);
  static const Color _orangeLight = Color(0xFFFF6D00);

  @override
  Widget build(BuildContext context) {
    if (!isFlashing) {
      return _staticMarker();
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      onEnd: onAnimationComplete,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1 + (value * 0.3),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 24 + (value * 30),
                height: 24 + (value * 30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _orange.withOpacity(_safeOpacity((1 - value) * 0.6)),
                ),
              ),
              Container(
                width: 24 + (value * 15),
                height: 24 + (value * 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _orangeLight.withOpacity(_safeOpacity((1 - value) * 0.4)),
                ),
              ),
              _staticMarker(glow: (12 * (1 - value)).clamp(0.0, 12.0)),
            ],
          ),
        );
      },
    );
  }

  Widget _staticMarker({double glow = 8}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _orange,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: _orange.withOpacity(0.5),
            blurRadius: glow,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.my_location, size: 12, color: Colors.white),
    );
  }
}

/// Pulsation continue pendant la navigation active.
class PulsingNavigationIndicator extends StatefulWidget {
  final bool isActive;
  final double size;

  const PulsingNavigationIndicator({
    super.key,
    required this.isActive,
    this.size = 40,
  });

  @override
  State<PulsingNavigationIndicator> createState() => _PulsingNavigationIndicatorState();
}

class _PulsingNavigationIndicatorState extends State<PulsingNavigationIndicator>
    with SingleTickerProviderStateMixin {
  static const Color _orange = Color(0xFFE65100);

  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingNavigationIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _orange,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.my_location, size: 20, color: Colors.white),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _orange.withOpacity(0.4),
                    boxShadow: [
                      BoxShadow(
                        color: _orange.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: widget.size * 0.7,
                  height: widget.size * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _orange,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.navigation, size: 20, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Effet flash radial plein écran (au centre de la vue carte).
class NavigationStartFlashOverlay extends StatelessWidget {
  final bool visible;

  const NavigationStartFlashOverlay({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(visible),
        duration: const Duration(milliseconds: 1000),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          final size = MediaQuery.sizeOf(context).width * (0.2 + value * 0.6);
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE65100).withOpacity(_safeOpacity((1 - value) * 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE65100).withOpacity(0.5),
                        blurRadius: (30 * (1 - value)).clamp(0.0, 30.0),
                        spreadRadius: (10 * (1 - value)).clamp(0.0, 10.0),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.5 + (value * 0.7),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE65100),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE65100).withOpacity(0.8),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location, size: 30, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
