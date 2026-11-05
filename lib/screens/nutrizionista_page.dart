import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/nutrizionista_service.dart';

class NutrizionistaPage extends StatefulWidget {
  const NutrizionistaPage({super.key});

  @override
  State<NutrizionistaPage> createState() => _NutrizionistaPageState();
}

class _NutrizionistaPageState extends State<NutrizionistaPage> {
  NutrizionistaInfo? _info;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    final info = await caricaNutrizionista();
    if (mounted) {
      setState(() {
        _info = info;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _info == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contatta la Consulente Nutrizionista'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _info!.nome,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Qualifiche', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._info!.titoli.map((titolo) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.school, size: 22, color: Colors.teal),
                      const SizedBox(width: 12),
                      Expanded(child: Text(titolo, style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                )),
            
            const SizedBox(height: 28),
            const Text('Servizi offerti', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._info!.servizi.map((servizio) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.teal, size: 28),
                    title: Text(servizio, style: const TextStyle(fontSize: 16)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                )),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _apriWhatsApp(_info!.whatsapp, _info!.whatsappMessaggio),
                icon: const Icon(Icons.message, size: 24),
                label: const Text('Scrivi su WhatsApp', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _apriEmail(_info!.email, _info!.emailOggetto),
                icon: const Icon(Icons.email, size: 24),
                label: const Text('Invia una Email', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _apriWhatsApp(String numero, String messaggio) async {
    final url = Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(messaggio)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _apriEmail(String email, String oggetto) async {
    final url = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(oggetto)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}