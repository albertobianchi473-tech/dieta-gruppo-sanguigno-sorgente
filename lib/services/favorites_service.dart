import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorite_foods_list';

  // Carica la lista dei preferiti
  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  // Aggiunge o rimuove un alimento dai preferiti (toggle)
  static Future<void> toggleFavorite(String foodName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];
    
    // .trim() rimuove gli spazi finali per evitare duplicati
    String cleanName = foodName.trim();

    if (favorites.contains(cleanName)) {
      favorites.remove(cleanName);
    } else {
      favorites.add(cleanName);
    }
    
    await prefs.setStringList(_key, favorites);
  }

  // Controlla se un alimento è già nei preferiti
  static Future<bool> isFavorite(String foodName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];
    return favorites.contains(foodName.trim());
  }
}