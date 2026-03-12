import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color _primaryBlue = Color(0xFF36a4da);
  static const Color _deepBlue = Color(0xFF0D5FBC);
  static const Color _accentOrange = Color(0xFFe85021);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final loginResult = await AuthService.instance.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!loginResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loginResult.message)),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final shortestSide = screenSize.shortestSide;
    final isTablet = shortestSide >= 600;
    final isLandscape = screenSize.width > screenSize.height;
    final heroAspectRatio = isTablet
        ? (isLandscape ? 2.8 : 1.55)
        : 1.75;
    final heroFit = isTablet ? BoxFit.contain : BoxFit.cover;

    return Scaffold(
      backgroundColor: _deepBlue,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_primaryBlue, _deepBlue],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: heroAspectRatio,
                            child: Container(
                              width: double.infinity,
                              color: Colors.white.withOpacity(0.05),
                              child: Image.asset(
                                'assets/images/login_students.png',
                                fit: heroFit,
                                alignment: isTablet ? Alignment.center : Alignment.topCenter,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/kid_reading.png',
                                    fit: heroFit,
                                    alignment: isTablet ? Alignment.center : Alignment.topCenter,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Login to your account',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildInputCard(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                hint: 'Enter your email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!text.contains('@')) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _buildInputCard(
                                icon: Icons.lock_outline,
                                label: 'Password',
                                hint: 'Enter your password',
                                controller: _passwordController,
                                isPassword: true,
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return 'Password is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              elevation: 8,
                              shadowColor: _deepBlue.withOpacity(0.4),
                              backgroundColor: _accentOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.8,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please contact admin for password reset.'),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No account yet? Contact Admin for access',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF5E6A82), size: 24),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF3C4A63),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              if (isPassword) const Spacer(),
              if (isPassword)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF5E6A82),
                    size: 22,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword ? _obscurePassword : false,
            validator: validator,
            style: const TextStyle(
              color: Color(0xFF2A3650),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF95A1B7),
                fontSize: 17,
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFD7DDE8), width: 1.4),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _primaryBlue, width: 2.0),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _accentOrange, width: 1.8),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _accentOrange, width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
