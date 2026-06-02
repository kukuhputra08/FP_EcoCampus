import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be added soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildPointCard(),
              const SizedBox(height: 26),
              _buildQuickActions(context),
              const SizedBox(height: 30),
              _buildSectionHeader(
                title: 'Active Challenge',
                actionText: 'View All',
                onTap: () => _showComingSoon(context, 'Challenges'),
              ),
              const SizedBox(height: 12),
              _buildActiveChallengeCard(context),
              const SizedBox(height: 30),
              _buildSectionTitle('Recent Reports'),
              const SizedBox(height: 12),
              _buildRecentReportCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Budi 👋',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Ready to make your campus greener?',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _showComingSoon(context, 'Notifications'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 26,
              color: Color(0xFF166534),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPointCard() {
    return Container(
      width: double.infinity,
      height: 145,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F766E),
            Color(0xFF166534),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -8,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eco Points',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.72),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1,250 pts',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Eco Starter',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'Create\nReport',
        icon: Icons.add_photo_alternate_outlined,
        color: const Color(0xFFBBF7D0),
        iconColor: const Color(0xFF166534),
        onTap: () => _showComingSoon(context, 'Create Report'),
      ),
      _QuickAction(
        title: 'View\nChallenge',
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFFBAEAFF),
        iconColor: const Color(0xFF0E7490),
        onTap: () => _showComingSoon(context, 'Challenges'),
      ),
      _QuickAction(
        title: 'Redeem\nReward',
        icon: Icons.card_giftcard_rounded,
        color: const Color(0xFFFFF0A8),
        iconColor: const Color(0xFF854D0E),
        onTap: () => _showComingSoon(context, 'Rewards'),
      ),
      _QuickAction(
        title: 'Join\nEvent',
        icon: Icons.event_available_rounded,
        color: const Color(0xFFFECACA),
        iconColor: const Color(0xFF991B1B),
        onTap: () => _showComingSoon(context, 'Events'),
      ),
    ];

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.15,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];

        return GestureDetector(
          onTap: action.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF14532D).withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: action.color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    action.icon,
                    size: 24,
                    color: action.iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action.title,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 23,
        height: 1.15,
        fontWeight: FontWeight.w900,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(child: _buildSectionTitle(title)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF166534),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChallengeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.water_drop_outlined,
              color: Color(0xFF0E7490),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bring Your Own Tumbler',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Earn 50 points',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0E7490),
                  ),
                ),
                SizedBox(height: 10),
                _StatusChip(label: 'Available'),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: () => _showComingSoon(context, 'Submit Proof'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
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
              size: 27,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broken trash bin\nnear Building A',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Today, 10:30 AM',
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7D6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'IN PROGRESS',
              style: TextStyle(
                fontSize: 10,
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
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF166534),
            Color(0xFF0F766E),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: true,
          ),
          _BottomNavItem(
            icon: Icons.article_outlined,
            label: 'Reports',
          ),
          _BottomNavItem(
            icon: Icons.emoji_events_outlined,
            label: 'Challenges',
          ),
          _BottomNavItem(
            icon: Icons.card_giftcard_outlined,
            label: 'Rewards',
          ),
          _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 4,
            backgroundColor: Color(0xFF166534),
          ),
          SizedBox(width: 7),
          Text(
            'Available',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });
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
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 23,
              color: const Color(0xFF16A34A),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF166534),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 23,
          color: Colors.white.withOpacity(0.86),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.82),
          ),
        ),
      ],
    );
  }
}