import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../theme_manager.dart';
import '../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  final ThemeManager themeManager;
  const OnboardingScreen({Key? key, required this.themeManager}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController(text: 'http://192.168.0.73:3000');
  final TextEditingController _usernameController = TextEditingController(text: 'admin');
  final TextEditingController _passwordController = TextEditingController(text: 'admin123');
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _loginAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final baseUrl = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final result = await ApiService().login(baseUrl, username, password);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      final token = result['token'];
      final user = result['user'];
      
      await widget.themeManager.saveAuthData(
        userName: user['username'],
        token: token,
        role: user['role'] ?? 'user',
        baseUrl: baseUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${user['username']}!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(themeManager: widget.themeManager)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Connection error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
                      ),
                      padding: const EdgeInsets.all(8),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, color: theme.hintColor),
                  ),
                  const Text(
                    'Premier Module Scanner',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with Node.js & MongoDB backend',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: theme.hintColor.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 36),
                  
                  // Base URL Field (hidden as requested)
                  // TextFormField(
                  //   controller: _urlController,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Backend API URL',
                  //     helperText: 'e.g. http://192.168.0.73:3000 or http://10.0.2.2:3000',
                  //     prefixIcon: Icon(Icons.link_rounded),
                  //   ),
                  //   validator: (value) => value!.trim().isEmpty ? 'Backend URL is required' : null,
                  // ),
                  // const SizedBox(height: 16),
                  
                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    maxLength: 25,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => value!.trim().isEmpty ? 'Username is required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    maxLength: 10,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) => value!.trim().isEmpty ? 'Password is required' : null,
                  ),
                  const SizedBox(height: 32),
                  
                  // Connect / Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _loginAndContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Connect & Login',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
