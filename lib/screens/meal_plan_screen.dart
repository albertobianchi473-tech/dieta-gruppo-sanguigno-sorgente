import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/diet_data.dart';
import '../models/blood_group.dart';
import '../services/meal_plan_service.dart';

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
    if (savedGroup != null) {
      _selectedGroup = savedGroup;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try { 
      await DietData.initialize(); 
    } catch (_) {}

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

  void _changeDay(String day) {
    setState(() => _selectedDay = day);
  }

  Future<void> _changeGroup(String group) async {
    if (_selectedGroup == group) return;
    setState(() {
      _selectedGroup = group;
      _isLoading = true;
    });
    await _loadData();
  }

  Future<void> _openFoodSelector(String mealType) async {
    final allFoods = _getAllFoodsForGroup(_selectedGroup);

    if (allFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nessun alimento disponibile per il Gruppo $_selectedGroup.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => _FoodSelectionDialog(
        mealType: mealType,
        availableFoods: allFoods,
        currentFoods: _mealPlan[_selectedDay]![mealType] ?? [],
        onFoodsSelected: (selectedFoods) async {
          for (var foodName in selectedFoods) {
            await MealPlanService.addFoodToMeal(_selectedGroup, _selectedDay, mealType, foodName);
          }
          await _loadData();
        },
      ),
    );
  }

  List<FoodItem> _getAllFoodsForGroup(String group) {
    try {
      final diet = DietData.getByGroup(group);
      return [...diet.beneficial, ...diet.neutral, ...diet.harmful];
    } catch (e) {
      print('Errore nel recupero alimenti: $e');
      return [];
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Il Mio Piano Alimentare'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearCurrentDay, tooltip: 'Svuota questo giorno'),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gruppo Sanguigno:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
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
                              boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
                            ),
                            child: Text(
                              'Gruppo $group',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: false, label: Text('Giornaliero'), icon: Icon(Icons.today)),
                ButtonSegment<bool>(value: true, label: Text('Settimanale'), icon: Icon(Icons.calendar_month)),
              ],
              selected: {_isWeekly},
              onSelectionChanged: (Set<bool> newSelection) => _toggleViewMode(newSelection.first),
            ),
          ),

          if (_isWeekly)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: MealPlanService.daysOfWeek.length,
                itemBuilder: (context, index) {
                  final day = MealPlanService.daysOfWeek[index];
                  final isSelected = _selectedDay == day;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: FilterChip(
                      label: Text(day),
                      selected: isSelected,
                      onSelected: (selected) => _changeDay(day),
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFFE53935).withOpacity(0.2),
                      checkmarkColor: const Color(0xFFE53935),
                    ),
                  );
                },
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: MealPlanService.mealTypes.length,
              itemBuilder: (context, index) {
                final mealType = MealPlanService.mealTypes[index];
                final foods = _mealPlan[_selectedDay]![mealType] ?? [];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(_getMealIcon(mealType), color: const Color(0xFFE53935), size: 28),
                        title: Text(mealType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        subtitle: Text('${foods.length} alimenti selezionati'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF43A047), size: 32),
                          onPressed: () => _openFoodSelector(mealType),
                        ),
                      ),
                      if (foods.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: foods.map((food) => Chip(
                              label: Text(food),
                              onDeleted: () async {
                                await MealPlanService.removeFoodFromMeal(_selectedGroup, _selectedDay, mealType, food);
                                await _loadData();
                              },
                              backgroundColor: const Color(0xFFE53935).withOpacity(0.1),
                              side: const BorderSide(color: Color(0xFFE53935), width: 0.5),
                            )).toList(),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Nessun alimento. Clicca sul + per aggiungere.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'Colazione': return Icons.coffee;
      case 'Pranzo': return Icons.lunch_dining;
      case 'Cena': return Icons.dinner_dining;
      case 'Merenda': return Icons.cookie;
      default: return Icons.restaurant;
    }
  }
}

// =========================================================================
// DIALOGO DI SELEZIONE ALIMENTI - STILE IDENTICO ALLO SCREENSHOT
// =========================================================================
class _FoodSelectionDialog extends StatefulWidget {
  final String mealType;
  final List<FoodItem> availableFoods;
  final List<String> currentFoods;
  final Function(List<String>) onFoodsSelected;

  const _FoodSelectionDialog({
    required this.mealType,
    required this.availableFoods,
    required this.currentFoods,
    required this.onFoodsSelected,
  });

  @override
  State<_FoodSelectionDialog> createState() => _FoodSelectionDialogState();
}

class _FoodSelectionDialogState extends State<_FoodSelectionDialog> {
  late Set<String> _selectedFoods;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMealFilter = 'Tutti'; // Tutti, Colazione, Pranzo, Cena, Merenda
  bool _filterByMeal = true;

