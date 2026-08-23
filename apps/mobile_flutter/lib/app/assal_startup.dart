import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:assalkom_design/assal_tokens.dart';

import '../core/assal_assets.dart';
import '../core/assal_widgets.dart';

/// Non-blocking boot gate for the real app shell.
///
/// The gate only wraps an already configured repository. It does not change
/// Supabase initialization, authentication, or production configuration.
class AssalStartupGate extends StatefulWidget {
  const AssalStartupGate({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 900),
  });

  final Widget child;
  final Duration duration;

  @override
  State<AssalStartupGate> createState() => _AssalStartupGateState();
}

class _AssalStartupGateState extends State<AssalStartupGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.duration, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: _ready
            ? KeyedSubtree(
                key: const ValueKey<String>('assal-home'),
                child: widget.child,
              )
            : const KeyedSubtree(
                key: ValueKey<String>('assal-startup'),
                child: AssalStartupView(),
              ),
      );
}

class AssalStartupView extends StatelessWidget {
  const AssalStartupView({super.key, this.fontFamily, this.logo});

  /// Test-only override keeps golden harnesses able to register the same
  /// bundled font under a fresh family name. Production uses the shared token.
  final String? fontFamily;
  final Widget? logo;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AssalColors.cream,
        body: Semantics(
          label: 'جارٍ تجهيز سوق العسل',
          liveRegion: true,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const CustomPaint(painter: _StartupHoneycombPainter()),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AssalSpacing.xl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      logo ??
                          const AssalBrandMark(
                            size: 132,
                            assetPath: AssalAssets.logoExternal,
                          ),
                      const SizedBox(height: AssalSpacing.lg),
                      Text(
                        'عسلكم',
                        textAlign: TextAlign.center,
                        style: AssalTypography.display.copyWith(
                          fontFamily: fontFamily ?? AssalTypography.family,
                          color: AssalColors.deepBrown,
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: AssalSpacing.xs),
                      Text(
                        'من اليمن .. طبيعة أصيلة',
                        textAlign: TextAlign.center,
                        style: AssalTypography.subtitle.copyWith(
                          fontFamily: fontFamily ?? AssalTypography.family,
                          color: AssalColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AssalSpacing.xl),
                      Container(
                        width: 76,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AssalColors.honey,
                          borderRadius: BorderRadius.circular(AssalRadius.pill),
                        ),
                      ),
                      const SizedBox(height: AssalSpacing.xl),
                      Text(
                        'جارٍ تجهيز سوق العسل...',
                        textAlign: TextAlign.center,
                        style: AssalTypography.bodyLarge.copyWith(
                          fontFamily: fontFamily ?? AssalTypography.family,
                          color: AssalColors.deepBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AssalSpacing.md),
                      const _StartupDots(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _StartupDots extends StatefulWidget {
  const _StartupDots();

  @override
  State<_StartupDots> createState() => _StartupDotsState();
}

class _StartupDotsState extends State<_StartupDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final active = (_controller.value * 3).floor() % 3;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(3, (index) {
              final isActive = index == active;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: isActive ? 9 : 7,
                  height: isActive ? 9 : 7,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AssalColors.honey
                        : AssalColors.deepBrown.withValues(alpha: .42),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      );
}

class _StartupHoneycombPainter extends CustomPainter {
  const _StartupHoneycombPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AssalColors.honey.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final accent = Paint()
      ..color = AssalColors.primaryLight.withValues(alpha: .11)
      ..style = PaintingStyle.fill;

    const radius = 28.0;
    const horizontal = radius * 1.72;
    const vertical = radius * 1.5;
    final columns = (size.width / horizontal).ceil() + 2;
    final rows = (size.height / vertical).ceil() + 2;

    for (var row = -1; row < rows; row++) {
      for (var column = -1; column < columns; column++) {
        final offset = row.isOdd ? horizontal / 2 : 0.0;
        final center = Offset(
          column * horizontal + offset,
          row * vertical,
        );
        final path = Path();
        for (var side = 0; side < 6; side++) {
          final angle = math.pi / 3 * side + math.pi / 6;
          final point = Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          );
          if (side == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, stroke);
        if ((row + column) % 7 == 0) canvas.drawPath(path, accent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StartupHoneycombPainter oldDelegate) => false;
}
