import '../data/diet_data.dart';

class FoodIndexService {
  static final FoodIndexService _instance = FoodIndexService._internal();
  factory FoodIndexService() => _instance;
  FoodIndexService._internal();

  // Mappa: nome normalizzato -> nome originale (per display)
  Map<String, String> _foodIndex = {};

  // Costruisce l'indice da tutti gli alimenti delle diete
  void buildIndex() {
    _foodIndex.clear();
    
    for (final diet in DietData.diets) {
      // Aggiungi tutti gli alimenti (benefici, indifferenti, dannosi)
      final allFoods = [...diet.beneficial, ...diet.neutral, ...diet.harmful];
      
      for (final food in allFoods) {
        final normalized = _normalize(food.name);
        _foodIndex[normalized] = food.name; // Mantieni il nome originale per display
      }
    }
    
    print('✅ Indice alimenti creato: ${_foodIndex.length} alimenti unici');
  }

  // Normalizza il nome: minuscolo, rimuovi spazi extra
  String _normalize(String name) {
    return name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Ottieni il nome normalizzato di un alimento
  String getNormalized(String foodName) {
    return _normalize(foodName);
  }

  // Verifica se un nome di ricetta contiene un alimento
  bool recipeContainsIngredient(String recipeIngredient, String foodName) {
    final normalizedRecipe = _normalize(recipeIngredient);
    final normalizedFood = _normalize(foodName);
    
    // Match esatto o contiene
    return normalizedRecipe == normalizedFood || 
           normalizedRecipe.contains(normalizedFood) ||
           normalizedFood.contains(normalizedRecipe);
  }

  // Trova tutte le ricette che contengono un alimento
  List<String> findRecipesForFood(String foodName, List<Map<String, dynamic>> allRecipes) {
    final normalizedFood = _normalize(foodName);
    
    return allRecipes.where((recipe) {
      final ingredients = recipe['ingredientiMatching'] as List<String>;
      return ingredients.any((ing) => recipeContainsIngredient(ing, foodName));
    }).map((r) => r['nome'] as String).toList();
  }
}