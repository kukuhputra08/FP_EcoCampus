import 'package:flutter/material.dart';

class BadgeData {
  final String icon;
  final String title;
  final String description;
  final String requirement;
  final int pointsRequired;
  final bool earned;
  final String? earnedDate;
  final String category;

  const BadgeData({
    required this.icon,
    required this.title,
    required this.description,
    required this.requirement,
    required this.pointsRequired,
    required this.earned,
    this.earnedDate,
    required this.category,
  });
}

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  static const Color _primaryDark = Color(0xFF0D4A30);
  static const Color _primary     = Color(0xFF1A6B4A);
  static const Color _surface     = Color(0xFFF4FAF7);
  static const Color _cardBg      = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0D2B1E);
  static const Color _textSec     = Color(0xFF5A7A6A);

  String _filter = 'Semua';
  final List<String> _filters = ['Semua', 'Diraih', 'Belum'];

  final List<BadgeData> _badges = const [
    BadgeData(icon: '🌱', title: 'First Report',    description: 'Buat laporan pertama kamu.',              requirement: '1 laporan',          pointsRequired: 0,    earned: true,  earnedDate: 'Jan 2024',  category: 'Laporan'),
    BadgeData(icon: '♻️', title: 'Eco Starter',     description: 'Selesaikan 5 laporan lingkungan.',        requirement: '5 laporan selesai',  pointsRequired: 0,    earned: true,  earnedDate: 'Feb 2024',  category: 'Laporan'),
    BadgeData(icon: '🌿', title: 'Green Guardian',  description: 'Selesaikan 10 challenge lingkungan.',     requirement: '10 challenge',       pointsRequired: 0,    earned: true,  earnedDate: 'Mar 2024',  category: 'Challenge'),
    BadgeData(icon: '🏆', title: 'Eco Warrior',     description: 'Masuk top 15 leaderboard.',               requirement: 'Top 15 leaderboard', pointsRequired: 0,    earned: true,  earnedDate: 'Apr 2024',  category: 'Komunitas'),
    BadgeData(icon: '🌳', title: 'Tree Hugger',     description: 'Ikut 3 event penanaman pohon.',           requirement: '3 event pohon',      pointsRequired: 0,    earned: false, earnedDate: null,        category: 'Event'),
    BadgeData(icon: '🔥', title: 'Streak Master',   description: 'Challenge harian 7 hari berturut-turut.', requirement: '7 hari streak',      pointsRequired: 0,    earned: false, earnedDate: null,        category: 'Challenge'),
    BadgeData(icon: '👥', title: 'Eco Recruiter',   description: 'Ajak 5 teman bergabung EcoCampus.',       requirement: '5 referral',         pointsRequired: 0,    earned: false, earnedDate: null,        category: 'Komunitas'),
    BadgeData(icon: '⭐', title: 'Silver Star',     description: 'Kumpulkan 2000 Eco Points.',              requirement: '2000 pts',           pointsRequired: 2000, earned: false, earnedDate: null,        category: 'Points'),
    BadgeData(icon: '💎', title: 'Gold Legend',     description: 'Kumpulkan 5000 Eco Points.',              requirement: '5000 pts',           pointsRequired: 5000, earned: false, earnedDate: null,        category: 'Points'),
    BadgeData(icon: '🌍', title: 'Planet Saver',    description: 'Selesaikan semua challenge kategori Lingkungan.', requirement: 'Semua challenge lingkungan', pointsRequired: 0, earned: false, earnedDate: null, category: 'Challenge'),
    BadgeData(icon: '📋', title: 'Report Master',   description: 'Buat 20 laporan yang terverifikasi.',     requirement: '20 laporan valid',   pointsRequired: 0,    earned: false, earnedDate: null,        category: 'Laporan'),
    BadgeData(icon: '🎯', title: 'Zero Waste Hero', description: 'Selesaikan challenge Zero Waste 3x.',     requirement: '3x zero waste',      pointsRequired: 0,    earned: false, earnedDate: null,        category: 'Challenge'),
  ];

  List<BadgeData> get _filtered {
    if (_filter == 'Diraih') return _badges.where((b) => b.earned).toList();
    if (_filter == 'Belum')  return _badges.where((b) => !b.earned).toList();
    return _badges;
  }

  int get _earnedCount => _badges.where((b) => b.earned).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildProgressBanner()),
          SliverToBoxAdapter(child: _buildFilterRow()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (_, i) => _badgeCard(_filtered[i]),
                childCount: _filtered.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Koleksi Badge',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildProgressBanner() {
    final double progress = _earnedCount / _badges.length;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D4A30), Color(0xFF2E9E6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Koleksi Badge Kamu',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text('$_earnedCount dari ${_badges.length} badge diraih',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text(
                '$_earnedCount/${_badges.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFFD700)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).toInt()}% lengkap  •  ${_badges.length - _earnedCount} badge lagi',
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: _filters.map((f) {
          final bool active = f == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: active ? _primary : _cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? _primary : const Color(0xFFE5E7EB)),
                boxShadow: active
                    ? [
                  BoxShadow(
                      color: _primary.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
                    : [],
              ),
              child: Text(f,
                  style: TextStyle(
                      color: active ? Colors.white : _textSec,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _badgeCard(BadgeData b) {
    return GestureDetector(
      onTap: () => _showDetail(b),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: b.earned ? _cardBg : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(18),
          border: b.earned
              ? Border.all(
              color: const Color(0xFF2E9E6E).withOpacity(0.35),
              width: 1.5)
              : null,
          boxShadow: b.earned
              ? [
            BoxShadow(
                color: const Color(0xFF2E9E6E).withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon dengan greyscale jika belum earned
            ColorFiltered(
              colorFilter: b.earned
                  ? const ColorFilter.mode(
                  Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0,      0,      0,      0.35, 0,
              ]),
              child: Text(b.icon,
                  style: const TextStyle(fontSize: 34)),
            ),
            const SizedBox(height: 8),
            Text(
              b.title,
              style: TextStyle(
                  color: b.earned ? _textPrimary : const Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              b.requirement,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            if (b.earned)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F7F0),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('✓ Diraih',
                    style: TextStyle(
                        color: Color(0xFF2E9E6E),
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              )
            else
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('Terkunci',
                    style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BadgeData b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Text(b.icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(b.title,
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F0),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(b.category,
                  style: const TextStyle(
                      color: Color(0xFF2E9E6E),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(b.description,
                style: TextStyle(
                    color: _textSec, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(
                    b.earned
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    color: b.earned
                        ? const Color(0xFF10B981)
                        : const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.earned ? 'Badge Diraih!' : 'Syarat',
                          style: TextStyle(
                              color: b.earned
                                  ? const Color(0xFF10B981)
                                  : _textSec,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          b.earned
                              ? 'Diraih pada ${b.earnedDate}'
                              : b.requirement,
                          style: TextStyle(
                              color: _textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}