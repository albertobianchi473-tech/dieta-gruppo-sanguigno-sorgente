import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/diet_data.dart';
import '../models/blood_group.dart';
import '../services/personality_service.dart';
import 'diet_screen.dart';
import 'profile_screen.dart';
import 'recipes_screen.dart';
import 'personality_screen.dart';
import 'nutrizionista_page.dart';
import 'favorites_screen.dart';
import '../widgets/ad_banner.dart';

class HomeScreen extends StatefulWidget {
  final String? initialGroup;
  const HomeScreen({super.key, this.initialGroup});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String? _selectedGroup;
  String? _dailyTip;

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.initialGroup;
    WidgetsBinding.instance.addObserver(this);
    _loadGroupAndTip();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadGroupAndTip();
    }
  }

  Future<void> _loadGroupAndTip() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGroup = prefs.getString('bloodGroup');
    if (mounted) {
      setState(() {
        _selectedGroup = savedGroup ?? widget.initialGroup;
      });
      _loadDailyTip();
    }
  }

  Future<void> _saveGroup(String group) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bloodGroup', group);
  }

  void _selectGroup(String group) {
    setState(() => _selectedGroup = group);
    _saveGroup(group);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DietScreen(diet: DietData.getByGroup(group))),
    );
  }

  void _openRecipes(String group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecipesScreen(selectedGroup: group)),
    );
  }

  Future<void> _exitApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uscire dall\'app?'),
        content: const Text('Sei sicuro di voler chiudere l\'applicazione?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Esci')),
        ],
      ),
    );
    if (confirm == true) SystemNavigator.pop();
  }

  Future<void> _loadDailyTip() async {
    if (_selectedGroup == null) return;
    final tip = await PersonalityService().getDailyTip(_selectedGroup!);
    if (mounted) setState(() => _dailyTip = tip);
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF26A69A).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.info_outline_rounded, color: Color(0xFF26A69A), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Informazioni importanti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF00695C)))),
                  IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ],
              ),
              const Divider(height: 24, thickness: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Si consiglia di attenersi alle razioni giornaliere indicate dalla CREA, WHO e Harvard T.H. Chan School of Public Health.', style: TextStyle(fontSize: 13, color: Color(0xFF546E7A), height: 1.5)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFB74D), width: 1)),
                        child: const Row(
                          children: [
                            Icon(Icons.medical_services_rounded, color: Color(0xFFFF8F00), size: 20),
                            SizedBox(width: 8),
                            Expanded(child: Text('L\'autore non si assume la responsabilità di eventuali effetti indesiderati...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100), height: 1.4))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26A69A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Ho capito', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) { if (!didPop) _exitApp(); },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 50,
          title: const Text('Il mio gruppo sanguigno', style: TextStyle(color: Color(0xFF00695C), fontSize: 17, fontWeight: FontWeight.w700)),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.psychology, color: Color(0xFF00695C), size: 22), tooltip: 'Personalità', onPressed: _selectedGroup != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => PersonalityScreen(group: _selectedGroup!))) : null),
            IconButton(icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF00695C), size: 22), tooltip: 'Informazioni', onPressed: _showInfoDialog),
            IconButton(icon: const Icon(Icons.contact_mail, color: Color(0xFF00695C), size: 22), tooltip: 'Contatta la Nutrizionista', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NutrizionistaPage()))),
            IconButton(icon: const Icon(Icons.person_rounded, color: Color(0xFF00695C), size: 22), tooltip: 'Profilo', onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); _loadGroupAndTip(); }),
            IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFF00695C), size: 22), tooltip: 'Esci', onPressed: _exitApp),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 85, height: 85,
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFE53935).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))]),
                child: ClipOval(child: Image.asset('assets/images/blood_drop_icon.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE53935), child: const Icon(Icons.bloodtype, color: Colors.white, size: 40)))),
              ),
              const SizedBox(height: 10),
              const Text('La tua dieta\npersonalizzata', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF00897B), letterSpacing: -0.5, height: 1.05)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 18, height: 2.5, decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 5), Container(width: 2.5, height: 2.5, decoration: const BoxDecoration(color: Color(0xFF43A047), shape: BoxShape.circle)), const SizedBox(width: 5), Container(width: 18, height: 2.5, decoration: BoxDecoration(color: const Color(0xFF26A69A), borderRadius: BorderRadius.circular(2)))]),
              const SizedBox(height: 10),
              const Text('Scopri gli alimenti benefici, indifferenti\ne sconsigliati per il tuo gruppo sanguigno.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF546E7A), height: 1.3)),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFB2DFDB).withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Text('📚 Dal libro "La vera dieta del gruppo sanguigno" - dr. Peter D\'Adamo', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF00897B)))),
              const SizedBox(height: 14),
              if (_dailyTip != null) Container(margin: const EdgeInsets.only(bottom: 14), width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5), width: 1.5), boxShadow: [BoxShadow(color: const Color(0xFFFFB74D).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFFF8F00), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.lightbulb, color: Colors.white, size: 16)), const SizedBox(width: 10), Expanded(child: Text('Consiglio del giorno per il Gruppo ${_selectedGroup}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE65100)))), Icon(Icons.auto_awesome, color: const Color(0xFFFF8F00).withOpacity(0.6), size: 16)]), const SizedBox(height: 10), Text('💡 $_dailyTip', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4E342E), height: 1.4))])),
              
              GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.80, children: DietData.diets.map(_buildGroupCard).toList()),
              
              const SizedBox(height: 12),
              
              // PULSANTE PREFERITI
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
                  title: const Text('I miei Preferiti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                  subtitle: const Text('Visualizza la lista degli alimenti salvati', style: TextStyle(color: Colors.redAccent)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE0F7FA), Color(0xFFE8F5E9)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF26A69A).withOpacity(0.3), width: 1.2)), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: const Color(0xFF26A69A), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.info_rounded, color: Colors.white, size: 14)), const SizedBox(width: 8), Expanded(child: Text('I contenuti della App sono a scopo informativo e non sostituiscono il parere medico.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF546E7A), height: 1.2)))])),
              
              // Spazio extra per evitare che il banner copra il disclaimer
              const SizedBox(height: 60),
            ],
          ),
        ),
        bottomNavigationBar: const AdBanner(), // ← BANNER PUBBLICITARIO
      ),
    );
  }

  Widget _buildGroupCard(BloodGroupDiet diet) {
    final color = Color(int.parse('0xFF${diet.color.substring(1)}'));
    final isSelected = _selectedGroup == diet.group;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelected ? color : const Color(0xFFE0E0E0), width: isSelected ? 2 : 1), boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Material(color: Colors.transparent, child: InkWell(onTap: () => _selectGroup(diet.group), borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(Icons.water_drop_rounded, color: color, size: 24)), const SizedBox(height: 8), Text(diet.group, style: const TextStyle(color: Color(0xFF2D3436), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)), const SizedBox(height: 4), Text(diet.name, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis)]), const SizedBox(height: 8), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _openRecipes(diet.group), icon: const Icon(Icons.restaurant_menu, size: 14), label: const Text('Ricette', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0)))])))),
    );
  }
}