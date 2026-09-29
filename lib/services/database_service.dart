import 'package:flutter/foundation.dart';

import '../config/database_config.dart';
import '../models/bridge_record.dart';
import '../models/inspection_models.dart';
import '../models/span_arrangement_record.dart';
import 'auth_user.dart';
import 'mysql_auth_query_stub.dart'
    if (dart.library.io) 'mysql_auth_query_io.dart'
    as mysql_auth;
import 'mysql_bridge_query_stub.dart'
    if (dart.library.io) 'mysql_bridge_query_io.dart'
    as mysql_bridge;

export 'auth_user.dart';

/// Centralized MySQL access. All methods are SELECT-only.
class DatabaseService {
  DatabaseService._();

  static void _ensureConfigured() {
    if (!DatabaseConfig.isConfigured) {
      if (kDebugMode) {
        debugPrint(
          '[AUTH_DIAG] stage=configCheck '
          'type=AuthConnectionException '
          'message=DatabaseConfig.isConfigured=false '
          '(fill lib/config/database_config_local.dart password OR pass --dart-define flags) '
          'host=${DatabaseConfig.host} '
          'port=${DatabaseConfig.port} '
          'user=${DatabaseConfig.user} '
          'db=${DatabaseConfig.name} '
          'secure=${DatabaseConfig.secure} '
          'passwordLength=${DatabaseConfig.password.length} '
          'passwordLooksQuoted=${DatabaseConfig.password.startsWith('"') || DatabaseConfig.password.endsWith('"')}',
        );
      }
      throw const AuthConnectionException();
    }
  }

  static Future<ActiveUserRecord?> findActiveUser(String username) {
    _ensureConfigured();
    return mysql_auth.findActiveUserImpl(username);
  }

  static Future<List<ProjectRecord>> getProjects() {
    _ensureConfigured();
    return mysql_bridge.getProjectsImpl();
  }

  static Future<List<String>> getChainagesForProject(String projectName) {
    _ensureConfigured();
    return mysql_bridge.getChainagesForProjectImpl(projectName);
  }

  static Future<List<StructureTypeRecord>> getStructureTypesForProject(
    String projectName,
  ) {
    _ensureConfigured();
    return mysql_bridge.getStructureTypesForProjectImpl(projectName);
  }

  static Future<List<String>> getChainagesForProjectAndStructureType(
    String projectName,
    String structureTypeCode,
  ) {
    _ensureConfigured();
    return mysql_bridge.getChainagesForProjectAndStructureTypeImpl(
      projectName,
      structureTypeCode,
    );
  }

  static Future<List<BridgeRecord>>
  getBridgesForProjectStructureTypeAndChainage(
    String projectName,
    String structureTypeCode,
    String chainage,
  ) {
    _ensureConfigured();
    return mysql_bridge.getBridgesForProjectStructureTypeAndChainageImpl(
      projectName,
      structureTypeCode,
      chainage,
    );
  }

  static Future<List<BridgeRecord>> getBridgesForProjectAndChainage(
    String projectName,
    String chainage,
  ) {
    _ensureConfigured();
    return mysql_bridge.getBridgesForProjectAndChainageImpl(
      projectName,
      chainage,
    );
  }

  static Future<List<SpanArrangementRecord>> getSpanArrangementsForBridge(
    int bridgeId,
  ) {
    _ensureConfigured();
    return mysql_bridge.getSpanArrangementsForBridgeImpl(bridgeId);
  }

  static Future<SuperstructureBridgeInfo?> getSuperstructureBridgeInfo(
    int bridgeId,
  ) {
    _ensureConfigured();
    return mysql_bridge.getSuperstructureBridgeInfoImpl(bridgeId);
  }

  static Future<List<String>> getSuperstructureTypeOptions() {
    _ensureConfigured();
    return mysql_bridge.getSuperstructureTypeOptionsImpl();
  }

  static Future<int?> getLatestBridgeInspectionId(int bridgeId) {
    _ensureConfigured();
    return mysql_bridge.getLatestBridgeInspectionIdImpl(bridgeId);
  }

  static Future<bool> insertBridgeInspectionDistress(
    List<BridgeInspectionDistressEntry> entries,
  ) {
    _ensureConfigured();
    return mysql_bridge.insertBridgeInspectionDistressImpl(entries);
  }
}
