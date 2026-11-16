
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:login_bear_animation/screens/login_screen.dart';

import 'firebase_options.dart';

Future<void> main() async {
  // Preparar Flutter antes de inicializar Firebase
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('✅ Firebase inicializado correctamente');

    // Abrir la aplicación cuando Firebase esté listo
    runApp(const MyApp());
  } catch (e) {
    debugPrint('❌ Error al inicializar Firebase: $e');

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'No se pudo inicializar Firebase.\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rive Animated Login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
