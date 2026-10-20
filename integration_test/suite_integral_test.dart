
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:kanbly/main.dart' as app;
import 'package:kanbly/utilerias/formato_util.dart';
import 'package:kanbly/modelo/usuario.dart';

void main() {
IntegrationTestWidgetsFlutterBinding.ensureInitialized();

// Iniciar sesión solo si todavía se muestra el formulario de login.
Future<void> iniciarSesionSiEsNecesario(
WidgetTester tester,
) async {
await tester.pumpAndSettle();

final botonLogin =
find.widgetWithText(ElevatedButton, 'Iniciar Sesión');

if (botonLogin.evaluate().isEmpty) {
// Si no está el botón, comprobar que ya estamos en Mis Tableros.
expect(
find.text('Mis Tableros'),
findsWidgets,
reason: 'No se encontró el login ni la pantalla Mis Tableros.',
);
return;
}

final campos = find.byType(TextFormField);

expect(
campos,
findsNWidgets(2),
reason: 'Se esperaban los campos de correo y contraseña.',
);

await tester.enterText(
campos.at(0),
'1230987@e.uttecamac.edu.mx',
);

// Usa la contraseña real de la cuenta de pruebas de Firebase.
await tester.enterText(
campos.at(1),
'contraseña@123',
);

await tester.testTextInput.receiveAction(
TextInputAction.done,
);

await tester.ensureVisible(botonLogin);
await tester.pumpAndSettle();

await tester.tap(botonLogin);

// Dar tiempo para que Firebase responda.
await tester.pumpAndSettle(
const Duration(seconds: 2),
);

await tester.runAsync(
() => Future<void>.delayed(
const Duration(seconds: 4),
),
);

await tester.pumpAndSettle();

expect(
find.text('Mis Tableros'),
findsWidgets,
reason: 'El inicio de sesión no llevó a Mis Tableros.',
);
}

group('Suite Integral de Pruebas de Integración - Kanbly', () {
// CASO 1: AUTENTICACIÓN
testWidgets(
'Caso 1: Validar rechazo de correo externo y login institucional exitoso',
(WidgetTester tester) async {
await app.main();
await tester.pumpAndSettle();

final botonLogin =
find.widgetWithText(ElevatedButton, 'Iniciar Sesión');

if (botonLogin.evaluate().isNotEmpty) {
final campos = find.byType(TextFormField);

expect(campos, findsNWidgets(2));

await tester.enterText(
campos.at(0),
'estudiante@gmail.com',
);

await tester.enterText(
campos.at(1),
'password123',
);

await tester.testTextInput.receiveAction(
TextInputAction.done,
);

await tester.ensureVisible(botonLogin);
await tester.pumpAndSettle();

await tester.tap(botonLogin);
await tester.pumpAndSettle();

expect(
find.text(
'Solo se permiten correos institucionales @e.uttecamac.edu.mx',
),
findsOneWidget,
);
}

await iniciarSesionSiEsNecesario(tester);

expect(find.text('Mis Tableros'), findsWidgets);
},
);

// CASO 2: CREACIÓN DE TAREA
testWidgets(
'Caso 2: Crear tarea y verificar sincronización en tiempo real en el tablero',
(WidgetTester tester) async {
await app.main();
await tester.pumpAndSettle();

await iniciarSesionSiEsNecesario(tester);

expect(find.text('Mis Tableros'), findsWidgets);

final tarjetaTablero = find.text('Por hacer');

expect(
tarjetaTablero,
findsWidgets,
reason: 'No se encontró una tarjeta con el texto Por hacer.',
);

await tester.tap(tarjetaTablero.first);
await tester.pumpAndSettle(
const Duration(seconds: 3),
);

expect(find.text('POR HACER'), findsWidgets);

final botonAgregar = find.byType(FloatingActionButton);

expect(botonAgregar, findsOneWidget);

await tester.tap(botonAgregar);
await tester.pumpAndSettle();

final campoTitulo =
find.widgetWithText(TextFormField, 'Título de la tarea*');

final campoDesc = find.widgetWithText(
TextFormField,
'Descripción (Opcional)',
);

final botonCrearTarea =
find.widgetWithText(ElevatedButton, 'Crear Tarea');

const tituloPrueba = 'Tarea QA Suite Integral';
const descripcionPrueba =
'Verificando interoperabilidad Firestore -> StreamBuilder';

await tester.enterText(campoTitulo, tituloPrueba);
await tester.enterText(campoDesc, descripcionPrueba);

await tester.testTextInput.receiveAction(
TextInputAction.done,
);

await tester.ensureVisible(botonCrearTarea);
await tester.pumpAndSettle();

await tester.tap(botonCrearTarea);
await tester.pumpAndSettle(
const Duration(seconds: 4),
);

expect(find.text(tituloPrueba), findsWidgets);
expect(find.text(descripcionPrueba), findsWidgets);
},
);

// CASO 3: MENÚ LATERAL Y CREACIÓN DE TABLERO
testWidgets(
'Caso 3: Navegación por menú lateral y creación de tablero individual',
(WidgetTester tester) async {
await app.main();
await tester.pumpAndSettle();

await iniciarSesionSiEsNecesario(tester);

final botonMenu = find.byIcon(Icons.menu);

expect(
botonMenu,
findsOneWidget,
reason: 'No se encontró el icono del menú lateral.',
);

await tester.tap(botonMenu);
await tester.pumpAndSettle();

expect(find.text('Kanbly'), findsWidgets);

final opcionMisTableros = find.text('Mis Tableros').last;

await tester.tap(opcionMisTableros);
await tester.pumpAndSettle();

final botonAgregar = find.byType(FloatingActionButton);

expect(botonAgregar, findsOneWidget);

await tester.tap(botonAgregar);
await tester.pumpAndSettle();

final opcionIndividual = find.text('Tablero Individual');

expect(opcionIndividual, findsOneWidget);

await tester.tap(opcionIndividual);
await tester.pumpAndSettle();

final campoNombre =
find.widgetWithText(TextFormField, 'Ej. Sprint 1...');

const nombreTableroTest = 'Tablero QA Automatizado';

await tester.enterText(
campoNombre,
nombreTableroTest,
);

await tester.testTextInput.receiveAction(
TextInputAction.done,
);

final botonGuardar =
find.widgetWithText(ElevatedButton, 'Crear Tablero');

await tester.ensureVisible(botonGuardar);
await tester.pumpAndSettle();

await tester.tap(botonGuardar);
await tester.pumpAndSettle(
const Duration(seconds: 3),
);

expect(find.text(nombreTableroTest), findsWidgets);
expect(find.text('Individual'), findsWidgets);
},
);

// CASO 4: UTILIDADES Y RENDERIZADO
testWidgets(
'Caso 4: Verificar que FormatoUtil se comunique correctamente sin errores de renderizado',
(WidgetTester tester) async {
// A. Validación lógica de FormatoUtil.
final usuarioPrueba = Usuario(
id: '123',
email: 'test@e.uttecamac.edu.mx',
nombreCompleto: 'Martin Villalobos',
fechaRegistro: DateTime.now(),
);

expect(
FormatoUtil.obtenerIniciales(usuarioPrueba),
'MV',
);

// Los colores deben coincidir con la implementación real.
expect(
FormatoUtil.obtenerColorPorPrioridad(3),
const Color(0xFFE53E3E),
);

expect(
FormatoUtil.obtenerColorPorPrioridad(2),
const Color(0xFFED8936),
);

expect(
FormatoUtil.obtenerColorPorPrioridad(1),
const Color(0xFF38A169),
);

expect(
FormatoUtil.obtenerTextoPrioridad(3),
'Alta',
);

expect(
FormatoUtil.obtenerTextoPrioridad(2),
'Media',
);

expect(
FormatoUtil.obtenerTextoPrioridad(1),
'Baja',
);

// B. Validación básica de la interfaz.
await app.main();
await tester.pumpAndSettle();

await iniciarSesionSiEsNecesario(tester);

expect(find.text('Mis Tableros'), findsWidgets);

final tarjetaTablero = find.text('Por hacer');

expect(tarjetaTablero, findsWidgets);

await tester.tap(tarjetaTablero.first);
await tester.pumpAndSettle(
const Duration(seconds: 4),
);

expect(find.text('POR HACER'), findsWidgets);
expect(find.byType(Container), findsWidgets);
},
);
});
}
