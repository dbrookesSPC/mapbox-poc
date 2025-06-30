import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'many_markers.events.dart';
import 'many_markers.state.dart';

class ManyMarkersBloc extends Bloc<ManyMarkersEvent, ManyMarkersState> {
  final List<PointAnnotation> _markers = [];
  PointAnnotationManager? _pointAnnotationManager;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  ManyMarkersBloc() : super(ManyMarkersInitial()) {
    on<GenerateMarkers>(_onGenerateMarkers);
    on<ClearMarkers>(_onClearMarkers);
    on<InitializeAnnotationManager>(_onInitializeAnnotationManager);
  }

  Future<void> _onInitializeAnnotationManager(
    InitializeAnnotationManager event,
    Emitter<ManyMarkersState> emit,
  ) async {
    _pointAnnotationManager = event.annotationManager;
  }

  Future<void> _onGenerateMarkers(
    GenerateMarkers event,
    Emitter<ManyMarkersState> emit,
  ) async {
    try {
      if (_pointAnnotationManager == null) {
        emit(const ManyMarkersError(error: "Annotation manager not initialized"));
        return;
      }

      emit(ManyMarkersLoading());

      final Random random = Random();
      final List<PointAnnotation> newMarkers = [];

      // Get current camera position if available
      double centerLat = 52.5; // Default to Berlin
      double centerLng = 13.4;
      double spread = 0.1;

      try {
        // Try to get current camera state (you'll need to pass the mapboxMap to the bloc)
        // For now, we'll use the default Berlin coordinates
        // In a full implementation, you'd pass the current camera state to this event
      } catch (e) {
        print('Using default Berlin coordinates');
      }

      final double minLat = centerLat - spread;
      final double maxLat = centerLat + spread;
      final double minLng = centerLng - spread;
      final double maxLng = centerLng + spread;

      for (int i = 0; i < event.count; i++) {
        // Emit progress
        if (i % 100 == 0) {
          emit(ManyMarkersGenerating(
            generatedCount: i,
            totalCount: event.count,
          ));
        }

        // Generate random coordinates around the center
        final double lat = minLat + (maxLat - minLat) * random.nextDouble();
        final double lng = minLng + (maxLng - minLng) * random.nextDouble();

        // Generate random herd size
        final int herdSize = 1 + random.nextInt(99);

        // Convert your herd widget to image
        final Uint8List imageBytes = await _createHerdMarkerImage(herdSize);

        // Create point annotation
        final PointAnnotationOptions options = PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          image: imageBytes,
          iconSize: 1.0,
          iconAnchor: IconAnchor.BOTTOM,
        );

        final PointAnnotation annotation = await _pointAnnotationManager!.create(options);
        newMarkers.add(annotation);

        // Add small delay to prevent UI freezing
        if (i % 50 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      _markers.clear();
      _markers.addAll(newMarkers);

      emit(ManyMarkersLoaded(
        markers: List.from(_markers),
        markerCount: _markers.length,
      ));
    } catch (e) {
      emit(ManyMarkersError(error: 'Failed to generate markers: $e'));
    }
  }

  Future<void> _onClearMarkers(
    ClearMarkers event,
    Emitter<ManyMarkersState> emit,
  ) async {
    try {
      if (_pointAnnotationManager != null) {
        // Delete all existing markers
        await _pointAnnotationManager!.deleteAll();
      }
      
      _markers.clear();
      emit(ManyMarkersInitial());
    } catch (e) {
      emit(ManyMarkersError(error: 'Failed to clear markers: $e'));
    }
  }

  // Create your exact herd widget as an image (since Mapbox needs static images)
  Future<Uint8List> _createHerdMarkerImage(int number) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    const double width = 110;
    const double height = 46;
    
    // Load and draw speech bubble SVG
    try {
      // For now, we'll create a simple representation
      // In a full implementation, you'd need to render the SVG to canvas
      await _drawHerdWidget(canvas, number, width, height);
    } catch (e) {
      // Fallback to simple drawing if SVG loading fails
      await _drawSimpleHerdWidget(canvas, number, width, height);
    }
    
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width.round(), height.round());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  Future<void> _drawHerdWidget(Canvas canvas, int number, double width, double height) async {
    // Draw speech bubble background (simplified version)
    final Paint bubblePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final Paint borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw rounded rectangle for speech bubble
    final RRect bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, 5, width - 15, height - 15),
      const Radius.circular(8),
    );
    
    canvas.drawRRect(bubbleRect, bubblePaint);
    canvas.drawRRect(bubbleRect, borderPaint);
    
    // Draw tail of speech bubble
    final Path tailPath = Path();
    tailPath.moveTo(20, height - 10);
    tailPath.lineTo(15, height - 5);
    tailPath.lineTo(25, height - 5);
    tailPath.close();
    canvas.drawPath(tailPath, bubblePaint);
    canvas.drawPath(tailPath, borderPaint);
    
    // Draw cow icon placeholder (simplified)
    final Paint cowPaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(const Offset(30, 20), 8, cowPaint);
    
    // Draw number text
    final textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 20,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, const Offset(47, 6));
    
    // Draw spinner placeholder (simplified rotating element)
    final Paint spinnerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    // Draw a simple rotating indicator
    canvas.save();
    canvas.translate(86, 17);
    canvas.rotate(DateTime.now().millisecondsSinceEpoch / 200.0); // Simple rotation
    canvas.drawRect(const Rect.fromLTWH(-8, -1, 16, 2), spinnerPaint);
    canvas.drawRect(const Rect.fromLTWH(-1, -8, 2, 16), spinnerPaint);
    canvas.restore();
  }

  Future<void> _drawSimpleHerdWidget(Canvas canvas, int number, double width, double height) async {
    // Simplified fallback version
    final Paint backgroundPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(15),
      ),
      backgroundPaint,
    );
    
    // Draw border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, width - 2, height - 2),
        const Radius.circular(15),
      ),
      borderPaint,
    );
    
    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🐄 $number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );
  }
}