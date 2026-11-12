import 'package:flutter/material.dart';
import '../services/shopping_list_history_service.dart';

class ShoppingListHistoryScreen extends StatefulWidget {
  final String bloodGroup;
  const ShoppingListHistoryScreen({super.key, required this.bloodGroup});

  @override
  State<ShoppingListHistoryScreen> createState() => _ShoppingListHistoryScreenState();
}

class _ShoppingListHistoryScreenState extends State<ShoppingListHistoryScreen> {
  List<Map<String, dynamic>> _lists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    _lists = await ShoppingListHistoryService.loadAllLists();
    setState(() => _isLoading = false);
  }

  Future<void> _deleteList(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina lista'),
        content: const Text('Sei sicuro di voler eliminare questa lista dallo storico?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
        ],
      ),
    );

    if (confirm == true) {
      await ShoppingListHistoryService.deleteShoppingList(id);
      _loadHistory();
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancella storico'),
        content: const Text('Eliminare tutte le liste spese salvate?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Elimina tutto')),
        ],
      ),
    );

    if (confirm == true) {
      await ShoppingListHistoryService.clearHistory();
      _loadHistory();
    }
  }

  Future<void> _viewList(Map<String, dynamic> list) async {
    final items = List<Map<String, dynamic>>.from(list['items'] as List);
    final type = list['type'] as String;
    final date = list['date'] as String;
    final group = list['group'] as String;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_basket, color: Color(0xFF00897B), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lista $type - $date',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final name = item['name'] as String;
                    final count = item['count'] as int;
                    final checked = item['checked'] as bool;
                    final category = item['category'] as String? ?? 'Altro';

                    return CheckboxListTile(
                      value: checked,
                      onChanged: null, // Solo visualizzazione
                      title: Text(
                        count > 1 ? '$name x$count' : name,
                        style: TextStyle(
                          decoration: checked ? TextDecoration.lineThrough : null,
                          color: checked ? Colors.grey : Colors.black87,
                        ),
                      ),
                      subtitle: Text(category, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      dense: true,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Chiudi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico Liste Spesa'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          if (_lists.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Cancella storico',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, color: Colors.grey.shade400, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Nessuna lista salvata',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Salva una lista della spesa per\nvederla qui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.4),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lists.length,
                  itemBuilder: (context, index) {
                    final list = _lists[index];
                    final date = list['date'] as String;
                    final group = list['group'] as String;
                    final type = list['type'] as String;
                    final items = List<Map<String, dynamic>>.from(list['items'] as List);

                    int checkedCount = items.where((item) => item['checked'] == true).length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF00897B).withOpacity(0.15),
                          child: const Icon(Icons.shopping_basket, color: Color(0xFF00897B)),
                        ),
                        title: Text(
                          'Lista $type - Gruppo $group',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text('$date • ${items.length} articoli ($checkedCount spuntati)'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'view') _viewList(list);
                            if (value == 'delete') _deleteList(list['id'] as int);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'view', child: Text('Visualizza')),
                            const PopupMenuItem(value: 'delete', child: Text('Elimina', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}