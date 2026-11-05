import 'dart:io';

class AdHelper {
  // Banner REALE per Android
  static String get bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-7044770884396100/7168338645';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return '';
  }

  // Interstitial (opzionale, per dopo)
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }
}