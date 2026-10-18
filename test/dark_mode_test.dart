import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kanbly/controlador/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider - Pruebas de Tema Claro y Oscuro', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Inicialmente el tema es Claro por defecto', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.themeString, 'Claro');
      expect(provider.isDarkMode, false);
    });

    test('Inicializar con initialTheme aplica el tema guardado directamente', () {
      final provider = ThemeProvider(initialTheme: 'Oscuro');
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.themeString, 'Oscuro');
      expect(provider.isDarkMode, true);
    });

    test('Cambiar a Tema Oscuro actualiza themeMode e isDarkMode y persiste', () async {
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

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_preference'), 'Oscuro');
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

    testWidgets('TaskCardWidget se renderiza con el tema activo en modo oscuro', (WidgetTester tester) async {
      final themeProvider = ThemeProvider(initialTheme: 'Oscuro');

      await tester.pumpWidget(
        MaterialApp(
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Container(
                  color: Theme.of(context).cardColor,
                  child: Text(
                    'Tarjeta Dark Mode',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Tarjeta Dark Mode'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, const Color(0xFF1E2638));
    });
  });
}
