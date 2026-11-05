import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class RimediService {
  static const String _url = 'https://raw.githubusercontent.com/albertobianchi473-tech/dieta_gruppo_sanguigno/main/rimedi.json';

  static Future<List<Map<String, dynamic>>> getRimediByGroup(String group) async {
    try {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Filtra solo i rimedi del gruppo sanguigno selezionato
        return data
            .where((item) => item['gruppo'].toString().trim() == group)
            .toList()
            .cast<Map<String, dynamic>>();
      } else {
        debugPrint('⚠️ Errore HTTP caricamento rimedi: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Eccezione caricamento rimedi: $e');
    }
    return [];
  }
}