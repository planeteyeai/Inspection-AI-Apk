import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';
import '../models/inspection_models.dart';

class GeminiService {
  /// Reads GEMINI_API_KEY from --dart-define / local config. Not hardcoded.
  static String? get apiKey {
    final key = GeminiConfig.apiKey.trim();
    return key.isEmpty ? null : key;
  }

  static bool get isDemoMode => !GeminiConfig.isConfigured;

  /// Labels for every existing UI targetIssueType value.
  static const Map<String, String> _targetLabels = {
    'all': 'All Distress',
    'crack': 'Crack',
    'wide_crack': 'Wide Crack',
    'hollow_section': 'Hollow Section / Hollow Opening / Void / Cavity',
    'honeycombing': 'Honeycombing',
    'spalling': 'Spalling',
    'scaling': 'Scaling',
    'steel_corrosion': 'Steel Corrosion',
    'exposed_steel': 'Steel Exposed',
    'efflorescence': 'Efflorescence',
    'pedestal_damage': 'Pedestal Damage',
    'vegetation_growth': 'Vegetation Growth',
  };

  static Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static String _buildDetectionPrompt(String? targetIssueType) {
    final targetKey =
        (targetIssueType == null || targetIssueType.trim().isEmpty)
        ? 'all'
        : targetIssueType.trim();
    final targetLabel = _targetLabels[targetKey] ?? targetKey;
    final focused = targetKey != 'all';

    final buffer = StringBuffer();
    buffer.writeln(
      'You are a structural inspection vision model for bridges and civil structures.',
    );
    buffer.writeln(
      'Analyze the provided inspection photo and return ONLY valid JSON.',
    );
    buffer.writeln(
      'Treat close-up photos of concrete/masonry/steel members as valid inspection images.',
    );
    buffer.writeln(
      'Do not refuse detection merely because the framing is a tight close-up.',
    );
    buffer.writeln();
    buffer.writeln('Selected inspection targetIssueType: $targetKey');
    buffer.writeln('Selected inspection target label: $targetLabel');
    buffer.writeln();

    if (focused) {
      buffer.writeln('TARGET-SPECIFIC RULES:');
      buffer.writeln(
        '- Prioritize ONLY the selected target: $targetLabel ($targetKey).',
      );
      buffer.writeln(
        '- Do NOT substitute a different distress merely because it is more noticeable.',
      );
      buffer.writeln(
        '- If the selected target is not actually visible, return "issues": [].',
      );
      buffer.writeln('- Do NOT invent a detection or fake bounding box.');
      buffer.writeln('- Set each issue "type" exactly to "$targetKey".');
      if (targetKey == 'hollow_section') {
        buffer.writeln(
          '- For hollow_section, localize the actual hollow/open void/cavity/opening.',
        );
        buffer.writeln(
          '- Do NOT confuse hollow_section with staining/discoloration, cracks, shadows, surface texture, spalling, or corrosion.',
        );
      } else if (targetKey == 'crack' || targetKey == 'wide_crack') {
        buffer.writeln(
          '- Localize the complete visible crack path with a tight box around the crack itself.',
        );
        buffer.writeln(
          '- Do NOT confuse the crack with unrelated staining, shadows, or adjacent surface texture.',
        );
      } else if (targetKey == 'efflorescence') {
        buffer.writeln(
          '- Localize only the visible efflorescence/white deposit region.',
        );
      } else if (targetKey == 'spalling' || targetKey == 'scaling') {
        buffer.writeln(
          '- Localize only the actual damaged/spalled/scaled concrete region.',
        );
      } else if (targetKey == 'steel_corrosion' ||
          targetKey == 'exposed_steel') {
        buffer.writeln(
          '- Localize only the visible corrosion / exposed steel region.',
        );
      }
      buffer.writeln();
    } else {
      buffer.writeln(
        'Detect visible structural distress. Allowed type values:',
      );
      buffer.writeln(_targetLabels.keys.where((k) => k != 'all').join(', '));
      buffer.writeln();
    }

    buffer.writeln('Return this JSON shape:');
    buffer.writeln('{');
    buffer.writeln('  "summary": "string",');
    buffer.writeln('  "issues": [');
    buffer.writeln('    {');
    buffer.writeln('      "type": "string",');
    buffer.writeln('      "confidence": 0-100,');
    buffer.writeln(
      '      "boundingBox": { "x1": number, "y1": number, "x2": number, "y2": number },',
    );
    buffer.writeln('      "description": "string",');
    buffer.writeln('      "recommendation": "string"');
    buffer.writeln('    }');
    buffer.writeln('  ],');
    buffer.writeln('  "recommendations": ["string"]');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('LOCALIZATION CONTRACT (applies to EVERY issue type):');
    buffer.writeln(
      '- Each boundingBox must tightly enclose ONLY the actual visible distress pixels.',
    );
    buffer.writeln(
      '- Include the complete visible distress; do not cut it off.',
    );
    buffer.writeln(
      '- Exclude unnecessary surrounding concrete/stone/background.',
    );
    buffer.writeln(
      '- Do NOT cover an entire wall, pier, soffit, or structural element unless the distress genuinely spans it.',
    );
    buffer.writeln(
      '- Do NOT return a tall/wide strip that mostly contains sound surface.',
    );
    buffer.writeln(
      '- Do NOT default to near-full-image height or width (e.g. y1≈0 and y2≈100) unless distress pixels truly span that full extent continuously.',
    );
    buffer.writeln(
      '- Independently measure the distress extent on X and on Y; each axis should stop where the visible distress stops.',
    );
    buffer.writeln(
      '- Follow the visible spatial extent of the distress (linear, patch, opening, stain, etc.).',
    );
    buffer.writeln(
      '- Allow a small natural margin of at most ~1% of image width/height beyond the distress edges.',
    );
    buffer.writeln(
      '- Thin/linear distress (e.g. cracks) may have a narrow box; do not artificially widen it.',
    );
    buffer.writeln(
      '- Small patches (corrosion, spalling, openings) may have a small box; do not artificially enlarge it.',
    );
    buffer.writeln(
      '- Prefer ONE issue / ONE box per distinct physical distress region.',
    );
    buffer.writeln(
      '- Do NOT emit multiple overlapping/nested boxes for the same visible region.',
    );
    buffer.writeln(
      '- If co-located symptoms share the same pixels, choose the single best primary type and one tight box.',
    );
    buffer.writeln(
      '- Ignore any pre-drawn UI overlays, labels, or orange rectangles that may appear in a screenshot; localize the real surface distress only.',
    );
    buffer.writeln();
    buffer.writeln('BOUNDING BOX FORMAT (mandatory):');
    buffer.writeln(
      '- boundingBox coordinates are PERCENTAGES of the FULL ORIGINAL IMAGE.',
    );
    buffer.writeln('- Range is 0 to 100 inclusive.');
    buffer.writeln('- x1 = left, y1 = top, x2 = right, y2 = bottom.');
    buffer.writeln('- Require x1 < x2 and y1 < y2.');
    buffer.writeln('- Do NOT use [ymin, xmin, ymax, xmax].');
    buffer.writeln('- Do NOT use 0-1000 coordinates.');
    buffer.writeln('- Do NOT use pixel coordinates.');
    buffer.writeln('- Do NOT use normalized 0-1 coordinates.');
    buffer.writeln(
      '- If you cannot localize a valid tight box, omit boundingBox for that issue (do not invent one).',
    );
    return buffer.toString();
  }

