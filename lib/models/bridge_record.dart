/// Inventory row from database_Bms.bridge (read-only selection).
class BridgeRecord {
  final int bridgeId;
  final String projectName;
  final String chainage;
  final String? bridgeNo;
  final String? bridgeSide;
  final String? latitude;
  final String? longitude;
  final int? totalNoOfSpan;
  final String? typeOfBridge;
  final String? structuralForm;
  final String? materialOfConstruction;
  final String? widthOfBridge;
  final String? lengthOfBridge;
  final String? heightOfBridge;

  const BridgeRecord({
    required this.bridgeId,
    required this.projectName,
    required this.chainage,
    this.bridgeNo,
    this.bridgeSide,
    this.latitude,
    this.longitude,
    this.totalNoOfSpan,
    this.typeOfBridge,
    this.structuralForm,
    this.materialOfConstruction,
    this.widthOfBridge,
    this.lengthOfBridge,
    this.heightOfBridge,
  });

  String get displayLabel {
    final no = (bridgeNo ?? '').trim();
    final side = (bridgeSide ?? '').trim();
    final parts = <String>[];
    if (no.isNotEmpty) parts.add('Bridge $no');
    if (side.isNotEmpty) parts.add(side);
    parts.add('ID $bridgeId');
    return parts.join(' · ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BridgeRecord && other.bridgeId == bridgeId;

  @override
  int get hashCode => bridgeId.hashCode;

  Map<String, dynamic> toJson() => {
    'bridgeId': bridgeId,
    'projectName': projectName,
    'chainage': chainage,
    'bridgeNo': bridgeNo,
    'bridgeSide': bridgeSide,
    'latitude': latitude,
    'longitude': longitude,
    'totalNoOfSpan': totalNoOfSpan,
    'typeOfBridge': typeOfBridge,
    'structuralForm': structuralForm,
    'materialOfConstruction': materialOfConstruction,
    'widthOfBridge': widthOfBridge,
    'lengthOfBridge': lengthOfBridge,
    'heightOfBridge': heightOfBridge,
  };

  factory BridgeRecord.fromJson(Map<String, dynamic> json) {
    return BridgeRecord(
      bridgeId: (json['bridgeId'] as num?)?.toInt() ?? 0,
      projectName: json['projectName'] as String? ?? '',
      chainage: json['chainage'] as String? ?? '',
      bridgeNo: json['bridgeNo'] as String?,
      bridgeSide: json['bridgeSide'] as String?,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      totalNoOfSpan: (json['totalNoOfSpan'] as num?)?.toInt(),
      typeOfBridge: json['typeOfBridge'] as String?,
      structuralForm: json['structuralForm'] as String?,
      materialOfConstruction: json['materialOfConstruction'] as String?,
      widthOfBridge: json['widthOfBridge']?.toString(),
      lengthOfBridge: json['lengthOfBridge']?.toString(),
      heightOfBridge: json['heightOfBridge']?.toString(),
    );
  }
}
