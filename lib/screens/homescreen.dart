import 'package:flutter/material.dart';
import 'profilescreen.dart';
import 'rewardscreen.dart';
import 'leaderboardscreen.dart';
import 'badgescreen.dart';
import 'redeemscreen.dart';
import 'laporan_screen.dart';
import 'buat_laporan_screen.dart';

// ─────────────────────────────────────────────
// PLACEHOLDER SCREEN (untuk semua route sementara)
// ─────────────────────────────────────────────
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D4A30),
        foregroundColor: Colors.white,
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D2B1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Halaman ini sedang dalam\npengembangan 🚧',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF5A7A6A), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────
class ReportItem {
  final String title;
  final String category;
  final String status;
  final String timeAgo;
  final Color statusColor;

  const ReportItem({
    required this.title,
    required this.category,
    required this.status,
    required this.timeAgo,
    required this.statusColor,
  });
}

class ChallengeItem {
  final String title;
  final int points;
  final String icon;
  final bool isDone;

  const ChallengeItem({
    required this.title,
    required this.points,
    required this.icon,
    required this.isDone,
  });
}

class EventItem {
  final String title;
  final String date;
  final String location;
  final int quota;
  final int registered;

  const EventItem({
    required this.title,
    required this.date,
    required this.location,
    required this.quota,
    required this.registered,
  });
}

