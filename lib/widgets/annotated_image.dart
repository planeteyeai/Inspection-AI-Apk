import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/inspection_models.dart';

class AnnotatedImageWidget extends StatelessWidget {
  final Uint8List imageBytes;
  final List<DistressIssue> issues;
  final int? hoveredIndex;

  const AnnotatedImageWidget({
    super.key,
    required this.imageBytes,
    required this.issues,
    this.hoveredIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: Colors.grey.shade100,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // BoxFit.contain: percentage boxes map onto the uncropped image rect.
            return FutureBuilder<ui.Image>(
              future: _decode(imageBytes),
              builder: (context, snapshot) {
                final image = snapshot.data;
                if (image == null) {
                  return Image.memory(
                    imageBytes,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  );
                }

                final maxW = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;
                final maxH = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 280.0;

                final fitted = applyBoxFit(
                  BoxFit.contain,
                  Size(image.width.toDouble(), image.height.toDouble()),
                  Size(maxW, maxH),
                );
                final displaySize = fitted.destination;
                final widgetHeight = displaySize.height.clamp(180.0, 420.0);

                return SizedBox(
                  width: double.infinity,
                  height: widgetHeight,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: image.width.toDouble(),
                      height: image.height.toDouble(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RawImage(image: image, fit: BoxFit.fill),
                          CustomPaint(
                            painter: _BoundingBoxPainter(
                              issues: issues,
                              hoveredIndex: hoveredIndex,
                              sourceWidth: image.width.toDouble(),
                              sourceHeight: image.height.toDouble(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  static Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final List<DistressIssue> issues;
  final int? hoveredIndex;
  final double sourceWidth;
  final double sourceHeight;

  _BoundingBoxPainter({
    required this.issues,
    required this.hoveredIndex,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (kDebugMode) {
      final scaleX = sourceWidth == 0 ? 0.0 : size.width / sourceWidth;
      final scaleY = sourceHeight == 0 ? 0.0 : size.height / sourceHeight;
      debugPrint(
        '[GEMINI_DET] overlayPaint displaySize=${size.width}x${size.height} '
        'sourceImageSize=${sourceWidth}x$sourceHeight '
        'boxFit=BoxFit.contain scaleX=$scaleX scaleY=$scaleY '
        'offsetX=0 offsetY=0 renderedImageSize=${size.width}x${size.height}',
      );
    }

    for (int i = 0; i < issues.length; i++) {
      final issue = issues[i];
      final box = issue.boundingBox;
      if (box == null) {
        if (kDebugMode) {
          debugPrint(
            '[GEMINI_DET] targetIssueType=n/a issueType=${issue.type} '
            'confidence=${issue.confidence} rawBox=null parsedBox=unavailable '
            'sourceImageSize=${sourceWidth}x$sourceHeight '
            'displaySize=${size.width}x${size.height} finalRect=unavailable',
          );
        }
        continue;
      }

      final isHovered = hoveredIndex == i;

      // Percentages 0–100 of the FULL original image, mapped onto contain-fitted image space.
      final left = (box.x1 / 100) * size.width;
      final top = (box.y1 / 100) * size.height;
      final right = (box.x2 / 100) * size.width;
      final bottom = (box.y2 / 100) * size.height;
      final rect = Rect.fromLTRB(left, top, right, bottom);

      if (kDebugMode) {
        debugPrint(
          '[GEMINI_DET] targetIssueType=n/a issueType=${issue.type} confidence=${issue.confidence} '
          'rawBox={x1:${box.x1},y1:${box.y1},x2:${box.x2},y2:${box.y2}} '
          'parsedBox={x1:${box.x1},y1:${box.y1},x2:${box.x2},y2:${box.y2}} '
          'sourceImageSize=${sourceWidth}x$sourceHeight '
          'displaySize=${size.width}x${size.height} '
          'finalRect=L=${rect.left},T=${rect.top},R=${rect.right},B=${rect.bottom}',
        );
      }

      final boxColor = isHovered ? Colors.amber : Colors.orangeAccent;

      final fillPaint = Paint()
        ..color = boxColor.withValues(alpha: isHovered ? 0.35 : 0.2)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = boxColor
        ..strokeWidth = isHovered ? 3.0 : 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        fillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        borderPaint,
      );

      final textSpan = TextSpan(
        text:
            ' #${i + 1} ${issue.type.toUpperCase()} (${(issue.confidence * 100).toStringAsFixed(0)}%) ',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black87,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final labelYMax = (size.height - 20).clamp(0.0, double.infinity);
      final labelY = (top - 16).clamp(0.0, labelYMax);
      textPainter.paint(canvas, Offset(left, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.issues != issues ||
        oldDelegate.sourceWidth != sourceWidth ||
        oldDelegate.sourceHeight != sourceHeight;
  }
}
