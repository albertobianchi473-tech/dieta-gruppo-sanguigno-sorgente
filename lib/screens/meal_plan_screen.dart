import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/diet_data.dart';
import '../models/blood_group.dart';
import '../models/recipe.dart';
import '../services/meal_plan_service.dart';
import '../services/plan_history_service.dart';
import '../services/recipe_service.dart';
import '../services/shopping_list_service.dart';
import 'plan_history_screen.dart';
import 'recipe_detail_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  bool _isWeekly = false;
  String _selectedDay = MealPlanService.dailyViewKey;
  String _selectedGroup = '0';
  Map<String, Map<String, List<String>>> _mealPlan = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initGroupAndLoad();
  }

  Future<void> _initGroupAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGroup = prefs.getString('bloodGroup');
    if (savedGroup != null) _selectedGroup = savedGroup;
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { await DietData.initialize(); } catch (_) {}
    _mealPlan = await MealPlanService.loadMealPlan(_selectedGroup);
    if (!_mealPlan.containsKey(_selectedDay)) {
      _mealPlan[_selectedDay] = {};
      for (var meal in MealPlanService.mealTypes) {
        _mealPlan[_selectedDay]![meal] = [];
      }
    }
    setState(() => _isLoading = false);
  }

  void _toggleViewMode(bool isWeekly) {
    setState(() {
      _isWeekly = isWeekly;
      _selectedDay = isWeekly ? MealPlanService.daysOfWeek[0] : MealPlanService.dailyViewKey;
    });
  }

  void _changeDay(String day) { setState(() => _selectedDay = day); }

  Future<void> _changeGroup(String group) async {
    if (_selectedGroup == group) return;
    setState(() { _selectedGroup = group; _isLoading = true; });
    await _loadData();
  }

  Future<void> _openFoodSelector(String mealType) async {
    final allFoods = _getAllFoodsForGroup(_selectedGroup);
    if (allFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nessun alimento disponibile per il Gruppo $_selectedGroup.')));
      return;
    }
    await showDialog(
      context: context,
      builder: (context) => _FoodSelectionDialog(
        mealType: mealType,
        availableFoods: allFoods,
        currentFoods: _mealPlan[_selectedDay]![mealType] ?? [],
        selectedGroup: _selectedGroup,
        selectedDay: _selectedDay,
        onFoodsSelected: (selectedFoods) async {
          for (var foodName in selectedFoods) {
            await MealPlanService.addFoodToMeal(_selectedGroup, _selectedDay, mealType, foodName);
          }
          await _loadData();
        },
        onRecipeAdded: () async { await _loadData(); },
      ),
    );
  }

  List<FoodItem> _getAllFoodsForGroup(String group) {
    try {
      final diet = DietData.getByGroup(group);
      return [...diet.beneficial, ...diet.neutral, ...diet.harmful];
    } catch (e) { return []; }
  }

  Future<void> _clearCurrentDay() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Svuota piano'),
        content: Text('Eliminare tutti gli alimenti per ${_isWeekly ? _selectedDay : "oggi"} del Gruppo $_selectedGroup?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
        ],
      ),
    );
    if (confirm == true) {
      await MealPlanService.clearDay(_selectedGroup, _selectedDay);
      await _loadData();
    }
  }

  String _generatePlanText() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('🍽️ PIANO ALIMENTARE - Gruppo $_selectedGroup');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    if (_isWeekly) {
      for (final day in MealPlanService.daysOfWeek) {
        if (!_mealPlan.containsKey(day)) continue;
        bool hasMeals = false;
        for (final meal in MealPlanService.mealTypes) {
          if (_mealPlan[day]![meal] != null && _mealPlan[day]![meal]!.isNotEmpty) { hasMeals = true; break; }
        }
        if (!hasMeals) continue;
        buffer.writeln('📅 $day\n──────────────────────────────');
        for (final meal in MealPlanService.mealTypes) {
          final foods = _mealPlan[day]![meal] ?? [];
          if (foods.isNotEmpty) {
            buffer.writeln('  $meal:');
            for (final food in foods) { buffer.writeln('    • $food'); }
            buffer.writeln('');
          }
        }
      }
    } else {
      buffer.writeln('📅 Oggi ($_selectedDay)\n──────────────────────────────\n');
      for (final meal in MealPlanService.mealTypes) {
        final foods = _mealPlan[_selectedDay]![meal] ?? [];
        if (foods.isNotEmpty) {
          buffer.writeln('$meal:');
          for (final food in foods) { buffer.writeln('  • $food'); }
          buffer.writeln('');
        }
      }
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Generato con "Dieta Gruppo Sanguigno"');
    return buffer.toString();
  }

  Future<void> _sharePlan() async {
    final planText = _generatePlanText();
    if (planText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Il piano è vuoto.')));
      return;
    }
    await Share.share(planText, subject: 'Piano Alimentare - Gruppo $_selectedGroup');
  }

  Future<void> _savePlan() async {
    bool hasFoods = false;
    if (_isWeekly) {
      for (final day in MealPlanService.daysOfWeek) {
        if (_mealPlan.containsKey(day)) {
          for (final meal in MealPlanService.mealTypes) {
            if (_mealPlan[day]![meal] != null && _mealPlan[day]![meal]!.isNotEmpty) { hasFoods = true; break; }
          }
        }
        if (hasFoods) break;
      }
    } else {
      for (final meal in MealPlanService.mealTypes) {
        if (_mealPlan[_selectedDay]![meal] != null && _mealPlan[_selectedDay]![meal]!.isNotEmpty) { hasFoods = true; break; }
      }
    }
    if (!hasFoods) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Il piano è vuoto.')));
      return;
    }
    await PlanHistoryService.savePlan(group: _selectedGroup, type: _isWeekly ? 'Settimanale' : 'Giornaliero', day: _selectedDay, meals: _mealPlan[_selectedDay] ?? {});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Piano salvato nello storico!')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Il Mio Piano Alimentare'),
        actions: [
          IconButton(icon: const Icon(Icons.history), tooltip: 'Storico', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlanHistoryScreen(bloodGroup: _selectedGroup)))),
          IconButton(icon: const Icon(Icons.save), tooltip: 'Salva', onPressed: _savePlan),
          IconButton(icon: const Icon(Icons.share), tooltip: 'Condividi', onPressed: _sharePlan),
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Svuota', onPressed: _clearCurrentDay),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Gruppo Sanguigno:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['0', 'A', 'B', 'AB'].map((group) {
                final isSelected = _selectedGroup == group;
                final color = _getGroupColor(group);
                return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: GestureDetector(
                  onTap: () => _changeGroup(group),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isSelected ? color : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: color, width: isSelected ? 2 : 1), boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : []),
                    child: Text('Gruppo $group', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 14))),
                )));
              }).toList()),
            ]),
          ),
          Container(padding: const EdgeInsets.all(16), color: Colors.grey.shade100, child: SegmentedButton<bool>(
            segments: const [ButtonSegment<bool>(value: false, label: Text('Giornaliero'), icon: Icon(Icons.today)), ButtonSegment<bool>(value: true, label: Text('Settimanale'), icon: Icon(Icons.calendar_month))],
            selected: {_isWeekly}, onSelectionChanged: (Set<bool> newSelection) => _toggleViewMode(newSelection.first),
          )),
          if (_isWeekly) SizedBox(height: 50, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: MealPlanService.daysOfWeek.length, itemBuilder: (context, index) {
            final day = MealPlanService.daysOfWeek[index];
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), child: FilterChip(label: Text(day), selected: _selectedDay == day, onSelected: (selected) => _changeDay(day), backgroundColor: Colors.white, selectedColor: const Color(0xFFE53935).withOpacity(0.2), checkmarkColor: const Color(0xFFE53935)));
          })),
          Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: MealPlanService.mealTypes.length, itemBuilder: (context, index) {
            final mealType = MealPlanService.mealTypes[index];
            final foods = _mealPlan[_selectedDay]![mealType] ?? [];
            return Card(margin: const EdgeInsets.only(bottom: 16), elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ListTile(leading: Icon(_getMealIcon(mealType), color: const Color(0xFFE53935), size: 28), title: Text(mealType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), subtitle: Text('${foods.length} alimenti selezionati'), trailing: IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF43A047), size: 32), onPressed: () => _openFoodSelector(mealType))),
              if (foods.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 8, runSpacing: 8, children: foods.map((food) => Chip(label: Text(food), onDeleted: () async { await MealPlanService.removeFoodFromMeal(_selectedGroup, _selectedDay, mealType, food); await _loadData(); }, backgroundColor: const Color(0xFFE53935).withOpacity(0.1), side: const BorderSide(color: Color(0xFFE53935), width: 0.5))).toList()))
              else const Padding(padding: EdgeInsets.all(16), child: Text('Nessun alimento. Clicca sul + per aggiungere.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
            ]));
          })),
        ],
      ),
    );
  }

  Color _getGroupColor(String group) {
    switch (group) { case '0': return const Color(0xFFE53935); case 'A': return const Color(0xFF43A047); case 'B': return const Color(0xFF1E88E5); case 'AB': return const Color(0xFF8E24AA); default: return Colors.grey; }
  }
  IconData _getMealIcon(String mealType) {
    switch (mealType) { case 'Colazione': return Icons.coffee; case 'Pranzo': return Icons.lunch_dining; case 'Cena': return Icons.dinner_dining; case 'Merenda': return Icons.cookie; default: return Icons.restaurant; }
  }
}

