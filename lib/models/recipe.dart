class Recipe {
  final String gruppo;
  final String nome;
  final String tempo;
  final String difficolta;
  final String ingredientiDisplay;
  final List<String> ingredientiMatching;
  final String preparazione;

  Recipe({
    required this.gruppo,
    required this.nome,
    required this.tempo,
    required this.difficolta,
    required this.ingredientiDisplay,
    required this.ingredientiMatching,
    required this.preparazione,
  });

  factory Recipe.fromExcelRow({
    required String gruppo,
    required String nome,
    required String tempo,
    required String difficolta,
    required String ingredientiDisplay,
    required String ingredientiMatching,
    required String preparazione,
  }) {
    // ✅ Dividi sia per virgola che per punto e virgola
    final List<String> parsedMatching = ingredientiMatching
        .split(RegExp(r'[,;]+'))  // ← Regex per entrambi i separatori
        .map((e) => e.toLowerCase().trim())
        .where((e) => e.isNotEmpty && e.length > 2)
        .toList();

    return Recipe(
      gruppo: gruppo.trim(),
      nome: nome.trim(),
      tempo: tempo.trim(),
      difficolta: difficolta.trim(),
      ingredientiDisplay: ingredientiDisplay.trim(),
      ingredientiMatching: parsedMatching,
      preparazione: preparazione.trim(),
    );
  }
}