import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimatedHerdWidget extends StatefulWidget {
  final int herdSize;
  final VoidCallback? onTap;

  const AnimatedHerdWidget({
    super.key,
    required this.herdSize,
    this.onTap,
  });

  @override
  State<AnimatedHerdWidget> createState() => _AnimatedHerdWidgetState();
}

class _AnimatedHerdWidgetState extends State<AnimatedHerdWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize rotation animation controller (2 seconds for full rotation, same as HERE implementation)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Create rotation animation (0 to 2π radians)
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Start rotation animation
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 110,
        height: 46,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Speech bubble background
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/speech_bubble.svg',
                width: 110,
                height: 46,
                fit: BoxFit.contain,
                allowDrawingOutsideViewBox: true,
                matchTextDirection: false,
              ),
            ),
            // Cow icon
            Positioned(
              left: 16,
              top: 4,
              child: SvgPicture.asset(
                'assets/cow_icon.svg',
                width: 30,
                height: 24,
                fit: BoxFit.contain,
                allowDrawingOutsideViewBox: true,
                matchTextDirection: false,
              ),
            ),
            // Dynamic number
            Positioned(
              left: 47,
              top: 6,
              child: Text(
                widget.herdSize.toString(),
                style: const TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            // Animated spinner
            Positioned(
              left: 76,
              top: 7,
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: SvgPicture.asset(
                      'assets/spinner_icon.svg',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      allowDrawingOutsideViewBox: true,
                      matchTextDirection: false,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}