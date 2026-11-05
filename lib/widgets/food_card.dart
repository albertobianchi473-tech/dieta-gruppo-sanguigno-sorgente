import 'package:flutter/material.dart';
import '../models/blood_group.dart';

class FoodCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onTap;
  final bool hasRecipe;

  const FoodCard({
    super.key,
    required this.food,
    this.onTap,
    this.hasRecipe = false,
  });

  IconData _iconFor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('carne')) return Icons.set_meal;
    if (cat.contains('pesce')) return Icons.set_meal_outlined;
    if (cat.contains('verdura')) return Icons.eco;
    if (cat.contains('frutta')) return Icons.apple;
    if (cat.contains('cereali')) return Icons.grain;
    if (cat.contains('latticini') || cat.contains('uova')) return Icons.egg;
    if (cat.contains('bevande')) return Icons.local_drink;
    if (cat.contains('condimento') || cat.contains('olio')) return Icons.oil_barrel;
    if (cat.contains('legumi')) return Icons.spa_outlined;
    if (cat.contains('secca')) return Icons.nature;
    return Icons.restaurant;
  }

  Color _getColorForType() {
    switch (food.type) {
      case FoodCategory.beneficial: return Colors.green;
      case FoodCategory.neutral: return Colors.lightBlue;
      case FoodCategory.harmful: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getColorForType();
    final borderColor = hasRecipe ? Colors.orange.shade700 : typeColor.withOpacity(0.6);
    final borderWidth = hasRecipe ? 2.5 : 1.0;
    final bgColor = hasRecipe 
        ? typeColor.withOpacity(0.30)
        : typeColor.withOpacity(0.15);

    return InkWell(
      onTap: hasRecipe ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: hasRecipe ? [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(food.category), color: typeColor, size: 18),
            const SizedBox(width: 4),
            Text(
              food.name,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: hasRecipe ? FontWeight.bold : FontWeight.w500,
                fontSize: hasRecipe ? 12.5 : 12,
              ),
            ),
            if (hasRecipe) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.restaurant_menu,
                color: Colors.orange.shade700,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}