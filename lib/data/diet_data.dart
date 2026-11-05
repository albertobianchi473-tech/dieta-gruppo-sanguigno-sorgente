import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/blood_group.dart';

class DietData {
  static List<BloodGroupDiet> _diets = [];
  static bool _initialized = false;

  // URL del file Excel su GitHub (assicurati di aver caricato qui la versione a 9 colonne)
  static const String _githubExcelUrl = 
      'https://raw.githubusercontent.com/albertobianchi473-tech/dieta-gruppo-sanguigno-v2/main/diete_gruppo_sanguigno.xlsx';
  
  // Percorso del file locale
  static const String _localExcelPath = 'assets/diete_gruppo_sanguigno.xlsx';

  static Future<void> initialize() async {
    if (_initialized) return;

    List<int> bytes = [];
    bool loadedFromGithub = false;

    // 1️⃣ TENTATIVO DI CARICAMENTO DA GITHUB
    try {
      print('🌐 Tentativo di caricamento Excel da GitHub...');
      final response = await http.get(Uri.parse(_githubExcelUrl)).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        bytes = response.bodyBytes;
        loadedFromGithub = true;
        print('✅ Dati Excel scaricati da GitHub.');
      } else {
        print('⚠️ Errore HTTP GitHub: ${response.statusCode}. Fallback al file locale.');
      }
    } catch (e) {
      print('⚠️ Impossibile connettersi a GitHub ($e). Fallback al file locale.');
    }

    // 2️⃣ FALLBACK AL FILE LOCALE
    if (!loadedFromGithub) {
      print('📱 Caricamento dati dal file locale (assets)...');
      try {
        final ByteData data = await rootBundle.load(_localExcelPath);
        bytes = data.buffer.asUint8List();
        print('✅ Dati Excel caricati dal file locale.');
      } catch (e) {
        print('❌ ERRORE CRITICO: Impossibile caricare il file locale: $e');
        return; 
      }
    }

    // 3️⃣ PARSING DEI DATI EXCEL (Ultra-sicuro)
    try {
      print('🔄 Parsing del file Excel in corso...');
      final Excel excel = Excel.decodeBytes(bytes);

      final List<String> groups = ['0', 'A', 'B', 'AB'];
      final Map<String, String> groupNames = {
        '0': 'Il Cacciatore', 'A': "L'Agricoltore", 'B': 'Il Nomade', 'AB': "L'Enigma",
      };
      final Map<String, String> groupDescriptions = {
        '0': 'Il gruppo più antico. Dieta iperproteica a base di carni magre, pesce e verdure.',
        'A': "Gruppo apparso con l'agricoltura. Dieta prevalentemente vegetariana.",
        'B': 'Gruppo equilibrato e onnivoro. Beneficia di latticini, carne, cereali e verdure.',
        'AB': 'Il gruppo più recente, combinazione di A e B. Dieta mista.',
      };
      final Map<String, String> groupColors = {
        '0': '#E53935', 'A': '#43A047', 'B': '#1E88E5', 'AB': '#8E24AA',
      };

      _diets = [];

      for (String group in groups) {
        final String sheetName = 'Gruppo $group';
        final Sheet? sheet = excel.tables[sheetName];

        if (sheet == null) {
          print('⚠️ Foglio "$sheetName" non trovato nel file Excel');
          continue;
        }

        final List<FoodItem> beneficial = [];
        final List<FoodItem> neutral = [];
        final List<FoodItem> harmful = [];

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row == null) continue;

          // Funzione helper ultra-sicura per leggere le celle
          String? getCellText(int index) {
            if (index < row.length) {
              final cell = row[index];
              if (cell != null && cell.value != null) {
                return cell.value.toString().trim();
              }
            }
            return null;
          }

          // Benefici: Colonna 0 (Nome), 1 (Categoria), 2 (Quando mangiarlo)
          final benName = getCellText(0);
          if (benName != null && benName.isNotEmpty) {
            beneficial.add(FoodItem(
              name: benName,
              category: getCellText(1) ?? 'altro',
              quandoMangiarlo: getCellText(2) ?? '',
              type: FoodCategory.beneficial,
            ));
          }

          // Indifferenti: Colonna 3 (Nome), 4 (Categoria), 5 (Quando mangiarlo)
          final neuName = getCellText(3);
          if (neuName != null && neuName.isNotEmpty) {
            neutral.add(FoodItem(
              name: neuName,
              category: getCellText(4) ?? 'altro',
              quandoMangiarlo: getCellText(5) ?? '',
              type: FoodCategory.neutral,
            ));
          }

          // Da evitare: Colonna 6 (Nome), 7 (Categoria), 8 (Quando mangiarlo)
          final harmName = getCellText(6);
          if (harmName != null && harmName.isNotEmpty) {
            harmful.add(FoodItem(
              name: harmName,
              category: getCellText(7) ?? 'altro',
              quandoMangiarlo: getCellText(8) ?? '',
              type: FoodCategory.harmful,
            ));
          }
        }

        _diets.add(BloodGroupDiet(
          group: group,
          name: groupNames[group]!,
          description: groupDescriptions[group]!,
          color: groupColors[group]!,
          beneficial: beneficial,
          neutral: neutral,
          harmful: harmful,
        ));
      }

      _initialized = true;
      print('✅ Caricati ${_diets.length} gruppi sanguigni con successo!');
    } catch (e, stackTrace) {
      print('❌ ERRORE DURANTE IL PARSING EXCEL: $e');
      print('Stack trace: $stackTrace');
      print('💡 SOLUZIONE: Il file Excel contiene formattazioni, colori o celle unite che il parser Dart non riesce a leggere. Apri il file in Excel, seleziona tutto, fai "Home > Cancella > Cancella tutto", rimuovi le celle unite e salva di nuovo.');
    }
  }

  static List<BloodGroupDiet> get diets {
    if (!_initialized) throw Exception('DietData non inizializzato. Chiama initialize() prima.');
    return _diets;
  }

  static BloodGroupDiet getByGroup(String group) {
    return _diets.firstWhere((d) => d.group == group);
  }
}