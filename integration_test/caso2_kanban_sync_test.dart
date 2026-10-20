
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanbly/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Caso 2: Crear tarea y verificar sincronización en tiempo real en el tablero',
        (WidgetTester tester) async {
      // Iniciar la aplicación.
      await app.main();
      await tester.pumpAndSettle();

      final pantallaTableros = find.text('Mis Tableros');

      // Iniciar sesión si todavía no se muestran los tableros.
      if (pantallaTableros.evaluate().isEmpty) {
        final camposLogin = find.byType(TextFormField);

        expect(
          camposLogin,
          findsNWidgets(2),
          reason: 'No se encontraron los dos campos del inicio de sesión.',
        );

        await tester.enterText(
          camposLogin.at(0),
          '1230987@e.uttecamac.edu.mx',
        );

        await tester.enterText(
          camposLogin.at(1),
          'contraseña@123',
        );

        await tester.pumpAndSettle();

        final botonLogin = find.text('Iniciar Sesión');

        expect(
          botonLogin,
          findsOneWidget,
          reason: 'No se encontró el botón Iniciar Sesión.',
        );

        await tester.ensureVisible(botonLogin);
        await tester.tap(botonLogin);

        // Esperar a que termine la autenticación.
        for (int i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 500));

          if (pantallaTableros.evaluate().isNotEmpty) {
            break;
          }
        }
      }

      // Comprobar el acceso a los tableros.
      expect(
        pantallaTableros,
        findsWidgets,
        reason:
        'No se llegó a Mis Tableros. Comprueba las credenciales y Firebase.',
      );

      // Abrir el tablero.
      final tarjetaTablero = find.text('Por hacer');

      expect(
        tarjetaTablero,
        findsWidgets,
        reason: 'No se encontró un tablero con el texto Por hacer.',
      );

      await tester.tap(tarjetaTablero.first);
      await tester.pumpAndSettle();

// Esperar a que cargue el contenido del tablero.
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();

// Comprobar que se abrió el tablero sin depender
// del nombre exacto de una columna personalizada.
          expect(
            find.byType(FloatingActionButton),
            findsOneWidget,
            reason: 'No se abrió correctamente el tablero o no aparece el botón para agregar tareas.',
          );

      // Abrir el formulario para agregar una tarea.
      final botonAgregar = find.byType(FloatingActionButton);

      expect(
        botonAgregar,
        findsOneWidget,
        reason: 'No se encontró el botón para agregar tareas.',
      );

      await tester.tap(botonAgregar);
      await tester.pumpAndSettle();

      // Localizar los campos del formulario de tarea por posición.
      final camposTarea = find.byType(TextFormField);

      expect(
        camposTarea,
        findsWidgets,
        reason: 'No se encontraron los campos del formulario de tarea.',
      );

      expect(
        camposTarea.evaluate().length,
        greaterThanOrEqualTo(2),
        reason: 'Se necesitan al menos dos campos para la tarea.',
      );

      const tituloPrueba = 'Tarea de Integración Automática';
      const descripcionPrueba =
          'Verificando comunicación Firestore -> StreamBuilder';

      await tester.enterText(
        camposTarea.at(0),
        tituloPrueba,
      );

      await tester.enterText(
        camposTarea.at(1),
        descripcionPrueba,
      );

      // Crear la tarea.
      final botonCrear = find.text('Crear Tarea');

      expect(
        botonCrear,
        findsOneWidget,
        reason: 'No se encontró el botón Crear Tarea.',
      );

      await tester.ensureVisible(botonCrear);
      await tester.pumpAndSettle();
      await tester.tap(botonCrear);

      // Esperar la actualización de la interfaz.
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));

        if (find.text(tituloPrueba).evaluate().isNotEmpty) {
          break;
        }
      }

      // Verificar que la tarea y su descripción aparezcan.
      expect(
        find.text(tituloPrueba),
        findsOneWidget,
        reason: 'La tarea no apareció en el tablero.',
      );

      expect(
        find.text(descripcionPrueba),
        findsOneWidget,
        reason: 'La descripción no apareció en el tablero.',
      );
    },
  );
}
