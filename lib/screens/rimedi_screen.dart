import 'package:flutter/material.dart';
import '../services/rimedi_service.dart';

class RimediScreen extends StatefulWidget {
  final String group;
  const RimediScreen({super.key, required this.group});

  @override
  State<RimediScreen> createState() => _RimediScreenState();
}

class _RimediScreenState extends State<RimediScreen> {
  List<Map<String, dynamic>> _rimedi = [];
  bool _isLoading = true;
  
  // ← NUOVO: Controller e variabile per la ricerca
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRimedi();
  }

  @override
  void dispose() {
    _searchController.dispose(); // ← Pulizia del controller
    super.dispose();
  }

  Future<void> _loadRimedi() async {
    final data = await RimediService.getRimediByGroup(widget.group);
    if (mounted) {
      setState(() {
        _rimedi = data;
        _isLoading = false;
      });
    }
  }

  // ← NUOVO: Metodo di filtraggio (cerca in nome, forma, proprietà e utilizzo)
  List<Map<String, dynamic>> _filterRimedi() {
    if (_searchQuery.isEmpty) return _rimedi;
    
    final query = _searchQuery.toLowerCase().trim();
    return _rimedi.where((rimedio) {
      final elemento = (rimedio['elemento'] ?? '').toString().toLowerCase();
      final parteForma = (rimedio['parte_forma'] ?? '').toString().toLowerCase();
      final proprieta = (rimedio['proprieta'] ?? '').toString().toLowerCase();
      final utilizzo = (rimedio['utilizzo'] ?? '').toString().toLowerCase();
      
      return elemento.contains(query) || 
             parteForma.contains(query) || 
             proprieta.contains(query) || 
             utilizzo.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(int.parse('0xFF${widget.group == "0" ? "E53935" : widget.group == "A" ? "43A047" : widget.group == "B" ? "1E88E5" : "8E24AA"}'));

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rimedi.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Nessun rimedio naturale specifico trovato per questo gruppo.', textAlign: TextAlign.center),
        ),
      );
    }

    // ← NUOVO: Lista filtrata
    final filteredRimedi = _filterRimedi();

    return Column(
      children: [
        // ← NUOVO: Barra di ricerca (stile identico a quello degli alimenti)
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cerca un rimedio...',
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
                borderSide: BorderSide(color: themeColor.withOpacity(0.3))
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        
        // ← MODIFICATO: Usa la lista filtrata e mostra messaggio se vuota
        Expanded(
          child: filteredRimedi.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Nessun rimedio trovato per "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRimedi.length,
                  itemBuilder: (context, index) {
                    final rimedio = filteredRimedi[index];
                    final elemento = rimedio['elemento'] ?? 'Sconosciuto';
                    final parteForma = rimedio['parte_forma'] ?? '';
                    final proprieta = rimedio['proprieta'] ?? '';
                    final utilizzo = rimedio['utilizzo'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.eco, color: themeColor, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(elemento, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
                                ),
                              ],
                            ),
                            if (parteForma.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Forma: $parteForma', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                            if (proprieta.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Proprietà: $proprieta', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                            ],
                            if (utilizzo.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Utilizzo: $utilizzo', style: const TextStyle(fontSize: 14, color: Colors.black87, fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}