import 'package:flutter/material.dart';
import '../services/meal_plan_service.dart';
import '../services/plan_history_service.dart';

class PlanHistoryScreen extends StatefulWidget {
  final String bloodGroup;
  const PlanHistoryScreen({super.key, required this.bloodGroup});

  @override
  State<PlanHistoryScreen> createState() => _PlanHistoryScreenState();
}

class _PlanHistoryScreenState extends State<PlanHistoryScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    _plans = await PlanHistoryService.loadAllPlans();
    setState(() => _isLoading = false);
  }

  Future<void> _deletePlan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina piano'),
        content: const Text('Sei sicuro di voler eliminare questo piano dallo storico?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
        ],
      ),
    );

    if (confirm == true) {
      await PlanHistoryService.deletePlan(id);
      _loadHistory();
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancella storico'),
        content: const Text('Eliminare tutti i piani salvati?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Elimina tutto')),
        ],
      ),
    );

    if (confirm == true) {
      await PlanHistoryService.clearHistory();
      _loadHistory();
    }
  }

  Future<void> _loadPlan(Map<String, dynamic> plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Carica piano'),
        content: const Text('Questo sostituirà il piano attuale. Continuare?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Carica')),
        ],
      ),
    );

    if (confirm == true) {
      final group = plan['group'] as String;
      final day = plan['day'] as String;
      final meals = Map<String, List<String>>.from(
        (plan['meals'] as Map<String, dynamic>).map((key, value) => 
          MapEntry(key, List<String>.from(value as List))
        )
      );

      // Carica il piano nel servizio
      for (final meal in meals.keys) {
        for (final food in meals[meal]!) {
          await MealPlanService.addFoodToMeal(group, day, meal, food);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Piano caricato con successo!')),
        );
        Navigator.pop(context); // Torna alla schermata piano
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico Piani Alimentari'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          if (_plans.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Cancella storico',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, color: Colors.grey.shade400, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Nessun piano salvato',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Salva un piano alimentare per\nvederlo qui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.4),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    final date = plan['date'] as String;
                    final group = plan['group'] as String;
                    final type = plan['type'] as String;
                    final day = plan['day'] as String;
                    final meals = Map<String, List<String>>.from(
                      (plan['meals'] as Map<String, dynamic>).map((key, value) => 
                        MapEntry(key, List<String>.from(value as List))
                      )
                    );

                    int totalFoods = 0;
                    meals.values.forEach((foods) => totalFoods += foods.length);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1E88E5).withOpacity(0.15),
                              child: const Icon(Icons.restaurant_menu, color: Color(0xFF1E88E5)),
                            ),
                            title: Text(
                              '$type - Gruppo $group',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text('$date • $day • $totalFoods alimenti'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'load') _loadPlan(plan);
                                if (value == 'delete') _deletePlan(plan['id'] as int);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'load', child: Text('Carica piano')),
                                const PopupMenuItem(value: 'delete', child: Text('Elimina', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ),
                          if (totalFoods > 0)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: meals.entries
                                    .where((entry) => entry.value.isNotEmpty)
                                    .map((entry) => Chip(
                                          label: Text('${entry.key}: ${entry.value.length}', style: const TextStyle(fontSize: 11)),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: const Color(0xFF1E88E5).withOpacity(0.1),
                                        ))
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}