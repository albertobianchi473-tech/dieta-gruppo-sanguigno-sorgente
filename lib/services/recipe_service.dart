import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/recipe.dart';

class RecipeService {
  static final RecipeService _instance = RecipeService._internal();
  factory RecipeService() => _instance;
  RecipeService._internal();

  List<Recipe>? _cachedRecipes;

  Future<List<Recipe>> getRecipes() async {
    if (_cachedRecipes != null) return _cachedRecipes!;

    try {
      print('📂 Caricamento ricette da GitHub (JSON)...');
      
      final localPath = await _getLocalFilePath('ricette.json');
      final file = File(localPath);
      
      if (!await file.exists()) {
        print('❌ File ricette.json non trovato in $localPath');
        return [];
      }

      final String jsonString = await file.readAsString();
      final decoded = json.decode(jsonString);
      
      List<dynamic> jsonList;
      if (decoded is List) {
        jsonList = decoded;
      } else if (decoded is Map) {
        print('⚠️ ATTENZIONE: Il file scaricato è un oggetto (Mappa), non una lista!');
        print('👉 Probabilmente l\'URL di download punta alle API GitHub o il file non esiste.');
        print('🔍 Inizio del contenuto scaricato: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}');
        return [];
      } else {
        print('⚠️ Formato JSON non valido.');
        return [];
      }
      
      final List<Recipe> recipes = [];
      
      for (var item in jsonList) {
        final Map<String, dynamic> jsonItem = item as Map<String, dynamic>;
        
        // Helper per gestire le chiavi con o senza spazio finale
        String getVal(String key) {
          return (jsonItem[key] ?? jsonItem['$key '] ?? '').toString().trim();
        }

        recipes.add(Recipe(
          gruppo: getVal('Gruppo'),
          nome: getVal('Nome'),
          tempo: getVal('Tempo'),
          difficolta: getVal('Difficolta'),
          ingredientiDisplay: getVal('Ingredienti_Display'),
          ingredientiMatching: getVal('Ingredienti_Matching')
              .split(RegExp(r'[,;]')) // FIX: divide sia per virgola che per punto e virgola
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          preparazione: getVal('Preparazione'),
        ));
      }

      _cachedRecipes = recipes;
      print('✅ Caricate ${recipes.length} ricette da JSON');
      return recipes;
    } catch (e, stackTrace) {
      print('❌ Errore caricamento JSON: $e');
      print('Stack: $stackTrace');
      return [];
    }
  }

  Future<Set<String>> getFoodsWithRecipes(String group) async {
    final recipes = await getRecipes();
    final Set<String> foodsWithRecipes = {};

    for (final recipe in recipes) {
      if (recipe.gruppo.trim().toUpperCase() != group.trim().toUpperCase()) continue;
      
      for (final ingredient in recipe.ingredientiMatching) {
        foodsWithRecipes.add(ingredient.toLowerCase().trim());
      }
    }

    print('✅ Trovati ${foodsWithRecipes.length} ingredienti unici per gruppo $group');
    return foodsWithRecipes;
  }

  Future<String> _getLocalFilePath(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${appDir.path}/diet_data');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return '${dataDir.path}/$fileName';
  }
}