// ─────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Warna Tema ──────────────────────────────
  static const Color _primaryDark  = Color(0xFF0D4A30);
  static const Color _primary      = Color(0xFF1A6B4A);
  static const Color _primaryLight = Color(0xFF2E9E6E);
  static const Color _surface      = Color(0xFFF4FAF7);
  static const Color _cardBg       = Color(0xFFFFFFFF);
  static const Color _textPrimary  = Color(0xFF0D2B1E);
  static const Color _textSec      = Color(0xFF5A7A6A);

  // ── Dummy Data ───────────────────────────────
  final List<ReportItem> _reports = const [
    ReportItem(title: 'Tumpukan sampah di Gedung B',    category: 'Sampah',     status: 'Diproses', timeAgo: '2 jam lalu',  statusColor: Color(0xFFF59E0B)),
    ReportItem(title: 'Lampu taman mati depan rektorat', category: 'Fasilitas',  status: 'Selesai',  timeAgo: '1 hari lalu', statusColor: Color(0xFF10B981)),
    ReportItem(title: 'Saluran air tersumbat parkiran',  category: 'Lingkungan', status: 'Pending',  timeAgo: '3 hari lalu', statusColor: Color(0xFF6B7280)),
  ];

  final List<ChallengeItem> _challenges = const [
    ChallengeItem(title: 'Bawa tumbler hari ini',          points: 50, icon: '🧴', isDone: true),
    ChallengeItem(title: 'Foto lingkungan bersih',         points: 30, icon: '📸', isDone: false),
    ChallengeItem(title: 'Kurangi 1 plastik sekali pakai', points: 40, icon: '♻️', isDone: false),
  ];

  final List<EventItem> _events = const [
    EventItem(title: 'Campus Clean-Up Day',  date: '1 Jun 2026', location: 'Lapangan Utama',   quota: 100, registered: 74),
    EventItem(title: 'Tanam Pohon Bersama', date: '7 Jun 2026', location: 'Area Hijau Kampus', quota: 50,  registered: 23),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Helper Navigate ──────────────────────────
  void _goto(String title, IconData icon, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PlaceholderScreen(title: title, icon: icon, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _sectionHeader('Aksi Cepat', Icons.bolt_rounded),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 28),
                  _sectionHeader('Daily Challenge 🌿',
                      Icons.emoji_events_rounded,
                      trailing: 'Lihat Semua',
                      onTrailing: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RewardScreen()))),
                  const SizedBox(height: 12),
                  _buildChallenges(),
                  const SizedBox(height: 28),
                  _sectionHeader('Laporan Terbaru', Icons.assignment_rounded,
                      trailing: 'Lihat Semua',
                      onTrailing: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LaporanScreen()))),
                  const SizedBox(height: 12),
                  _buildReports(),
                  const SizedBox(height: 28),
                  _sectionHeader('Event Mendatang', Icons.event_rounded,
                      trailing: 'Lihat Semua',
                      onTrailing: () => _goto('Event & Volunteer',
                          Icons.calendar_month_rounded,
                          const Color(0xFF8B5CF6))),
                  const SizedBox(height: 12),
                  _buildEvents(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ═══════════════════════════════════════════════
  // APP BAR — FIXED: pakai Expanded biar tidak overflow
  // ═══════════════════════════════════════════════
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryDark,
      automaticallyImplyLeading: false,
      title: const Text(
        '🌿 EcoCampus',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      actions: [
        // Notifikasi
        GestureDetector(
          onTap: () =>
              _goto('Notifikasi', Icons.notifications_rounded, _primary),
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 20),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFF6B6B), shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Avatar
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: 16, left: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF7D), Color(0xFF2E9E6E)]),
              borderRadius: BorderRadius.circular(11),
              border:
              Border.all(color: Colors.white.withOpacity(0.35), width: 2),
            ),
            child: const Center(
              child: Text('B',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D4A30), Color(0xFF1A6B4A), Color(0xFF2E9E6E)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Halo, Budi! 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Universitas Surabaya  •  Eco Warrior 🏆',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _statCard('1,240', 'Eco Points', Icons.star_rounded,
              const Color(0xFF2E9E6E), const Color(0xFFE8F7F0)),
          const SizedBox(width: 10),
          _statCard('8', 'Laporan', Icons.assignment_rounded,
              const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
          const SizedBox(width: 10),
          _statCard('#12', 'Rank', Icons.emoji_events_rounded,
              const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color,
      Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(color: _textSec, fontSize: 10),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════
  Widget _sectionHeader(String title, IconData icon,
      {String? trailing, VoidCallback? onTrailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F7F0),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: _primary, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailing,
              child: Text(trailing,
                  style: const TextStyle(
                      color: Color(0xFF2E9E6E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // QUICK ACTIONS — 4 tombol responsif
  // ═══════════════════════════════════════════════
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionBtn(
            label: 'Buat\nLaporan',
            icon: Icons.add_photo_alternate_rounded,
            color: _primary,
            bg: const Color(0xFFE8F7F0),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BuatLaporanScreen())),
          ),
          _actionBtn(
            label: 'Challenge\nHarian',
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFF59E0B),
            bg: const Color(0xFFFFFBEB),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RewardScreen())),
          ),
          _actionBtn(
            label: 'Event &\nVolunteer',
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF8B5CF6),
            bg: const Color(0xFFF5F3FF),
            onTap: () => _goto('Event & Volunteer',
                Icons.calendar_month_rounded, const Color(0xFF8B5CF6)),
          ),
          _actionBtn(
            label: 'Papan\nSkor',
            icon: Icons.leaderboard_rounded,
            color: const Color(0xFF3B82F6),
            bg: const Color(0xFFEFF6FF),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.3),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // DAILY CHALLENGES
  // ═══════════════════════════════════════════════
  Widget _buildChallenges() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _challenges
            .map((c) => _challengeCard(c))
            .toList(),
      ),
    );
  }

  Widget _challengeCard(ChallengeItem c) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const RewardScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: c.isDone
                ? const Color(0xFF2E9E6E).withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.isDone
                    ? const Color(0xFFE8F7F0)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(c.icon, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: c.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFF59E0B), size: 13),
                      const SizedBox(width: 3),
                      Text('+${c.points} pts',
                          style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color:
                c.isDone ? const Color(0xFF2E9E6E) : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: c.isDone
                      ? const Color(0xFF2E9E6E)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: c.isDone
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // RECENT REPORTS
  // ═══════════════════════════════════════════════
  Widget _buildReports() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child:
      Column(children: _reports.map((r) => _reportCard(r)).toList()),
    );
  }

  Widget _reportCard(ReportItem r) {
    final Map<String, dynamic> meta = {
      'Sampah':    {'icon': Icons.delete_outline_rounded,  'color': const Color(0xFF10B981)},
      'Fasilitas': {'icon': Icons.build_outlined,           'color': const Color(0xFF3B82F6)},
    };
    final IconData icon =
        meta[r.category]?['icon'] ?? Icons.eco_outlined;
    final Color color =
        meta[r.category]?['color'] ?? _primaryLight;

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LaporanScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${r.category}  •  ${r.timeAgo}',
                      style: TextStyle(color: _textSec, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: r.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(r.status,
                  style: TextStyle(
                      color: r.statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // UPCOMING EVENTS
  // ═══════════════════════════════════════════════
  Widget _buildEvents() {
    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _events.length,
        itemBuilder: (_, i) => _eventCard(_events[i]),
      ),
    );
  }

  Widget _eventCard(EventItem e) {
    final double fill = e.registered / e.quota;
    return GestureDetector(
      onTap: () => _goto(
          'Event & Volunteer', Icons.calendar_month_rounded, const Color(0xFF8B5CF6)),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A6B4A), Color(0xFF0D4A30)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1A6B4A).withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(e.date,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Text(e.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: Colors.white.withOpacity(0.7), size: 11),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(e.location,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${e.registered}/${e.quota} peserta',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 10)),
                Text('${(fill * 100).toInt()}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fill,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4CAF7D)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // BOTTOM NAV BAR
  // ═══════════════════════════════════════════════
  Widget _buildBottomNav() {
    return BottomAppBar(
      color: _cardBg,
      elevation: 10,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 58,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.home_rounded, 'Home',
                onTap: () => setState(() => _currentIndex = 0)),
            _navItem(1, Icons.assignment_rounded, 'Laporan',
                onTap: () {
                  setState(() => _currentIndex = 1);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LaporanScreen()));
                }),
            const SizedBox(width: 48), // ruang FAB
            _navItem(2, Icons.emoji_events_rounded, 'Reward',
                onTap: () {
                  setState(() => _currentIndex = 2);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RewardScreen()));
                }),
            _navItem(3, Icons.person_rounded, 'Profil',
                onTap: () {
                  setState(() => _currentIndex = 3);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()));
                }),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label,
      {required VoidCallback onTap}) {
    final bool active = _currentIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: active ? _primary : const Color(0xFFADB5BD), size: 23),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: active ? _primary : const Color(0xFFADB5BD),
                  fontSize: 10,
                  fontWeight:
                  active ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // FAB
  // ═══════════════════════════════════════════════
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const BuatLaporanScreen())),
      backgroundColor: _primary,
      elevation: 5,
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
    );
  }
}