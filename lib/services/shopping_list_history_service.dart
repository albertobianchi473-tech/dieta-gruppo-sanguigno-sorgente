import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListHistoryService {
  static const String _key = 'saved_shopping_lists_history';

  /// Struttura di una lista spesa salvata
  /// {
  ///   'id': timestamp,
  ///   'date': '2026-11-10 14:30',
  ///   'group': '0',
  ///   'type': 'Giornaliera' o 'Settimanale',
  ///   'items': [ { 'name': 'Pollo', 'count': 2, 'checked': true }, ... ]
  /// }

  /// Carica tutte le liste spese salvate
  static Future<List<Map<String, dynamic>>> loadAllLists() async {
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

  /// Salva una nuova lista spesa nello storico
  static Future<void> saveShoppingList({
    required String group,
    required String type,
    required Map<String, List<MapEntry<String, int>>> groupedItems,
    required Map<String, bool> itemStatus,
  }) async {
    final lists = await loadAllLists();
    
    // Converti la struttura in formato JSON-friendly
    final List<Map<String, dynamic>> items = [];
    groupedItems.forEach((category, entries) {
      for (final entry in entries) {
        items.add({
          'name': entry.key,
          'count': entry.value,
          'checked': itemStatus[entry.key] ?? false,
          'category': category,
        });
      }
    });

    final newList = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'date': _formatDate(DateTime.now()),
      'group': group,
      'type': type,
      'items': items,
    };

    lists.insert(0, newList);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lists));
  }

  /// Elimina una lista spesa dallo storico
  static Future<void> deleteShoppingList(int id) async {
    final lists = await loadAllLists();
    lists.removeWhere((list) => list['id'] == id);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lists));
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