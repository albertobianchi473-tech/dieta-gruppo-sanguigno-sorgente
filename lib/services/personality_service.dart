import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import '../models/personality_trait.dart';

class PersonalityService {
  static final PersonalityService _instance = PersonalityService._internal();
  factory PersonalityService() => _instance;
  PersonalityService._internal();

  List<PersonalityTrait>? _cachedTraits;

  Future<List<PersonalityTrait>> getTraits() async {
    if (_cachedTraits != null) return _cachedTraits!;

    try {
      final ByteData data = await rootBundle.load('assets/Ketsuekigataods.xlsx');
      final List<int> bytes = data.buffer.asUint8List();
      final Excel excel = Excel.decodeBytes(bytes);

      // Cerca il foglio
      Sheet? sheet = excel.tables['Foglio1'] ?? 
                     excel.tables['Sheet1'];
      
      if (sheet == null) {
        final keys = excel.tables.keys.toList();
        if (keys.isNotEmpty) {
          sheet = excel.tables[keys.first];
          print('📄 Usato foglio: ${keys.first}');
        }
      }

      if (sheet == null) {
        print('⚠️ Nessun foglio trovato');
        return [];
      }

      print('📄 Foglio trovato con ${sheet.rows.length} righe');

      final List<PersonalityTrait> traits = [];
      String currentGroup = '';
      String currentKetsuekigata = '';
      String currentAmbienti = '';
      String currentReazione = '';
      String currentForza = '';
      String currentDebolezza = '';
      String currentGestione = '';

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        
        String getVal(int index) => row[index]?.value?.toString().trim() ?? '';

        final groupCell = getVal(0);
        final ketsuekigataCell = getVal(1);
        final ambientiCell = getVal(2);
        final reazioneCell = getVal(3);
        final forzaCell = getVal(4);
        final debolezzaCell = getVal(5);
        final gestioneCell = getVal(6);

        print('Riga $i - Gruppo: "$groupCell"');

        // Se la riga ha un nuovo gruppo, salva il precedente
        if (groupCell.toLowerCase().contains('gruppo')) {
          if (currentGroup.isNotEmpty) {
            traits.add(PersonalityTrait.fromExcelRow(
              group: currentGroup,
              ketsuekigata: currentKetsuekigata,
              ambientiStressogeni: currentAmbienti,
              reazioneStress: currentReazione,
              puntiDiForza: currentForza,
              puntiDiDebolezza: currentDebolezza,
              gestioneStress: currentGestione,
            ));
            print('✅ Aggiunto tratto per gruppo: $currentGroup');
          }

          // Estrai il numero del gruppo
          final groupMatch = RegExp(r'Gruppo\s+(\w+)').firstMatch(groupCell);
          currentGroup = groupMatch?.group(1) ?? '';
          
          currentKetsuekigata = ketsuekigataCell;
          currentAmbienti = ambientiCell;
          currentReazione = reazioneCell;
          currentForza = forzaCell;
          currentDebolezza = debolezzaCell;
          currentGestione = gestioneCell;
        } else {
          // Accumula il testo per celle unite
          if (ketsuekigataCell.isNotEmpty) currentKetsuekigata += ' $ketsuekigataCell';
          if (ambientiCell.isNotEmpty) currentAmbienti += ' $ambientiCell';
          if (reazioneCell.isNotEmpty) currentReazione += ' $reazioneCell';
          if (forzaCell.isNotEmpty) currentForza += ' $forzaCell';
          if (debolezzaCell.isNotEmpty) currentDebolezza += ' $debolezzaCell';
          if (gestioneCell.isNotEmpty) currentGestione += ', $gestioneCell';
        }
      }

      // Salva l'ultimo gruppo
      if (currentGroup.isNotEmpty) {
        traits.add(PersonalityTrait.fromExcelRow(
          group: currentGroup,
          ketsuekigata: currentKetsuekigata,
          ambientiStressogeni: currentAmbienti,
          reazioneStress: currentReazione,
          puntiDiForza: currentForza,
          puntiDiDebolezza: currentDebolezza,
          gestioneStress: currentGestione,
        ));
        print('✅ Aggiunto ultimo tratto per gruppo: $currentGroup');
      }

      _cachedTraits = traits;
      print('✅ Caricati ${traits.length} tratti totali');
      
      // Debug: stampa tutti i gruppi caricati
      for (final trait in traits) {
        print('  - Gruppo: ${trait.group}');
      }
      
      return traits;
    } catch (e, stackTrace) {
      print('❌ Errore: $e');
      print('Stack: $stackTrace');
      return [];
    }
  }

  Future<PersonalityTrait?> getTraitByGroup(String group) async {
    final traits = await getTraits();
    if (traits.isEmpty) {
      print('⚠️ Nessun tratto disponibile');
      return null;
    }
    
    final normalizedGroup = group.trim().toLowerCase();
    print(' Cerco gruppo: "$normalizedGroup"');
    
    // Cerca il gruppo esatto
    for (final trait in traits) {
      print('  - Confronto con: "${trait.group.toLowerCase()}"');
      if (trait.group.toLowerCase() == normalizedGroup) {
        print('✅ Trovato!');
        return trait;
      }
    }
    
    // Fallback: cerca se contiene il gruppo
    for (final trait in traits) {
      if (trait.group.toLowerCase().contains(normalizedGroup)) {
        print('✅ Trovato (contains)!');
        return trait;
      }
    }
    
    print('️ Gruppo non trovato, restituisco il primo');
    return traits.first;
  }

  Future<String?> getDailyTip(String group) async {
    final trait = await getTraitByGroup(group);
    if (trait == null || trait.gestioneStress.isEmpty) {
      print('️ Nessun consiglio disponibile');
      return null;
    }

    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final index = seed % trait.gestioneStress.length;
    
    print(' Consiglio: ${trait.gestioneStress[index]}');
    return trait.gestioneStress[index];
  }
}