import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MealPlanService {
  // La chiave ora include il gruppo sanguigno
  static String _getKey(String bloodGroup) => 'meal_plan_v3_$bloodGroup';

  static const List<String> mealTypes = ['Colazione', 'Pranzo', 'Cena', 'Merenda'];
  static const List<String> daysOfWeek = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];
  static const String dailyViewKey = 'Oggi';

  // Struttura: Map<Giorno, Map<Pasto, ListaAlimenti>>
  static Future<Map<String, Map<String, List<String>>>> loadMealPlan(String bloodGroup) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_getKey(bloodGroup));
    
    if (jsonString == null) {
      return _createEmptyPlan();
    }
    
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final Map<String, Map<String, List<String>>> plan = {};
      
      decoded.forEach((day, meals) {
        plan[day] = Map<String, List<String>>.from(
          (meals as Map<String, dynamic>).map((meal, foods) => 
            MapEntry(meal, List<String>.from(foods))
          )
        );
      });
      return plan;
    } catch (e) {
      print('Errore nel caricamento del piano: $e');
      return _createEmptyPlan();
    }
  }

  static Map<String, Map<String, List<String>>> _createEmptyPlan() {
    final Map<String, Map<String, List<String>>> emptyPlan = {};
    for (final day in [...daysOfWeek, dailyViewKey]) {
      emptyPlan[day] = {};
      for (final meal in mealTypes) {
        emptyPlan[day]![meal] = [];
      }
    }
    return emptyPlan;
  }

  static Future<void> saveMealPlan(String bloodGroup, Map<String, Map<String, List<String>>> plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getKey(bloodGroup), jsonEncode(plan));
  }

  static Future<void> addFoodToMeal(String bloodGroup, String day, String mealType, String food) async {
    final plan = await loadMealPlan(bloodGroup);
    if (!plan.containsKey(day)) {
      plan[day] = {};
      for (final meal in mealTypes) {
        plan[day]![meal] = [];
      }
    }
    if (!plan[day]!.containsKey(mealType)) {
      plan[day]![mealType] = [];
    }
    if (!plan[day]![mealType]!.contains(food)) {
      plan[day]![mealType]!.add(food);
      await saveMealPlan(bloodGroup, plan);
    }
  }

  static Future<void> removeFoodFromMeal(String bloodGroup, String day, String mealType, String food) async {
    final plan = await loadMealPlan(bloodGroup);
    if (plan.containsKey(day) && plan[day]!.containsKey(mealType)) {
      plan[day]![mealType]!.remove(food);
      await saveMealPlan(bloodGroup, plan);
    }
  }

  static Future<void> clearDay(String bloodGroup, String day) async {
    final plan = await loadMealPlan(bloodGroup);
    if (plan.containsKey(day)) {
      for (final meal in mealTypes) {
        plan[day]![meal] = [];
      }
      await saveMealPlan(bloodGroup, plan);
    }
  }

  static Future<void> clearAll(String bloodGroup) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getKey(bloodGroup));
  }
}