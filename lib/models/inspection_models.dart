/// Represents a project with its full MySQL database name and a human-readable UI display label.
/// [databaseName] is the original full string stored in database_Bms.bridge.project_name (e.g. "Tolling, Operation...").
/// [displayName] is the short readable label for UI dropdowns (e.g. "Kochugaon – Khaljhar Section").
class ProjectRecord {
  final String databaseName;
  final String displayName;

  const ProjectRecord({required this.databaseName, required this.displayName});

  /// Excludes demo projects (such as "Aasam") and converts raw database project names into UI project records.
  static List<ProjectRecord> fromDatabaseProjects(List<String> rawProjects) {
    final validRawProjects = rawProjects.where((raw) {
      final lower = raw.trim().toLowerCase();
      return lower != 'aasam' &&
          !lower.startsWith('aasam') &&
          !lower.contains('aasam');
    }).toList();

    final Map<String, String> rawToDisplay = {};
    final Map<String, int> displayCounts = {};

    for (final raw in validRawProjects) {
      final disp = _deriveDisplayName(raw);
      rawToDisplay[raw] = disp;
      displayCounts[disp] = (displayCounts[disp] ?? 0) + 1;
    }

    final List<ProjectRecord> records = [];
    for (final raw in validRawProjects) {
      var disp = rawToDisplay[raw]!;
      if ((displayCounts[disp] ?? 0) > 1) {
        disp = _disambiguate(raw, disp);
      }
      records.add(ProjectRecord(databaseName: raw, displayName: disp));
    }

    return records;
  }

  static String _deriveDisplayName(String dbName) {
    final trimmed = dbName.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = trimmed.toLowerCase();

    // Known project mappings based on section names
    if (lower.contains('agra') &&
        (lower.contains('by- pass') ||
            lower.contains('by pass') ||
            lower.contains('bypass'))) {
      return 'Agra-Bypass Section';
    }
    if (lower.contains('swaroopganj') ||
        lower.contains('abu road-swaroopganj') ||
        lower.contains('abu road - swaroopganj')) {
      return 'Abu Road-Swaroopganj Section';
    }
    if (lower.contains('chittorgarh')) {
      return 'Chittorgarh Bypass to Kota Section';
    }
    if (lower.contains('bhopkhedi')) {
      return 'Bhopkhedi-Wadner Section';
    }
    if (lower.contains('chichra')) {
      return 'Four Lane Chichra to Kharagpur Section';
    }
    if (lower.contains('kochugaon')) {
      return 'Kochugaon – Khaljhar Section';
    }
    if (lower.contains('palanpur') || lower.contains('khemana')) {
      return 'Palanpur/Khemana – Abu Road Section';
    }
    if (lower.contains('shivpuri')) {
      return 'Shivpuri-Jhansi Section';
    }

    // Dynamic smart fallback parser for any unspecified projects
    var s = trimmed;

    // Strip common NHAI / Project preambles
    s = s.replaceFirst(
      RegExp(
        r'^(?:Tolling\s*[,&]?\s*Operation\s*[,&]?\s*Maintenance\s*(?:and|&)?\s*Transfer\s*of\s*|Operation\s*and\s*Maintenance\s*of\s*|Six\s*Laning\s*of\s*|Four\s*Laning\s*of\s*|Development\s*of\s*|Construction\s*of\s*)',
        caseSensitive: false,
      ),
      '',
    );

    // Truncate at chainage or location markers ("from km...", "form KM...", "of NH...", "in the state...")
    final cutRegex = RegExp(
      r'\s+(?:from|form)\s+km|\s+of\s+NH-?|\s+in\s+the\s+state',
      caseSensitive: false,
    );
    final match = cutRegex.firstMatch(s);
    if (match != null) {
      s = s.substring(0, match.start).trim();
    }

    // Clean up variations like "By- Pass" or "By-Pass" -> "Bypass"
    s = s.replaceAll(RegExp(r'By-\s*Pass', caseSensitive: false), 'Bypass');

    // Capitalize "section" -> "Section"
    s = s.replaceAll(RegExp(r'\bsection\b', caseSensitive: false), 'Section');

    // Ensure it ends with "Section"
    if (!s.toLowerCase().endsWith('section')) {
      s = '$s Section';
    }

    return s.trim();
  }

