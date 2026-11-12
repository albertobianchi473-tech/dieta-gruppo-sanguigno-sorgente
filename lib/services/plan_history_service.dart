import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlanHistoryService {
  static const String _key = 'saved_plans_history';

  /// Struttura di un piano salvato
  /// {
  ///   'id': timestamp,
  ///   'date': '2026-11-10 14:30',
  ///   'group': '0',
  ///   'type': 'Giornaliero' o 'Settimanale',
  ///   'day': 'Oggi' o 'Lunedì',
  ///   'meals': { 'Colazione': [...], 'Pranzo': [...], ... }
  /// }

  /// Carica tutti i piani salvati
  static Future<List<Map<String, dynamic>>> loadAllPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    
    if (jsonString == null) return [];

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Salva un nuovo piano nello storico
  static Future<void> savePlan({
    required String group,
    required String type,
    required String day,
    required Map<String, List<String>> meals,
  }) async {
    final plans = await loadAllPlans();
    
    final newPlan = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'date': _formatDate(DateTime.now()),
      'group': group,
      'type': type,
      'day': day,
      'meals': meals,
    };

    plans.insert(0, newPlan); // Aggiunge all'inizio (più recente)
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(plans));
  }

  /// Elimina un piano dallo storico
  static Future<void> deletePlan(int id) async {
    final plans = await loadAllPlans();
    plans.removeWhere((plan) => plan['id'] == id);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(plans));
  }

  /// Elimina tutto lo storico
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}