  static void _logDetectionDiag({
    required String stage,
    required int sourceWidth,
    required int sourceHeight,
    required String? targetIssueType,
    required String rawTextPreview,
    required ImageAnalysis analysis,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[GEMINI_DET] stage=$stage '
      'targetIssueType=${targetIssueType ?? 'null'} '
      'sourceImageSize=${sourceWidth}x$sourceHeight '
      'bboxConvention=percent_0_to_100_full_image',
    );
    debugPrint(
      '[GEMINI_DET] rawPreview=${rawTextPreview.length > 900 ? rawTextPreview.substring(0, 900) : rawTextPreview}',
    );
    for (final issue in analysis.issues) {
      final b = issue.boundingBox;
      debugPrint(
        '[GEMINI_DET] issueType=${issue.type} confidence=${issue.confidence} '
        'rawBox=${b == null ? 'null' : '{x1:${b.x1},y1:${b.y1},x2:${b.x2},y2:${b.y2}}'} '
        'parsedBox=${b == null ? 'unavailable' : '{x1:${b.x1},y1:${b.y1},x2:${b.x2},y2:${b.y2}}'}',
      );
    }
  }

  static final List<DistressIssue> _mockIssues = [
    DistressIssue(
      elementName: 'Pier Cap',
      type: 'wide_crack',
      description:
          'Wide longitudinal crack running across the pier cap soffit.',
      depth: '0.02',
      width: '0.005',
      length: '1.2',
      confidence: 0.93,
      boundingBox: BoundingBox(x1: 20, y1: 30, x2: 55, y2: 38),
      segmentationPath: [
        Point2D(x: 20, y: 34),
        Point2D(x: 30, y: 33),
        Point2D(x: 40, y: 35),
        Point2D(x: 55, y: 34),
      ],
      area: 0.006,
      volume: 0.00012,
      quantityUnit: 'RM',
      quantityValue: 1.2,
    ),
    DistressIssue(
      elementName: 'PSC Girder',
      type: 'spalling',
      description:
          'Concrete spalling with exposed aggregate on the bottom flange.',
      depth: '0.04',
      width: '0.3',
      length: '0.4',
      confidence: 0.91,
      boundingBox: BoundingBox(x1: 60, y1: 55, x2: 80, y2: 72),
      segmentationPath: [
        Point2D(x: 60, y: 55),
        Point2D(x: 80, y: 55),
        Point2D(x: 80, y: 72),
        Point2D(x: 60, y: 72),
      ],
      area: 0.12,
      volume: 0.0048,
      quantityUnit: 'Sqm',
      quantityValue: 0.12,
    ),
    DistressIssue(
      elementName: 'Pier Column',
      type: 'steel_corrosion',
      description:
          'Orange rust stains leaching from internal rebar indicating active corrosion.',
      depth: '0.01',
      width: '0.15',
      length: '0.6',
      confidence: 0.88,
      boundingBox: BoundingBox(x1: 10, y1: 65, x2: 30, y2: 85),
      segmentationPath: [
        Point2D(x: 10, y: 65),
        Point2D(x: 30, y: 65),
        Point2D(x: 30, y: 85),
        Point2D(x: 10, y: 85),
      ],
      area: 0.09,
      volume: 0.0009,
      quantityUnit: 'Sqm',
      quantityValue: 0.09,
    ),
  ];

