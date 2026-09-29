import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mysql_client/mysql_client.dart';

import '../config/database_config.dart';
import '../models/bridge_record.dart';
import '../models/inspection_models.dart';
import '../models/span_arrangement_record.dart';
import 'auth_user.dart';

void _debugBridgeDiag(String stage, Object error, {String? queryName}) {
  if (!kDebugMode) return;
  // Never log password or full credentials.
  debugPrint(
    '[BRIDGE_DB_DIAG] stage=$stage '
    '${queryName != null ? 'query=$queryName ' : ''}'
    'type=${error.runtimeType} '
    'message=$error '
    'host=${DatabaseConfig.host} '
    'port=${DatabaseConfig.port} '
    'user=${DatabaseConfig.user} '
    'db=${DatabaseConfig.name} '
    'secure=${DatabaseConfig.secure} '
    'passwordLength=${DatabaseConfig.password.length}',
  );
}

Future<T> _withConnection<T>(
  String queryName,
  Future<T> Function(MySQLConnection conn) action,
) async {
  if (!DatabaseConfig.isConfigured) {
    _debugBridgeDiag(
      'configCheck',
      const AuthConnectionException(),
      queryName: queryName,
    );
    throw const AuthConnectionException();
  }

  MySQLConnection? conn;
  var stage = 'createConnection';
  try {
    if (kDebugMode) {
      debugPrint(
        '[BRIDGE_DB_DIAG] starting query=$queryName '
        'host=${DatabaseConfig.host} '
        'port=${DatabaseConfig.port} '
        'user=${DatabaseConfig.user} '
        'db=${DatabaseConfig.name} '
        'secure=${DatabaseConfig.secure} '
        'configured=${DatabaseConfig.isConfigured} '
        'passwordLength=${DatabaseConfig.password.length}',
      );
    }

    conn = await MySQLConnection.createConnection(
      host: DatabaseConfig.host,
      port: DatabaseConfig.port,
      userName: DatabaseConfig.user,
      password: DatabaseConfig.password,
      databaseName: DatabaseConfig.name,
      secure: DatabaseConfig.secure,
    );

    stage = 'connect';
    await conn.connect(timeoutMs: 10000);

    stage = 'execute:$queryName';
    return await action(conn).timeout(const Duration(seconds: 20));
  } on AuthConnectionException catch (e) {
    _debugBridgeDiag(stage, e, queryName: queryName);
    rethrow;
  } on TimeoutException catch (e) {
    _debugBridgeDiag(stage, e, queryName: queryName);
    throw const AuthConnectionException();
  } catch (e) {
    _debugBridgeDiag(stage, e, queryName: queryName);
    throw const AuthConnectionException();
  } finally {
    if (conn != null) {
      try {
        await conn.close();
      } catch (_) {}
    }
  }
}

