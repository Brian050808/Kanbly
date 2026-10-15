import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controlador/auth_controller.dart';
import 'controlador/theme_controller.dart';
import 'Vistas/login_view.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'servicios/notificacion_vencimiento_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar formateo de fechas local
  await initializeDateFormatting();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  await NotificacionVencimientoService.inicializar();

  // Cargar preferencia de tema guardada antes de iniciar la app
  String? temaInicial;
  try {
    final prefs = await SharedPreferences.getInstance();
    temaInicial = prefs.getString('theme_preference');
  } catch (_) {}

  runApp(MyApp(temaInicial: temaInicial));
}

class MyApp extends StatelessWidget {
  final String? temaInicial;

  const MyApp({super.key, this.temaInicial});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthController()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(initialTheme: temaInicial),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Kanbly',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', 'ES'),
              Locale('es'),
              Locale('en', 'US'),
              Locale('en'),
            ],
            home: const LoginView(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