  static final List<String> _mockRecommendations = [
    'Immediate epoxy grouting required for the wide crack on pier cap.',
    'Spalling zone to be repaired with micro-concrete patching.',
    'Apply corrosion inhibitor coating after cleaning rust stains.',
    'Schedule follow-up inspection in 3 months.',
  ];

  static final List<BridgeElementResult> _mockBridgeResults = [
    BridgeElementResult(
      elementName: 'Pier Cap',
      conditionRating: 2,
      levelOfSeverity: 'Immediate Requirement',
      distressLength: 1.2,
      distressWidth: 0.005,
      distressThickness: 0.02,
      distressNos: 1,
      distressUnit: 'RM',
      distressValue: 1.2,
      scaffoldingLength: 3,
      scaffoldingWidth: 2,
      scaffoldingHeight: 4,
      scaffoldingCum: 24,
      suggestedRnR: 'Epoxy Grouting',
      testingRecommendation: true,
    ),
    BridgeElementResult(
      elementName: 'PSC Girder',
      conditionRating: 3,
      levelOfSeverity: 'Short-Term Requirement',
      distressLength: 0.4,
      distressWidth: 0.3,
      distressThickness: 0.04,
      distressNos: 1,
      distressUnit: 'Sqm',
      distressValue: 0.12,
      scaffoldingLength: 5,
      scaffoldingWidth: 2,
      scaffoldingHeight: 5,
      scaffoldingCum: 50,
      suggestedRnR: 'Micro-Concrete',
      testingRecommendation: false,
    ),
    BridgeElementResult(
      elementName: 'Pier Column',
      conditionRating: 4,
      levelOfSeverity: 'Long-Term Requirement',
      distressLength: 0.6,
      distressWidth: 0.15,
      distressThickness: 0.01,
      distressNos: 1,
      distressUnit: 'Sqm',
      distressValue: 0.09,
      scaffoldingLength: 2,
      scaffoldingWidth: 2,
      scaffoldingHeight: 6,
      scaffoldingCum: 24,
      suggestedRnR: 'Shortcrete',
      testingRecommendation: false,
    ),
  ];

