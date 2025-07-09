import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FPSCounter extends StatefulWidget {
  final Widget child;
  final bool showFPS;

  const FPSCounter({
    Key? key,
    required this.child,
    this.showFPS = true,
  }) : super(key: key);

  @override
  State<FPSCounter> createState() => _FPSCounterState();
}

class _FPSCounterState extends State<FPSCounter> with TickerProviderStateMixin {
  late Ticker _ticker;
  int _frameCount = 0;
  double _fps = 0.0;
  DateTime _lastTime = DateTime.now();
  static const Duration _updateInterval = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.showFPS) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(FPSCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFPS != oldWidget.showFPS) {
      if (widget.showFPS) {
        _ticker.start();
      } else {
        _ticker.stop();
      }
    }
  }

  void _onTick(Duration elapsed) {
    _frameCount++;
    final now = DateTime.now();
    final timeDiff = now.difference(_lastTime);
    
    if (timeDiff >= _updateInterval) {
      setState(() {
        _fps = _frameCount / timeDiff.inMilliseconds * 1000;
        _frameCount = 0;
        _lastTime = now;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showFPS)
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'FPS: ${_fps.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _fps >= 55 ? 'Excellent' : _fps >= 30 ? 'Good' : 'Poor',
                    style: TextStyle(
                      color: _fps >= 55 ? Colors.green : _fps >= 30 ? Colors.yellow : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
