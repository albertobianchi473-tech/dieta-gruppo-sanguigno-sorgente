import 'package:flutter/material.dart';
import '../models/blood_group.dart';
import '../widgets/food_card.dart';
import '../services/recipe_service.dart';
import '../services/favorites_service.dart';
import 'recipes_screen.dart';
import 'rimedi_screen.dart';
import 'favorites_screen.dart';

class DietScreen extends StatefulWidget {
  final BloodGroupDiet diet;
  const DietScreen({super.key, required this.diet});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> with SingleTickerProviderStateMixin {
  late TabController _innerTabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _mealFilter = 'Tutti';
  bool _isLoadingRecipes = false;
  Set<String> _foodsWithRecipes = {};

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 3, vsync: this);
    _loadFoodsWithRecipes();
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodsWithRecipes() async {
    final foods = await RecipeService().getFoodsWithRecipes(widget.diet.group);
    if (mounted) {
      setState(() {
        _foodsWithRecipes = foods;
      });
    }
  }

  String _normalize(String text) {
    return text.toLowerCase().trim().replaceAll('’', "'").replaceAll('`', "'");
  }

  bool _hasRecipe(FoodItem food) {
    final String foodName = _normalize(food.name);
    if (foodName.contains('(')) {
      return _foodsWithRecipes.any((ing) => _normalize(ing).contains(foodName));
    }
    if (_foodsWithRecipes.any((ing) => _normalize(ing) == foodName)) return true;

    final Map<String, List<String>> aliases = {
      'uova di gallina': ['uova', 'uovo', 'albume', 'tuorlo'],
      'olio extravergine di oliva': ['olio extravergine d\'oliva', 'olio e.v.o.', 'olio extravergine'],
      'sale': ['sale marino', 'sale fino', 'sale integrale'],
      'limoni': ['limone', 'succo di limone', 'scorza di limone'],
      'manzo': ['carne di manzo', 'carne tritata', 'macinato di manzo', 'carne bovina'],
      'vitello': ['carne di vitello', 'ossobuco di vitello', 'nervetti di vitello', 'animelle di vitello'],
      'agnello': ['costolette d\'agnello', 'costolette d\'agnello', 'polpa di agnello', 'carne di agnello'],
      'patate dolci bianche': ['patate bianche dolci', 'patate dolci'],
      'patate dolci rosse': ['patate rosse dolci', 'patate dolci'],
    };

    if (aliases.containsKey(foodName)) {
      for (final alias in aliases[foodName]!) {
        if (_foodsWithRecipes.any((ing) => _normalize(ing).contains(_normalize(alias)))) return true;
      }
    }
    if (foodName.length >= 4) {
      if (_foodsWithRecipes.any((ing) => _normalize(ing).contains(foodName))) return true;
    }
    return false;
  }

  Color get _themeColor => Color(int.parse('0xFF${widget.diet.color.substring(1)}'));

  // Metodo di filtraggio con gestione sicura dei valori nulli
  List<FoodItem> _filterFoods(List<FoodItem> items) {
    return items.where((item) {
      // Filtro per testo (ricerca)
      final matchesText = _searchQuery.isEmpty || 
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Filtro per momento del pasto - GESTIONE SICURA DEI NULLI
      bool matchesMeal;
      if (_mealFilter == 'Tutti') {
        matchesMeal = true;
      } else {
        final quando = item.quandoMangiarlo ?? '';
        matchesMeal = quando.isNotEmpty && 
            quando.toLowerCase().contains(_mealFilter.toLowerCase());
      }
      
      return matchesText && matchesMeal;
    }).toList();
  }

