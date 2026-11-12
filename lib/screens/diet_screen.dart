import 'package:flutter/material.dart';
import '../models/blood_group.dart';
import '../models/recipe.dart';
import '../services/favorites_service.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_screen.dart';
import 'rimedi_screen.dart';

class DietScreen extends StatefulWidget {
  final BloodGroupDiet diet;
  const DietScreen({super.key, required this.diet});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> with TickerProviderStateMixin {
  late TabController _tabController; // Alimenti / Rimedi / Preferiti
  late TabController _foodTabController; // Benefici / Indifferenti / Da Evitare
  Set<String> _favoriteNames = {};

  List<Recipe> _allRecipes = [];
  Map<String, List<String>> _foodRecipesMap = {};
  bool _recipesLoaded = false;

  String _selectedMealFilter = 'Tutti';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color _colorBeneficial = Color(0xFF43A047);
  static const Color _colorNeutral = Color(0xFFFFA000);
  static const Color _colorHarmful = Color(0xFFE53935);
  static const Color _colorRecipe = Color(0xFFFF6D00);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _foodTabController = TabController(length: 3, vsync: this);
    _loadFavorites();
    _loadRecipes();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _foodTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favs = await FavoritesService.getFavorites(widget.diet.group);
    if (mounted) {
      setState(() {
        _favoriteNames = favs.toSet();
      });
    }
  }

  Future<void> _loadRecipes() async {
    try {
      final recipeService = RecipeService();
      _allRecipes = await recipeService.getRecipes();

      // Normalizza il gruppo: gestisce "O" (lettera) e "0" (numero)
      final target = widget.diet.group.trim().toUpperCase();
      final groupRecipes = _allRecipes.where((r) {
        final g = r.gruppo.trim().toUpperCase();
        return g == target || (g == 'O' && target == '0');
      }).toList();

      final allFoods = [
        ...widget.diet.beneficial,
        ...widget.diet.neutral,
        ...widget.diet.harmful,
      ];

      for (final food in allFoods) {
        final foodNameLower = food.name.toLowerCase().trim();
        final Set<String> matchingRecipes = {};

        for (final recipe in groupRecipes) {
          final hasIngredient = recipe.ingredientiMatching.any((ing) {
            final ingLower = ing.toLowerCase().trim();
            return ingLower == foodNameLower ||
                ingLower.contains(foodNameLower) ||
                foodNameLower.contains(ingLower);
          });
          if (hasIngredient) matchingRecipes.add(recipe.nome);
        }

        if (matchingRecipes.isNotEmpty) {
          _foodRecipesMap[food.name] = matchingRecipes.toList();
        }
      }

      if (mounted) setState(() => _recipesLoaded = true);
    } catch (e) {
      print('Errore caricamento ricette: $e');
      if (mounted) setState(() => _recipesLoaded = true);
    }
  }

