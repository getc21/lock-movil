import 'dart:io';

class ApiConfig {
  // URL DE PRODUCCION - Render
  static const String _productionUrl = 'https://api.naturalmarkets.net';

  // Desarrollo Local
  //static const String _localIP = '192.168.0.48';
  //static const String _emulatorIP = '10.0.2.2';
  //static const String _port = '3000';

  static String get baseUrl {
    // DESARROLLO LOCAL - Usar backend local
    // Para Android Emulator: http://10.0.2.2:3000/api
    // Para dispositivo físico: http://[TU_IP_LOCAL]:3000/api
    // Para Flutter Web: http://localhost:3000/api
    
    // Descomentar según tu caso:
    return 'http://10.0.2.2:3000/api'; // Android Emulator
    // return 'http://192.168.0.48:3000/api'; // Dispositivo físico (cambia IP según tu red)
    // return 'http://localhost:3000/api'; // Flutter Web
    
    // PRODUCCION - Comentar para desarrollo
    // return _productionUrl;
  }

  // Detecta si estamos en un emulador
  // static bool _isEmulator() {
  //   if (Platform.isAndroid) {
  //     final String? androidHome = Platform.environment['ANDROID_HOME'];
  //     final String? isEmulator = Platform.environment['ANDROID_EMULATOR'];
  //     final bool isGenymotion = Platform.environment['USER']?.contains('genymotion') ?? false;

  //     return isEmulator == 'true' || 
  //            androidHome != null || 
  //            isGenymotion;
  //   }

  //   if (Platform.isIOS) {
  //     return Platform.environment['SIMULATOR_DEVICE_NAME'] != null ||
  //            Platform.environment['SIMULATOR_ROOT'] != null;
  //   }

  //   return false;
  // }

  // Metodo para cambiar manualmente la configuracion
  static String getUrlForMode({required bool useProduction}) {
    if (useProduction) {
      return _productionUrl;
    } else {
      // Para desarrollo local
      return 'http://192.168.0.48:3000/api';
    }
  }

  // Informacion de debug
  static Map<String, dynamic> getDebugInfo() {
    return <String, dynamic>{
      'baseUrl': baseUrl,
      'isProduction': baseUrl == _productionUrl,
      'productionUrl': _productionUrl,
      'platform': Platform.operatingSystem,
    };
  }
}
