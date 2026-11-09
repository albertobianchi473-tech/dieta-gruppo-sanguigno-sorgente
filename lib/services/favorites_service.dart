import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  // Cambiamo la chiave per evitare conflitti con i vecchi dati globali
  static const String _key = 'favorites_by_group_v2';

  /// Carica l'intera mappa dei preferiti
  static Future<Map<String, List<String>>> _loadAllFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    
    if (jsonString == null) {
      return {'0': [], 'A': [], 'B': [], 'AB': []};
    }

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((key, value) => 
        MapEntry(key, List<String>.from(value))
      );
    } catch (e) {
      // Se c'è un errore di parsing, restituisci una mappa vuota inizializzata
      return {'0': [], 'A': [], 'B': [], 'AB': []};
    }
  }

  /// Salva l'intera mappa dei preferiti
  static Future<void> _saveAllFavorites(Map<String, List<String>> allFavorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(allFavorites));
  }

  /// Carica la lista dei preferiti per un gruppo specifico
  static Future<List<String>> getFavorites(String bloodGroup) async {
    final allFavorites = await _loadAllFavorites();
    // Se il gruppo non esiste nella mappa, restituisci una lista vuota
    return allFavorites[bloodGroup] ?? [];
  }

  /// Aggiunge o rimuove un alimento dai preferiti di un gruppo specifico
  static Future<void> toggleFavorite(String bloodGroup, String itemName) async {
    final allFavorites = await _loadAllFavorites();
    
    // Assicurati che la lista per questo gruppo esista
    if (!allFavorites.containsKey(bloodGroup)) {
      allFavorites[bloodGroup] = [];
    }

    String cleanName = itemName.trim();
    List<String> groupFavorites = allFavorites[bloodGroup]!;

    if (groupFavorites.contains(cleanName)) {
      groupFavorites.remove(cleanName); // Se c'è già, lo rimuove
    } else {
      groupFavorites.add(cleanName); // Se non c'è, lo aggiunge
    }
    
    await _saveAllFavorites(allFavorites);
  }

  /// Controlla se un alimento è nei preferiti di un gruppo specifico
  static Future<bool> isFavorite(String bloodGroup, String itemName) async {
    final groupFavorites = await getFavorites(bloodGroup);
    return groupFavorites.contains(itemName.trim());
  }
}