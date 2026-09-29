import 'auth_user.dart';
import '../models/bridge_record.dart';
import '../models/inspection_models.dart';
import '../models/span_arrangement_record.dart';

Future<List<ProjectRecord>> getProjectsImpl() async {
  throw const AuthConnectionException();
}

Future<List<String>> getChainagesForProjectImpl(String projectName) async {
  throw const AuthConnectionException();
}

Future<List<StructureTypeRecord>> getStructureTypesForProjectImpl(
  String projectName,
) async {
  throw const AuthConnectionException();
}

Future<List<String>> getChainagesForProjectAndStructureTypeImpl(
  String projectName,
  String structureTypeCode,
) async {
  throw const AuthConnectionException();
}

Future<List<BridgeRecord>> getBridgesForProjectAndChainageImpl(
  String projectName,
  String chainage,
) async {
  throw const AuthConnectionException();
}

Future<List<BridgeRecord>> getBridgesForProjectStructureTypeAndChainageImpl(
  String projectName,
  String structureTypeCode,
  String chainage,
) async {
  throw const AuthConnectionException();
}

Future<List<SpanArrangementRecord>> getSpanArrangementsForBridgeImpl(int bridgeId) async {
  throw const AuthConnectionException();
}

Future<SuperstructureBridgeInfo?> getSuperstructureBridgeInfoImpl(int bridgeId) async {
  throw const AuthConnectionException();
}

Future<List<String>> getSuperstructureTypeOptionsImpl() async {
  throw const AuthConnectionException();
}
