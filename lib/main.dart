import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SecureEbookReaderApp());
}

class SecureEbookReaderApp extends StatelessWidget {
  const SecureEbookReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elimu Pepe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: WelcomeScreen(),
    );
  }
}
