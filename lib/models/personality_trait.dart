class PersonalityTrait {
  final String group;
  final String ketsuekigata; // Personalità
  final String ambientiStressogeni;
  final String reazioneStress;
  final String puntiDiForza;
  final String puntiDiDebolezza;
  final List<String> gestioneStress; // Lista di attività

  PersonalityTrait({
    required this.group,
    required this.ketsuekigata,
    required this.ambientiStressogeni,
    required this.reazioneStress,
    required this.puntiDiForza,
    required this.puntiDiDebolezza,
    required this.gestioneStress,
  });

  factory PersonalityTrait.fromExcelRow({
    required String group,
    required String ketsuekigata,
    required String ambientiStressogeni,
    required String reazioneStress,
    required String puntiDiForza,
    required String puntiDiDebolezza,
    required String gestioneStress,
  }) {
    // Separa le attività per virgola, newline o punto e virgola
    final List<String> parsedActivities = gestioneStress
        .split(RegExp(r'[,\n;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.length > 2)
        .toList();

    return PersonalityTrait(
      group: group.trim(),
      ketsuekigata: ketsuekigata.trim(),
      ambientiStressogeni: ambientiStressogeni.trim(),
      reazioneStress: reazioneStress.trim(),
      puntiDiForza: puntiDiForza.trim(),
      puntiDiDebolezza: puntiDiDebolezza.trim(),
      gestioneStress: parsedActivities,
    );
  }
}