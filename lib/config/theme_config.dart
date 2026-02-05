import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;
  final String description;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final Color primaryColor;
  final Color accentColor;

  AppTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.lightTheme,
    required this.darkTheme,
    required this.primaryColor,
    required this.accentColor,
  });
}

class ThemeConfig {
  // Colores base para los temas
  static const Map<String, Map<String, Color>> themeColors = {
    'professional': {
      'primary': Color(0xFF1565C0),
      'accent': Color(0xFF424242),
      'background': Color(0xFFF5F5F5),
      'card': Color(0xFFFFFFFF),
      'surface': Color(0xFF42A5F5),
    },
    'slate': {
      'primary': Color(0xFF455A64),
      'accent': Color(0xFF37474F),
      'background': Color(0xFFF5F5F5),
      'card': Color(0xFFFFFFFF),
      'surface': Color(0xFF607D8B),
    },
    'ocean': {
      'primary': Color(0xFF0277BD),
      'accent': Color(0xFF03A9F4),
      'background': Color(0xFFB3E5FC),
      'card': Color(0xFFE1F5FE),
      'surface': Color(0xFF4FC3F7),
    },
    'nature': {
      'primary': Color(0xFF388E3C),
      'accent': Color(0xFF4CAF50),
      'background': Color(0xFFC8E6C9),
      'card': Color(0xFFE8F5E8),
      'surface': Color(0xFF81C784),
    },
    'teal': {
      'primary': Color(0xFF00897B),
      'accent': Color(0xFF004D40),
      'background': Color(0xFFB2DFDB),
      'card': Color(0xFFE0F2F1),
      'surface': Color(0xFF26A69A),
    }
  };

  // Colores funcionales
  static const Color successColor = Color(0xFF66BB6A);
  static const Color errorColor = Color(0xFFEF5350);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color infoColor = Color(0xFF64B5F6);
  static const Color deleteColor = Color(0xFFE57373);
  static const Color editColor = Color(0xFF64B5F6);
  static const Color addColor = Color(0xFFFFB74D);

  // Crear tema claro
  static ThemeData createLightTheme(String themeId) {
    final colors = themeColors[themeId]!;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: _createMaterialColor(colors['primary']!),
      primaryColor: colors['primary']!,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors['primary']!,
        brightness: Brightness.light,
        primary: colors['primary']!,
        secondary: colors['accent']!,
        surface: colors['background']!,
        surfaceContainerHighest: colors['card']!,
      ),
      scaffoldBackgroundColor: colors['background']!,
      cardColor: colors['card']!,
      appBarTheme: AppBarTheme(
        backgroundColor: colors['accent']!,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['primary']!,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors['primary']!,
        selectionColor: colors['primary']!.withValues(alpha: 0.3),
        selectionHandleColor: colors['primary']!,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors['accent']!.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors['primary']!, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors['accent']!.withValues(alpha: 0.3)),
        ),
        fillColor: colors['card']!,
        filled: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors['accent']!,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors['card']!,
      ),
    );
  }

  // Crear tema oscuro
  static ThemeData createDarkTheme(String themeId) {
    final colors = themeColors[themeId]!;
    final darkPrimary = _darkenColor(colors['primary']!, 0.3);
    final darkAccent = _darkenColor(colors['accent']!, 0.2);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: _createMaterialColor(darkPrimary),
      primaryColor: darkPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimary,
        brightness: Brightness.dark,
        primary: darkPrimary,
        secondary: darkAccent,
        surface: Color(0xFF121212),
        surfaceContainerHighest: Color(0xFF1E1E1E),
      ),
      scaffoldBackgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black54,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: darkPrimary,
        selectionColor: darkPrimary.withValues(alpha: 0.3),
        selectionHandleColor: darkPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkAccent.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkPrimary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkAccent.withValues(alpha: 0.3)),
        ),
        fillColor: Color(0xFF2A2A2A),
        filled: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1F1F1F),
        selectedItemColor: darkPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
    );
  }

  // Lista de temas disponibles
  static List<AppTheme> get availableThemes => [
    AppTheme(
      id: 'professional',
      name: 'Profesional Azul',
      description: 'Tema corporativo y profesional con tonos azules, ideal para inventarios',
      lightTheme: createLightTheme('professional'),
      darkTheme: createDarkTheme('professional'),
      primaryColor: themeColors['professional']!['primary']!,
      accentColor: themeColors['professional']!['accent']!,
    ),
    AppTheme(
      id: 'slate',
      name: 'Slate Minimalista',
      description: 'Tema gris-azul minimalista y moderno, muy profesional',
      lightTheme: createLightTheme('slate'),
      darkTheme: createDarkTheme('slate'),
      primaryColor: themeColors['slate']!['primary']!,
      accentColor: themeColors['slate']!['accent']!,
    ),
    AppTheme(
      id: 'ocean',
      name: 'Océano Azul',
      description: 'Tema fresco y profesional con tonos azules del océano',
      lightTheme: createLightTheme('ocean'),
      darkTheme: createDarkTheme('ocean'),
      primaryColor: themeColors['ocean']!['primary']!,
      accentColor: themeColors['ocean']!['accent']!,
    ),
    AppTheme(
      id: 'nature',
      name: 'Naturaleza Verde',
      description: 'Tema natural y relajante con tonos verdes',
      lightTheme: createLightTheme('nature'),
      darkTheme: createDarkTheme('nature'),
      primaryColor: themeColors['nature']!['primary']!,
      accentColor: themeColors['nature']!['accent']!,
    ),
    AppTheme(
      id: 'teal',
      name: 'Teal Empresarial',
      description: 'Tema azul-verde profesional con carácter y presencia',
      lightTheme: createLightTheme('teal'),
      darkTheme: createDarkTheme('teal'),
      primaryColor: themeColors['teal']!['primary']!,
      accentColor: themeColors['teal']!['accent']!,
    ),
  ];

  // Obtener tema por ID
  static AppTheme getThemeById(String id) {
    return availableThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => availableThemes.first,
    );
  }

  // Utilidades privadas
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = (color.r * 255.0).round() & 0xff;
    final int g = (color.g * 255.0).round() & 0xff;
    final int b = (color.b * 255.0).round() & 0xff;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.toARGB32(), swatch);
  }

  static Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDarkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDarkened.toColor();
  }
}
