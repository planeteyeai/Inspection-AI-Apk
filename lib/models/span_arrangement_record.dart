/// Row from database_Bms.sapn_arrangment (read-only).
class SpanArrangementRecord {
  final int spId;
  final int bridgeId;
  final String? spanMaterial;
  final String? spanType;
  final String? spanLength;
  final int displayIndex;

  const SpanArrangementRecord({
    required this.spId,
    required this.bridgeId,
    this.spanMaterial,
    this.spanType,
    this.spanLength,
    required this.displayIndex,
  });

  String get label {
    final parts = <String>['Span $displayIndex'];
    final type = (spanType ?? '').trim();
    final material = (spanMaterial ?? '').trim();
    final length = (spanLength ?? '').trim();
    if (type.isNotEmpty) parts.add(type);
    if (material.isNotEmpty) parts.add(material);
    if (length.isNotEmpty) parts.add(length);
    return parts.join(' · ');
  }

  String get shortLabel => 'Span $displayIndex';

  /// Suggested Type of Superstructure text from this span's DB values.
  String? get suggestedSuperstructureLabel {
    final type = (spanType ?? '').trim();
    final material = (spanMaterial ?? '').trim();
    if (type.isEmpty && material.isEmpty) return null;
    if (type.isEmpty) return material;
    if (material.isEmpty) return type;
    return '$type / $material';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpanArrangementRecord && other.spId == spId;

  @override
  int get hashCode => spId.hashCode;
}

/// Bridge-linked flags from database_Bms.superstructure_bridge.
class SuperstructureBridgeInfo {
  final int? superstructureBridgeId;
  final int bridgeId;
  final String? reinforcedConcreteAndPrestressedConcreteMembers;
  final String? checkSteelMembers;
  final String? status;

  const SuperstructureBridgeInfo({
    this.superstructureBridgeId,
    required this.bridgeId,
    this.reinforcedConcreteAndPrestressedConcreteMembers,
    this.checkSteelMembers,
    this.status,
  });
}