String? _col(dynamic row, String name) {
  final value = row.colByName(name) as String?;
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Future<List<ProjectRecord>> getProjectsImpl() {
  return _withConnection('getProjects', (conn) async {
    // Table name must match MySQL on Railway (case-sensitive): database_Bms.bridge
    final result = await conn.execute('''
SELECT DISTINCT project_name
FROM database_Bms.bridge
WHERE project_name IS NOT NULL
  AND TRIM(project_name) <> ''
ORDER BY project_name
''');

    final rawProjects = <String>[];
    final seen = <String>{};
    for (final row in result.rows) {
      final name = _col(row, 'project_name');
      if (name == null) continue;
      if (seen.add(name)) {
        rawProjects.add(name);
      }
    }
    return ProjectRecord.fromDatabaseProjects(rawProjects);
  });
}

Future<List<String>> getChainagesForProjectImpl(String projectName) {
  return _withConnection('getChainagesForProject', (conn) async {
    final result = await conn.execute(
      '''
SELECT DISTINCT chainage
FROM database_Bms.bridge
WHERE project_name = :projectName
  AND chainage IS NOT NULL
  AND TRIM(chainage) <> ''
ORDER BY chainage
''',
      {'projectName': projectName},
    );

    final chainages = <String>[];
    final seen = <String>{};
    for (final row in result.rows) {
      final value = _col(row, 'chainage');
      if (value == null) continue;
      if (seen.add(value)) {
        chainages.add(value);
      }
    }
    return chainages;
  });
}

/// Returns distinct structure types (code + human-readable name) that actually
/// exist for the given project, by joining bridge with type_of_bridge master.
Future<List<StructureTypeRecord>> getStructureTypesForProjectImpl(
  String projectName,
) {
  return _withConnection('getStructureTypesForProject', (conn) async {
    final result = await conn.execute(
      '''
SELECT DISTINCT
    b.type_of_bridge AS type_code,
    t.type_of_bridge AS type_name
FROM database_Bms.bridge b
JOIN database_Bms.type_of_bridge t
    ON t.type_of_bridge_code = b.type_of_bridge
WHERE b.project_name = :projectName
  AND b.type_of_bridge IS NOT NULL
  AND TRIM(b.type_of_bridge) <> ''
ORDER BY t.type_of_bridge
''',
      {'projectName': projectName},
    );

    final types = <StructureTypeRecord>[];
    final seen = <String>{};
    for (final row in result.rows) {
      final code = _col(row, 'type_code');
      final name = _col(row, 'type_name');
      if (code == null || name == null) continue;
      if (seen.add(code)) {
        types.add(StructureTypeRecord(code: code, name: name));
      }
    }
    return types;
  });
}

/// Returns chainages filtered by project AND structure type code.
Future<List<String>> getChainagesForProjectAndStructureTypeImpl(
  String projectName,
  String structureTypeCode,
) {
  return _withConnection('getChainagesForProjectAndStructureType', (conn) async {
    final result = await conn.execute(
      '''
SELECT DISTINCT chainage
FROM database_Bms.bridge
WHERE project_name = :projectName
  AND type_of_bridge = :structureTypeCode
  AND chainage IS NOT NULL
  AND TRIM(chainage) <> ''
ORDER BY chainage
''',
      {
        'projectName': projectName,
        'structureTypeCode': structureTypeCode,
      },
    );

    final chainages = <String>[];
    final seen = <String>{};
    for (final row in result.rows) {
      final value = _col(row, 'chainage');
      if (value == null) continue;
      if (seen.add(value)) {
        chainages.add(value);
      }
    }
    return chainages;
  });
}

Future<List<BridgeRecord>> getBridgesForProjectAndChainageImpl(
  String projectName,
  String chainage,
) {
  return _withConnection('getBridgesForProjectAndChainage', (conn) async {
    final result = await conn.execute(
      '''
SELECT
    bridge_id,
    project_name,
    chainage,
    bridge_no,
    bridge_side,
    latitude,
    longitude,
    total_no_of_span,
    type_of_bridge,
    structural_form,
    material_of_construction,
    width_of_bridge,
    length_of_bridge,
    height_of_bridge
FROM database_Bms.bridge
WHERE project_name = :projectName
  AND chainage = :chainage
ORDER BY bridge_id
''',
      {
        'projectName': projectName,
        'chainage': chainage,
      },
    );

    return result.rows.map((row) {
      return BridgeRecord(
        bridgeId: int.tryParse(row.colByName('bridge_id') ?? '') ?? 0,
        projectName: _col(row, 'project_name') ?? projectName,
        chainage: _col(row, 'chainage') ?? chainage,
        bridgeNo: _col(row, 'bridge_no'),
        bridgeSide: _col(row, 'bridge_side'),
        latitude: _col(row, 'latitude'),
        longitude: _col(row, 'longitude'),
        totalNoOfSpan: int.tryParse(row.colByName('total_no_of_span') ?? ''),
        typeOfBridge: _col(row, 'type_of_bridge'),
        structuralForm: _col(row, 'structural_form'),
        materialOfConstruction: _col(row, 'material_of_construction'),
        widthOfBridge: _col(row, 'width_of_bridge'),
        lengthOfBridge: _col(row, 'length_of_bridge'),
        heightOfBridge: _col(row, 'height_of_bridge'),
      );
    }).where((b) => b.bridgeId > 0).toList();
  });
}

/// Returns bridges filtered by project, structure type code, AND chainage.
Future<List<BridgeRecord>> getBridgesForProjectStructureTypeAndChainageImpl(
  String projectName,
  String structureTypeCode,
  String chainage,
) {
  return _withConnection('getBridgesForProjectStructureTypeAndChainage', (conn) async {
    final result = await conn.execute(
      '''
SELECT
    bridge_id,
    project_name,
    chainage,
    bridge_no,
    bridge_side,
    latitude,
    longitude,
    total_no_of_span,
    type_of_bridge,
    structural_form,
    material_of_construction,
    width_of_bridge,
    length_of_bridge,
    height_of_bridge
FROM database_Bms.bridge
WHERE project_name = :projectName
  AND type_of_bridge = :structureTypeCode
  AND chainage = :chainage
ORDER BY bridge_id
''',
      {
        'projectName': projectName,
        'structureTypeCode': structureTypeCode,
        'chainage': chainage,
      },
    );

    return result.rows.map((row) {
      return BridgeRecord(
        bridgeId: int.tryParse(row.colByName('bridge_id') ?? '') ?? 0,
        projectName: _col(row, 'project_name') ?? projectName,
        chainage: _col(row, 'chainage') ?? chainage,
        bridgeNo: _col(row, 'bridge_no'),
        bridgeSide: _col(row, 'bridge_side'),
        latitude: _col(row, 'latitude'),
        longitude: _col(row, 'longitude'),
        totalNoOfSpan: int.tryParse(row.colByName('total_no_of_span') ?? ''),
        typeOfBridge: _col(row, 'type_of_bridge'),
        structuralForm: _col(row, 'structural_form'),
        materialOfConstruction: _col(row, 'material_of_construction'),
        widthOfBridge: _col(row, 'width_of_bridge'),
        lengthOfBridge: _col(row, 'length_of_bridge'),
        heightOfBridge: _col(row, 'height_of_bridge'),
      );
    }).where((b) => b.bridgeId > 0).toList();
  });
}

Future<List<SpanArrangementRecord>> getSpanArrangementsForBridgeImpl(int bridgeId) {
  return _withConnection('getSpanArrangementsForBridge', (conn) async {
    final result = await conn.execute(
      '''
SELECT
    sp_id,
    bridge_id,
    span_material,
    span_type,
    span_length
FROM database_Bms.sapn_arrangment
WHERE bridge_id = :bridgeId
ORDER BY sp_id
''',
      {'bridgeId': bridgeId},
    );

    var index = 1;
    return result.rows.map((row) {
      final record = SpanArrangementRecord(
        spId: int.tryParse(row.colByName('sp_id') ?? '') ?? 0,
        bridgeId: int.tryParse(row.colByName('bridge_id') ?? '') ?? bridgeId,
        spanMaterial: _col(row, 'span_material'),
        spanType: _col(row, 'span_type'),
        spanLength: _col(row, 'span_length'),
        displayIndex: index,
      );
      index++;
      return record;
    }).where((s) => s.spId > 0).toList();
  });
}

Future<SuperstructureBridgeInfo?> getSuperstructureBridgeInfoImpl(int bridgeId) {
  return _withConnection('getSuperstructureBridgeInfo', (conn) async {
    final result = await conn.execute(
      '''
SELECT
    superstructure_bridge_id,
    bridge_id,
    reinforced_concrete_and_prestressed_concrete_members,
    check_steel_members,
    status
FROM database_Bms.superstructure_bridge
WHERE bridge_id = :bridgeId
ORDER BY superstructure_bridge_id DESC
LIMIT 1
''',
      {'bridgeId': bridgeId},
    );

    if (result.numOfRows < 1) return null;
    final row = result.rows.first;
    return SuperstructureBridgeInfo(
      superstructureBridgeId:
          int.tryParse(row.colByName('superstructure_bridge_id') ?? ''),
      bridgeId: int.tryParse(row.colByName('bridge_id') ?? '') ?? bridgeId,
      reinforcedConcreteAndPrestressedConcreteMembers:
          _col(row, 'reinforced_concrete_and_prestressed_concrete_members'),
      checkSteelMembers: _col(row, 'check_steel_members'),
      status: _col(row, 'status'),
    );
  });
}

/// Master dropdown options from distinct meaningful superstructure combinations.
/// Excludes obvious seed/test rows (values beginning with seed_).
/// NOTE: database_Bms.superstructure is keyed by bridge_inspection_id, not bridge_id,
/// so these are master options, not bridge-specific stored values.
Future<List<String>> getSuperstructureTypeOptionsImpl() {
  return _withConnection('getSuperstructureTypeOptions', (conn) async {
    final result = await conn.execute('''
SELECT DISTINCT
    type_of_span,
    structural_system,
    type_of_material
FROM database_Bms.superstructure
WHERE type_of_span IS NOT NULL
  AND TRIM(type_of_span) <> ''
  AND LOWER(TRIM(type_of_span)) NOT LIKE 'seed\\_%'
  AND (structural_system IS NULL OR LOWER(TRIM(structural_system)) NOT LIKE 'seed\\_%')
  AND (type_of_material IS NULL OR LOWER(TRIM(type_of_material)) NOT LIKE 'seed\\_%')
ORDER BY type_of_span, structural_system, type_of_material
''');

    final options = <String>[];
    final seen = <String>{};
    for (final row in result.rows) {
      final typeOfSpan = _col(row, 'type_of_span');
      if (typeOfSpan == null) continue;
      if (typeOfSpan.toLowerCase().startsWith('seed_')) continue;

      final structural = _col(row, 'structural_system');
      final material = _col(row, 'type_of_material');
      if (structural != null && structural.toLowerCase().startsWith('seed_')) continue;
      if (material != null && material.toLowerCase().startsWith('seed_')) continue;

      final parts = <String>[typeOfSpan];
      if (structural != null) parts.add(structural);
      if (material != null) parts.add(material);
      final label = parts.join(' / ');
      if (seen.add(label)) {
        options.add(label);
      }
    }
    return options;
  });
}
