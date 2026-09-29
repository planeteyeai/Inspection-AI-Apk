import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inspection_models.dart';

class StorageService {
  static const String _reportsKey = 'thermal_ai_reports_v1';
  static const String _locationKey = 'thermal_ai_last_gps';

  static Future<List<Report>> getAllReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_reportsKey) ?? [];
      return rawList.map((jsonStr) => Report.fromJson(jsonDecode(jsonStr))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveReport(Report report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reports = await getAllReports();
      final existingIndex = reports.indexWhere((r) => r.id == report.id);
      if (existingIndex >= 0) {
        reports[existingIndex] = report;
      } else {
        reports.insert(0, report);
      }
      final jsonList = reports.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_reportsKey, jsonList);
    } catch (e) {
      // ignore
    }
  }

  static Future<void> clearAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportsKey);
  }

  static Future<void> deleteReport(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getAllReports();
    reports.removeWhere((r) => r.id == id);
    final jsonList = reports.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_reportsKey, jsonList);
  }

  static Future<void> saveLocation(String loc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationKey, loc);
  }

  static Future<String?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_locationKey);
  }
}