import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class RecipesScreen extends StatefulWidget {
  final String selectedGroup;
  final String? initialSearchQuery;

  const RecipesScreen({
    super.key, 
    required this.selectedGroup, 
    this.initialSearchQuery,
  });

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _loading = true;
  bool _hasError = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
    }
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final recipes = await RecipeService().getRecipes();
      
      // ✅ FIX: Gestisce sia "0" che "O" (lettera) per il Gruppo 0
      final groupRecipes = recipes.where((r) {
        final recipeGroup = r.gruppo.trim().toUpperCase();
        final targetGroup = widget.selectedGroup.trim().toUpperCase();
        return recipeGroup == targetGroup || (recipeGroup == 'O' && targetGroup == '0');
      }).toList();
      
      setState(() {
        _allRecipes = groupRecipes;
        _applySearch();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      setState(() => _filteredRecipes = List.from(_allRecipes));
      return;
    }

    setState(() {
      _filteredRecipes = _allRecipes.where((recipe) {
        final nameMatches = recipe.nome.toLowerCase().contains(query);
        final ingredientMatches = recipe.ingredientiMatching.any((ing) => 
          ing.toLowerCase().contains(query)
        );
        return nameMatches || ingredientMatches;
      }).toList();
    });
  }

  Color _getGroupColor() {
    switch (widget.selectedGroup) {
      case '0': return const Color(0xFFE53935);
      case 'A': return const Color(0xFF43A047);
      case 'B': return const Color(0xFF1E88E5);
      case 'AB': return const Color(0xFF8E24AA);
      default: return Colors.blue;
    }
  }

  // ✅ NUOVI METODI PER PARSARE INGREDIENTI E PREPARAZIONE
  List<String> _parseIngredients(String ingredientsText) {
    if (ingredientsText.isEmpty) return [];
    String normalized = ingredientsText.replaceAll('\n', ';');
    List<String> items = normalized.split(RegExp(r'[;,\n]'));
    return items.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  List<String> _parsePreparation(String prepText) {
    if (prepText.isEmpty) return [];
    return prepText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getGroupColor();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Ricette Gruppo ${widget.selectedGroup}'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applySearch(),
              decoration: InputDecoration(
                hintText: 'Cerca ricetta o ingrediente...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _applySearch();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: themeColor.withOpacity(0.3)),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: themeColor))
                : _hasError
                    ? _buildErrorView(themeColor)
                    : _filteredRecipes.isEmpty
                        ? _buildEmptyView(themeColor)
                        : _buildRecipesList(themeColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Color themeColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Impossibile caricare le ricette',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Verifica la connessione e riprova',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRecipes,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(Color themeColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Nessuna ricetta disponibile\nper il gruppo ${widget.selectedGroup}'
                  : 'Nessuna ricetta trovata\nper "${_searchController.text}"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesList(Color themeColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _filteredRecipes[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showRecipeDetails(context, recipe, themeColor),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant, color: themeColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          recipe.nome,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (recipe.tempo.isNotEmpty) ...[
                        Chip(
                          avatar: const Icon(Icons.timer, size: 18),
                          label: Text(recipe.tempo),
                          backgroundColor: themeColor.withOpacity(0.1),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Chip(
                        avatar: const Icon(Icons.trending_up, size: 18),
                        label: Text(recipe.difficolta),
                        backgroundColor: themeColor.withOpacity(0.1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRecipeDetails(BuildContext context, Recipe recipe, Color themeColor) {
    final ingredients = _parseIngredients(recipe.ingredientiDisplay);
    final preparationSteps = _parsePreparation(recipe.preparazione);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Maniglia per trascinare
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Titolo e Info
              Text(
                recipe.nome,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (recipe.tempo.isNotEmpty) ...[
                    Icon(Icons.timer_outlined, color: themeColor, size: 20),
                    const SizedBox(width: 6),
                    Text('${recipe.tempo} min', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.bar_chart_outlined, color: themeColor, size: 20),
                  const SizedBox(width: 6),
                  Text(recipe.difficolta.isNotEmpty ? recipe.difficolta : 'N/D', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 20),
              
              // ✅ Ingredienti formattati
              if (ingredients.isNotEmpty) ...[
                _buildSectionHeader(title: 'INGREDIENTI', icon: Icons.shopping_basket, color: themeColor),
                const SizedBox(height: 12),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = ingredients[index];
                      final isMatch = _searchController.text.isNotEmpty && 
                          recipe.ingredientiMatching.any((matchingIng) => 
                              matchingIng.toLowerCase().contains(_searchController.text.toLowerCase()) &&
                              ingredient.toLowerCase().contains(matchingIng.toLowerCase())
                          );
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isMatch ? Colors.orange : themeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ingredient,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: isMatch ? Colors.orange : const Color(0xFF37474F),
                                  fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ✅ Preparazione formattata
              if (preparationSteps.isNotEmpty) ...[
                _buildSectionHeader(title: 'PREPARAZIONE', icon: Icons.local_dining, color: themeColor),
                const SizedBox(height: 12),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: preparationSteps.length,
                    itemBuilder: (context, index) {
                      final step = preparationSteps[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: themeColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: themeColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Color(0xFF37474F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon, required Color color}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}