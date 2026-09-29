import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:shravani_thermal/config/gemini_config.dart';
import 'package:shravani_thermal/services/gemini_service.dart';

/// One-shot live Gemini hollow_section verification.
/// flutter run -d windows -t tool/live_hollow_main.dart --dart-define=GEMINI_API_KEY=...
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!GeminiConfig.isConfigured) {
    stderr.writeln('FAIL: GEMINI_API_KEY not configured');
    exit(2);
  }

  final fixture = File('tool/hollow_section_fixture.png');
  if (!fixture.existsSync()) {
    _writeFixture(fixture);
  }

  final bytes = await fixture.readAsBytes();
  stdout.writeln(
    '[LIVE_HOLLOW] calling Gemini targetIssueType=hollow_section bytes=${bytes.length}',
  );

  final analysis = await GeminiService.analyzeImageDetails(
    bytes,
    'image/png',
    targetIssueType: 'hollow_section',
  );

  stdout.writeln('[LIVE_HOLLOW] issueCount=${analysis.issues.length}');
  stdout.writeln('[LIVE_HOLLOW] summary=${analysis.summary}');

  var ok = analysis.issues.isNotEmpty;
  for (final issue in analysis.issues) {
    final b = issue.boundingBox;
    stdout.writeln(
      '[LIVE_HOLLOW] type=${issue.type} conf=${issue.confidence} '
      'box=${b == null ? 'null' : 'x1=${b.x1},y1=${b.y1},x2=${b.x2},y2=${b.y2}'}',
    );
    if (issue.type != 'hollow_section') ok = false;
    if (b != null) {
      final area = (b.x2 - b.x1) * (b.y2 - b.y1);
      if (b.x1 == 10 && b.y1 == 10 && b.x2 == 50 && b.y2 == 50) ok = false;
      if (area >= 60 * 60) ok = false;
      if (b.x2 <= b.x1 || b.y2 <= b.y1) ok = false;
    } else {
      ok = false;
    }
  }

  if (!ok) {
    stderr.writeln('FAIL: hollow_section localization check did not pass');
    exit(1);
  }
  stdout.writeln('PASS: hollow_section live detection looks localized');
  exit(0);
}

void _writeFixture(File out) {
  const w = 800;
  const h = 600;
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final n = ((x * 17 + y * 31) % 40) - 20;
      final v = (150 + n).clamp(110, 190);
      image.setPixelRgb(x, y, v, v - 2, v - 5);
    }
  }
  for (var y = 80; y < 180; y++) {
    for (var x = 500; x < 720; x++) {
      final p = image.getPixel(x, y);
      image.setPixelRgb(x, y, (p.r * 0.75).round(), (p.g * 0.7).round(), (p.b * 0.55).round());
    }
  }
  for (var y = 220; y < 420; y++) {
    for (var x = 180; x < 340; x++) {
      final edge = x < 185 || x > 335 || y < 225 || y > 415;
      final depth = edge ? 45 : 18 + ((x + y) % 8);
      image.setPixelRgb(x, y, depth, depth, depth + 5);
    }
  }
  for (var y = 250; y < 390; y++) {
    for (var x = 210; x < 310; x++) {
      image.setPixelRgb(x, y, 8, 8, 12);
    }
  }
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(img.encodePng(image));
}
