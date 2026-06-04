import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../theme_manager.dart';

class OnboardingScreen extends StatefulWidget {
  final ThemeManager themeManager;
  const OnboardingScreen({Key? key, required this.themeManager}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();

  void _saveAndContinue() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await widget.themeManager.saveUserName(name);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(themeManager: widget.themeManager)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.solar_power_rounded, size: 80, color: Color(0xFF6C63FF)),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
                const Text(
                  'Premier Module Scanner',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Enter your name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