// =========================================================================
// DIALOGO DI SELEZIONE ALIMENTI CON 3 TAB
// =========================================================================
class _FoodSelectionDialog extends StatefulWidget {
  final String mealType;
  final List<FoodItem> availableFoods;
  final List<String> currentFoods;
  final String selectedGroup;
  final String selectedDay;
  final Function(List<String>) onFoodsSelected;
  final Function() onRecipeAdded;

  const _FoodSelectionDialog({
    required this.mealType, required this.availableFoods, required this.currentFoods,
    required this.selectedGroup, required this.selectedDay, required this.onFoodsSelected, required this.onRecipeAdded,
  });

  @override
  State<_FoodSelectionDialog> createState() => _FoodSelectionDialogState();
}

class _FoodSelectionDialogState extends State<_FoodSelectionDialog> {
  late Set<String> _selectedFoods;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMealFilter = 'Tutti';
  bool _filterByMeal = true;
  int _selectedTab = 0; // 0=Benefici, 1=Indifferenti, 2=Da Evitare

  List<Recipe> _allRecipes = [];
  Map<String, List<String>> _foodRecipesMap = {};
  bool _recipesLoaded = false;

  static const Color _colorBeneficial = Color(0xFF43A047);
  static const Color _colorNeutral = Color(0xFFFFA000);
  static const Color _colorHarmful = Color(0xFFE53935);
  static const Color _colorRecipe = Color(0xFFFF6D00);

