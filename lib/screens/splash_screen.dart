import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Start both timer and initialization in parallel
    final splashTimer = Future.delayed(const Duration(seconds: 6));
    
    // Initialize ebooks while showing splash screen
    try {
      final databaseService = DatabaseService.instance;
      final storageService = StorageService.instance;
      
      // Copy bundled ebooks to storage (only happens first time)
      await storageService.copyBundledEbooksToStorage(databaseService);
      
      // Debug: Check if books were added
      final books = await databaseService.getAllEbooks();
      print('Books loaded: ${books.length}');
    } catch (e) {
      print('Initialization error: $e');
    }

    // Wait for minimum splash time (whichever is longer)
    await splashTimer;

    // Navigate to HomeScreen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36a4da), // Background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 100,
              color: Color(0xFFe85020),
            ),
            const SizedBox(height: 30),
            const Text(
              'Welcome to',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'LoHo Ebook Reader',
              style: TextStyle(
                fontSize: 36,
                color: Color(0xFFe85020), // Text color
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFe85020)),
            ),
          ],
        ),
      ),
    );
  }
}
