import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../features/auth/pages/login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _goToStudentLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  Future<void> _goToAdminInfo(BuildContext context) async {
    final Uri adminUrl = Uri.parse('https://website-admin-ecocampus.vercel.app/login');

    if(!await launchUrl(adminUrl, mode: LaunchMode.externalApplication)){
      if(!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open admin login page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FAF5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 30),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14532D).withOpacity(0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    AppAssets.welcome,
                    height: 305,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 42),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.logo,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  const Text(
                    'Welcome to EcoCampus!',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF166534),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),

              const Text(
                'Join our joyful environmental journey.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF475569),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton.icon(
                  onPressed: () => _goToStudentLogin(context),
                  icon: const Icon(Icons.school_rounded, size: 24),
                  label: const Text(
                    'Login as Mahasiswa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF166534),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 62,
                child: OutlinedButton.icon(
                  onPressed: () => _goToAdminInfo(context),
                  icon: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 24,
                  ),
                  label: const Text(
                    'Login as Admin Kampus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0E7490),
                    side: const BorderSide(color: Color(0xFF0E7490), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
