import 'package:flutter/material.dart';
import '../data/diet_data.dart';
import '../models/blood_group.dart';
import '../services/favorites_service.dart';

class FavoritesScreen extends StatefulWidget {
  final String? initialGroup;
  const FavoritesScreen({super.key, this.initialGroup});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _selectedGroup = '0';
  Map<String, List<FoodItem>> _favoritesByCategory = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.initialGroup ?? '0';
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      await DietData.initialize();
      
      // ✅ CORRETTO: Usa getFavorites
      final favorites = await FavoritesService.getFavorites(_selectedGroup);
      final diet = DietData.getByGroup(_selectedGroup);
      final allFoods = [...diet.beneficial, ...diet.neutral, ...diet.harmful];

      final Map<String, List<FoodItem>> grouped = {};
      for (final favName in favorites) {
        try {
          final food = allFoods.firstWhere((f) => f.name == favName);
          final category = food.category.isNotEmpty &&
                  food.category.toLowerCase() != 'altro'
              ? food.category
              : 'Altro';
          if (!grouped.containsKey(category)) grouped[category] = [];
          grouped[category]!.add(food);
        } catch (e) {
          // Alimento non trovato, lo rimuoviamo dai preferiti
          await FavoritesService.toggleFavorite(_selectedGroup, favName);
        }
      }

      if (mounted) {
        setState(() {
          _favoritesByCategory = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(FoodItem food) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina preferito'),
        content: Text('Vuoi rimuovere "${food.name}" dai preferiti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // ✅ CORRETTO: Usa toggleFavorite per rimuovere
      await FavoritesService.toggleFavorite(_selectedGroup, food.name);
      _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${food.name}" rimosso dai preferiti')),
        );
      }
    }
  }

  void _changeGroup(String group) {
    if (_selectedGroup == group) return;
    setState(() {
      _selectedGroup = group;
      _isLoading = true;
    });
    _loadFavorites();
  }

  Color _getGroupColor(String group) {
    switch (group) {
      case '0': return const Color(0xFFE53935);
      case 'A': return const Color(0xFF43A047);
      case 'B': return const Color(0xFF1E88E5);
      case 'AB': return const Color(0xFF8E24AA);
      default: return Colors.grey;
    }
  }

  Color _getColorForFood(FoodItem food) {
    switch (food.type) {
      case FoodCategory.beneficial: return const Color(0xFF43A047);
      case FoodCategory.neutral: return const Color(0xFFFFA000);
      case FoodCategory.harmful: return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }

  IconData _getIconForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('carne')) return Icons.set_meal;
    if (cat.contains('pesce') || cat.contains('crostacei') || cat.contains('molluschi')) return Icons.set_meal;
    if (cat.contains('verdura') || cat.contains('ortaggi')) return Icons.eco;
    if (cat.contains('frutta')) return Icons.apple;
    if (cat.contains('latticini') || cat.contains('formaggi') || cat.contains('yogurt')) return Icons.icecream;
    if (cat.contains('cereali') || cat.contains('pane') || cat.contains('pasta') || cat.contains('riso')) return Icons.bakery_dining;
    if (cat.contains('bevande') || cat.contains('succhi') || cat.contains('tè') || cat.contains('caffè') || cat.contains('acqua')) return Icons.local_drink;
    if (cat.contains('olio') || cat.contains('grassi') || cat.contains('burro')) return Icons.water_drop;
    if (cat.contains('dolci') || cat.contains('zuccheri') || cat.contains('miele')) return Icons.cake;
    if (cat.contains('legumi') || cat.contains('fagioli') || cat.contains('lenticchie') || cat.contains('ceci')) return Icons.grain;
    if (cat.contains('frutta secca') || cat.contains('noci') || cat.contains('mandorle')) return Icons.eco;
    if (cat.contains('spezie') || cat.contains('erbe') || cat.contains('aromi')) return Icons.local_florist;
    if (cat.contains('uova')) return Icons.egg;
    return Icons.restaurant;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I miei Preferiti'),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Selettore gruppo sanguigno
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['0', 'A', 'B', 'AB'].map((group) {
                final isSelected = _selectedGroup == group;
                final color = _getGroupColor(group);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _changeGroup(group),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color, width: isSelected ? 2 : 1),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Text(
                          'Gruppo $group',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Lista preferiti
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _favoritesByCategory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite_border, color: Colors.grey.shade400, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'Nessun preferito',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Tieni premuto su un alimento nella dieta per aggiungerlo ai preferiti',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favoritesByCategory.keys.length,
                        itemBuilder: (context, index) {
                          final category = _favoritesByCategory.keys.elementAt(index);
                          final foods = _favoritesByCategory[category]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53935),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        category.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE53935),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53935).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${foods.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE53935),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: foods.map((food) {
                                    final foodColor = _getColorForFood(food);
                                    final categoryIcon = _getIconForCategory(food.category);

                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: foodColor.withOpacity(0.15),
                                        child: Icon(categoryIcon, color: foodColor, size: 20),
                                      ),
                                      title: Text(
                                        food.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Text(
                                        food.type == FoodCategory.beneficial
                                            ? '✅ Benefico'
                                            : food.type == FoodCategory.neutral
                                                ? '⚠️ Indifferente'
                                                : '❌ Da evitare',
                                        style: TextStyle(
                                          color: foodColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      // ✅ NUOVO: Long press per eliminare (nessun cestino visibile)
                                      onLongPress: () => _removeFavorite(food),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}