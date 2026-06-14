import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../reports/pages/reports_page.dart';
import '../rewards/pages/rewards_page.dart';
import '../profile/pages/profile_page.dart';
import '../reports/pages/create_report_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int selectedIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      HomePage(onNavigate: changeTab),
      const ReportsPage(),
      const RewardsPage(initialTabIndex: 0),
      const RewardsPage(initialTabIndex: 1),
      const ProfilePage(),
    ];
  }

  void changeTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void openCreateReportPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateReportPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.10),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: selectedIndex == 0,
                onTap: () => changeTab(0),
              ),
              _BottomNavItem(
                icon: Icons.article_outlined,
                label: 'Laporan',
                isActive: selectedIndex == 1,
                onTap: () => changeTab(1),
              ),
              _BottomCenterButton(onTap: openCreateReportPage),
              _BottomNavItem(
                icon: Icons.emoji_events_outlined,
                label: 'Challenge',
                isActive: selectedIndex == 2 || selectedIndex == 3,
                onTap: () => changeTab(2),
              ),
              _BottomNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isActive: selectedIndex == 4,
                onTap: () => changeTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomCenterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BottomCenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFF0F8A5F),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F8A5F).withOpacity(0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive
                  ? const Color(0xFF0F8A5F)
                  : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isActive
                    ? const Color(0xFF0F8A5F)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