  static const Color _colorBeneficial = Color(0xFF43A047);
  static const Color _colorNeutral = Color(0xFFFFA000);
  static const Color _colorHarmful = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _selectedFoods = widget.currentFoods.toSet();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtra gli alimenti in base a ricerca, filtro pasto e filtro categoria
  List<FoodItem> _getFilteredFoods() {
    return widget.availableFoods.where((food) {
      // Filtro ricerca
      if (_searchQuery.isNotEmpty &&
          !food.name.toLowerCase().contains(_searchQuery) &&
          !food.category.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      
      // Filtro pasto (se attivo)
      if (_filterByMeal) {
        final quando = food.quandoMangiarlo.toLowerCase();
        final keyword = widget.mealType.toLowerCase();
        return quando.contains(keyword) || quando.isEmpty;
      }
      
      return true;
    }).toList();
  }

  // Raggruppa gli alimenti per categoria (usando il valore ESATTO dal file Excel)
  Map<String, List<FoodItem>> _groupedByCategory(List<FoodItem> foods) {
    final Map<String, List<FoodItem>> grouped = {};
    for (final food in foods) {
      final category = food.category.isNotEmpty && food.category.toLowerCase() != 'altro' 
          ? food.category 
          : 'Altro';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(food);
    }
    return grouped;
  }

  void _toggleFood(String foodName) {
    setState(() {
      if (_selectedFoods.contains(foodName)) {
        _selectedFoods.remove(foodName);
      } else {
        _selectedFoods.add(foodName);
      }
    });
  }

  // Ottieni il colore in base al tipo di alimento
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

  // Ottieni l'icona in base alla categoria dal file Excel
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titolo
            Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Color(0xFFE53935), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aggiungi a ${widget.mealType}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 20),
            
            // Filtri pasto (Tutti, Colazione, Pranzo, Cena, Merenda) - stile screenshot
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['Tutti', 'Colazione', 'Pranzo', 'Cena', 'Merenda'].map((filter) {
                  final isSelected = _selectedMealFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMealFilter = filter;
                          _filterByMeal = filter != 'Tutti';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE53935).withOpacity(0.15) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFE53935) : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Icon(Icons.check, color: Color(0xFFE53935), size: 16),
                            if (isSelected) const SizedBox(width: 4),
                            Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFE53935) : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Barra di ricerca grande (stile screenshot)
            Container(
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
            const SizedBox(height: 12),

            // Lista scrollabile con categorie e chip (stile screenshot)
            Expanded(
              child: groupedFoods.isEmpty
                  ? Center(
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
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: groupedFoods.keys.length,
                      itemBuilder: (context, index) {
                        final category = groupedFoods.keys.elementAt(index);
                        final foods = groupedFoods[category]!;
                        final categoryIcon = _getIconForCategory(category);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Intestazione categoria (stile screenshot: linea + nome maiuscolo + contatore)
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 22,
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
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE53935),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF43A047).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${foods.length}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF43A047),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Chip degli alimenti in griglia (stile screenshot)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: foods.map((food) {
                                final isSelected = _selectedFoods.contains(food.name);
                                final color = _getColorForFood(food);
                                final hasQuando = food.quandoMangiarlo.isNotEmpty;
                                
                                // Bordo arancione spesso se è "indifferente" o ha restrizioni (come nello screenshot)
                                final bool isHighlighted = food.type == FoodCategory.neutral || hasQuando;
                                final borderColor = isSelected 
                                    ? color 
                                    : (isHighlighted ? const Color(0xFFFFA000) : color.withOpacity(0.6));
                                final borderWidth = isSelected ? 2.5 : (isHighlighted ? 2.0 : 1.0);
                                final bgColor = isSelected 
                                    ? color.withOpacity(0.2) 
                                    : (isHighlighted ? const Color(0xFFFFA000).withOpacity(0.08) : Colors.white);

                                return GestureDetector(
                                  onTap: () => _toggleFood(food.name),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      border: Border.all(
                                        color: borderColor,
                                        width: borderWidth,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: isSelected ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ] : [],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Icona categoria
                                        Icon(
                                          categoryIcon,
                                          color: color,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        // Nome alimento
                                        Text(
                                          food.name,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: isSelected ? color : Colors.black87,
                                            fontSize: 13,
                                          ),
                                        ),
                                        // Icona forchetta/coltello se ha "quando mangiarlo"
                                        if (hasQuando) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.restaurant,
                                            color: const Color(0xFFFFA000),
                                            size: 14,
                                          ),
                                        ],
                                        // Check se selezionato
                                        if (isSelected) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF43A047),
                                            size: 16,
                                          ),
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
                    ),
            ),
            const SizedBox(height: 12),

            // Contatore selezioni
            if (_selectedFoods.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📋 ${_selectedFoods.length} aliment${_selectedFoods.length == 1 ? 'o' : 'i'} selezionat${_selectedFoods.length == 1 ? 'o' : 'i'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                ),
              ),
            const SizedBox(height: 8),

            // Pulsanti azione
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _selectedFoods.isEmpty ? null : () {
                      widget.onFoodsSelected(_selectedFoods.toList());
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Salva'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}