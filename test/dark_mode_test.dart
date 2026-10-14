import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanbly/controlador/theme_controller.dart';

void main() {
  group('ThemeProvider - Pruebas de Tema Claro y Oscuro', () {
    test('Inicialmente el tema es Claro por defecto', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.themeString, 'Claro');
      expect(provider.isDarkMode, false);
    });

    test('Cambiar a Tema Oscuro actualiza themeMode e isDarkMode', () {
      final provider = ThemeProvider();
      bool notificado = false;
      provider.addListener(() {
        notificado = true;
      });

      provider.setThemeString('Oscuro');

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.themeString, 'Oscuro');
      expect(provider.isDarkMode, true);
      expect(notificado, true);
    });

    test('Cambiar a Tema Sistema actualiza themeMode a system', () {
      final provider = ThemeProvider();
      provider.setThemeString('Sistema');

      expect(provider.themeMode, ThemeMode.system);
      expect(provider.themeString, 'Sistema');
    });

    test('lightTheme tiene propiedades visuales validas', () {
      final provider = ThemeProvider();
      final theme = provider.lightTheme;

      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFCFDFD));
      expect(theme.cardColor, Colors.white);
      expect(theme.colorScheme.onSurface, const Color(0xFF1E293B));
    });

    test('darkTheme tiene propiedades de modo oscuro validas', () {
      final provider = ThemeProvider();
      final theme = provider.darkTheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF121824));
      expect(theme.cardColor, const Color(0xFF1E2638));
      expect(theme.colorScheme.onSurface, const Color(0xFFE2E8F0));
      expect(theme.bottomSheetTheme.backgroundColor, const Color(0xFF1E2638));
    });
  });
}
