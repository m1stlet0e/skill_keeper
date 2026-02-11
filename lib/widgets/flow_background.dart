import 'dart:math';
import 'package:flutter/material.dart';
import '../models/practice_session.dart';

/// 心流状态背景视觉效果
class FlowBackground extends StatefulWidget {
  final FlowState flowState;
  final Color themeColor;
  final Widget child;

  const FlowBackground({
    super.key,
    required this.flowState,
    required this.themeColor,
    required this.child,
  });

  @override
  State<FlowBackground> createState() => _FlowBackgroundState();
}

class _FlowBackgroundState extends State<FlowBackground>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _particleController;
  late AnimationController _auroraController;
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    )..repeat();
    _particleController.addListener(_updateParticles);

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle.random(_random));
    }
  }

  void _updateParticles() {
    if (!mounted) return;
    for (final p in _particles) {
      p.y -= p.speed;
      p.x += sin(p.y * 0.02 + p.phase) * 0.2;
      p.opacity = (sin(p.y * 0.01 + p.phase) * 0.3 + 0.7).clamp(0.0, 1.0);
      if (p.y < -20) {
        p.y = 1.1;
        p.x = _random.nextDouble();
        p.phase = _random.nextDouble() * pi * 2;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _breathController.dispose();
    _particleController.removeListener(_updateParticles);
    _particleController.dispose();
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.flowState.backgroundColors,
        ),
      ),
      child: Stack(
        children: [
          // 呼吸圆环 - 所有阶段都有
          _buildBreathCircle(),

          // 涟漪效果 - 专注及以上
          if (widget.flowState.index >= FlowState.focus.index)
            _buildRipples(),

          // 粒子效果 - 心流及以上
          if (widget.flowState.index >= FlowState.flow.index)
            _buildParticles(),

          // 极光效果 - 深度心流
          if (widget.flowState == FlowState.deepFlow)
            _buildAurora(),

          // 子内容
          widget.child,
        ],
      ),
    );
  }

  Widget _buildBreathCircle() {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final breathValue = _breathController.value;
        final baseSize = size.width * 0.5;
        final currentSize = baseSize + breathValue * 40;

        return Positioned.fill(
          child: Center(
            child: Container(
              width: currentSize,
              height: currentSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.themeColor.withValues(alpha: 0.08 + breathValue * 0.05),
                    widget.themeColor.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRipples() {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _RipplePainter(
            progress: _breathController.value,
            color: widget.themeColor,
            ringCount: widget.flowState.index >= FlowState.flow.index ? 4 : 2,
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    return CustomPaint(
      size: Size.infinite,
      painter: _ParticlePainter(
        particles: _particles,
        color: widget.themeColor,
        intensity: widget.flowState == FlowState.deepFlow ? 1.0 : 0.6,
      ),
    );
  }

  Widget _buildAurora() {
    return AnimatedBuilder(
      animation: _auroraController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _AuroraPainter(
            progress: _auroraController.value,
            themeColor: widget.themeColor,
          ),
        );
      },
    );
  }
}

/// 涟漪绘制器
class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int ringCount;

  _RipplePainter({
    required this.progress,
    required this.color,
    required this.ringCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4;

    for (int i = 0; i < ringCount; i++) {
      final phase = (progress + i / ringCount) % 1.0;
      final radius = maxRadius * phase;
      final opacity = (1.0 - phase) * 0.15;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 粒子数据
class _Particle {
  double x;     // 0-1 normalized
  double y;     // 0-1 normalized
  double size;
  double speed;
  double opacity;
  double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });

  factory _Particle.random(Random random) {
    return _Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: random.nextDouble() * 3 + 1,
      speed: random.nextDouble() * 0.003 + 0.001,
      opacity: random.nextDouble() * 0.5 + 0.3,
      phase: random.nextDouble() * pi * 2,
    );
  }
}

/// 粒子绘制器
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double intensity;

  _ParticlePainter({
    required this.particles,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity * intensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

/// 极光绘制器
class _AuroraPainter extends CustomPainter {
  final double progress;
  final Color themeColor;

  _AuroraPainter({
    required this.progress,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final phase = progress * 2 * pi + i * pi / 3;
      final path = Path();
      
      final y1 = size.height * 0.3 + sin(phase) * size.height * 0.1;
      final y2 = size.height * 0.5 + sin(phase + 1) * size.height * 0.08;
      
      path.moveTo(0, y1);
      path.quadraticBezierTo(
        size.width * 0.25,
        y1 + sin(phase + 0.5) * 50,
        size.width * 0.5,
        y2,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        y2 + cos(phase + 0.8) * 50,
        size.width,
        y1 + sin(phase + 1.5) * 30,
      );
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      final colors = [
        themeColor.withValues(alpha: 0.03),
        const Color(0xFF11998E).withValues(alpha: 0.05),
        const Color(0xFF38EF7D).withValues(alpha: 0.03),
      ];

      paint.color = colors[i % colors.length];
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
