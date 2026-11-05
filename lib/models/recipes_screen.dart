import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import '../models/recipe.dart';

class RecipesScreen extends StatefulWidget {
  final String selectedGroup;
  const RecipesScreen({super.key, required this.selectedGroup});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Recipe> _recipes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      // Carica il file Excel
      final ByteData data = await rootBundle.load('assets/ricette.xlsx');
      final List<int> bytes = data.buffer.asUint8List();
      final Excel excel = Excel.decodeBytes(bytes);

      // Ottieni il foglio "Ricette"
      final Sheet? sheet = excel.tables['Ricette'];
      
      if (sheet == null) {
        setState(() {
          _error = 'Foglio "Ricette" non trovato';
          _loading = false;
        });
        return;
      }

      final List<Recipe> recipes = [];

      // Salta la prima riga (intestazioni) e leggi le altre
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        
        // Verifica che la riga non sia vuota
        if (row[0]?.value == null || row[0]!.value.toString().isEmpty) {
          continue;
        }

        final recipe = Recipe.fromExcelRow(
          gruppo: row[0]?.value?.toString() ?? '',
          nome: row[1]?.value?.toString() ?? '',
          tempo: row[2]?.value?.toString() ?? '',
          difficolta: row[3]?.value?.toString() ?? '',
          ingredienti: row[4]?.value?.toString() ?? '',
          preparazione: row[5]?.value?.toString() ?? '',
        );

        // Filtra solo le ricette del gruppo selezionato
        if (recipe.gruppo == widget.selectedGroup) {
          recipes.add(recipe);
        }
      }

      setState(() {
        _recipes = recipes;
        _loading = false;
      });

      print('✅ Caricate ${_recipes.length} ricette per gruppo ${widget.selectedGroup}');
    } catch (e) {
      setState(() {
        _error = 'Errore nel caricamento: $e';
        _loading = false;
      });
      print('❌ Errore caricamento ricette: $e');
    }
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
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: themeColor),
                  const SizedBox(height: 16),
                  Text(
                    'Caricamento ricette...',
                    style: TextStyle(color: themeColor),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _loadRecipes();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Riprova'),
                      ),
                    ],
                  ),
                )
              : _recipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 80, color: themeColor),
                          const SizedBox(height: 16),
                          Text(
                            'Nessuna ricetta disponibile per il gruppo ${widget.selectedGroup}',
                            style: TextStyle(fontSize: 18, color: themeColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _recipes[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Chip(
                                        avatar: const Icon(Icons.timer, size: 18),
                                        label: Text(recipe.tempo),
                                        backgroundColor: themeColor.withOpacity(0.1),
                                      ),
                                      const SizedBox(width: 8),
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
                    ),
    );
  }

  void _showRecipeDetails(BuildContext context, Recipe recipe, Color themeColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              recipe.nome,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.timer, color: themeColor),
                const SizedBox(width: 8),
                Text('Tempo: ${recipe.tempo}'),
                const SizedBox(width: 16),
                Icon(Icons.trending_up, color: themeColor),
                const SizedBox(width: 8),
                Text('Difficoltà: ${recipe.difficolta}'),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'INGREDIENTI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recipe.ingredienti.map((ing) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: themeColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ing)),
                ],
              ),
            )),
            const Divider(height: 32),
            const Text(
              'PREPARAZIONE',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  recipe.preparazione,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}