  static String _disambiguate(String raw, String currentDisp) {
    // Try to extract NH highway number (e.g. NH-44, NH-27)
    final nhMatch = RegExp(
      r'NH-[0-9A-Z]+',
      caseSensitive: false,
    ).firstMatch(raw);
    if (nhMatch != null) {
      return '$currentDisp (${nhMatch.group(0)!.toUpperCase()})';
    }

    // Try to extract State (e.g. Rajasthan, Uttar Pradesh, Assam)
    final stateMatch = RegExp(
      r'in\s+the\s+state\s+of\s+([A-Za-z\s]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (stateMatch != null) {
      final stateName = stateMatch.group(1)!.trim();
      return '$currentDisp ($stateName)';
    }

    return currentDisp;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectRecord &&
          other.databaseName == databaseName &&
          other.displayName == displayName;

  @override
  int get hashCode => Object.hash(databaseName, displayName);

  @override
  String toString() => displayName;
}

/// Represents a row from database_Bms.type_of_bridge joined with database_Bms.bridge.
/// [code] is the raw DB value stored in bridge.type_of_bridge (e.g. "MA").
/// [name] is the human-readable label from type_of_bridge.type_of_bridge (e.g. "Major Bridge length above 60m").
class StructureTypeRecord {
  final String code;
  final String name;

  const StructureTypeRecord({required this.code, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StructureTypeRecord && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => name;
}

class Point2D {
  final double x;
  final double y;
  Point2D({required this.x, required this.y});

  factory Point2D.fromJson(Map<String, dynamic> json) {
    return Point2D(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class BoundingBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  /// Parses percentage coordinates (0–100) of the FULL original image.
  /// Returns null when missing/invalid. Never invents a default box.
  static BoundingBox? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);

    double? read(String key) {
      final v = json[key];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim());
      return null;
    }

    var x1 = read('x1');
    var y1 = read('y1');
    var x2 = read('x2');
    var y2 = read('y2');
    if (x1 == null || y1 == null || x2 == null || y2 == null) return null;
    if (![x1, y1, x2, y2].every((v) => v.isFinite)) return null;

    // Reject clearly out-of-range values; only clamp tiny floating-point boundary drift.
    double? clampMinor(double v) {
      if (v >= 0.0 && v <= 100.0) return v;
      if (v > -0.5 && v < 0.0) return 0.0;
      if (v > 100.0 && v < 100.5) return 100.0;
      return null;
    }

    final cx1 = clampMinor(x1);
    final cy1 = clampMinor(y1);
    final cx2 = clampMinor(x2);
    final cy2 = clampMinor(y2);
    if (cx1 == null || cy1 == null || cx2 == null || cy2 == null) return null;

    if (cx2 <= cx1 || cy2 <= cy1) return null;

    return BoundingBox(x1: cx1, y1: cy1, x2: cx2, y2: cy2);
  }

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return tryParse(json) ?? BoundingBox(x1: 0, y1: 0, x2: 0, y2: 0);
  }

  Map<String, dynamic> toJson() => {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2};
}

class DistressIssue {
  final String? elementName;
  final String type;
  final String description;
  final String depth;
  final String? width;
  final String? length;
  final double? area;
  final double? volume;
  final String? quantityUnit;
  final double? quantityValue;

  /// Normalized 0–1 confidence used by existing UI.
  final double confidence;

  /// Percentage box (0–100) of the full source image, or null if unavailable/invalid.
  final BoundingBox? boundingBox;
  final List<Point2D>? segmentationPath;

  DistressIssue({
    this.elementName,
    required this.type,
    required this.description,
    required this.depth,
    this.width,
    this.length,
    this.area,
    this.volume,
    this.quantityUnit,
    this.quantityValue,
    required this.confidence,
    this.boundingBox,
    this.segmentationPath,
  });

  static double _normalizeConfidence(dynamic raw) {
    final v = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '');
    if (v == null || !v.isFinite) return 0.0;
    if (v > 1.0) return (v / 100.0).clamp(0.0, 1.0);
    return v.clamp(0.0, 1.0);
  }

