import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be added soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreenHeader(context),
                Transform.translate(
                  offset: const Offset(0, -48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 30),
                        _buildSectionTitle(
                          icon: Icons.flash_on_rounded,
                          title: 'Aksi Cepat',
                        ),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                        const SizedBox(height: 34),
                        _buildSectionHeader(
                          icon: Icons.emoji_events_rounded,
                          title: 'Daily Challenge',
                          actionText: 'Lihat Semua',
                          onTap: () =>
                              _showComingSoon(context, 'Daily Challenge'),
                        ),
                        const SizedBox(height: 14),
                        _buildChallengeCard(context),
                        const SizedBox(height: 28),
                        _buildReportCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 18,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 48, 22, 82),
      decoration: const BoxDecoration(
        color: Color(0xFF0F8A5F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'EcoCampus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              _buildHeaderIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () => _showComingSoon(context, 'Notifications'),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'B',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          const Text(
            'Halo, Budi! 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Universitas Surabaya • Eco Warrior 🏆',
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
            const Positioned(
              top: 12,
              right: 12,
              child: CircleAvatar(
                radius: 4,
                backgroundColor: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            iconBackground: Color(0xFFDDFCEB),
            iconColor: Color(0xFF0F8A5F),
            value: '1,240',
            label: 'Eco Points',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.assignment_rounded,
            iconBackground: Color(0xFFDFF3FF),
            iconColor: Color(0xFF087EA4),
            value: '8',
            label: 'Laporan',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events_rounded,
            iconBackground: Color(0xFFFFF4BA),
            iconColor: Color(0xFFB7791F),
            value: '#12',
            label: 'Rank',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFF0F8A5F),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildSectionTitle(
            icon: icon,
            title: title,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F8A5F),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.add_photo_alternate_outlined,
        title: 'Buat\nLaporan',
        backgroundColor: const Color(0xFFD9FBE8),
        iconColor: const Color(0xFF0F8A5F),
        onTap: () => _showComingSoon(context, 'Buat Laporan'),
      ),
      _QuickActionData(
        icon: Icons.emoji_events_rounded,
        title: 'Challenge\nHarian',
        backgroundColor: const Color(0xFFFFF3B0),
        iconColor: const Color(0xFFB7791F),
        onTap: () => _showComingSoon(context, 'Challenge Harian'),
      ),
      _QuickActionData(
        icon: Icons.calendar_month_rounded,
        title: 'Event &\nVolunteer',
        backgroundColor: const Color(0xFFF1E4FF),
        iconColor: const Color(0xFF7E22CE),
        onTap: () => _showComingSoon(context, 'Event & Volunteer'),
      ),
      _QuickActionData(
        icon: Icons.bar_chart_rounded,
        title: 'Papan\nSkor',
        backgroundColor: const Color(0xFFE0F4FF),
        iconColor: const Color(0xFF087EA4),
        onTap: () => _showComingSoon(context, 'Papan Skor'),
      ),
    ];

    return Row(
      children: List.generate(actions.length, (index) {
        final item = actions[index];

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == actions.length - 1 ? 0 : 12,
            ),
            child: _QuickActionCard(data: item),
          ),
        );
      }),
    );
  }

  Widget _buildChallengeCard(BuildContext context) {
    return Column(
      children: [
        _DailyChallengeItem(
          icon: Icons.local_drink_outlined,
          iconBackground: const Color(0xFFE0F2FE),
          title: 'Bawa tumbler hari ini',
          points: '+50 pts',
          isCompleted: true,
          onTap: () => _showComingSoon(context, 'Challenge Completed'),
        ),
        const SizedBox(height: 14),
        _DailyChallengeItem(
          icon: Icons.camera_alt_rounded,
          iconBackground: const Color(0xFFF1F5F3),
          title: 'Foto lingkungan bersih',
          points: '+30 pts',
          isCompleted: false,
          onTap: () => _showComingSoon(context, 'Submit Challenge'),
        ),
      ],
    );
  }

  Widget _buildReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 28,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tempat sampah rusak',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Hari ini, 10:30',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7D6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PROSES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF715C00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
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
        children: const [
          _BottomNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: true,
          ),
          _BottomNavItem(
            icon: Icons.article_outlined,
            label: 'Laporan',
          ),
          _BottomCenterButton(),
          _BottomNavItem(
            icon: Icons.emoji_events_outlined,
            label: 'Reward',
          ),
          _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 76,
            decoration: BoxDecoration(
              color: data.backgroundColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: data.iconColor.withOpacity(0.13),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 32,
              color: data.iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyChallengeItem extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String points;
  final bool isCompleted;
  final VoidCallback onTap;

  const _DailyChallengeItem({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.points,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              icon,
              size: 28,
              color: const Color(0xFF0F8A5F),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: isCompleted
                        ? const Color(0xFF64748B)
                        : const Color(0xFF111827),
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 17,
                      color: Color(0xFFB7791F),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      points,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB7791F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF0F8A5F)
                    : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF0F8A5F)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.add_rounded,
                color: isCompleted ? Colors.white : const Color(0xFF64748B),
                size: 27,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCenterButton extends StatelessWidget {
  const _BottomCenterButton();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
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
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
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
    );
  }
}