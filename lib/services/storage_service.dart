import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/investment_account.dart';
import '../models/asset.dart';
import '../models/projection_settings.dart';

class StorageService {
  static const String _investmentsKey = 'investments';
  static const String _assetsKey = 'assets';
  static const String _settingsKey = 'projection_settings';

  // Investment Accounts
  Future<void> saveInvestments(List<InvestmentAccount> accounts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = accounts.map((a) => a.toJson()).toList();
      await prefs.setString(_investmentsKey, jsonEncode(json));
    } catch (e) {
      throw Exception('Failed to save investments: $e');
    }
  }

  Future<List<InvestmentAccount>> loadInvestments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_investmentsKey);
      if (jsonString == null) return [];
      final List<dynamic> json = jsonDecode(jsonString);
      return json.map((j) => InvestmentAccount.fromJson(j)).toList();
    } catch (e) {
      throw Exception('Failed to load investments: $e');
    }
  }

  // Assets
  Future<void> saveAssets(List<Asset> assets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = assets.map((a) => a.toJson()).toList();
      await prefs.setString(_assetsKey, jsonEncode(json));
    } catch (e) {
      throw Exception('Failed to save assets: $e');
    }
  }

  Future<List<Asset>> loadAssets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_assetsKey);
      if (jsonString == null) return [];
      final List<dynamic> json = jsonDecode(jsonString);
      return json.map((j) => Asset.fromJson(j)).toList();
    } catch (e) {
      throw Exception('Failed to load assets: $e');
    }
  }

  // Projection Settings
  Future<void> saveSettings(ProjectionSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  Future<ProjectionSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);
      if (jsonString == null) return const ProjectionSettings();
      final json = jsonDecode(jsonString);
      return ProjectionSettings.fromJson(json);
    } catch (e) {
      throw Exception('Failed to load settings: $e');
    }
  }

  // Clear all data (useful for testing or reset)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_investmentsKey);
      await prefs.remove(_assetsKey);
      await prefs.remove(_settingsKey);
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }
}
