import 'package:flutter/material.dart';
import '../services/file_downloader_service.dart';
import '../data/diet_data.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _message = 'Connessione al server...';
  double _progress = 0.1;
  bool _hasError = false;
  String? _errorMessage;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _message = 'Verifica aggiornamenti...';
        _progress = 0.05;
      });

      // 1. Scarica/aggiorna i file da GitHub
      final results = await FileDownloaderService().downloadAllFiles(
        onProgress: (fileName, status) {
          setState(() {
            _message = '$fileName: $status';
            if (fileName != 'Dati') {
              _isUpdating = true;
            }
          });
        },
      );

      final hasError = results.values.any((r) => r == false);
      
      if (hasError && results.keys.every((k) => k != 'status')) {
        // Se tutti i download falliscono, mostra errore
        throw Exception('Impossibile scaricare i file. Controlla la connessione.');
      }

      setState(() {
        _message = 'Elaborazione dati...';
        _progress = 0.8;
      });

      // 2. Inizializza i dati delle diete
      await DietData.initialize();

      setState(() {
        _message = 'Pronto!';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00897B), Color(0xFF26A69A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: _hasError
              ? _buildErrorView()
              : _buildLoadingView(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isUpdating ? Icons.cloud_download : Icons.bloodtype,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Il mio gruppo sanguigno',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isUpdating ? 'Aggiornamento in corso...' : 'Caricamento dati...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 40),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Text(
            _message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.white),
          const SizedBox(height: 24),
          const Text(
            'Errore di connessione',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Impossibile scaricare i dati',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = null;
                _isUpdating = false;
              });
              _initializeApp();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00897B),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}