  @override
  void initState() {
    super.initState();
    _selectedFoods = widget.currentFoods.toSet();
    _searchController.addListener(() { setState(() => _searchQuery = _searchController.text.toLowerCase()); });
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final recipeService = RecipeService();
      _allRecipes = await recipeService.getRecipes();
      final groupRecipes = _allRecipes.where((r) {
        final recipeGroup = r.gruppo.trim().toUpperCase();
        final targetGroup = widget.selectedGroup.trim().toUpperCase();
        return recipeGroup == targetGroup || (recipeGroup == 'O' && targetGroup == '0');
      }).toList();
      for (final food in widget.availableFoods) {
        final foodNameLower = food.name.toLowerCase().trim();
        final Set<String> matchingRecipes = {};
        for (final recipe in groupRecipes) {
          final hasIngredient = recipe.ingredientiMatching.any((ing) {
            final ingLower = ing.toLowerCase().trim();
            return ingLower == foodNameLower || ingLower.contains(foodNameLower) || foodNameLower.contains(ingLower);
          });
          if (hasIngredient) matchingRecipes.add(recipe.nome);
        }
        if (matchingRecipes.isNotEmpty) _foodRecipesMap[food.name] = matchingRecipes.toList();
      }
      if (mounted) setState(() => _recipesLoaded = true);
    } catch (e) {
      print('Errore caricamento ricette: $e');
      if (mounted) setState(() => _recipesLoaded = true);
    }
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  List<FoodItem> _getFilteredFoods() {
    return widget.availableFoods.where((food) {
      bool matchesTab = false;
      if (_selectedTab == 0 && food.type == FoodCategory.beneficial) matchesTab = true;
      if (_selectedTab == 1 && food.type == FoodCategory.neutral) matchesTab = true;
      if (_selectedTab == 2 && food.type == FoodCategory.harmful) matchesTab = true;
      if (!matchesTab) return false;
      if (_searchQuery.isNotEmpty && !food.name.toLowerCase().contains(_searchQuery) && !food.category.toLowerCase().contains(_searchQuery)) return false;
      if (_filterByMeal) {
        final quando = food.quandoMangiarlo.toLowerCase();
        return quando.contains(widget.mealType.toLowerCase()) || quando.isEmpty;
      }
      return true;
    }).toList();
  }

  Map<String, List<FoodItem>> _groupedByCategory(List<FoodItem> foods) {
    final Map<String, List<FoodItem>> grouped = {};
    for (final food in foods) {
      final category = food.category.isNotEmpty && food.category.toLowerCase() != 'altro' ? food.category : 'Altro';
      if (!grouped.containsKey(category)) grouped[category] = [];
      grouped[category]!.add(food);
    }
    return grouped;
  }

