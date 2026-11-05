import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileDownloaderService {
  static final FileDownloaderService _instance = FileDownloaderService._internal();
  factory FileDownloaderService() => _instance;
  FileDownloaderService._internal();

  final Map<String, String> _remoteFiles = {
    'diete_gruppo_sanguigno.xlsx': 
        'https://raw.githubusercontent.com/albertobianchi473-tech/dieta_gruppo_sanguigno/main/diete_gruppo_sanguigno.xlsx',
    'ricette.json': 
        'https://raw.githubusercontent.com/albertobianchi473-tech/dieta_gruppo_sanguigno/main/ricette.json',
    'Ketsuekigataods.xlsx': 
        'https://raw.githubusercontent.com/albertobianchi473-tech/dieta_gruppo_sanguigno/main/Ketsuekigataods.xlsx',
  };

  final String _versionUrl = 
      'https://raw.githubusercontent.com/albertobianchi473-tech/dieta_gruppo_sanguigno/main/version.txt';

  Future<Directory> _getLocalDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${appDir.path}/diet_data');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir;
  }

  Future<String> getLocalFilePath(String fileName) async {
    final dir = await _getLocalDir();
    return '${dir.path}/$fileName';
  }

  Future<String?> _getLocalVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dataVersion');
  }

  Future<void> _setLocalVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dataVersion', version);
  }

  Future<String?> _getRemoteVersion() async {
    try {
      final url = Uri.parse('$_versionUrl?v=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return response.body.trim();
      }
      return null;
    } catch (e) {
      print('❌ Errore controllo versione: $e');
      return null;
    }
  }

  Future<bool> _needsUpdate() async {
    final localVersion = await _getLocalVersion();
    final remoteVersion = await _getRemoteVersion();
    
    print('📊 Versione locale: $localVersion');
    print('📊 Versione remota: $remoteVersion');
    
    if (localVersion == null || localVersion.isEmpty) {
      print('🔄 Primo avvio, download forzato');
      return true;
    }
    
    if (remoteVersion == null) {
      print('⚠️ Impossibile ottenere versione remota');
      return false;
    }
    
    return remoteVersion != localVersion;
  }

  Future<bool> downloadFile(String fileName) async {
    final url = _remoteFiles[fileName];
    if (url == null) return false;

    try {
      print('🌐 Download: $fileName');
      
      final urlWithCache = Uri.parse('$url?v=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(urlWithCache);

      if (response.statusCode != 200) {
        print('❌ Errore HTTP ${response.statusCode} per $fileName');
        return false;
      }

      final path = await getLocalFilePath(fileName);
      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);

      print('✅ Salvato: $fileName (${response.bodyBytes.length} bytes)');
      return true;
    } catch (e) {
      print('❌ Eccezione download $fileName: $e');
      return false;
    }
  }

  Future<Map<String, bool>> downloadAllFiles({
    void Function(String fileName, String status)? onProgress,
  }) async {
    final results = <String, bool>{};
    
    final needsUpdate = await _needsUpdate();
    
    if (!needsUpdate) {
      print('✅ Dati già aggiornati');
      onProgress?.call('Dati', 'Aggiornati ✓');
      return {'status': true};
    }

    print('🔄 Nuova versione disponibile, download in corso...');
    
    int current = 0;
    final total = _remoteFiles.length;

    for (final entry in _remoteFiles.entries) {
      current++;
      onProgress?.call(entry.key, 'Download $current/$total...');
      
      final success = await downloadFile(entry.key);
      results[entry.key] = success;
      
      onProgress?.call(entry.key, success ? 'Completato ✓' : 'Errore ✗');
    }

    final allSuccess = results.values.every((s) => s);
    if (allSuccess) {
      final remoteVersion = await _getRemoteVersion();
      if (remoteVersion != null) {
        await _setLocalVersion(remoteVersion);
        print('✅ Versione salvata: $remoteVersion');
      }
    }

    return results;
  }
}