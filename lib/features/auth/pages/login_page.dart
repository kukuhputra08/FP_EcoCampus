import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../main_navigation/main_navigation_page.dart';
import 'register_page.dart';
import 'verify_email_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService authService = AuthService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email dan password wajib diisi.');
      return;
    }

    if (!email.contains('@')) {
      showMessage('Format email tidak valid.');
      return;
    }

    if (password.length < 6) {
      showMessage('Password minimal 6 karakter.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final UserCredential credential = await authService.login(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw Exception('User tidak ditemukan.');
      }

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await authService.logout();

        if (!mounted) return;
        showMessage('Data user tidak ditemukan di database.');
        return;
      }

      final Map<String, dynamic> data = userDoc.data() ?? {};
      final String role = (data['role'] ?? '').toString();

      if (role != 'student') {
        await authService.logout();

        if (!mounted) return;
        showMessage('Akun admin tidak dapat masuk melalui aplikasi mahasiswa.');
        return;
      }

      await authService.reloadUser();

      final User? refreshedUser = authService.currentUser;

      if (!mounted) return;

      if (refreshedUser != null && !refreshedUser.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const VerifyEmailPage(),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigationPage(),
        ),
      );
    } on FirebaseAuthException catch (error) {
      String message = 'Login gagal.';

      if (error.code == 'user-not-found') {
        message = 'Akun tidak ditemukan.';
      } else if (error.code == 'wrong-password') {
        message = 'Password salah.';
      } else if (error.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (error.code == 'invalid-credential') {
        message = 'Email atau password salah.';
      } else if (error.code == 'network-request-failed') {
        message = 'Koneksi internet bermasalah.';
      }

      if (!mounted) return;
      showMessage(message);
    } catch (error) {
      if (!mounted) return;
      showMessage('Terjadi kesalahan: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterPage(),
      ),
    );
  }

  void forgotPassword() {
    final String email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage('Masukkan email terlebih dahulu.');
      return;
    }

    authService.resetPassword(email: email).then((_) {
      if (!mounted) return;
      showMessage('Link reset password sudah dikirim ke email.');
    }).catchError((error) {
      if (!mounted) return;
      showMessage('Gagal mengirim reset password: $error');
    });
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
                vertical: 34,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 28),
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
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFFBBF7D0),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 40,
                            color: Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF166534),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Continue your green campus journey',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 34),
                        _buildLabel('Email'),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: emailController,
                          hintText: 'student@university.edu',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Password'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passwordController,
                          obscureText: isPasswordHidden,
                          enabled: !isLoading,
                          decoration: _inputDecoration(
                            hintText: '••••••••',
                            icon: Icons.lock_outline_rounded,
                          ).copyWith(
                            suffixIcon: IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
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
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: isLoading ? null : forgotPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF166534),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF166534),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF94A3B8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.6,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        GestureDetector(
                          onTap: isLoading ? null : goToRegister,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF475569),
                              ),
                              children: [
                                TextSpan(text: 'Don’t have an account? '),
                                TextSpan(
                                  text: 'Create Account',
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

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: _labelStyle(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !isLoading,
      decoration: _inputDecoration(
        hintText: hintText,
        icon: icon,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF475569),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      focusedBorder: _focusedBorder(),
      disabledBorder: _inputBorder(),
    );
  }

  TextStyle _labelStyle() {
    return const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: Color(0xFF0F172A),
      letterSpacing: 0.2,
    );
  }

  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(
        color: Color(0xFFE2E8F0),
        width: 1.4,
      ),
    );
  }

  OutlineInputBorder _focusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(
        color: Color(0xFF16A34A),
        width: 1.7,
      ),
    );
  }
}