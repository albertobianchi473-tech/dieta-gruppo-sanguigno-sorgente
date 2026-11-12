import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../data/diet_data.dart';
import '../models/blood_group.dart';
import '../services/meal_plan_service.dart';
import '../services/shopping_list_history_service.dart';
import '../services/shopping_list_service.dart';
import 'shopping_list_history_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  final String bloodGroup;
  const ShoppingListScreen({super.key, required this.bloodGroup});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  Map<String, List<MapEntry<String, int>>> _groupedList = {};
  Map<String, bool> _itemStatus = {};
  bool _isLoading = true;
  bool _isEmpty = true;
  String _selectedPlanType = 'Oggi';

  @override
  void initState() {
    super.initState();
    _generateShoppingList();
  }

  Future<void> _generateShoppingList() async {
    setState(() => _isLoading = true);
    try {
      final weeklyPlan = await MealPlanService.loadMealPlan(widget.bloodGroup);
      _itemStatus = await ShoppingListService.loadStatus(widget.bloodGroup, _selectedPlanType);
      
      // ✅ Carica anche gli ingredienti extra delle ricette
      final extraIngredients = await ShoppingListService.loadExtraIngredients(widget.bloodGroup, _selectedPlanType);

      final Map<String, int> foodCounts = {};

      // 1. Conta gli alimenti dal piano
      if (_selectedPlanType == 'Oggi') {
        final day = MealPlanService.dailyViewKey;
        if (weeklyPlan.containsKey(day)) {
          for (final meal in MealPlanService.mealTypes) {
            if (weeklyPlan[day]!.containsKey(meal)) {
              for (final food in weeklyPlan[day]![meal]!) {
                foodCounts[food] = (foodCounts[food] ?? 0) + 1;
              }
            }
          }
        }
      } else {
        for (final day in MealPlanService.daysOfWeek) {
          if (weeklyPlan.containsKey(day)) {
            for (final meal in MealPlanService.mealTypes) {
              if (weeklyPlan[day]!.containsKey(meal)) {
                for (final food in weeklyPlan[day]![meal]!) {
                  foodCounts[food] = (foodCounts[food] ?? 0) + 1;
                }
              }
            }
          }
        }
      }

      // ✅ 2. Aggiungi gli ingredienti extra delle ricette
      for (final ing in extraIngredients) {
        foodCounts[ing] = (foodCounts[ing] ?? 0) + 1;
      }

      // 3. Raggruppa per categoria
      _groupedList = {};
      foodCounts.forEach((foodName, count) {
        final category = _getCategoryForFood(foodName);
        if (!_groupedList.containsKey(category)) {
          _groupedList[category] = [];
        }
        _groupedList[category]!.add(MapEntry(foodName, count));
      });

      _groupedList.forEach((category, items) {
        items.sort((a, b) => a.key.compareTo(b.key));
      });

      setState(() {
        _isEmpty = foodCounts.isEmpty;
        _isLoading = false;
      });
    } catch (e) {
      print('Errore generazione lista spesa: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getCategoryForFood(String foodName) {
    try {
      final diet = DietData.getByGroup(widget.bloodGroup);
      final allFoods = [...diet.beneficial, ...diet.neutral, ...diet.harmful];
      final food = allFoods.firstWhere((f) => f.name.toLowerCase() == foodName.toLowerCase());
      return food.category.isNotEmpty && food.category.toLowerCase() != 'altro' ? food.category : 'Altro';
    } catch (e) {
      return '📝 Ingredienti Ricette'; // Fallback per ingredienti non trovati nel file diete
    }
  }

  Future<void> _onItemChanged(String itemName, bool? isChecked) async {
    if (isChecked == null) return;
    setState(() { _itemStatus[itemName] = isChecked; });
    await ShoppingListService.toggleItemStatus(widget.bloodGroup, _selectedPlanType, itemName, isChecked);
  }

  Future<void> _resetList() async {
    final planLabel = _selectedPlanType == 'Oggi' ? 'giornaliera' : 'settimanale';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetta Lista'),
        content: Text('Vuoi togliere tutte le spunte e svuotare la lista $planLabel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Resetta')),
        ],
      ),
    );
    if (confirm == true) {
      await ShoppingListService.resetStatus(widget.bloodGroup, _selectedPlanType);
      _generateShoppingList();
    }
  }

  String _generateShoppingListText() {
    final StringBuffer buffer = StringBuffer();
    final planLabel = _selectedPlanType == 'Oggi' ? 'Giornaliera' : 'Settimanale';
    buffer.writeln('🛒 LISTA DELLA SPESA - $planLabel');
    buffer.writeln('Gruppo ${widget.bloodGroup}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    _groupedList.forEach((category, items) {
      buffer.writeln('📦 $category');
      buffer.writeln('──────────────────────────────');
      for (final entry in items) {
        final itemName = entry.key;
        final count = entry.value;
        final isChecked = _itemStatus[itemName] ?? false;
        final checkSymbol = isChecked ? '✅' : '⬜';
        final quantityText = count > 1 ? ' x$count' : '';
        buffer.writeln('$checkSymbol $itemName$quantityText');
      }
      buffer.writeln('');
    });
    return buffer.toString();
  }

  Future<void> _shareShoppingList() async {
    final listText = _generateShoppingListText();
    if (listText.isEmpty) return;
    await Share.share(listText, subject: 'Lista della Spesa - Gruppo ${widget.bloodGroup}');
  }

  Future<void> _saveShoppingList() async {
    if (_isEmpty) return;
    await ShoppingListHistoryService.saveShoppingList(
      group: widget.bloodGroup, type: _selectedPlanType == 'Oggi' ? 'Giornaliera' : 'Settimanale',
      groupedItems: _groupedList, itemStatus: _itemStatus,
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Lista salvata nello storico!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista della Spesa'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.history), tooltip: 'Storico', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShoppingListHistoryScreen(bloodGroup: widget.bloodGroup)))),
          if (!_isEmpty) IconButton(icon: const Icon(Icons.save), tooltip: 'Salva', onPressed: _saveShoppingList),
          if (!_isEmpty) IconButton(icon: const Icon(Icons.share), tooltip: 'Condividi', onPressed: _shareShoppingList),
          if (!_isEmpty) IconButton(icon: const Icon(Icons.refresh), tooltip: 'Resetta', onPressed: _resetList),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16), color: Colors.grey.shade100,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(value: 'Oggi', label: Text('Giornaliero'), icon: Icon(Icons.today)),
                ButtonSegment<String>(value: 'Settimana', label: Text('Settimanale'), icon: Icon(Icons.calendar_month)),
              ],
              selected: {_selectedPlanType},
              onSelectionChanged: (Set<String> newSelection) { setState(() { _selectedPlanType = newSelection.first; }); _generateShoppingList(); },
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator())
            : _isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shopping_cart_outlined, color: Colors.grey.shade400, size: 64), const SizedBox(height: 16), Text('La lista è vuota', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold))]))
            : ListView.builder(
                padding: const EdgeInsets.all(16), itemCount: _groupedList.keys.length,
                itemBuilder: (context, index) {
                  final category = _groupedList.keys.elementAt(index);
                  final items = _groupedList[category]!;
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Row(children: [
                      Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF00897B), borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(category.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00897B)))),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF00897B).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text('${items.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00897B)))),
                    ])),
                    Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Column(children: items.map((entry) {
                      final itemName = entry.key;
                      final count = entry.value;
                      final isChecked = _itemStatus[itemName] ?? false;
                      final displayName = count > 1 ? '$itemName x$count' : itemName;
                      return CheckboxListTile(value: isChecked, onChanged: (val) => _onItemChanged(itemName, val),
                        title: Text(displayName, style: TextStyle(decoration: isChecked ? TextDecoration.lineThrough : null, color: isChecked ? Colors.grey : Colors.black87, fontWeight: FontWeight.w500)),
                        secondary: Icon(isChecked ? Icons.check_circle : Icons.radio_button_unchecked, color: isChecked ? const Color(0xFF00897B) : Colors.grey.shade400), dense: true);
                    }).toList())),
                  ]);
                },
              ),
          ),
        ],
      ),
    );
  }
}