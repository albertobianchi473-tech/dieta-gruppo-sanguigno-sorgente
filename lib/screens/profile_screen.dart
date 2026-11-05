import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class WeightEntry {
  final DateTime date;
  final double weight;

  WeightEntry({required this.date, required this.weight});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weight': weight,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      date: DateTime.parse(json['date']),
      weight: (json['weight'] as num).toDouble(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weightController = TextEditingController();
  final _dateController = TextEditingController();
  
  // 👇 Variabile per il gruppo sanguigno
  String? _selectedBloodGroup;
  final List<String> _bloodGroups = ['0', 'A', 'B', 'AB'];

  DateTime? _selectedDate;
  List<WeightEntry> _weightHistory = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _name.text = prefs.getString('name') ?? '';
    _age.text = prefs.getString('age') ?? '';
    _height.text = prefs.getString('height') ?? '';
    
    // 👇 Carica il gruppo sanguigno salvato
    _selectedBloodGroup = prefs.getString('bloodGroup');

    final weightJson = prefs.getString('weightHistory');
    if (weightJson != null) {
      final List<dynamic> decoded = json.decode(weightJson);
      _weightHistory = decoded
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    }
    setState(() {});
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _name.text);
    await prefs.setString('age', _age.text);
    await prefs.setString('height', _height.text);
    
    // 👇 Salva il gruppo sanguigno
    if (_selectedBloodGroup != null) {
      await prefs.setString('bloodGroup', _selectedBloodGroup!);
    } else {
      await prefs.remove('bloodGroup');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilo salvato con successo ✓')),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _addWeight() async {
    if (_weightController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci peso e data')),
      );
      return;
    }

    final weight = double.tryParse(_weightController.text);
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso non valido')),
      );
      return;
    }

    final entry = WeightEntry(date: _selectedDate!, weight: weight);
    _weightHistory.add(entry);
    _weightHistory.sort((a, b) => a.date.compareTo(b.date));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'weightHistory',
      json.encode(_weightHistory.map((e) => e.toJson()).toList()),
    );

    _weightController.clear();
    _selectedDate = null;
    _dateController.clear();

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peso registrato ✓')),
    );
  }

  Future<void> _editWeight(int index) async {
    final entry = _weightHistory[index];
    
    final editWeightController = TextEditingController(
      text: entry.weight.toString(),
    );
    final editDateController = TextEditingController(
      text: '${entry.date.day}/${entry.date.month}/${entry.date.year}',
    );
    DateTime editSelectedDate = entry.date;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifica misurazione'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editDateController,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: editSelectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      editSelectedDate = picked;
                      editDateController.text = 
                          '${picked.day}/${picked.month}/${picked.year}';
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Data',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: editWeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  prefixIcon: Icon(Icons.monitor_weight),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final newWeight = double.tryParse(editWeightController.text);
      if (newWeight == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peso non valido')),
        );
        return;
      }

      _weightHistory[index] = WeightEntry(
        date: editSelectedDate,
        weight: newWeight,
      );
      _weightHistory.sort((a, b) => a.date.compareTo(b.date));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'weightHistory',
        json.encode(_weightHistory.map((e) => e.toJson()).toList()),
      );

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Misurazione aggiornata ✓')),
      );
    }
  }

  Future<void> _deleteWeight(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina misurazione'),
        content: const Text('Vuoi eliminare questa misurazione?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _weightHistory.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'weightHistory',
        json.encode(_weightHistory.map((e) => e.toJson()).toList()),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Il mio profilo'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Dati personali',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // 👇 1. NOME
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nome',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // 👇 2. GRUPPO SANGUIGNO (SPOSTATO QUI)
          DropdownButtonFormField<String>(
            value: _selectedBloodGroup,
            decoration: const InputDecoration(
              labelText: 'Gruppo Sanguigno',
              prefixIcon: Icon(Icons.bloodtype),
              border: OutlineInputBorder(),
              hintText: 'Seleziona il tuo gruppo',
            ),
            items: _bloodGroups.map((String group) {
              return DropdownMenuItem<String>(
                value: group,
                child: Text('Gruppo $group'),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedBloodGroup = newValue;
              });
            },
          ),
          const SizedBox(height: 12),

          // 👇 3. ETÀ
          TextField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Età',
              prefixIcon: Icon(Icons.cake),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // 👇 4. ALTEZZA
          TextField(
            controller: _height,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Altezza (cm)',
              prefixIcon: Icon(Icons.height),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          FilledButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save),
            label: const Text('Salva profilo'),
          ),
          const SizedBox(height: 32),

          const Text(
            'Registra peso',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _selectDate,
            decoration: const InputDecoration(
              labelText: 'Data',
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
              hintText: 'Seleziona una data',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso (kg)',
              prefixIcon: Icon(Icons.monitor_weight),
              border: OutlineInputBorder(),
              hintText: 'es. 70.5',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _addWeight,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi misurazione'),
          ),
          const SizedBox(height: 32),

          if (_weightHistory.isNotEmpty) ...[
            const Text(
              'Andamento peso',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 24),

            const Text(
              'Cronologia',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._weightHistory.asMap().entries.map((entry) {
              final index = entry.key;
              final weight = entry.value;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.monitor_weight, color: Colors.blue),
                  title: Text('${weight.weight.toStringAsFixed(1)} kg'),
                  subtitle: Text(
                    '${weight.date.day}/${weight.date.month}/${weight.date.year}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Modifica',
                        onPressed: () => _editWeight(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Elimina',
                        onPressed: () => _deleteWeight(index),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_weightHistory.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Aggiungi almeno 2 misurazioni per vedere il grafico',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final weights = _weightHistory.map((e) => e.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b) - 1;
    final maxWeight = weights.reduce((a, b) => a > b ? a : b) + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toStringAsFixed(0)} kg',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < _weightHistory.length) {
                        final date = _weightHistory[value.toInt()].date;
                        return Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              minX: 0,
              maxX: (_weightHistory.length - 1).toDouble(),
              minY: minWeight,
              maxY: maxWeight,
              lineBarsData: [
                LineChartBarData(
                  spots: _weightHistory.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.weight);
                  }).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}