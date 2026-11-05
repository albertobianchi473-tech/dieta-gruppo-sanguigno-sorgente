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
    // 🔍 DEBUG: solo nella console
    print('📂 Caricamento ricette per gruppo ${widget.selectedGroup}...');
    
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final recipes = await RecipeService().getRecipes();
      final groupRecipes = recipes.where((r) => r.gruppo == widget.selectedGroup).toList();
      
      // 🔍 DEBUG: solo nella console
      print('✅ Trovate ${groupRecipes.length} ricette per gruppo ${widget.selectedGroup}');
      
      setState(() {
        _allRecipes = groupRecipes;
        _applySearch();
        _loading = false;
      });
    } catch (e) {
      // 🔍 DEBUG: solo nella console
      print('❌ Errore caricamento ricette: $e');
      
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

  // 👇 Vista errore: semplice e amichevole (senza dettagli tecnici)
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Verifica la connessione e riprova',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
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

  // 👇 Vista vuota: quando non ci sono ricette per il gruppo
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 👇 Lista ricette
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

  // 👇 Dettaglio ricetta (modal bottom sheet)
  void _showRecipeDetails(BuildContext context, Recipe recipe, Color themeColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(recipe.nome, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: themeColor)),
            const SizedBox(height: 16),
            Row(
              children: [
                if (recipe.tempo.isNotEmpty) ...[
                  Icon(Icons.timer, color: themeColor),
                  const SizedBox(width: 8),
                  Text('Tempo: ${recipe.tempo}'),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.trending_up, color: themeColor),
                const SizedBox(width: 8),
                Text('Difficoltà: ${recipe.difficolta}'),
              ],
            ),
            const Divider(height: 32),
            const Text('INGREDIENTI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: ListView(
                children: recipe.ingredientiDisplay.split(';').map((ing) {
                  if (ing.trim().isEmpty) return const SizedBox.shrink();
                  final isMatch = _searchController.text.isNotEmpty && 
                      recipe.ingredientiMatching.any((matchingIng) => 
                          matchingIng.toLowerCase().contains(_searchController.text.toLowerCase())
                      );
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle, 
                          color: isMatch ? Colors.orange : themeColor, 
                          size: 20
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ing.trim(),
                            style: TextStyle(
                              fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
                              color: isMatch ? Colors.orange : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 32),
            const Text('PREPARAZIONE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Text(recipe.preparazione, style: const TextStyle(fontSize: 15, height: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}