import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shravani_thermal/config/gemini_config.dart';
import 'package:shravani_thermal/services/gemini_service.dart';

/// Live Gemini localization check.
///
/// Env:
///   LIVE_IMAGE  - path to test image (required)
///   LIVE_TARGET - targetIssueType (default: crack)
///
/// flutter run -d windows -t tool/live_bbox_main.dart --dart-define=GEMINI_API_KEY=...
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!GeminiConfig.isConfigured) {
    stderr.writeln('FAIL: GEMINI_API_KEY not configured');
    exit(2);
  }

  final imagePath = Platform.environment['LIVE_IMAGE'];
  final target = Platform.environment['LIVE_TARGET'] ?? 'crack';
  if (imagePath == null || imagePath.isEmpty) {
    stderr.writeln('FAIL: set LIVE_IMAGE to an image path');
    exit(3);
  }

  final file = File(imagePath);
  if (!file.existsSync()) {
    stderr.writeln('FAIL: image missing at $imagePath');
    exit(4);
  }

  final bytes = await file.readAsBytes();
  final mime = imagePath.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
  stdout.writeln(
    '[LIVE_BBOX] targetIssueType=$target bytes=${bytes.length} path=$imagePath',
  );

  final analysis = await GeminiService.analyzeImageDetails(
    bytes,
    mime,
    targetIssueType: target,
  );

  stdout.writeln('[LIVE_BBOX] issueCount=${analysis.issues.length}');
  stdout.writeln('[LIVE_BBOX] summary=${analysis.summary}');

  var ok = true;
  if (target != 'all' && analysis.issues.any((i) => i.type != target)) {
    ok = false;
  }

  for (final issue in analysis.issues) {
    final b = issue.boundingBox;
    stdout.writeln(
      '[LIVE_BBOX] type=${issue.type} conf=${issue.confidence} '
      'box=${b == null ? 'null' : 'x1=${b.x1},y1=${b.y1},x2=${b.x2},y2=${b.y2} '
          'w=${b.x2 - b.x1},h=${b.y2 - b.y1},area=${(b.x2 - b.x1) * (b.y2 - b.y1)}'}',
    );
    if (b != null) {
      if (b.x1 == 10 && b.y1 == 10 && b.x2 == 50 && b.y2 == 50) ok = false;
      if (b.x2 <= b.x1 || b.y2 <= b.y1) ok = false;
      // Generic soft check: reject near-full-frame boxes as still too loose.
      final w = b.x2 - b.x1;
      final h = b.y2 - b.y1;
      if (w >= 90 && h >= 90) ok = false;
    }
  }

  if (!ok) {
    stderr.writeln('FAIL: live bbox localization check did not pass');
    exit(1);
  }
  stdout.writeln('PASS: live bbox check completed (see boxes above)');
  exit(0);
}