  factory DistressIssue.fromJson(Map<String, dynamic> json) {
    return DistressIssue(
      elementName: json['elementName'] as String?,
      type: json['type'] as String? ?? 'crack',
      description:
          json['description'] as String? ??
          json['recommendation']?.toString() ??
          '',
      depth: json['depth']?.toString() ?? '0.01',
      width: json['width']?.toString(),
      length: json['length']?.toString(),
      area: (json['area'] as num?)?.toDouble(),
      volume: (json['volume'] as num?)?.toDouble(),
      quantityUnit: json['quantityUnit'] as String?,
      quantityValue: (json['quantityValue'] as num?)?.toDouble(),
      confidence: _normalizeConfidence(json['confidence']),
      boundingBox: BoundingBox.tryParse(json['boundingBox']),
      segmentationPath: (json['segmentationPath'] as List<dynamic>?)
          ?.map((p) => Point2D.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'elementName': elementName,
    'type': type,
    'description': description,
    'depth': depth,
    'width': width,
    'length': length,
    'area': area,
    'volume': volume,
    'quantityUnit': quantityUnit,
    'quantityValue': quantityValue,
    'confidence': confidence,
    'boundingBox': boundingBox?.toJson(),
    'segmentationPath': segmentationPath?.map((p) => p.toJson()).toList(),
  };
}

class ImageAnalysis {
  final String summary;
  final List<DistressIssue> issues;
  final List<String> recommendations;

  ImageAnalysis({
    required this.summary,
    required this.issues,
    required this.recommendations,
  });

  factory ImageAnalysis.fromJson(Map<String, dynamic> json) {
    return ImageAnalysis(
      summary: json['summary'] as String? ?? '',
      issues:
          (json['issues'] as List<dynamic>?)
              ?.map((e) => DistressIssue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'issues': issues.map((e) => e.toJson()).toList(),
    'recommendations': recommendations,
  };
}

class ElementFormData {
  String elementName;
  String description;

  /// Subtype labels when a safe DB master exists. Empty for now.
  List<String> elementTypes;

  /// Bearing metadata when schema supports it. Empty for now.
  Map<String, String> bearingMetadata;

  ElementFormData({
    required this.elementName,
    this.description = '',
    List<String>? elementTypes,
    Map<String, String>? bearingMetadata,
  }) : elementTypes = elementTypes ?? <String>[],
       bearingMetadata = bearingMetadata ?? <String, String>{};

  factory ElementFormData.fromJson(Map<String, dynamic> json) {
    return ElementFormData(
      elementName: json['elementName'] as String? ?? '',
      description:
          json['description'] as String? ??
          json['element_descriptions'] as String? ??
          '',
      elementTypes:
          (json['elementTypes'] as List<dynamic>? ??
                  json['element_types'] as List<dynamic>? ??
                  const [])
              .map((e) => e.toString())
              .toList(),
      bearingMetadata: Map<String, String>.from(
        (json['bearingMetadata'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            (json['bearing_metadata'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'elementName': elementName,
    'structural_element': elementName,
    'description': description,
    'element_descriptions': description,
    'elementTypes': elementTypes,
    'element_types': elementTypes,
    'bearingMetadata': bearingMetadata,
    'bearing_metadata': bearingMetadata,
  };
}

class BridgeFormData {
  final String projectName;
  final String chainages;
  final int? bridgeId;
  final int? bridgeInspectionId;
  final String? bridgeNo;
  final String? bridgeSide;
  final String? bridgeType;
  final int? totalNoOfSpan;
  final int? spId;
  final String? spanMaterial;
  final String? spanType;
  final String? spanLength;
  final String distanceX;
  final String distanceY;
  final String span;
  final String typeOfSuperstructure;
  final String? rcPscMembers;
  final String? steelMembers;
  final List<ElementFormData> elements;

  BridgeFormData({
    this.projectName = '',
    required this.chainages,
    this.bridgeId,
    this.bridgeInspectionId,
    this.bridgeNo,
    this.bridgeSide,
    this.bridgeType,
    this.totalNoOfSpan,
    this.spId,
    this.spanMaterial,
    this.spanType,
    this.spanLength,
    this.distanceX = '',
    this.distanceY = '',
    required this.span,
    required this.typeOfSuperstructure,
    this.rcPscMembers,
    this.steelMembers,
    required this.elements,
  });

  factory BridgeFormData.fromJson(Map<String, dynamic> json) {
    return BridgeFormData(
      projectName: json['projectName'] as String? ?? '',
      chainages: json['chainages'] as String? ?? '',
      bridgeId: (json['bridgeId'] as num?)?.toInt(),
      bridgeInspectionId: (json['bridgeInspectionId'] as num?)?.toInt(),
      bridgeNo: json['bridgeNo'] as String?,
      bridgeSide: json['bridgeSide'] as String?,
      bridgeType: json['bridgeType'] as String?,
      totalNoOfSpan: (json['totalNoOfSpan'] as num?)?.toInt(),
      spId: (json['spId'] as num?)?.toInt(),
      spanMaterial: json['spanMaterial'] as String?,
      spanType: json['spanType'] as String?,
      spanLength: json['spanLength'] as String?,
      distanceX: json['distanceX'] as String? ?? '',
      distanceY: json['distanceY'] as String? ?? '',
      span: json['span'] as String? ?? '',
      typeOfSuperstructure: json['typeOfSuperstructure'] as String? ?? '',
      rcPscMembers: json['rcPscMembers'] as String?,
      steelMembers: json['steelMembers'] as String?,
      elements:
          (json['elements'] as List<dynamic>?)
              ?.map((e) => ElementFormData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'projectName': projectName,
    'chainages': chainages,
    'bridgeId': bridgeId,
    'bridgeInspectionId': bridgeInspectionId,
    'bridgeNo': bridgeNo,
    'bridgeSide': bridgeSide,
    'bridgeType': bridgeType,
    'totalNoOfSpan': totalNoOfSpan,
    'spId': spId,
    'spanMaterial': spanMaterial,
    'spanType': spanType,
    'spanLength': spanLength,
    'distanceX': distanceX,
    'distanceY': distanceY,
    'span': span,
    'typeOfSuperstructure': typeOfSuperstructure,
    'rcPscMembers': rcPscMembers,
    'steelMembers': steelMembers,
    'elements': elements.map((e) => e.toJson()).toList(),
  };
}

/// Represents an AI-detected distress record to be persisted into MySQL `database_Bms.bridge_inspection_distress`.
class BridgeInspectionDistressEntry {
  final int bridgeInspectionId;
  final String tableType;
  final String distressType;
  final String? nameOfSpan;
  final String? fieldType;
  final double distressLength;
  final double distressWidth;
  final double distressDepth;
  final int? distressNos;
  final double distanceOfDistressX;
  final double distanceOfDistressY;
  final int abutmentA1;
  final int abutmentA2;
  final int piers;
  final int spans;
  final int foundation;
  final int expansion;
  final int lhsDistress;
  final int rhsDistress;
  final int createdBy;
  final String createdOn;
  final String? repairMethodology;
  final String? images;

  const BridgeInspectionDistressEntry({
    required this.bridgeInspectionId,
    required this.tableType,
    required this.distressType,
    this.nameOfSpan,
    this.fieldType,
    this.distressLength = 0.0,
    this.distressWidth = 0.0,
    this.distressDepth = 0.0,
    this.distressNos,
    this.distanceOfDistressX = 0.0,
    this.distanceOfDistressY = 0.0,
    this.abutmentA1 = 0,
    this.abutmentA2 = 0,
    this.piers = 0,
    this.spans = 0,
    this.foundation = 0,
    this.expansion = 0,
    this.lhsDistress = 0,
    this.rhsDistress = 0,
    required this.createdBy,
    required this.createdOn,
    this.repairMethodology,
    this.images,
  });

  /// Factory helper that maps actual domain model fields into database columns.
  static BridgeInspectionDistressEntry fromIssueAndBridgeData({
    required DistressIssue issue,
    required BridgeFormData bridgeData,
    required int bridgeInspectionId,
    required int createdByUid,
    String? imageIdentifier,
  }) {
    // Derive structural flags from element name
    final elName =
        (issue.elementName ??
                (bridgeData.elements.isNotEmpty
                    ? bridgeData.elements.first.elementName
                    : ''))
            .toLowerCase();

    int isAbutmentA1 = 0;
    int isAbutmentA2 = 0;
    int isPiers = 0;
    int isSpans = 0;
    int isFoundation = 0;
    int isExpansion = 0;

    if (elName.contains('abutment')) {
      if (elName.contains('foundation')) {
        isFoundation = 1;
      } else if (elName.contains('a2')) {
        isAbutmentA2 = 1;
      } else {
        isAbutmentA1 = 1;
      }
    } else if (elName.contains('pier')) {
      if (elName.contains('foundation')) {
        isFoundation = 1;
      } else {
        isPiers = 1;
      }
    } else if (elName.contains('span') ||
        elName.contains('girder') ||
        elName.contains('superstructure')) {
      isSpans = 1;
    } else if (elName.contains('expansion')) {
      isExpansion = 1;
    } else if (elName.contains('foundation')) {
      isFoundation = 1;
    } else {
      isSpans = 1;
    }

    // Derive LHS / RHS distress flags from bridge side metadata
    final side = (bridgeData.bridgeSide ?? '').toUpperCase();
    int lhs = 0;
    int rhs = 0;
    if (side.contains('LHS') || side == 'L') {
      lhs = 1;
    }
    if (side.contains('RHS') || side == 'R') {
      rhs = 1;
    }
    if (lhs == 0 && rhs == 0 && side.contains('BOTH')) {
      lhs = 1;
      rhs = 1;
    }

    // Determine table_type and field_type from element & distress categorization
    String tableType = 'superstructure';
    if (isAbutmentA1 == 1 ||
        isAbutmentA2 == 1 ||
        isPiers == 1 ||
        isFoundation == 1) {
      tableType = 'substructure';
    } else if (elName.contains('approach') || elName.contains('pavement')) {
      tableType = 'approaches';
    }

    final dType = issue.type.toLowerCase();
    String fieldType = 'condition_distress';
    if (dType.contains('crack')) {
      fieldType = 'crack_distress';
    } else if (dType.contains('spall')) {
      fieldType = 'spalling_distress';
    } else if (dType.contains('corros') || dType.contains('steel')) {
      fieldType = 'corrosion_distress';
    } else if (dType.contains('honeycomb')) {
      fieldType = 'honeycombing_distress';
    } else if (dType.contains('efflor')) {
      fieldType = 'efflorescence_distress';
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);

    return BridgeInspectionDistressEntry(
      bridgeInspectionId: bridgeInspectionId,
      tableType: tableType,
      distressType: issue.type,
      nameOfSpan: bridgeData.span.isNotEmpty ? bridgeData.span : null,
      fieldType: fieldType,
      distressLength: double.tryParse(issue.length ?? '') ?? 0.0,
      distressWidth: double.tryParse(issue.width ?? '') ?? 0.0,
      distressDepth: double.tryParse(issue.depth) ?? 0.0,
      distressNos: issue.quantityUnit == 'Nos'
          ? (issue.quantityValue?.toInt() ?? 1)
          : issue.quantityValue?.toInt(),
      distanceOfDistressX: double.tryParse(bridgeData.distanceX) ?? 0.0,
      distanceOfDistressY: double.tryParse(bridgeData.distanceY) ?? 0.0,
      abutmentA1: isAbutmentA1,
      abutmentA2: isAbutmentA2,
      piers: isPiers,
      spans: isSpans,
      foundation: isFoundation,
      expansion: isExpansion,
      lhsDistress: lhs,
      rhsDistress: rhs,
      createdBy: createdByUid,
      createdOn: today,
      repairMethodology: issue.description.isNotEmpty
          ? issue.description
          : null,
      images: imageIdentifier,
    );
  }
}

class BridgeElementResult {
  final String elementName;
  final int conditionRating;
  final String levelOfSeverity;
  final double? distressLength;
  final double? distressWidth;
  final double? distressThickness;
  final int? distressNos;
  final String distressUnit;
  final double distressValue;
  final double? scaffoldingLength;
  final double? scaffoldingWidth;
  final double? scaffoldingHeight;
  final double scaffoldingCum;
  final String suggestedRnR;
  final bool testingRecommendation;

  /// Demo/Excel testing columns: UPV, RHT, HCP, CD, Core, Profoscope, Chemical Test, GPR.
  final Map<String, bool> testingOptions;

  BridgeElementResult({
    required this.elementName,
    required this.conditionRating,
    required this.levelOfSeverity,
    this.distressLength,
    this.distressWidth,
    this.distressThickness,
    this.distressNos,
    required this.distressUnit,
    required this.distressValue,
    this.scaffoldingLength,
    this.scaffoldingWidth,
    this.scaffoldingHeight,
    required this.scaffoldingCum,
    required this.suggestedRnR,
    required this.testingRecommendation,
    Map<String, bool>? testingOptions,
  }) : testingOptions =
           testingOptions ??
           {
             for (final k in const [
               'UPV',
               'RHT',
               'HCP',
               'CD',
               'Core',
               'Profoscope',
               'Chemical Test',
               'GPR',
             ])
               k: false,
           };

  BridgeElementResult copyWith({
    String? elementName,
    int? conditionRating,
    String? levelOfSeverity,
    double? distressLength,
    double? distressWidth,
    double? distressThickness,
    int? distressNos,
    String? distressUnit,
    double? distressValue,
    double? scaffoldingLength,
    double? scaffoldingWidth,
    double? scaffoldingHeight,
    double? scaffoldingCum,
    String? suggestedRnR,
    bool? testingRecommendation,
    Map<String, bool>? testingOptions,
  }) {
    return BridgeElementResult(
      elementName: elementName ?? this.elementName,
      conditionRating: conditionRating ?? this.conditionRating,
      levelOfSeverity: levelOfSeverity ?? this.levelOfSeverity,
      distressLength: distressLength ?? this.distressLength,
      distressWidth: distressWidth ?? this.distressWidth,
      distressThickness: distressThickness ?? this.distressThickness,
      distressNos: distressNos ?? this.distressNos,
      distressUnit: distressUnit ?? this.distressUnit,
      distressValue: distressValue ?? this.distressValue,
      scaffoldingLength: scaffoldingLength ?? this.scaffoldingLength,
      scaffoldingWidth: scaffoldingWidth ?? this.scaffoldingWidth,
      scaffoldingHeight: scaffoldingHeight ?? this.scaffoldingHeight,
      scaffoldingCum: scaffoldingCum ?? this.scaffoldingCum,
      suggestedRnR: suggestedRnR ?? this.suggestedRnR,
      testingRecommendation:
          testingRecommendation ?? this.testingRecommendation,
      testingOptions:
          testingOptions ?? Map<String, bool>.from(this.testingOptions),
    );
  }

  factory BridgeElementResult.fromJson(Map<String, dynamic> json) {
    final defaults = {
      for (final k in const [
        'UPV',
        'RHT',
        'HCP',
        'CD',
        'Core',
        'Profoscope',
        'Chemical Test',
        'GPR',
      ])
        k: false,
    };
    final rawTests = json['testingOptions'];
    if (rawTests is Map) {
      for (final e in rawTests.entries) {
        defaults[e.key.toString()] = e.value == true;
      }
    }

    return BridgeElementResult(
      elementName: json['elementName'] as String? ?? 'Element',
      conditionRating: (json['conditionRating'] as num?)?.toInt() ?? 3,
      levelOfSeverity:
          json['levelOfSeverity'] as String? ?? 'Short-Term Requirement',
      distressLength: (json['distressLength'] as num?)?.toDouble(),
      distressWidth: (json['distressWidth'] as num?)?.toDouble(),
      distressThickness: (json['distressThickness'] as num?)?.toDouble(),
      distressNos: (json['distressNos'] as num?)?.toInt(),
      distressUnit: json['distressUnit'] as String? ?? 'Sqm',
      distressValue: (json['distressValue'] as num?)?.toDouble() ?? 0.0,
      scaffoldingLength: (json['scaffoldingLength'] as num?)?.toDouble(),
      scaffoldingWidth: (json['scaffoldingWidth'] as num?)?.toDouble(),
      scaffoldingHeight: (json['scaffoldingHeight'] as num?)?.toDouble(),
      scaffoldingCum: (json['scaffoldingCum'] as num?)?.toDouble() ?? 0.0,
      suggestedRnR: json['suggestedRnR'] as String? ?? 'None Required',
      testingRecommendation: json['testingRecommendation'] as bool? ?? false,
      testingOptions: defaults,
    );
  }

  Map<String, dynamic> toJson() => {
    'elementName': elementName,
    'conditionRating': conditionRating,
    'levelOfSeverity': levelOfSeverity,
    'distressLength': distressLength,
    'distressWidth': distressWidth,
    'distressThickness': distressThickness,
    'distressNos': distressNos,
    'distressUnit': distressUnit,
    'distressValue': distressValue,
    'scaffoldingLength': scaffoldingLength,
    'scaffoldingWidth': scaffoldingWidth,
    'scaffoldingHeight': scaffoldingHeight,
    'scaffoldingCum': scaffoldingCum,
    'suggestedRnR': suggestedRnR,
    'testingRecommendation': testingRecommendation,
    'testingOptions': testingOptions,
  };
}

class ReportMetrics {
  final int issueCount;
  final double minDepth;
  final double maxDepth;
  final double minWidth;
  final double maxWidth;
  final double totalArea;
  final double totalLength;

  ReportMetrics({
    required this.issueCount,
    required this.minDepth,
    required this.maxDepth,
    required this.minWidth,
    required this.maxWidth,
    required this.totalArea,
    required this.totalLength,
  });

  factory ReportMetrics.fromJson(Map<String, dynamic> json) {
    return ReportMetrics(
      issueCount: (json['issueCount'] as num?)?.toInt() ?? 0,
      minDepth: (json['minDepth'] as num?)?.toDouble() ?? 0.0,
      maxDepth: (json['maxDepth'] as num?)?.toDouble() ?? 0.0,
      minWidth: (json['minWidth'] as num?)?.toDouble() ?? 0.0,
      maxWidth: (json['maxWidth'] as num?)?.toDouble() ?? 0.0,
      totalArea: (json['totalArea'] as num?)?.toDouble() ?? 0.0,
      totalLength: (json['totalLength'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'issueCount': issueCount,
    'minDepth': minDepth,
    'maxDepth': maxDepth,
    'minWidth': minWidth,
    'maxWidth': maxWidth,
    'totalArea': totalArea,
    'totalLength': totalLength,
  };
}

class Report {
  final int id;
  final String title;
  final String description;
  final String? imageBase64;
  final String timestamp;
  final ReportMetrics metrics;
  final String category;
  final String location;
  final List<DistressIssue> issues;
  final List<String> recommendations;
  final BridgeFormData? bridgeData;
  final List<BridgeElementResult>? bridgeResults;

  Report({
    required this.id,
    required this.title,
    required this.description,
    this.imageBase64,
    required this.timestamp,
    required this.metrics,
    required this.category,
    required this.location,
    required this.issues,
    required this.recommendations,
    this.bridgeData,
    this.bridgeResults,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id:
          (json['id'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      title: json['title'] as String? ?? 'Inspection Report',
      description: json['description'] as String? ?? '',
      imageBase64: json['imageBase64'] as String?,
      timestamp:
          json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      metrics: json['metrics'] != null
          ? ReportMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : ReportMetrics(
              issueCount: 0,
              minDepth: 0,
              maxDepth: 0,
              minWidth: 0,
              maxWidth: 0,
              totalArea: 0,
              totalLength: 0,
            ),
      category: json['category'] as String? ?? 'Optimal',
      location: json['location'] as String? ?? 'Site A',
      issues:
          (json['issues'] as List<dynamic>?)
              ?.map((e) => DistressIssue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      bridgeData: json['bridgeData'] != null
          ? BridgeFormData.fromJson(json['bridgeData'] as Map<String, dynamic>)
          : null,
      bridgeResults: (json['bridgeResults'] as List<dynamic>?)
          ?.map((e) => BridgeElementResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageBase64': imageBase64,
    'timestamp': timestamp,
    'metrics': metrics.toJson(),
    'category': category,
    'location': location,
    'issues': issues.map((e) => e.toJson()).toList(),
    'recommendations': recommendations,
    'bridgeData': bridgeData?.toJson(),
    'bridgeResults': bridgeResults?.map((e) => e.toJson()).toList(),
  };
}
