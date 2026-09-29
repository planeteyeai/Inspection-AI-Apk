import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shravani_thermal/config/gemini_config.dart';
import 'package:shravani_thermal/services/gemini_service.dart';

/// Live Gemini hollow_section check against the saved diagnosis image.
/// Skips when GEMINI_API_KEY is not provided via --dart-define.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'live hollow_section detection returns localized percentage box',
    () async {
      if (!GeminiConfig.isConfigured) {
        // ignore: avoid_print
        print('SKIP live Gemini: GEMINI_API_KEY not configured');
        return;
      }

      final imagePath =
          r'C:\Users\Rutuja.Dugaje\.cursor\projects\c-Users-Rutuja-Dugaje-Desktop-Shravani-thermal\assets\c__Users_Rutuja.Dugaje_AppData_Roaming_Cursor_User_workspaceStorage_704dd315a353d33d7d3404406ef76784_images_image-1f08e6a1-4f9c-494e-b0fa-4798c87ba5c4.png';
      final file = File(imagePath);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'diagnosis hollow-section image must exist',
      );

      final bytes = await file.readAsBytes();
      final analysis = await GeminiService.analyzeImageDetails(
        bytes,
        'image/png',
        targetIssueType: 'hollow_section',
      );

      // ignore: avoid_print
      print(
        '[LIVE_HOLLOW] issueCount=${analysis.issues.length} summary=${analysis.summary}',
      );
      for (final issue in analysis.issues) {
        final b = issue.boundingBox;
        // ignore: avoid_print
        print(
          '[LIVE_HOLLOW] type=${issue.type} conf=${issue.confidence} '
          'box=${b == null ? 'null' : 'x1=${b.x1},y1=${b.y1},x2=${b.x2},y2=${b.y2}'}',
        );
      }

      expect(
        analysis.issues,
        isNotEmpty,
        reason: 'hollow section should be visible in this image',
      );
      for (final issue in analysis.issues) {
        expect(issue.type, 'hollow_section');
        // Must not invent the old silent fallback (10,10)-(50,50).
        if (issue.boundingBox != null) {
          final b = issue.boundingBox!;
          expect(b.x1, inInclusiveRange(0, 100));
          expect(b.y1, inInclusiveRange(0, 100));
          expect(b.x2, inInclusiveRange(0, 100));
          expect(b.y2, inInclusiveRange(0, 100));
          expect(b.x2, greaterThan(b.x1));
          expect(b.y2, greaterThan(b.y1));
          final area = (b.x2 - b.x1) * (b.y2 - b.y1);
          expect(
            area,
            lessThan(60 * 60),
            reason: 'box should be tighter than a huge default region',
          );
          expect(
            !(b.x1 == 10 && b.y1 == 10 && b.x2 == 50 && b.y2 == 50),
            isTrue,
            reason: 'must not use silent 10-50 fallback box',
          );
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
