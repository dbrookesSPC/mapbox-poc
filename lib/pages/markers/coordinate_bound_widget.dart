import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class CoordinateBoundWidget extends StatefulWidget {
  final MapboxMap mapboxMap;
  final double latitude;
  final double longitude;
  final Widget child;
  final Offset offset;

  const CoordinateBoundWidget({
    super.key,
    required this.mapboxMap,
    required this.latitude,
    required this.longitude,
    required this.child,
    this.offset = Offset.zero,
  });

  @override
  State<CoordinateBoundWidget> createState() => _CoordinateBoundWidgetState();
}

class _CoordinateBoundWidgetState extends State<CoordinateBoundWidget> {
  ScreenCoordinate? _screenPosition;
  Timer? _updateTimer;
  bool _mapReady = false;
  bool _isVisible = false;
  
  @override
  void initState() {
    super.initState();
    _waitForMapAndUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _waitForMapAndUpdate() async {
    // Wait for map to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Try to get camera state to check if map is ready
    for (int i = 0; i < 10; i++) {
      try {
        final cameraState = await widget.mapboxMap.getCameraState();
        _mapReady = true;
        break;
      } catch (e) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    
    if (_mapReady) {
      _updatePosition();
      _startPositionUpdates();
    }
  }

  void _startPositionUpdates() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) async {
      if (!mounted) return;
      await _updatePosition();
    });
  }

  Future<void> _updatePosition() async {
    if (!mounted || !_mapReady) return;
    
    try {
      final coordinate = Point(
        coordinates: Position(widget.longitude, widget.latitude),
      );
      
      final screenCoordinate = await widget.mapboxMap.pixelForCoordinate(coordinate);
      
      // Check if we got valid coordinates (not the default -1, -1)
      if (screenCoordinate.x == -1.0 && screenCoordinate.y == -1.0) {
        // Point is not visible on screen
        if (mounted) {
          setState(() {
            _screenPosition = null;
            _isVisible = false;
          });
        }
        return;
      }
      
      // Get screen dimensions
      final mediaQuery = MediaQuery.of(context);
      final screenWidth = mediaQuery.size.width;
      final screenHeight = mediaQuery.size.height;
      
      // Add a buffer zone around the screen edges (100px margin)
      const double margin = 100.0;
      
      // Check if the point is within the visible screen area (with margin)
      final bool isOnScreen = screenCoordinate.x >= -margin && 
                             screenCoordinate.x <= screenWidth + margin &&
                             screenCoordinate.y >= -margin && 
                             screenCoordinate.y <= screenHeight + margin;
      
      if (mounted) {
        setState(() {
          _screenPosition = screenCoordinate;
          _isVisible = isOnScreen;
        });
      }
      
    } catch (e) {
      // Error in coordinate conversion - hide the widget
      if (mounted) {
        setState(() {
          _screenPosition = null;
          _isVisible = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render if position is not available or not visible
    if (_screenPosition == null || !_isVisible) {
      return const SizedBox.shrink();
    }

    // Calculate final position with offset
    final finalX = _screenPosition!.x + widget.offset.dx;
    final finalY = _screenPosition!.y + widget.offset.dy;

    return Positioned(
      left: finalX,
      top: finalY,
      child: widget.child,
    );
  }
}