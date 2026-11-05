enum FoodCategory { beneficial, neutral, harmful }

class FoodItem {
  final String name;
  final String category;
  final String quandoMangiarlo; // ← NUOVO CAMPO
  final FoodCategory type;

  const FoodItem({
    required this.name,
    required this.category,
    this.quandoMangiarlo = '', // Default vuoto se non compilato
    required this.type,
  });
}

class BloodGroupDiet {
  final String group;
  final String name;
  final String description;
  final String color;
  final List<FoodItem> beneficial;
  final List<FoodItem> neutral;
  final List<FoodItem> harmful;

  const BloodGroupDiet({
    required this.group,
    required this.name,
    required this.description,
    required this.color,
    required this.beneficial,
    required this.neutral,
    required this.harmful,
  });
}