import 'package:permission_handler/permission_handler.dart' as ph;
import 'dart:io';
import 'package:flutter/foundation.dart';

class PermissionsService {
  /// Solicitar permisos de almacenamiento (compatible con Android 6+)
  /// Para Android 13+: solo pide READ_MEDIA_IMAGES si es necesario
  /// Para Android < 13: pide WRITE_EXTERNAL_STORAGE una sola vez
  static Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      if (kDebugMode) {
        print('🔵 [PERMISOS] Solicitando permisos de almacenamiento...');
      }

      ph.PermissionStatus status;

      // Android 13+ (API 33+): Usar READ_MEDIA_IMAGES (más seguro)
      if (await ph.Permission.photos.isDenied) {
        status = await ph.Permission.photos.request();
        if (kDebugMode) {
          print('🟡 [PERMISOS] READ_MEDIA_IMAGES: $status');
        }
      }

      // Android 12 y anteriores: Usar WRITE_EXTERNAL_STORAGE
      if (await ph.Permission.storage.isDenied) {
        status = await ph.Permission.storage.request();
        if (kDebugMode) {
          print('🟡 [PERMISOS] WRITE_EXTERNAL_STORAGE: $status');
        }
      }

      // Verificar si tenemos al menos uno de los permisos
      final photosGranted = await ph.Permission.photos.isGranted;
      final storageGranted = await ph.Permission.storage.isGranted;
      final hasPermission = photosGranted || storageGranted;

      if (kDebugMode) {
        print('✅ [PERMISOS] Estado final:');
        print('   - READ_MEDIA_IMAGES: $photosGranted');
        print('   - WRITE_EXTERNAL_STORAGE: $storageGranted');
        print('   - Permitido: $hasPermission');
      }

      return hasPermission;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PERMISOS] Error solicitando permisos: $e');
      }
      return false;
    }
  }

  /// Verificar si los permisos ya fueron otorgados
  static Future<bool> hasStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      // Verificar si tenemos al menos uno de los permisos necesarios
      final photosGranted = await ph.Permission.photos.isGranted;
      final storageGranted = await ph.Permission.storage.isGranted;

      if (kDebugMode) {
        print('🔍 [PERMISOS] Verificando permisos existentes:');
        print('   - READ_MEDIA_IMAGES: $photosGranted');
        print('   - WRITE_EXTERNAL_STORAGE: $storageGranted');
      }

      return photosGranted || storageGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PERMISOS] Error verificando permisos: $e');
      }
      return false;
    }
  }

  /// Abrir configuración de la app si los permisos fueron denegados
  static Future<void> openAppSettings() async {
    if (kDebugMode) {
      print('🔵 [PERMISOS] Abriendo configuración de la app...');
    }
    await ph.openAppSettings();
  }
}