  void _addToPlan(FoodItem food) {
    setState(() {
      if (_selectedFoods.contains(food.name)) _selectedFoods.remove(food.name);
      else _selectedFoods.add(food.name);
    });
  }

  void _onFoodTap(FoodItem food) {
    final recipes = _foodRecipesMap[food.name];
    if (recipes != null && recipes.isNotEmpty) _showRecipeDialog(food.name, recipes);
    else _addToPlan(food);
  }

  void _showRecipeDialog(String foodName, List<String> recipeNames) {
    final uniqueRecipeNames = recipeNames.toSet().toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Icon(Icons.restaurant_menu, color: _colorRecipe), const SizedBox(width: 8), Expanded(child: Text('Ricette con $foodName'))]),
        content: SizedBox(width: double.maxFinite, child: ListView.builder(shrinkWrap: true, itemCount: uniqueRecipeNames.length, itemBuilder: (context, index) {
          final recipeName = uniqueRecipeNames[index];
          final recipe = _allRecipes.firstWhere((r) => r.nome == recipeName, orElse: () => Recipe(gruppo: '', nome: recipeName, tempo: '', difficolta: '', ingredientiDisplay: '', ingredientiMatching: [], preparazione: ''));
          return ListTile(
            leading: CircleAvatar(backgroundColor: _colorRecipe.withOpacity(0.2), child: Icon(Icons.restaurant, color: _colorRecipe)),
            title: Text(recipe.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: (recipe.difficolta.isNotEmpty || recipe.tempo.isNotEmpty) ? Text('⏱️ ${recipe.tempo} • 📊 ${recipe.difficolta}') : null,
            trailing: const Icon(Icons.touch_app, color: Colors.grey, size: 20),
            onLongPress: () async {
              Navigator.pop(context);
              await MealPlanService.addFoodToMeal(widget.selectedGroup, widget.selectedDay, widget.mealType, recipe.nome);
              await ShoppingListService.addExtraIngredients(widget.selectedGroup, 'Oggi', recipe.ingredientiMatching);
              widget.onRecipeAdded();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('✅ Ricetta aggiunta al piano!', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('🛒 ${recipe.ingredientiMatching.length} ingredienti aggiunti alla lista spesa.', style: TextStyle(fontSize: 12)),
                ]), duration: const Duration(seconds: 3), backgroundColor: const Color(0xFF43A047)));
              }
            },
            onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe))); },
          );
        })),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi'))],
      ),
    );
  }

  Color _getColorForFood(FoodItem food) {
    switch (food.type) { case FoodCategory.beneficial: return _colorBeneficial; case FoodCategory.neutral: return _colorNeutral; case FoodCategory.harmful: return _colorHarmful; default: return Colors.grey; }
  }

  Color _getTabColor(int tabIndex) {
    if (tabIndex == 0) return _colorBeneficial;
    if (tabIndex == 1) return _colorNeutral;
    return _colorHarmful;
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
    final filteredFoods = _getFilteredFoods();
    final groupedFoods = _groupedByCategory(filteredFoods);
    final tabColor = _getTabColor(_selectedTab);

    return Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Container(constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750), padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [const Icon(Icons.restaurant_menu, color: Color(0xFFE53935), size: 24), const SizedBox(width: 8), Expanded(child: Text('Aggiungi a ${widget.mealType}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints())]),
      const Divider(height: 20),
      // TAB Benefici / Indifferenti / Da Evitare
      Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Row(children: [
        Expanded(child: GestureDetector(onTap: () => setState(() => _selectedTab = 0), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: _selectedTab == 0 ? _colorBeneficial : Colors.transparent, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle, size: 16, color: Colors.white), const SizedBox(width: 4), Text('Benefici', style: TextStyle(color: _selectedTab == 0 ? Colors.white : _colorBeneficial, fontWeight: FontWeight.bold, fontSize: 13))])))),
        Expanded(child: GestureDetector(onTap: () => setState(() => _selectedTab = 1), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: _selectedTab == 1 ? _colorNeutral : Colors.transparent), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.remove_circle, size: 16, color: Colors.white), const SizedBox(width: 4), Text('Indifferenti', style: TextStyle(color: _selectedTab == 1 ? Colors.white : _colorNeutral, fontWeight: FontWeight.bold, fontSize: 13))])))),
        Expanded(child: GestureDetector(onTap: () => setState(() => _selectedTab = 2), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: _selectedTab == 2 ? _colorHarmful : Colors.transparent, borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.cancel, size: 16, color: Colors.white), const SizedBox(width: 4), Text('Da Evitare', style: TextStyle(color: _selectedTab == 2 ? Colors.white : _colorHarmful, fontWeight: FontWeight.bold, fontSize: 13))])))),
      ])),
      const SizedBox(height: 12),
      SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: ['Tutti', 'Colazione', 'Pranzo', 'Cena', 'Merenda'].map((filter) {
        final isSelected = _selectedMealFilter == filter;
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: GestureDetector(onTap: () { setState(() { _selectedMealFilter = filter; _filterByMeal = filter != 'Tutti'; }); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isSelected ? tabColor.withOpacity(0.15) : Colors.white, border: Border.all(color: isSelected ? tabColor : Colors.grey.shade300, width: isSelected ? 1.5 : 1), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [if (isSelected) Icon(Icons.check, color: tabColor, size: 16), if (isSelected) const SizedBox(width: 4), Text(filter, style: TextStyle(color: isSelected ? tabColor : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14))]))));
      }).toList())),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400, width: 1.5), borderRadius: BorderRadius.circular(25)), child: Row(children: [Icon(Icons.search, color: Colors.grey.shade600, size: 22), const SizedBox(width: 8), Expanded(child: TextField(controller: _searchController, decoration: const InputDecoration(hintText: 'Cerca un alimento...', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 12))))])),
      const SizedBox(height: 12),
      Expanded(child: !_recipesLoaded ? const Center(child: CircularProgressIndicator()) : groupedFoods.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search_off, color: Colors.grey.shade400, size: 48), const SizedBox(height: 12), Text('Nessun alimento trovato', style: TextStyle(color: Colors.grey.shade600, fontSize: 14))])) : ListView.builder(padding: const EdgeInsets.symmetric(vertical: 4), itemCount: groupedFoods.keys.length, itemBuilder: (context, index) {
        final catName = groupedFoods.keys.elementAt(index);
        final catFoods = groupedFoods[catName]!;
        final categoryIcon = _getIconForCategory(catName);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Row(children: [Container(width: 4, height: 22, decoration: BoxDecoration(color: tabColor, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Expanded(child: Text(catName.toUpperCase(), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: tabColor, letterSpacing: 0.5))), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), decoration: BoxDecoration(color: tabColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Text('${catFoods.length}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tabColor)))])),
          Wrap(spacing: 8, runSpacing: 8, children: catFoods.map((food) {
            final isSelected = _selectedFoods.contains(food.name);
            final foodColor = _getColorForFood(food);
            final hasRecipe = _foodRecipesMap.containsKey(food.name);
            final hasQuando = food.quandoMangiarlo.isNotEmpty;
            final borderColor = hasRecipe ? _colorRecipe : foodColor.withOpacity(0.6);
            final borderWidth = hasRecipe ? 3.0 : 1.0;
            final bgColor = hasRecipe ? _colorRecipe.withOpacity(0.08) : foodColor.withOpacity(0.1);
            return GestureDetector(onTap: () => _onFoodTap(food), onLongPress: () => _addToPlan(food), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor, width: borderWidth), borderRadius: BorderRadius.circular(25), boxShadow: hasRecipe ? [BoxShadow(color: _colorRecipe.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : []), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(categoryIcon, color: foodColor, size: 16), const SizedBox(width: 6), Text(food.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? foodColor : Colors.black87, fontSize: 13)), if (hasQuando) ...[const SizedBox(width: 4), Icon(Icons.restaurant, color: _colorNeutral, size: 14)], if (hasRecipe) ...[const SizedBox(width: 4), Icon(Icons.menu_book, color: _colorRecipe, size: 14)], if (isSelected) ...[const SizedBox(width: 4), const Icon(Icons.check_circle, color: Color(0xFF43A047), size: 16)]])));
          }).toList()),
          const SizedBox(height: 8),
        ]);
      })),
      const SizedBox(height: 12),
      if (_selectedFoods.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: tabColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('📋 ${_selectedFoods.length} aliment${_selectedFoods.length == 1 ? 'o' : 'i'} selezionat${_selectedFoods.length == 1 ? 'o' : 'i'}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: tabColor))),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla'))), const SizedBox(width: 12), Expanded(child: FilledButton.icon(onPressed: _selectedFoods.isEmpty ? null : () { widget.onFoodsSelected(_selectedFoods.toList()); Navigator.pop(context); }, icon: const Icon(Icons.check, size: 18), label: const Text('Salva'), style: FilledButton.styleFrom(backgroundColor: tabColor)))])
    ])));
  }
}