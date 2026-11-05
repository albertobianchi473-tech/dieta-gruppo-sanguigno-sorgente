import 'package:flutter/material.dart';
import '../models/personality_trait.dart';
import '../services/personality_service.dart';

class PersonalityScreen extends StatefulWidget {
  final String group;
  const PersonalityScreen({super.key, required this.group});

  @override
  State<PersonalityScreen> createState() => _PersonalityScreenState();
}

class _PersonalityScreenState extends State<PersonalityScreen> {
  PersonalityTrait? _trait;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrait();
  }

  Future<void> _loadTrait() async {
    try {
      final trait = await PersonalityService().getTraitByGroup(widget.group);
      setState(() {
        _trait = trait;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Errore nel caricamento: $e';
        _loading = false;
      });
    }
  }

  Color _getGroupColor() {
    switch (widget.group) {
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
        title: Text('Personalità Gruppo ${widget.group}'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: themeColor))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadTrait,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Riprova'),
                      ),
                    ],
                  ),
                )
              : _trait == null
                  ? Center(
                      child: Text(
                        'Nessun dato disponibile per il gruppo ${widget.group}',
                        style: TextStyle(color: themeColor, fontSize: 16),
                      ),
                    )
                  : _buildContent(themeColor),
    );
  }

  Widget _buildContent(Color themeColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER CON PERSONALITÀ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor, themeColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎭 Ketsuekigata',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _trait!.ketsuekigata,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AMBIENTI STRESSOGENI
          _buildInfoCard(
            icon: Icons.warning_amber_rounded,
            title: 'Ambienti stressogeni',
            content: _trait!.ambientiStressogeni,
            color: Colors.orange,
            themeColor: themeColor,
          ),
          const SizedBox(height: 12),

          // REAZIONE ALLO STRESS
          _buildInfoCard(
            icon: Icons.psychology,
            title: 'Reazione allo stress',
            content: _trait!.reazioneStress,
            color: Colors.red,
            themeColor: themeColor,
          ),
          const SizedBox(height: 12),

          // PUNTI DI FORZA
          _buildInfoCard(
            icon: Icons.emoji_events,
            title: 'Punti di forza',
            content: _trait!.puntiDiForza,
            color: Colors.green,
            themeColor: themeColor,
          ),
          const SizedBox(height: 12),

          // PUNTI DI DEBOLEZZA
          _buildInfoCard(
            icon: Icons.trending_down,
            title: 'Punti di debolezza',
            content: _trait!.puntiDiDebolezza,
            color: Colors.redAccent,
            themeColor: themeColor,
          ),
          const SizedBox(height: 20),

          // GESTIONE DELLO STRESS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.self_improvement,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Gestione dello stress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _trait!.gestioneStress.map((activity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: themeColor.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: themeColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            activity,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required Color themeColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF546E7A),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}