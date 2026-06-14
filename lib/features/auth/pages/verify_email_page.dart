import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/constants/app_assets.dart';
import '../../main_navigation/main_navigation_page.dart';
import 'login_page.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  void handleVerified(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationPage(),
      ),
    );
  }

  void handleResendEmail(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification email has been resent.'),
      ),
    );
  }

  void handleContactSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support contact will be added later.'),
      ),
    );
  }

  void goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF6),
      body: SafeArea(
        child: Stack(
          children: [
Positioned(
  top: -110,
  left: -100,
  child: ImageFiltered(
    imageFilter: ImageFilter.blur(
      sigmaX: 55,
      sigmaY: 55,
    ),
    child: Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFABF1D2).withOpacity(0.45),
      ),
    ),
  ),
),
Positioned(
  top: -110,
  left: -100,
  child: ImageFiltered(
    imageFilter: ImageFilter.blur(
      sigmaX: 55,
      sigmaY: 55,
    ),
    child: Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color.fromARGB(255, 7, 175, 222).withOpacity(0.45),
      ),
    ),
  ),
),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: Column(
                children: [
                  const SizedBox(height: 26),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF246A52).withOpacity(0.14),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.asset(
                        AppAssets.verifyEmail,
                        height: 305,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 42),

                  const Text(
                    'Check your email! 💌',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 31,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF166534),
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'We just sent a verification link to your inbox. Tap the link to activate your EcoCampus account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.65,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ),

                  const SizedBox(height: 58),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () => handleVerified(context),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 24,
                      ),
                      label: const Text(
                        "I've Verified My Account",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF166534),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: const Color(0xFF166534).withOpacity(0.22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  TextButton.icon(
                    onPressed: () => handleResendEmail(context),
                    icon: const Icon(
                      Icons.forward_to_inbox_rounded,
                      size: 22,
                    ),
                    label: const Text(
                      "Didn't get it? Resend Email",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0E7490),
                    ),
                  ),

                  const SizedBox(height: 42),

                  TextButton(
                    onPressed: () => handleContactSupport(context),
                    child: const Text(
                      'Need help? Contact Support',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6F7973),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () => goToLogin(context),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF166534),
                      ),
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
}