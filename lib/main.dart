import 'screens/welcome_screen.dart';
import 'package:flutter/material.dart';

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
