import 'package:flutter/material.dart';

import 'login_page.dart';
import 'verify_email_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;

  String? selectedUniversity;
  String? selectedDepartment;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final List<String> universities = [
    'Test University',
    'Institut Teknologi Sepuluh Nopember',
  ];

  final Map<String, List<String>> departments = {
    'Test University': [
      'Ilmu Testing',
    ],
    'Institut Teknologi Sepuluh Nopember': [
      'Teknik Informatika',
      'Sistem Informasi',
      'Teknik Elektro',
    ],
  };

  List<String> get availableDepartments {
    if (selectedUniversity == null) return [];
    return departments[selectedUniversity] ?? [];
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    studentIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void handleRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const VerifyEmailPage(),
      ),
    );
  }

  void goToLogin() {
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
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
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
                          'Join EcoCampus',
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
                          'Start your green campus journey',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 34),

                        _buildLabel('Full Name'),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: nameController,
                          hintText: 'Budi Santoso',
                          icon: Icons.person_outline_rounded,
                        ),

                        const SizedBox(height: 20),

                        _buildLabel('Email'),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: emailController,
                          hintText: 'student@university.edu',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        _buildLabel('Student ID / NIM / NRP'),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: studentIdController,
                          hintText: '5026241001',
                          icon: Icons.badge_outlined,
                        ),

                        const SizedBox(height: 20),

                        _buildLabel('University'),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedUniversity,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            hintText: 'Select university',
                            icon: Icons.account_balance_rounded,
                          ),
                          items: universities.map((university) {
                            return DropdownMenuItem(
                              value: university,
                              child: Text(
                                university,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedUniversity = value;
                              selectedDepartment = null;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        _buildLabel('Department'),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedDepartment,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            hintText: 'Select department',
                            icon: Icons.apartment_rounded,
                          ),
                          items: availableDepartments.map((department) {
                            return DropdownMenuItem(
                              value: department,
                              child: Text(
                                department,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: selectedUniversity == null
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedDepartment = value;
                                  });
                                },
                        ),

                        const SizedBox(height: 20),

                        _buildLabel('Password'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passwordController,
                          obscureText: isPasswordHidden,
                          decoration: _inputDecoration(
                            hintText: '••••••••',
                            icon: Icons.lock_outline_rounded,
                          ).copyWith(
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
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildLabel('Confirm Password'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: isConfirmPasswordHidden,
                          decoration: _inputDecoration(
                            hintText: '••••••••',
                            icon: Icons.verified_user_outlined,
                          ).copyWith(
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isConfirmPasswordHidden =
                                      !isConfirmPasswordHidden;
                                });
                              },
                              icon: Icon(
                                isConfirmPasswordHidden
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 34),

                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF166534),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create Account',
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
                          onTap: goToLogin,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF475569),
                              ),
                              children: [
                                TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Login',
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