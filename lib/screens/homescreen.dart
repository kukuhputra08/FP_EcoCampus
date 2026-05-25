import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// MODEL SEDERHANA (replace dengan model nyata)
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
  static const Color _primaryDark = Color(0xFF0D4A30);
  static const Color _primary = Color(0xFF1A6B4A);
  static const Color _primaryLight = Color(0xFF2E9E6E);
  static const Color _accent = Color(0xFF4CAF7D);
  static const Color _surface = Color(0xFFF4FAF7);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0D2B1E);
  static const Color _textSecondary = Color(0xFF5A7A6A);

  // ── Dummy Data ───────────────────────────────
  final List<ReportItem> _recentReports = const [
    ReportItem(
      title: 'Tumpukan sampah di Gedung B',
      category: 'Sampah',
      status: 'Diproses',
      timeAgo: '2 jam lalu',
      statusColor: Color(0xFFF59E0B),
    ),
    ReportItem(
      title: 'Lampu taman mati depan rektorat',
      category: 'Fasilitas',
      status: 'Selesai',
      timeAgo: '1 hari lalu',
      statusColor: Color(0xFF10B981),
    ),
    ReportItem(
      title: 'Saluran air tersumbat parkiran',
      category: 'Lingkungan',
      status: 'Pending',
      timeAgo: '3 hari lalu',
      statusColor: Color(0xFF6B7280),
    ),
  ];

  final List<ChallengeItem> _dailyChallenges = const [
    ChallengeItem(
        title: 'Bawa tumbler hari ini', points: 50, icon: '🧴', isDone: true),
    ChallengeItem(
        title: 'Foto lingkungan bersih', points: 30, icon: '📸', isDone: false),
    ChallengeItem(
        title: 'Kurangi 1 plastik sekali pakai',
        points: 40,
        icon: '♻️',
        isDone: false),
  ];

  final List<EventItem> _upcomingEvents = const [
    EventItem(
      title: 'Campus Clean-Up Day',
      date: '1 Jun 2026',
      location: 'Lapangan Utama',
      quota: 100,
      registered: 74,
    ),
    EventItem(
      title: 'Tanam Pohon Bersama',
      date: '7 Jun 2026',
      location: 'Area Hijau Kampus',
      quota: 50,
      registered: 23,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
            // ── App Bar / Header ──────────────────
            _buildSliverAppBar(),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats Cards ─────────────────
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // ── Quick Actions ───────────────
                  _buildSectionHeader('Aksi Cepat', icon: Icons.bolt_rounded),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 28),

                  // ── Daily Challenge ─────────────
                  _buildSectionHeader('Daily Challenge 🌿',
                      icon: Icons.emoji_events_rounded,
                      trailing: 'Lihat Semua'),
                  const SizedBox(height: 12),
                  _buildDailyChallenges(),
                  const SizedBox(height: 28),

                  // ── Recent Reports ──────────────
                  _buildSectionHeader('Laporan Terbaru',
                      icon: Icons.assignment_rounded,
                      trailing: 'Lihat Semua'),
                  const SizedBox(height: 12),
                  _buildRecentReports(),
                  const SizedBox(height: 28),

                  // ── Upcoming Events ─────────────
                  _buildSectionHeader('Event Mendatang',
                      icon: Icons.event_rounded, trailing: 'Lihat Semua'),
                  const SizedBox(height: 12),
                  _buildUpcomingEvents(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Nav Bar ─────────────────────────
      bottomNavigationBar: _buildBottomNav(),

      // ── FAB ────────────────────────────────────
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ═══════════════════════════════════════════════
  // SLIVER APP BAR
  // ═══════════════════════════════════════════════
  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D4A30),
                Color(0xFF1A6B4A),
                Color(0xFF2E9E6E),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '🌿 ',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'EcoCampus',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Halo, Budi! 👋',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Universitas Surabaya • Eco Warrior 🏆',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      // Avatar + Notif
                      Row(
                        children: [
                          // Notifikasi Bell
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.notifications_outlined,
                                    color: Colors.white, size: 22),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF6B6B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Avatar
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF7D), Color(0xFF2E9E6E)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2),
                            ),
                            child: const Center(
                              child: Text(
                                'B',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Title saat collapsed
        title: const Text(
          'EcoCampus',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          _buildStatCard(
            label: 'Eco Points',
            value: '1,240',
            icon: Icons.star_rounded,
            color: const Color(0xFF2E9E6E),
            bgColor: const Color(0xFFE8F7F0),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            label: 'Laporan',
            value: '8',
            icon: Icons.assignment_rounded,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            label: 'Rank',
            value: '#12',
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFFBEB),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════
  Widget _buildSectionHeader(String title,
      {required IconData icon, String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (trailing != null)
            GestureDetector(
              onTap: () {},
              child: Text(
                trailing,
                style: const TextStyle(
                  color: Color(0xFF2E9E6E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════════════
  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'Buat\nLaporan',
        'icon': Icons.add_photo_alternate_rounded,
        'color': const Color(0xFF1A6B4A),
        'bg': const Color(0xFFE8F7F0),
      },
      {
        'label': 'Challenge\nHarian',
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
      },
      {
        'label': 'Event &\nVolunteer',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
      },
      {
        'label': 'Papan\nSkor',
        'icon': Icons.leaderboard_rounded,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((a) {
          return _buildActionButton(
            label: a['label'] as String,
            icon: a['icon'] as IconData,
            color: a['color'] as Color,
            bgColor: a['bg'] as Color,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // DAILY CHALLENGES
  // ═══════════════════════════════════════════════
  Widget _buildDailyChallenges() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _dailyChallenges.map((c) {
          return _buildChallengeCard(c);
        }).toList(),
      ),
    );
  }

  Widget _buildChallengeCard(ChallengeItem challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: challenge.isDone
              ? const Color(0xFF2E9E6E).withOpacity(0.3)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: challenge.isDone
                  ? const Color(0xFFE8F7F0)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                challenge.icon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: challenge.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '+${challenge.points} pts',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Checkbox
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: challenge.isDone
                  ? const Color(0xFF2E9E6E)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: challenge.isDone
                    ? const Color(0xFF2E9E6E)
                    : const Color(0xFFD1D5DB),
                width: 2,
              ),
            ),
            child: challenge.isDone
                ? const Icon(Icons.check_rounded,
                color: Colors.white, size: 16)
                : null,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // RECENT REPORTS
  // ═══════════════════════════════════════════════
  Widget _buildRecentReports() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _recentReports.map((r) => _buildReportCard(r)).toList(),
      ),
    );
  }

  Widget _buildReportCard(ReportItem report) {
    IconData categoryIcon;
    Color categoryColor;
    switch (report.category) {
      case 'Sampah':
        categoryIcon = Icons.delete_outline_rounded;
        categoryColor = const Color(0xFF10B981);
        break;
      case 'Fasilitas':
        categoryIcon = Icons.build_outlined;
        categoryColor = const Color(0xFF3B82F6);
        break;
      default:
        categoryIcon = Icons.eco_outlined;
        categoryColor = const Color(0xFF2E9E6E);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      report.category,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      ' • ${report.timeAgo}',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: report.statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              report.status,
              style: TextStyle(
                color: report.statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // UPCOMING EVENTS
  // ═══════════════════════════════════════════════
  Widget _buildUpcomingEvents() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _upcomingEvents.length,
        itemBuilder: (_, i) => _buildEventCard(_upcomingEvents[i]),
      ),
    );
  }

  Widget _buildEventCard(EventItem event) {
    final double fillPercent = event.registered / event.quota;
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A6B4A),
            Color(0xFF0D4A30),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A6B4A).withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  color: Colors.white.withOpacity(0.7), size: 12),
              const SizedBox(width: 3),
              Text(
                event.location,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Progress bar kuota
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${event.registered}/${event.quota} peserta',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${(fillPercent * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fillPercent,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4CAF7D)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // BOTTOM NAVIGATION BAR
  // ═══════════════════════════════════════════════
  Widget _buildBottomNav() {
    return BottomAppBar(
      color: _cardBg,
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.1),
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.assignment_rounded, 'Laporan'),
            const SizedBox(width: 40), // FAB space
            _buildNavItem(2, Icons.emoji_events_rounded, 'Reward'),
            _buildNavItem(3, Icons.person_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? _primary : const Color(0xFFADB5BD),
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? _primary : const Color(0xFFADB5BD),
              fontSize: 10,
              fontWeight:
              isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // FAB — Buat Laporan
  // ═══════════════════════════════════════════════
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        // TODO: Navigate to CreateReportScreen
      },
      backgroundColor: _primary,
      elevation: 6,
      child: const Icon(
        Icons.add_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}