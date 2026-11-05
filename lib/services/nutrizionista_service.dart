import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NutrizionistaInfo {
  final String nome;
  final List<String> titoli;
  final List<String> servizi;
  final String whatsapp;
  final String whatsappMessaggio;
  final String email;
  final String emailOggetto;

  NutrizionistaInfo({
    required this.nome,
    required this.titoli,
    required this.servizi,
    required this.whatsapp,
    required this.whatsappMessaggio,
    required this.email,
    required this.emailOggetto,
  });

  factory NutrizionistaInfo.fromJson(Map<String, dynamic> json) {
    return NutrizionistaInfo(
      nome: json['nome'] ?? 'Giovanna Paoletta',
      titoli: List<String>.from(json['titoli'] ?? []),
      servizi: List<String>.from(json['servizi'] ?? []),
      whatsapp: json['whatsapp'] ?? '39XXXXXXXXXX',
      whatsappMessaggio: json['whatsapp_messaggio'] ?? 'Salve, la contatto dall\'app.',
      email: json['email'] ?? 'paolettag@gmail.com',
      emailOggetto: json['email_oggetto'] ?? 'Richiesta consulenza',
    );
  }
}

Future<NutrizionistaInfo> caricaNutrizionista() async {
  try {
    // URL RAW di GitHub (fondamentale per ottenere il JSON e non la pagina HTML)
    final url = Uri.parse('https://raw.githubusercontent.com/albertobianchi473-tech/dieta_gruppo_sanguigno/main/nutrizionista.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return NutrizionistaInfo.fromJson(data);
    } else {
      debugPrint('⚠️ Errore HTTP caricamento nutrizionista: ${response.statusCode}');
      return _fallback();
    }
  } catch (e) {
    debugPrint('⚠️ Eccezione caricamento nutrizionista: $e');
    return _fallback();
  }
}

// Dati di riserva se GitHub non risponde
NutrizionistaInfo _fallback() {
  return NutrizionistaInfo(
    nome: 'Giovanna Paoletta',
    titoli: const [
      'Laureata in Chimica e Tecnologie Farmaceutiche',
      'Master internazionale in nutrizione e dietetica applicata',
      'Attestato di partecipazione al corso di nutrizione sportiva',
      'Esperienza pluriennale nella nutrizione di adulti e bambini'
    ],
    servizi: const [
      'Piano nutrizionale settimanale personalizzato',
      'Piano nutrizionale per gruppo sanguigno',
      'Elenco degli alimenti per gruppo sanguigno'
    ],
    whatsapp: '39XXXXXXXXXX',
    whatsappMessaggio: 'Salve, la contatto dall\'app Diete Gruppo Sanguigno.',
    email: 'paolettag@gmail.com',
    emailOggetto: 'Richiesta consulenza',
  );
}