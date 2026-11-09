import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

class FavoritesScreen extends StatefulWidget {
  final String? initialGroup;

  const FavoritesScreen({super.key, this.initialGroup});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<String> _groups = ['0', 'A', 'B', 'AB'];
  String _selectedGroup = '0';

  // Cache dei preferiti per ogni gruppo
  final Map<String, List<String>> _favoritesByGroup = {
    '0': [],
    'A': [],
    'B': [],
    'AB': [],
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialGroup != null && _groups.contains(widget.initialGroup)) {
      _selectedGroup = widget.initialGroup!;
    }
    _loadAllFavorites();
  }

  /// Carica i preferiti di tutti i gruppi
  Future<void> _loadAllFavorites() async {
    setState(() => _isLoading = true);

    for (final group in _groups) {
      final favs = await FavoritesService.getFavorites(group);
      _favoritesByGroup[group] = favs;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _changeGroup(String group) {
    setState(() => _selectedGroup = group);
  }

  /// Rimuove un preferito da un gruppo specifico
  Future<void> _removeFavorite(String group, String itemName) async {
    await FavoritesService.toggleFavorite(group, itemName);

    final favs = await FavoritesService.getFavorites(group);
    setState(() {
      _favoritesByGroup[group] = favs;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$itemName rimosso dai preferiti del Gruppo $group'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Color _getGroupColor(String group) {
    switch (group) {
      case '0':
        return const Color(0xFFE53935);
      case 'A':
        return const Color(0xFF43A047);
      case 'B':
        return const Color(0xFF1E88E5);
      case 'AB':
        return const Color(0xFF8E24AA);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _favoritesByGroup[_selectedGroup] ?? [];
    final groupColor = _getGroupColor(_selectedGroup);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 24),
            SizedBox(width: 8),
            Text('I miei Preferiti'),
          ],
        ),
        backgroundColor: const Color(0xFFAD1457),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // 👈 Selettore Gruppo Sanguigno (stesso stile del Piano Alimentare)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gruppo Sanguigno:',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _groups.map((group) {
                    final isSelected = _selectedGroup == group;
                    final color = _getGroupColor(group);
                    final count = _favoritesByGroup[group]?.length ?? 0;
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
                              border: Border.all(
                                  color: color, width: isSelected ? 2 : 1),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2))
                                    ]
                                  : [],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Gruppo $group',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (count > 0)
                                  Text(
                                    '($count)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.9)
                                          : color.withOpacity(0.8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
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

          // Lista preferiti del gruppo selezionato
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : favorites.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_border,
                                  color: groupColor.withOpacity(0.5),
                                  size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'Nessun preferito per il Gruppo $_selectedGroup',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    height: 1.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Clicca il cuore ❤️ su un alimento per aggiungerlo qui.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final foodName = favorites[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: groupColor.withOpacity(0.15),
                                child: Icon(Icons.favorite,
                                    color: groupColor, size: 24),
                              ),
                              title: Text(
                                foodName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16),
                              ),
                              subtitle: Text(
                                'Gruppo $_selectedGroup',
                                style: TextStyle(
                                    color: groupColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.grey),
                                onPressed: () =>
                                    _removeFavorite(_selectedGroup, foodName),
                                tooltip: 'Rimuovi dai preferiti',
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}