  Future<void> _openRecipesForIngredient(String ingredientName) async {
    setState(() => _isLoadingRecipes = true);
    await RecipeService().getRecipes();
    setState(() => _isLoadingRecipes = false);
    if (mounted) {
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (_) => RecipesScreen(
            selectedGroup: widget.diet.group, 
            initialSearchQuery: ingredientName.toLowerCase()
          )
        )
      );
    }
  }

  void _mostraDialogoPreferiti(BuildContext context, String foodName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aggiungi ai preferiti'),
          content: Text('Vuoi aggiungere "$foodName" alla lista dei preferiti?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Annulla')
            ),
            TextButton(
              onPressed: () async {
                await FavoritesService.toggleFavorite(foodName);
                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$foodName aggiunto ai preferiti ❤️'), 
                      backgroundColor: Colors.green
                    )
                  );
                }
              },
              child: const Text('Aggiungi', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text('Gruppo ${widget.diet.group} — ${widget.diet.name}'),
          backgroundColor: _themeColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Alimenti', icon: Icon(Icons.restaurant, size: 20)),
              Tab(text: 'Rimedi Naturali', icon: Icon(Icons.eco, size: 20)),
              Tab(text: 'Preferiti', icon: Icon(Icons.favorite, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAlimentiTab(),
            RimediScreen(group: widget.diet.group),
            const FavoritesScreen(),
          ],
        ),
        bottomSheet: _isLoadingRecipes 
            ? Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Caricamento ricette...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ) 
            : null,
      ),
    );
  }

  Widget _buildAlimentiTab() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 160, // Spazio aumentato per evitare sovrapposizioni
          pinned: true,
          backgroundColor: _themeColor,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16, end: 16),
            title: Text(
              widget.diet.description, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 13, 
                fontWeight: FontWeight.w500,
                shadows: [Shadow(blurRadius: 3, color: Colors.black45)]
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_themeColor, _themeColor.withOpacity(0.5)], 
                  begin: Alignment.topCenter, 
                  end: Alignment.bottomCenter
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.bloodtype, size: 80, color: Colors.white12),
            ),
          ),
        ),
      ],
      body: Column(
        children: [
          // Tab interne: Benefici / Indifferenti / Sconsigliati
          TabBar(
            controller: _innerTabController,
            labelColor: _themeColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _themeColor,
            tabs: const [
              Tab(icon: Icon(Icons.check_circle, color: Colors.green), text: 'Benefici'),
              Tab(icon: Icon(Icons.remove_circle_outline, color: Colors.lightBlue), text: 'Indifferenti'),
              Tab(icon: Icon(Icons.cancel, color: Colors.red), text: 'Sconsigliati'),
            ],
          ),
          
          // Filtri a chip per il momento della giornata
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['Tutti', 'Colazione', 'Pranzo', 'Cena', 'Merenda'].map((meal) {
                final isSelected = _mealFilter == meal;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(meal),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _mealFilter = meal;
                      });
                    },
                    selectedColor: _themeColor.withOpacity(0.2),
                    checkmarkColor: _themeColor,
                    labelStyle: TextStyle(
                      color: isSelected ? _themeColor : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Barra di ricerca
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cerca un alimento...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isEmpty ? null : IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () { 
                    _searchController.clear(); 
                    setState(() => _searchQuery = ''); 
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), 
                  borderSide: BorderSide(color: _themeColor.withOpacity(0.3))
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          
          // Lista degli alimenti
          Expanded(
            child: TabBarView(
              controller: _innerTabController,
              children: [
                _buildFoodList(widget.diet.beneficial, Colors.green),
                _buildFoodList(widget.diet.neutral, Colors.lightBlue),
                _buildFoodList(widget.diet.harmful, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(List<FoodItem> items, Color categoryColor) {
    final filteredItems = _filterFoods(items);
    if (filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty 
                  ? 'Nessun alimento trovato per il filtro "$_mealFilter"\n\nCompila la colonna "Quando mangiarlo" nel file Excel per vedere risultati.'
                  : 'Nessun risultato per "$_searchQuery"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<FoodItem>>{};
    for (final item in filteredItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    final categories = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(width: 4, height: 20, decoration: BoxDecoration(color: categoryColor, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text(cat.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _themeColor)),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 1, color: Colors.grey[300])),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: categoryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('${grouped[cat]!.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: categoryColor)),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: grouped[cat]!.map((f) {
                final hasRecipe = _hasRecipe(f);
                return GestureDetector(
                  onLongPress: () => _mostraDialogoPreferiti(context, f.name),
                  onSecondaryTap: () => _mostraDialogoPreferiti(context, f.name),
                  child: FoodCard(
                    food: f,
                    hasRecipe: hasRecipe,
                    onTap: hasRecipe ? () => _openRecipesForIngredient(f.name) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}