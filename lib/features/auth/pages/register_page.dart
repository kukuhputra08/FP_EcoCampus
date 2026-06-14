import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';
import 'verify_email_page.dart';
import '../../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService authService = AuthService();

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;
  bool isLoading = false;
  bool isLoadingOptions = true;

  String? selectedUniversityId;
  String? selectedDepartmentId;

  List<UniversityOption> universities = [];
  Map<String, List<DepartmentOption>> departmentsByUniversityId = {};

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  List<DepartmentOption> get availableDepartments {
    if (selectedUniversityId == null) return [];
    return departmentsByUniversityId[selectedUniversityId] ?? [];
  }

  UniversityOption? get selectedUniversity {
    if (selectedUniversityId == null) return null;

    try {
      return universities.firstWhere(
        (item) => item.id == selectedUniversityId,
      );
    } catch (_) {
      return null;
    }
  }

  DepartmentOption? get selectedDepartment {
    if (selectedDepartmentId == null) return null;

    try {
      return availableDepartments.firstWhere(
        (item) => item.id == selectedDepartmentId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    loadAcademicOptions();
  }

  Future<void> loadAcademicOptions() async {
    setState(() {
      isLoadingOptions = true;
    });

    try {
      final AcademicOptions options =
          await authService.getAcademicOptionsFromAdmins();

      if (!mounted) return;

      setState(() {
        universities = options.universities;
        departmentsByUniversityId = options.departmentsByUniversityId;
        isLoadingOptions = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingOptions = false;
      });

      showMessage('Gagal memuat data kampus: $error');
    }
  }

  Future<void> handleRegister() async {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String studentId = studentIdController.text.trim();
    final String password = passwordController.text.trim();
    final String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        studentId.isEmpty ||
        selectedUniversity == null ||
        selectedDepartment == null ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Semua field wajib diisi.');
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

    if (password != confirmPassword) {
      showMessage('Konfirmasi password tidak sama.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await authService.registerStudent(
        name: name,
        email: email,
        studentId: studentId,
        universityId: selectedUniversity!.id,
        universityName: selectedUniversity!.name,
        universityShortName: selectedUniversity!.shortName,
        departmentId: selectedDepartment!.id,
        departmentName: selectedDepartment!.name,
        password: password,
      );

      if (!mounted) return;

      showMessage('Registrasi berhasil. Silakan verifikasi email kamu.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const VerifyEmailPage(),
        ),
      );
    } on FirebaseAuthException catch (error) {
      String message = 'Registrasi gagal.';

      if (error.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar.';
      } else if (error.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (error.code == 'weak-password') {
        message = 'Password terlalu lemah.';
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

  void goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
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
                          value: selectedUniversityId,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            hintText: isLoadingOptions
                                ? 'Loading universities...'
                                : universities.isEmpty
                                    ? 'No university available'
                                    : 'Select university',
                            icon: Icons.account_balance_rounded,
                          ),
                          items: universities.map((university) {
                            final String label = university.shortName.isEmpty
                                ? university.name
                                : '${university.name} (${university.shortName})';

                            return DropdownMenuItem(
                              value: university.id,
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: isLoading ||
                                  isLoadingOptions ||
                                  universities.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedUniversityId = value;
                                    selectedDepartmentId = null;
                                  });
                                },
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Department'),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedDepartmentId,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            hintText: selectedUniversityId == null
                                ? 'Select university first'
                                : availableDepartments.isEmpty
                                    ? 'No department available'
                                    : 'Select department',
                            icon: Icons.apartment_rounded,
                          ),
                          items: availableDepartments.map((department) {
                            return DropdownMenuItem(
                              value: department.id,
                              child: Text(
                                department.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: selectedUniversityId == null ||
                                  isLoading ||
                                  isLoadingOptions ||
                                  availableDepartments.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedDepartmentId = value;
                                  });
                                },
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
                        const SizedBox(height: 20),
                        _buildLabel('Confirm Password'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: isConfirmPasswordHidden,
                          enabled: !isLoading,
                          decoration: _inputDecoration(
                            hintText: '••••••••',
                            icon: Icons.verified_user_outlined,
                          ).copyWith(
                            suffixIcon: IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
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
                            onPressed: isLoading ? null : handleRegister,
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
                          onTap: isLoading ? null : goToLogin,
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