  Future<void> _toggleFavorite(FoodItem food) async {
    await FavoritesService.toggleFavorite(widget.diet.group, food.name);
    await _loadFavorites();

    if (mounted) {
      final isNowFav = _favoriteNames.contains(food.name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNowFav
              ? '❤️ Aggiunto ai preferiti del Gruppo ${widget.diet.group}'
              : 'Rimosso dai preferiti'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _confirmRemoveFavorite(FoodItem food) async {
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
      await _toggleFavorite(food);
    }
  }

  void _onFoodTap(FoodItem food) {
    final recipes = _foodRecipesMap[food.name];
    if (recipes != null && recipes.isNotEmpty) {
      _showRecipeDialog(food.name, recipes);
    }
  }

  void _showRecipeDialog(String foodName, List<String> recipeNames) {
    final uniqueRecipeNames = recipeNames.toSet().toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.restaurant_menu, color: _colorRecipe),
            const SizedBox(width: 8),
            Expanded(child: Text('Ricette con $foodName')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: uniqueRecipeNames.length,
            itemBuilder: (context, index) {
              final recipeName = uniqueRecipeNames[index];
              final recipe = _allRecipes.firstWhere(
                (r) => r.nome == recipeName,
                orElse: () => Recipe(
                  gruppo: '',
                  nome: recipeName,
                  tempo: '',
                  difficolta: '',
                  ingredientiDisplay: '',
                  ingredientiMatching: [],
                  preparazione: '',
                ),
              );
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _colorRecipe.withOpacity(0.2),
                  child: Icon(Icons.restaurant, color: _colorRecipe),
                ),
                title: Text(recipe.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: (recipe.difficolta.isNotEmpty ||
                        recipe.tempo.isNotEmpty)
                    ? Text('⏱️ ${recipe.tempo}  •  📊 ${recipe.difficolta}')
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailScreen(recipe: recipe),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Color _getColorForFood(FoodItem food) {
    switch (food.type) {
      case FoodCategory.beneficial:
        return _colorBeneficial;
      case FoodCategory.neutral:
        return _colorNeutral;
      case FoodCategory.harmful:
        return _colorHarmful;
      default:
        return Colors.grey;
    }
  }

  String _typeLabel(FoodItem food) {
    switch (food.type) {
      case FoodCategory.beneficial:
        return '✅ Benefico';
      case FoodCategory.neutral:
        return '⚠️ Indifferente';
      case FoodCategory.harmful:
        return '❌ Da evitare';
      default:
        return '';
    }
  }

  IconData _getIconForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('carne')) return Icons.set_meal;
    if (cat.contains('pesce') ||
        cat.contains('crostacei') ||
        cat.contains('molluschi')) return Icons.set_meal;
    if (cat.contains('verdura') || cat.contains('ortaggi')) return Icons.eco;
    if (cat.contains('frutta')) return Icons.apple;
    if (cat.contains('latticini') ||
        cat.contains('formaggi') ||
        cat.contains('yogurt')) return Icons.icecream;
    if (cat.contains('cereali') ||
        cat.contains('pane') ||
        cat.contains('pasta') ||
        cat.contains('riso')) return Icons.bakery_dining;
    if (cat.contains('bevande') ||
        cat.contains('succhi') ||
        cat.contains('tè') ||
        cat.contains('caffè') ||
        cat.contains('acqua')) return Icons.local_drink;
    if (cat.contains('olio') ||
        cat.contains('grassi') ||
        cat.contains('burro')) return Icons.water_drop;
    if (cat.contains('dolci') ||
        cat.contains('zuccheri') ||
        cat.contains('miele')) return Icons.cake;
    if (cat.contains('legumi') ||
        cat.contains('fagioli') ||
        cat.contains('lenticchie') ||
        cat.contains('ceci')) return Icons.grain;
    if (cat.contains('frutta secca') ||
        cat.contains('noci') ||
        cat.contains('mandorle')) return Icons.eco;
    if (cat.contains('spezie') ||
        cat.contains('erbe') ||
        cat.contains('aromi')) return Icons.local_florist;
    if (cat.contains('uova')) return Icons.egg;
    return Icons.restaurant;
  }

  List<FoodItem> _getFilteredFoods(List<FoodItem> foods) {
    return foods.where((food) {
      if (_searchQuery.isNotEmpty &&
          !food.name.toLowerCase().contains(_searchQuery) &&
          !food.category.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      if (_selectedMealFilter != 'Tutti') {
        final quando = food.quandoMangiarlo.toLowerCase();
        final keyword = _selectedMealFilter.toLowerCase();
        return quando.contains(keyword) || quando.isEmpty;
      }
      return true;
    }).toList();
  }

  Map<String, List<FoodItem>> _groupedByCategory(List<FoodItem> foods) {
    final Map<String, List<FoodItem>> grouped = {};
    for (final food in foods) {
      final category =
          food.category.isNotEmpty && food.category.toLowerCase() != 'altro'
              ? food.category
              : 'Altro';
      if (!grouped.containsKey(category)) grouped[category] = [];
      grouped[category]!.add(food);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xFF${widget.diet.color.substring(1)}'));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Gruppo ${widget.diet.group} - ${widget.diet.name}'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Alimenti'),
            Tab(icon: Icon(Icons.eco), text: 'Rimedi'),
            Tab(icon: Icon(Icons.favorite), text: 'Preferiti'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlimentiTab(color),
          RimediScreen(group: widget.diet.group),
          _buildPreferitiTab(color),
        ],
      ),
    );
  }

  // ================= TAB ALIMENTI =================
  Widget _buildAlimentiTab(Color themeColor) {
    return Column(
      children: [
        // Filtri pasto
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.white,
          child: SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children:
                  ['Tutti', 'Colazione', 'Pranzo', 'Cena', 'Merenda'].map(
                (filter) {
                  final isSelected = _selectedMealFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedMealFilter = filter);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeColor.withOpacity(0.15)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? themeColor
                                : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Icon(Icons.check, color: themeColor, size: 16),
                            if (isSelected) const SizedBox(width: 4),
                            Text(
                              filter,
                              style: TextStyle(
                                color:
                                    isSelected ? themeColor : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ),

        // Barra di ricerca
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade600, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cerca un alimento...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab interne: Benefici / Indifferenti / Da Evitare
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _foodTabController,
            labelColor: themeColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: themeColor,
            tabs: const [
              Tab(text: 'Benefici'),
              Tab(text: 'Indifferenti'),
              Tab(text: 'Da Evitare'),
            ],
          ),
        ),

        // Liste alimenti
        Expanded(
          child: TabBarView(
            controller: _foodTabController,
            children: [
              _buildFoodList(widget.diet.beneficial, themeColor),
              _buildFoodList(widget.diet.neutral, themeColor),
              _buildFoodList(widget.diet.harmful, themeColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoodList(List<FoodItem> foods, Color themeColor) {
    final filteredFoods = _getFilteredFoods(foods);
    final groupedFoods = _groupedByCategory(filteredFoods);

    if (!_recipesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (groupedFoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 12),
            Text(
              'Nessun alimento trovato',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedFoods.keys.length,
      itemBuilder: (context, index) {
        final catName = groupedFoods.keys.elementAt(index);
        final catFoods = groupedFoods[catName]!;
        final categoryIcon = _getIconForCategory(catName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      catName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${catFoods.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: catFoods.map((food) {
                final isFavorite = _favoriteNames.contains(food.name);
                final foodColor = _getColorForFood(food);
                final hasRecipe = _foodRecipesMap.containsKey(food.name);
                final hasQuando = food.quandoMangiarlo.isNotEmpty;

                final borderColor =
                    hasRecipe ? _colorRecipe : foodColor.withOpacity(0.6);
                final borderWidth = hasRecipe ? 3.0 : 1.0;
                final bgColor = hasRecipe
                    ? _colorRecipe.withOpacity(0.08)
                    : foodColor.withOpacity(0.1);

                return GestureDetector(
                  onTap: () => _onFoodTap(food),
                  onLongPress: () => _toggleFavorite(food),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: borderWidth),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: hasRecipe
                          ? [
                              BoxShadow(
                                color: _colorRecipe.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon, color: foodColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                        if (hasQuando) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.restaurant, color: _colorNeutral, size: 14),
                        ],
                        if (hasRecipe) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.menu_book, color: _colorRecipe, size: 14),
                        ],
                        if (isFavorite) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.favorite,
                              color: Colors.redAccent, size: 16),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ================= TAB PREFERITI =================
  Widget _buildPreferitiTab(Color themeColor) {
    final allFoods = [
      ...widget.diet.beneficial,
      ...widget.diet.neutral,
      ...widget.diet.harmful,
    ];
    final favFoods =
        allFoods.where((f) => _favoriteNames.contains(f.name)).toList();

    if (favFoods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, color: Colors.grey.shade400, size: 64),
              const SizedBox(height: 16),
              Text(
                'Nessun preferito per il Gruppo ${widget.diet.group}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tieni premuto su un alimento nella tab Alimenti per aggiungerlo ai preferiti.',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final grouped = _groupedByCategory(favFoods);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final catName = grouped.keys.elementAt(index);
        final catFoods = grouped[catName]!;

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
                      color: themeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      catName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${catFoods.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: catFoods.map((food) {
                  final foodColor = _getColorForFood(food);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: foodColor.withOpacity(0.15),
                      child: Icon(_getIconForCategory(food.category),
                          color: foodColor, size: 20),
                    ),
                    title: Text(
                      food.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      _typeLabel(food),
                      style: TextStyle(
                          color: foodColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    trailing:
                        const Icon(Icons.favorite, color: Colors.redAccent),
                    onLongPress: () => _confirmRemoveFavorite(food),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}