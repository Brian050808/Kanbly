import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'theme_preference';

  ThemeMode _themeMode = ThemeMode.light;
  String _themeString = 'Claro';

  ThemeProvider({String? initialTheme}) {
    if (initialTheme != null) {
      _aplicarTemaSinNotificar(initialTheme);
    } else {
      _cargarTemaGuardado();
    }
  }

  ThemeMode get themeMode => _themeMode;
  String get themeString => _themeString;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _aplicarTemaSinNotificar(String modeStr) {
    _themeString = modeStr;
    switch (modeStr) {
      case 'Oscuro':
        _themeMode = ThemeMode.dark;
        break;
      case 'Sistema':
        _themeMode = ThemeMode.system;
        break;
      case 'Claro':
      default:
        _themeMode = ThemeMode.light;
        break;
    }
  }

  Future<void> _cargarTemaGuardado() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_prefKey);
      if (savedTheme != null) {
        _aplicarTemaSinNotificar(savedTheme);
        notifyListeners();
      }
    } catch (_) {}
  }

  void setThemeString(String modeStr) {
    _aplicarTemaSinNotificar(modeStr);
    notifyListeners();
    _guardarTema(modeStr);
  }

  Future<void> _guardarTema(String modeStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, modeStr);
    } catch (_) {}
  }

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF52ABEB),
      scaffoldBackgroundColor: const Color(0xFFFCFDFD),
      cardColor: Colors.white,
      canvasColor: const Color(0xFFFCFDFD),
      dividerColor: const Color(0xFFE2E8F0),
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF52ABEB),
        secondary: Color(0xFF63D0A1),
        surface: Colors.white,
        onSurface: Color(0xFF1E293B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFCFDFD),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF37B5F4)),
        titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFFFCFDFD),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF52ABEB),
      scaffoldBackgroundColor: const Color(0xFF121824),
      cardColor: const Color(0xFF1E2638),
      canvasColor: const Color(0xFF1E2638),
      dividerColor: const Color(0xFF2D3748),
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF52ABEB),
        secondary: Color(0xFF63D0A1),
        surface: Color(0xFF1E2638),
        onSurface: Color(0xFFE2E8F0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121824),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF37B5F4)),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E2638),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E2638),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1E2638),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2D3748),
      ),
    );
  }
}
