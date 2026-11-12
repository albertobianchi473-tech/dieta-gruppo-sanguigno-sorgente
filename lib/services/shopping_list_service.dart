import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListService {
  static String _getStatusKey(String bloodGroup, String planType) => 
      'shopping_list_status_${bloodGroup}_$planType';
  
  static String _getExtraKey(String bloodGroup, String planType) => 
      'shopping_list_extras_${bloodGroup}_$planType';

  /// Carica lo stato delle checkbox (spunte)
  static Future<Map<String, bool>> loadStatus(String bloodGroup, String planType) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_getStatusKey(bloodGroup, planType));
    if (jsonString == null) return {};
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as bool));
    } catch (e) { return {}; }
  }

  /// Aggiorna lo stato di una spunta
  static Future<void> toggleItemStatus(String bloodGroup, String planType, String itemName, bool isChecked) async {
    final prefs = await SharedPreferences.getInstance();
    final currentStatus = await loadStatus(bloodGroup, planType);
    currentStatus[itemName] = isChecked;
    await prefs.setString(_getStatusKey(bloodGroup, planType), jsonEncode(currentStatus));
  }

  /// Resetta la lista (spunte e ingredienti extra)
  static Future<void> resetStatus(String bloodGroup, String planType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getStatusKey(bloodGroup, planType));
    await prefs.remove(_getExtraKey(bloodGroup, planType));
  }

  // ✅ NUOVE FUNZIONI PER GLI INGREDIENTI DELLE RICETTE
  
  /// Aggiunge ingredienti extra (da ricette) evitando duplicati
  static Future<void> addExtraIngredients(String bloodGroup, String planType, List<String> ingredients) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getExtraKey(bloodGroup, planType);
    final current = await loadExtraIngredients(bloodGroup, planType);
    
    for (var ing in ingredients) {
      final trimmed = ing.trim();
      if (trimmed.isNotEmpty && !current.contains(trimmed)) {
        current.add(trimmed);
      }
    }
    await prefs.setString(key, jsonEncode(current));
  }

  /// Carica la lista degli ingredienti extra
  static Future<List<String>> loadExtraIngredients(String bloodGroup, String planType) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_getExtraKey(bloodGroup, planType));
    if (jsonString == null) return [];
    try {
      return List<String>.from(jsonDecode(jsonString));
    } catch (e) { return []; }
  }
}