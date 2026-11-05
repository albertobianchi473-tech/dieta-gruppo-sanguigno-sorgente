import 'dart:io' show Platform; // 👈 AGGIUNTO per il controllo piattaforma
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 Inizializza AdMob SOLO su Android/iOS (su Windows crasherebbe)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await MobileAds.instance.initialize();
      print('✅ AdMob inizializzato con successo');
    } catch (e) {
      print('⚠️ Errore inizializzazione AdMob: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Il mio gruppo sanguigno',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE53935),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE53935),
        brightness: Brightness.dark,
      ),
      home: const LoadingScreen(),
    );
  }
}