import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

class Utils {
  // Detectar si estamos en modo oscuro
  static bool get isDarkMode {
    try {
      final context = Get.context;
      if (context != null) {
        return Theme.of(context).brightness == Brightness.dark;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Colores dinámicos que se obtienen del tema actual
  static Color get defaultColor {
    try {
      final themeController = Get.find<ThemeController>();
      final context = Get.context;
      if (context != null) {
        return Theme.of(context).colorScheme.onSurface;
      }
      return themeController.currentTheme.lightTheme.colorScheme.onSurface;
    } catch (e) {
      return Color(0xFF616161); // fallback
    }
  }

  static Color get colorBotones {
    try {
      final themeController = Get.find<ThemeController>();
      return themeController.currentTheme.primaryColor;
    } catch (e) {
      return Color(0xFFEC407A); // fallback
    }
  }

  static Color get colorFondo {
    try {
      final themeController = Get.find<ThemeController>();
      final context = Get.context;
      if (context != null) {
        return Theme.of(context).colorScheme.surface;
      }
      return themeController.currentTheme.lightTheme.colorScheme.surface;
    } catch (e) {
      return Color(0xFFF8BBD0); // fallback
    }
  }

  static Color get colorFondoCards {
    try {
      final themeController = Get.find<ThemeController>();
      final context = Get.context;
      if (context != null) {
        Color baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
        // En modo oscuro, agregar transparencia para efecto plomo
        if (isDarkMode) {
          return baseColor.withValues(alpha: 0.6);
        }
        return baseColor;
      }
      return themeController.currentTheme.lightTheme.colorScheme.surfaceContainerHighest;
    } catch (e) {
      return Color(0xFFFCE4EC); // fallback
    }
  }

  static Color get colorGnav {
    try {
      final themeController = Get.find<ThemeController>();
      return themeController.currentTheme.accentColor;
    } catch (e) {
      return Color(0xFFF06292); // fallback
    }
  }

  // Color de texto adaptativo para modo claro/oscuro
  static Color get colorTexto {
    try {
      final context = Get.context;
      if (context != null) {
        return Theme.of(context).colorScheme.onSurface;
      }
      return isDarkMode ? Colors.white : Colors.black87;
    } catch (e) {
      return Colors.black87; // fallback
    }
  }

  // Colores funcionales del tema
  static Color get yes {
    try {
      final themeController = Get.find<ThemeController>();
      return themeController.successColor;
    } catch (e) {
      return Color(0xFF66BB6A); // fallback
    }
  }

  static Color get no {
    try {
      final themeController = Get.find<ThemeController>();
      return themeController.errorColor;
    } catch (e) {
      return Color(0xFFEF5350); // fallback
    }
  }

  static Color get edit {
    try {
      final themeController = Get.find<ThemeController>();
      return themeController.editColor;
    } catch (e) {
      return Color(0xFF64B5F6); // fallback
    }
  }

  static Color get add {
    try {
      final themeController = Get.find<ThemeController>();
      return themeController.addColor;
    } catch (e) {
      return Color(0xFFFFB74D); // fallback
    }
  }

  static Color get delete {
    try {
      final themeController = Get.find<ThemeController>();
      return themeController.deleteColor;
    } catch (e) {
      return Color(0xFFE57373); // fallback
    }
  }
  static get espacio05 => const Gap(05.0);
  static get espacio10 => const Gap(10.0);
  static get espacio15 => const Gap(15.0);
  static get espacio20 => const Gap(20.0);
  static get espacio25 => const Gap(25.0);
  static get espacio30 => const Gap(30.0);
  static get espacio35 => const Gap(35.0);
  static get espacio40 => const Gap(40.0);
  static get espacio45 => const Gap(45.0);
  static get espacio50 => const Gap(50.0);
  static get espacio55 => const Gap(55.0);
  static get espacio60 => const Gap(60.0);
  static loadingCustom([double? size]) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitSpinningLines(
              color: Utils.colorBotones,
              size: size ?? 120.0,
            ),
          ],
        ),
      );
  static RichText textLlaveValor(String llave, String valor,
      {Color? color}) {
    color ??= defaultColor;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "$llave: ", // Agrego ":" para mayor claridad
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color, // Usa el color recibido
            ),
          ),
          TextSpan(
            text: valor,
            style: TextStyle(
              fontSize: 12,
              color: color, // Usa el color recibido
            ),
          ),
        ],
      ),
    );
  }

  static RichText textTitle(String llave) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: llave,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Utils.defaultColor,
            ),
          ),
        ],
      ),
    );
  }

  static RichText textDescription(String llave) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: llave,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Utils.defaultColor,
            ),
          ),
        ],
      ),
    );
  }

  static ElevatedButton elevatedButton(
          String txtBoton, Color colorBorde, VoidCallback voidCallback,
          [double tamanioLetra = 14.0]) =>
      ElevatedButton(
        style: estiloBotonRedondeado(colorBorde),
        onPressed: voidCallback,
        child: setText(txtBoton, tamanioLetra, true),
      );
  static ElevatedButton elevatedButtonWithIcon(String txtboton,
          Color colorBorde, VoidCallback voidCallback, IconData iconData,
          [double tamanioLetra = 14.0]) =>
      ElevatedButton.icon(
        style: estiloBotonRedondeado(colorBorde),
        onPressed: voidCallback,
        icon: Icon(iconData, color: Colors.white, size: 25),
        label: setText(txtboton, tamanioLetra, true),
      );

  static ButtonStyle estiloBotonRedondeado(
    Color color,
  ) =>
      ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color,
        disabledForegroundColor: color,
        shadowColor: Utils.defaultColor,
        elevation: 5,
        //minimumSize: Size(30.0, 30.0),
        animationDuration: const Duration(milliseconds: 1),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
        //side: BorderSide(color: color, width: 2.0)
      );
  static Text setText(String txt, double tamanio, fontWeight, [bool? center]) {
    double tamanioTexto = 12;
    return Text(txt,
        textAlign: TextAlign.center,
        style: Get.textTheme.bodyMedium!.copyWith(
          fontSize: tamanioTexto,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ));
  }

  static RichText bigTextLlaveValor(String llave, String valor,
      {Color? color}) {
    color ??= defaultColor;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: llave,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          TextSpan(
            text: valor,
            style: TextStyle(fontSize: 18, color: color),
          ),
        ],
      ),
    );
  }

  static Future<bool> showConfirmationDialog(
      BuildContext context, String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: colorFondoCards,
              title: Text(
                title,
                style: TextStyle(color: defaultColor),
              ),
              content: Text(
                content,
                style: TextStyle(color: defaultColor),
              ),
              actions: <Widget>[
                elevatedButton('Cancelar', no, () {
                  Navigator.of(context).pop(false);
                }),
                elevatedButton('Eliminar', yes, () {
                  Navigator.of(context).pop(true);
                }),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<DateTime?> showCustomDatePicker(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: isDarkMode ? ThemeData.dark().copyWith(
            primaryColor: Utils.colorBotones,
            colorScheme: ColorScheme.dark(
                primary: Utils.colorBotones, secondary: Utils.colorGnav),
            textTheme: TextTheme(
              headlineMedium: TextStyle(color: Utils.colorTexto),
              bodyMedium: TextStyle(color: Utils.colorTexto),
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ), dialogTheme: DialogThemeData(backgroundColor: Utils.colorFondo),
          ) : ThemeData.light().copyWith(
            primaryColor: Utils.colorBotones,
            colorScheme: ColorScheme.light(
                primary: Utils.colorBotones, secondary: Utils.colorGnav),
            textTheme: TextTheme(
              headlineMedium: TextStyle(color: Utils.colorTexto),
              bodyMedium: TextStyle(color: Utils.colorTexto),
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ), dialogTheme: DialogThemeData(backgroundColor: Utils.colorFondo),
          ),
          child: child!,
        );
      },
    );
  }

  // Diálogo profesional para seleccionar fuente de imagen (Cámara o Galería)
  static Future<void> showImageSourceDialog(
    BuildContext context, {
    required Function(dynamic) onImageSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            
            // Título
            Text(
              'Seleccionar imagen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 24),
            
            // Opciones
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildImageSourceOption(
                      context: context,
                      icon: Icons.camera_alt_rounded,
                      label: 'Cámara',
                      color: Colors.blue,
                      onTap: () async {
                        Navigator.pop(context);
                        await onImageSelected('camera');
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildImageSourceOption(
                      context: context,
                      icon: Icons.photo_library_rounded,
                      label: 'Galería',
                      color: Colors.purple,
                      onTap: () async {
                        Navigator.pop(context);
                        await onImageSelected('gallery');
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildImageSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para formatear hora en formato de 12 horas
  static String formatTime12Hour(DateTime dateTime) {
    int hour = dateTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    
    // Convertir hora de 24h a 12h
    if (hour == 0) {
      hour = 12; // Medianoche
    } else if (hour > 12) {
      hour = hour - 12; // Tarde
    }
    
    return '${hour.toString()}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  // ============= SNACKBARS REUTILIZABLES =============
  
  /// Mostrar snackbar de éxito con estilo consistente
  static void showSuccessSnackbar(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      '✅ $title',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: yes, // Color verde del tema
      colorText: Colors.white,
      duration: duration,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      boxShadows: [
        BoxShadow(
          color: yes.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Mostrar snackbar de error con estilo consistente
  static void showErrorSnackbar(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      '❌ $title',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: no, // Color rojo del tema
      colorText: Colors.white,
      duration: duration,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      boxShadows: [
        BoxShadow(
          color: no.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Mostrar snackbar de información con estilo consistente
  static void showInfoSnackbar(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      'ℹ️ $title',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: edit, // Color azul del tema
      colorText: Colors.white,
      duration: duration,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      boxShadows: [
        BoxShadow(
          color: edit.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Mostrar snackbar de advertencia con estilo consistente
  static void showWarningSnackbar(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      '⚠️ $title',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: delete, // Color naranja/rojo del tema
      colorText: Colors.white,
      duration: duration,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      boxShadows: [
        BoxShadow(
          color: delete.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  
}
