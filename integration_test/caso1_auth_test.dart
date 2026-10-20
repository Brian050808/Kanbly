import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanbly/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Caso 1: Pruebas de Integración de Autenticación', () {
    testWidgets('Validar rechazo de correo no institucional y login exitoso', (WidgetTester tester) async {
      // 1. Levantar la aplicación
      await app.main();
      await tester.pumpAndSettle();
      print('Widgets encontrados:');
      print(tester.widgetList(find.byType(TextFormField)).length);
      debugDumpApp();

      // 2. Localizar los campos de texto
// 2. Localizar los campos de texto y el botón
      final camposTexto = find.byType(TextFormField);

      expect(
        camposTexto,
        findsNWidgets(2),
        reason: 'Se esperaban los campos de correo y contraseña',
      );

      final campoCorreo = camposTexto.at(0);
      final campoPassword = camposTexto.at(1);

      final botonLogin = find.text('Iniciar Sesión');

      // --- PRUEBA A: RECHAZO DE DOMINIO INCORRECTO ---
      await tester.enterText(campoCorreo, 'estudiante@gmail.com');
      await tester.enterText(campoPassword, 'password123');

      // ✅ OCULTAR TECLADO Y HACER SCROLL HASTA EL BOTÓN
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.ensureVisible(botonLogin);
      await tester.pumpAndSettle();

      // Tocar el botón ahora que está visible
      await tester.tap(botonLogin);
      await tester.pumpAndSettle();

      // Validar que el validador impida el paso
      expect(find.text('Solo se permiten correos institucionales @e.uttecamac.edu.mx'), findsOneWidget);

      // --- PRUEBA B: COMUNICACIÓN REAL CON FIREBASE ---
      // Limpiamos y escribimos credenciales REALES
      await tester.enterText(campoCorreo, '1230987@e.uttecamac.edu.mx');

      // ⚠️ IMPORTANTE: REEMPLAZA ESTO POR LA CONTRASEÑA REAL DE ESA CUENTA EN TU FIREBASE
      await tester.enterText(campoPassword, 'contraseña@123');

      // ✅ VOLVEMOS A OCULTAR TECLADO Y ASEGURAR VISIBILIDAD
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.ensureVisible(botonLogin);
      await tester.pumpAndSettle();

      // Tocamos el botón para iniciar sesión
      await tester.tap(botonLogin);

      // ✅ ESPERAMOS LA RESPUESTA ASÍNCRONA DE LA NUBE (6 segundos para evitar latencia)
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Criterio de éxito: Verificar que navegamos exitosamente a la pantalla principal
      expect(find.text('Mis Tableros'), findsWidgets);
    });
  });
}