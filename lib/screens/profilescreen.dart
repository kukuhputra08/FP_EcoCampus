import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// PROFILE SCREEN
// ─────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── Warna Tema (sama dengan HomeScreen) ─────
  static const Color _primaryDark = Color(0xFF0D4A30);
  static const Color _primary = Color(0xFF1A6B4A);
  static const Color _primaryLight = Color(0xFF2E9E6E);
  static const Color _accent = Color(0xFF4CAF7D);
  static const Color _surface = Color(0xFFF4FAF7);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0D2B1E);
  static const Color _textSecondary = Color(0xFF5A7A6A);

  late TabController _tabController;
  bool _notifEnabled = true;
  bool _darkMode = false;

  // ── Dummy User Data ──────────────────────────
  final Map<String, dynamic> _user = {
    'name': 'Budi Santoso',
    'email': 'budi.santoso@student.ubaya.ac.id',
    'campus': 'Universitas Surabaya',
    'faculty': 'Teknik Informatika',
    'joinDate': 'Januari 2024',
    'points': 1240,
    'rank': 12,
    'totalReports': 8,
    'completedChallenges': 24,
    'eventsJoined': 5,
    'badge': 'Eco Warrior 🏆',
    'level': 'Silver',
  };

  // ── Riwayat Laporan ──────────────────────────
  final List<Map<String, dynamic>> _reportHistory = [
    {
      'title': 'Tumpukan sampah di Gedung B',
      'category': 'Sampah',
      'status': 'Selesai',
      'date': '28 Mei 2026',
      'statusColor': Color(0xFF10B981),
    },
    {
      'title': 'Lampu taman mati depan rektorat',
      'category': 'Fasilitas',
      'status': 'Selesai',
      'date': '20 Mei 2026',
      'statusColor': Color(0xFF10B981),
    },
    {
      'title': 'Saluran air tersumbat parkiran',
      'category': 'Lingkungan',
      'status': 'Diproses',
      'date': '15 Mei 2026',
      'statusColor': Color(0xFFF59E0B),
    },
    {
      'title': 'Kursi taman rusak area FT',
      'category': 'Fasilitas',
      'status': 'Pending',
      'date': '10 Mei 2026',
      'statusColor': Color(0xFF6B7280),
    },
  ];

  // ── Badge / Achievement ──────────────────────
  final List<Map<String, dynamic>> _badges = [
    {
      'icon': '🌱',
      'title': 'First Report',
      'desc': 'Laporan pertama',
      'earned': true,
    },
    {
      'icon': '♻️',
      'title': 'Eco Starter',
      'desc': '5 laporan selesai',
      'earned': true,
    },
    {
      'icon': '🌿',
      'title': 'Green Guardian',
      'desc': '10 challenge selesai',
      'earned': true,
    },
    {
      'icon': '🏆',
      'title': 'Eco Warrior',
      'desc': 'Top 15 leaderboard',
      'earned': true,
    },
    {
      'icon': '🌳',
      'title': 'Tree Hugger',
      'desc': '3 event diikuti',
      'earned': false,
    },
    {
      'icon': '⭐',
      'title': 'Legend',
      'desc': '5000 total points',
      'earned': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: Column(
          children: [
            // ── Tab Bar ─────────────────────────
            Container(
              color: _cardBg,
              child: TabBar(
                controller: _tabController,
                indicatorColor: _primary,
                indicatorWeight: 3,
                labelColor: _primary,
                unselectedLabelColor: _textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Aktivitas'),
                  Tab(text: 'Badge'),
                  Tab(text: 'Pengaturan'),
                ],
              ),
            ),
            // ── Tab Content ─────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActivityTab(),
                  _buildBadgeTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // SLIVER APP BAR + PROFILE HEADER
  // ═══════════════════════════════════════════════
  SliverAppBar _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      snap: false,
      backgroundColor: _primaryDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
          onPressed: _showEditProfileDialog,
          tooltip: 'Edit Profil',
        ),
        const SizedBox(width: 8),
      ],
      title: AnimatedOpacity(
        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          _user['name'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildProfileHeader(),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),

            // ── Avatar ───────────────────────────
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF7D), Color(0xFF1A6B4A)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'BS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Level badge
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    _user['level'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Nama & Info ──────────────────────
            Text(
              _user['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _user['faculty'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
            Text(
              _user['campus'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),

            // ── Badge chip ───────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Text(
                _user['badge'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Stats Row ────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderStat(
                      '${_user['points']}', 'Eco Points', Icons.star_rounded),
                  _buildHeaderDivider(),
                  _buildHeaderStat('${_user['totalReports']}', 'Laporan',
                      Icons.assignment_rounded),
                  _buildHeaderDivider(),
                  _buildHeaderStat('#${_user['rank']}', 'Rank',
                      Icons.emoji_events_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.white.withOpacity(0.25),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 1 — AKTIVITAS
  // ═══════════════════════════════════════════════
  Widget _buildActivityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // ── Progress Level ───────────────────────
        _buildLevelProgress(),
        const SizedBox(height: 20),

        // ── Stats Grid ───────────────────────────
        _buildActivityStatsGrid(),
        const SizedBox(height: 24),

        // ── Riwayat Laporan ──────────────────────
        _buildSectionTitle('Riwayat Laporan', Icons.history_rounded),
        const SizedBox(height: 12),
        ..._reportHistory.map((r) => _buildHistoryCard(r)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLevelProgress() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A6B4A), Color(0xFF2E9E6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Level Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Silver → Gold',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1,240 / 2,000 pts',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
              Text(
                '62%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.62,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor:
              const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '760 pts lagi untuk naik ke level Gold 🥇',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStatsGrid() {
    final stats = [
      {
        'label': 'Challenge\nSelesai',
        'value': '${_user['completedChallenges']}',
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
      },
      {
        'label': 'Event\nDiikuti',
        'value': '${_user['eventsJoined']}',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
      },
      {
        'label': 'Total\nLaporan',
        'value': '${_user['totalReports']}',
        'icon': Icons.assignment_rounded,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'label': 'Bergabung\nSejak',
        'value': 'Jan\n2024',
        'icon': Icons.person_add_rounded,
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFECFDF5),
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: stats.map((s) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (s['color'] as Color).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: s['bg'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(s['icon'] as IconData,
                    color: s['color'] as Color, size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s['value'] as String,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    s['label'] as String,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> report) {
    IconData icon;
    switch (report['category']) {
      case 'Sampah':
        icon = Icons.delete_outline_rounded;
        break;
      case 'Fasilitas':
        icon = Icons.build_outlined;
        break;
      default:
        icon = Icons.eco_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: (report['statusColor'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: report['statusColor'] as Color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['title'],
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      report['category'],
                      style:
                      TextStyle(color: _textSecondary, fontSize: 11),
                    ),
                    Text(
                      ' • ${report['date']}',
                      style:
                      TextStyle(color: _textSecondary, fontSize: 11),
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
              color: (report['statusColor'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              report['status'],
              style: TextStyle(
                color: report['statusColor'] as Color,
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
  // TAB 2 — BADGE
  // ═══════════════════════════════════════════════
  Widget _buildBadgeTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // Total badge earned
        Container(
          padding: const EdgeInsets.all(16),
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
              const Text('🏅', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '4 dari 6 Badge Diraih',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Terus semangat kumpulkan semua badge!',
                    style: TextStyle(
                        color: _textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Koleksi Badge', Icons.workspace_premium_rounded),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: _badges.map((b) => _buildBadgeCard(b)).toList(),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    final bool earned = badge['earned'] as bool;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: earned ? _cardBg : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned
              ? const Color(0xFF2E9E6E).withOpacity(0.3)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: earned
            ? [
          BoxShadow(
            color: const Color(0xFF2E9E6E).withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ColorFiltered(
            colorFilter: earned
                ? const ColorFilter.mode(
                Colors.transparent, BlendMode.multiply)
                : const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 0.4, 0,
            ]),
            child: Text(
              badge['icon'],
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge['title'],
            style: TextStyle(
              color: earned ? _textPrimary : const Color(0xFF9CA3AF),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            badge['desc'],
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (earned) ...[
            const SizedBox(height: 4),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '✓ Diraih',
                style: TextStyle(
                  color: Color(0xFF2E9E6E),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 3 — PENGATURAN
  // ═══════════════════════════════════════════════
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // ── Akun ────────────────────────────────
        _buildSectionTitle('Akun', Icons.manage_accounts_rounded),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildSettingsTile(
            icon: Icons.person_outline_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            title: 'Edit Profil',
            onTap: _showEditProfileDialog,
          ),
          _buildSettingsDivider(),
          _buildSettingsTile(
            icon: Icons.school_outlined,
            iconBg: const Color(0xFFE8F7F0),
            iconColor: _primary,
            title: 'Informasi Kampus',
            subtitle: _user['campus'],
            onTap: () {},
          ),
          _buildSettingsDivider(),
          _buildSettingsTile(
            icon: Icons.lock_outline_rounded,
            iconBg: const Color(0xFFFFFBEB),
            iconColor: const Color(0xFFF59E0B),
            title: 'Ubah Password',
            onTap: () {},
          ),
        ]),
        const SizedBox(height: 20),

        // ── Notifikasi ───────────────────────────
        _buildSectionTitle('Notifikasi', Icons.notifications_outlined),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildSettingsToggle(
            icon: Icons.notifications_active_outlined,
            iconBg: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF8B5CF6),
            title: 'Push Notification',
            subtitle: 'Terima notifikasi event & laporan',
            value: _notifEnabled,
            onChanged: (v) => setState(() => _notifEnabled = v),
          ),
          _buildSettingsDivider(),
          _buildSettingsToggle(
            icon: Icons.dark_mode_outlined,
            iconBg: const Color(0xFF1F2937),
            iconColor: const Color(0xFFD1D5DB),
            title: 'Dark Mode',
            subtitle: 'Ganti tampilan gelap',
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
        ]),
        const SizedBox(height: 20),

        // ── Tentang ──────────────────────────────
        _buildSectionTitle('Tentang', Icons.info_outline_rounded),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildSettingsTile(
            icon: Icons.eco_rounded,
            iconBg: const Color(0xFFE8F7F0),
            iconColor: _primary,
            title: 'Tentang EcoCampus',
            subtitle: 'Versi 1.0.0',
            onTap: () {},
          ),
          _buildSettingsDivider(),
          _buildSettingsTile(
            icon: Icons.help_outline_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            title: 'Bantuan & FAQ',
            onTap: () {},
          ),
          _buildSettingsDivider(),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconBg: const Color(0xFFFFFBEB),
            iconColor: const Color(0xFFF59E0B),
            title: 'Kebijakan Privasi',
            onTap: () {},
          ),
        ]),
        const SizedBox(height: 20),

        // ── Logout ───────────────────────────────
        GestureDetector(
          onTap: _showLogoutDialog,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFFCA5A5).withOpacity(0.5)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded,
                    color: Color(0xFFEF4444), size: 20),
                SizedBox(width: 8),
                Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Helper Settings Widgets ─────────────────────
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
          style:
          TextStyle(color: _textSecondary, fontSize: 12))
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          color: _textSecondary, size: 20),
    );
  }

  Widget _buildSettingsToggle({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle,
          style: TextStyle(color: _textSecondary, fontSize: 12)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: _primary,
      ),
    );
  }

  Widget _buildSettingsDivider() {
    return Divider(
      height: 1,
      indent: 68,
      endIndent: 16,
      color: Colors.grey.withOpacity(0.1),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
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
    );
  }

  // ═══════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════
  void _showEditProfileDialog() {
    final nameCtrl =
    TextEditingController(text: _user['name']);
    final facultyCtrl =
    TextEditingController(text: _user['faculty']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Profil',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                  controller: nameCtrl, label: 'Nama Lengkap'),
              const SizedBox(height: 14),
              _buildTextField(
                  controller: facultyCtrl, label: 'Program Studi'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _user['name'] = nameCtrl.text;
                      _user['faculty'] = facultyCtrl.text;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textSecondary, fontSize: 13),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar?',
            style:
            TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text(
            'Kamu yakin ingin keluar dari akun EcoCampus?',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: implement logout & navigate to LoginScreen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Keluar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}