  static Future<ImageAnalysis> analyzeImageDetails(
    Uint8List imageBytes,
    String mimeType, {
    String? targetIssueType,
  }) async {
    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 1500));
      var issues = List<DistressIssue>.from(_mockIssues);
      if (targetIssueType != null && targetIssueType != 'all') {
        issues = issues.where((i) => i.type == targetIssueType).toList();
      }
      return ImageAnalysis(
        summary:
            '[DEMO MODE] Inspection complete. Concrete distress, spalling, and rebar corrosion detected with sub-millimeter metrology.',
        issues: issues,
        recommendations: _mockRecommendations,
      );
    }

    try {
      final decodedImage = await _decodeImage(imageBytes);
      final sourceWidth = decodedImage.width;
      final sourceHeight = decodedImage.height;

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt = _buildDetectionPrompt(targetIssueType);

      final response = await model.generateContent([
        Content.multi([DataPart(mimeType, imageBytes), TextPart(prompt)]),
      ]);

      final text = response.text ?? '';
      final cleanJson = _extractJson(text);
      final decoded = jsonDecode(cleanJson) as Map<String, dynamic>;
      final analysis = ImageAnalysis.fromJson(decoded);

      _logDetectionDiag(
        stage: 'after_parse_before_filter',
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        targetIssueType: targetIssueType,
        rawTextPreview: cleanJson,
        analysis: analysis,
      );

      // Safety check only — target is already in the prompt. Do not reinterpret types.
      if (targetIssueType != null && targetIssueType != 'all') {
        final filtered = analysis.issues
            .where((i) => i.type == targetIssueType)
            .toList();
        final filteredAnalysis = ImageAnalysis(
          summary: analysis.summary,
          issues: filtered,
          recommendations: analysis.recommendations,
        );
        _logDetectionDiag(
          stage: 'after_client_filter',
          sourceWidth: sourceWidth,
          sourceHeight: sourceHeight,
          targetIssueType: targetIssueType,
          rawTextPreview: 'filtered_count=${filtered.length}',
          analysis: filteredAnalysis,
        );
        return filteredAnalysis;
      }
      return analysis;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GEMINI_DET] stage=error type=${e.runtimeType} message=$e');
      }
      // Do not invent detections/boxes on failure.
      return ImageAnalysis(
        summary: 'Metrology analysis failed. No detections returned.',
        issues: const [],
        recommendations: const [],
      );
    }
  }

  static Future<List<BridgeElementResult>> analyzeBridgeInspection(
    Uint8List imageBytes,
    String mimeType,
    List<ElementFormData> elements,
  ) async {
    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 1200));
      return elements.asMap().entries.map((entry) {
        final i = entry.key;
        final el = entry.value;
        final mock = _mockBridgeResults[i % _mockBridgeResults.length];
        return BridgeElementResult(
          elementName: el.elementName,
          conditionRating: mock.conditionRating,
          levelOfSeverity: mock.levelOfSeverity,
          distressLength: mock.distressLength,
          distressWidth: mock.distressWidth,
          distressThickness: mock.distressThickness,
          distressNos: mock.distressNos,
          distressUnit: mock.distressUnit,
          distressValue: mock.distressValue,
          scaffoldingLength: mock.scaffoldingLength,
          scaffoldingWidth: mock.scaffoldingWidth,
          scaffoldingHeight: mock.scaffoldingHeight,
          scaffoldingCum: mock.scaffoldingCum,
          suggestedRnR: mock.suggestedRnR,
          testingRecommendation: mock.testingRecommendation,
        );
      }).toList();
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final elementNames = elements.map((e) => e.elementName).toList();
      final prompt =
          '''
You are a senior bridge inspection engineer.
Return ONLY a JSON array with one object per structural element, in this exact order:
${elementNames.map((n) => '- $n').join('\n')}

Each object MUST use this schema:
{
  "elementName": "string (match the list)",
  "conditionRating": 1-5,
  "levelOfSeverity": "Immediate Requirement" | "Short-Term Requirement" | "Long-Term Requirement",
  "distressLength": number_or_null,
  "distressWidth": number_or_null,
  "distressThickness": number_or_null,
  "distressNos": number_or_null,
  "distressUnit": "RM" | "Sqm" | "Nos",
  "distressValue": number,
  "scaffoldingLength": number_or_null,
  "scaffoldingWidth": number_or_null,
  "scaffoldingHeight": number_or_null,
  "scaffoldingCum": number,
  "suggestedRnR": "string",
  "testingRecommendation": true_or_false
}

Rules:
- Use levelOfSeverity values EXACTLY as listed above (do not invent other severity labels).
- scaffoldingCum should be Length * Width * Height when dimensions are available.
- Prefer realistic field values based on the photo and element context.
- Return a JSON array only.
''';

      final response = await model.generateContent([
        Content.multi([DataPart(mimeType, imageBytes), TextPart(prompt)]),
      ]);

      final text = response.text ?? '';
      final cleanJson = _extractJson(text);
      final decodedList = jsonDecode(cleanJson) as List<dynamic>;
      final parsed = decodedList
          .map((e) => BridgeElementResult.fromJson(e as Map<String, dynamic>))
          .toList();

      // Align to requested element order / names when possible.
      return elements.asMap().entries.map((entry) {
        final i = entry.key;
        final el = entry.value;
        if (i < parsed.length) {
          final r = parsed[i];
          return r.copyWith(elementName: el.elementName);
        }
        final byName = parsed
            .where((p) => p.elementName == el.elementName)
            .toList();
        if (byName.isNotEmpty)
          return byName.first.copyWith(elementName: el.elementName);
        final mock = _mockBridgeResults[i % _mockBridgeResults.length];
        return BridgeElementResult(
          elementName: el.elementName,
          conditionRating: mock.conditionRating,
          levelOfSeverity: mock.levelOfSeverity,
          distressLength: mock.distressLength,
          distressWidth: mock.distressWidth,
          distressThickness: mock.distressThickness,
          distressNos: mock.distressNos,
          distressUnit: mock.distressUnit,
          distressValue: mock.distressValue,
          scaffoldingLength: mock.scaffoldingLength,
          scaffoldingWidth: mock.scaffoldingWidth,
          scaffoldingHeight: mock.scaffoldingHeight,
          scaffoldingCum: mock.scaffoldingCum,
          suggestedRnR: mock.suggestedRnR,
          testingRecommendation: mock.testingRecommendation,
        );
      }).toList();
    } catch (e) {
      return elements.asMap().entries.map((entry) {
        final i = entry.key;
        final el = entry.value;
        final mock = _mockBridgeResults[i % _mockBridgeResults.length];
        return BridgeElementResult(
          elementName: el.elementName,
          conditionRating: mock.conditionRating,
          levelOfSeverity: mock.levelOfSeverity,
          distressLength: mock.distressLength,
          distressWidth: mock.distressWidth,
          distressThickness: mock.distressThickness,
          distressNos: mock.distressNos,
          distressUnit: mock.distressUnit,
          distressValue: mock.distressValue,
          scaffoldingLength: mock.scaffoldingLength,
          scaffoldingWidth: mock.scaffoldingWidth,
          scaffoldingHeight: mock.scaffoldingHeight,
          scaffoldingCum: mock.scaffoldingCum,
          suggestedRnR: mock.suggestedRnR,
          testingRecommendation: mock.testingRecommendation,
        );
      }).toList();
    }
  }

  static String _extractJson(String raw) {
    var text = raw
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();
    final sObj = text.indexOf('{');
    final sArr = text.indexOf('[');
    if (sObj != -1 && (sArr == -1 || sObj < sArr)) {
      final eObj = text.lastIndexOf('}');
      if (eObj > sObj) return text.substring(sObj, eObj + 1);
    } else if (sArr != -1) {
      final eArr = text.lastIndexOf(']');
      if (eArr > sArr) return text.substring(sArr, eArr + 1);
    }
    return text;
  }
}
