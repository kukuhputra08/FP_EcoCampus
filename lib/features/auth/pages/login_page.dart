import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../home/home_page.dart';
import '../../../core/constants/app_text_styles.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isPasswordHidden = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }

  void goToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterPage(),
      ),
    );
  }

  void goToForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Forgot password page will be added next.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FAF5),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF16A34A).withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF14B8A6).withOpacity(0.10),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 28,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF14532D).withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          child:
                            Image.asset(
                              AppAssets.logo,
                              width: 80,
                              height: 80,
                            ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Hello EcoWarrior!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading1(
                            color: const Color(0xFF166534),
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Welcome back to EcoCampus',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(
                            color: const Color(0xFF475569),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 42),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email',
                            style: _labelStyle(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'student@university.edu',
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: Color(0xFF475569),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAF9),
                            border: _inputBorder(),
                            enabledBorder: _inputBorder(),
                            focusedBorder: _focusedBorder(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Password',
                              style: _labelStyle(),
                            ),
                            GestureDetector(
                              onTap: goToForgotPassword,
                              child: const Text(
                                'Forgot it?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passwordController,
                          obscureText: isPasswordHidden,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF475569),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isPasswordHidden = !isPasswordHidden;
                                });
                              },
                              icon: Icon(
                                isPasswordHidden
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAF9),
                            border: _inputBorder(),
                            enabledBorder: _inputBorder(),
                            focusedBorder: _focusedBorder(),
                          ),
                        ),

                        const SizedBox(height: 38),

                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF166534),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor:
                                  const Color(0xFF166534).withOpacity(0.24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 25,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        GestureDetector(
                          onTap: goToRegister,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF475569),
                              ),
                              children: [
                                TextSpan(text: 'New here? '),
                                TextSpan(
                                  text: 'Join the movement!',
                                  style: TextStyle(
                                    color: Color(0xFF166534),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: Color(0xFF0F172A),
      letterSpacing: 0.2,
    );
  }

  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: const BorderSide(
        color: Color(0xFFE2E8F0),
        width: 1.4,
      ),
    );
  }

  OutlineInputBorder _focusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: const BorderSide(
        color: Color(0xFF16A34A),
        width: 1.7,
      ),
    );
  }
}