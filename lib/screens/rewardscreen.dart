import 'package:flutter/material.dart';
import 'leaderboardscreen.dart';
import 'badgescreen.dart';
import 'redeemscreen.dart';

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────
class ChallengeData {
  final String id;
  final String title;
  final String description;
  final int points;
  final String icon;
  final String category;
  final bool isDone;
  final String difficulty; // 'Mudah' | 'Sedang' | 'Sulit'

  const ChallengeData({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.icon,
    required this.category,
    required this.isDone,
    required this.difficulty,
  });
}

// ─────────────────────────────────────────────
// REWARD SCREEN
// ─────────────────────────────────────────────
class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with SingleTickerProviderStateMixin {
  // ── Warna ────────────────────────────────────
  static const Color _primaryDark = Color(0xFF0D4A30);
  static const Color _primary     = Color(0xFF1A6B4A);
  static const Color _surface     = Color(0xFFF4FAF7);
  static const Color _cardBg      = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0D2B1E);
  static const Color _textSec     = Color(0xFF5A7A6A);

  late TabController _tabController;
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua', 'Harian', 'Mingguan', 'Lingkungan', 'Sosial'
  ];

  // ── Dummy Challenges ─────────────────────────
  final List<ChallengeData> _allChallenges = const [
    ChallengeData(id: 'c1', title: 'Bawa tumbler hari ini',           description: 'Gunakan tumbler pribadi, hindari plastik sekali pakai.',  points: 50,  icon: '🧴', category: 'Harian',      isDone: true,  difficulty: 'Mudah'),
    ChallengeData(id: 'c2', title: 'Foto lingkungan bersih',          description: 'Abadikan sudut kampus yang bersih dan unggah ke app.',     points: 30,  icon: '📸', category: 'Harian',      isDone: false, difficulty: 'Mudah'),
    ChallengeData(id: 'c3', title: 'Kurangi 1 plastik sekali pakai',  description: 'Tolak kantong plastik atau sedotan hari ini.',            points: 40,  icon: '♻️', category: 'Harian',      isDone: false, difficulty: 'Mudah'),
    ChallengeData(id: 'c4', title: 'Ikut kegiatan kerja bakti',       description: 'Bergabung di kegiatan bersih-bersih kampus mingguan.',    points: 120, icon: '🧹', category: 'Mingguan',    isDone: false, difficulty: 'Sedang'),
    ChallengeData(id: 'c5', title: 'Laporkan 3 masalah lingkungan',   description: 'Buat 3 laporan valid di minggu ini.',                     points: 150, icon: '📋', category: 'Mingguan',    isDone: false, difficulty: 'Sedang'),
    ChallengeData(id: 'c6', title: 'Tanam 1 bibit pohon',             description: 'Ikuti program penanaman pohon di area kampus.',           points: 200, icon: '🌱', category: 'Lingkungan',  isDone: false, difficulty: 'Sulit'),
    ChallengeData(id: 'c7', title: 'Zero waste selama 3 hari',        description: 'Tidak menghasilkan sampah plastik selama 3 hari penuh.',  points: 300, icon: '🌍', category: 'Lingkungan',  isDone: false, difficulty: 'Sulit'),
    ChallengeData(id: 'c8', title: 'Ajak 2 teman ikut challenge',     description: 'Rekrut teman untuk bergabung di EcoCampus.',              points: 100, icon: '👥', category: 'Sosial',      isDone: true,  difficulty: 'Sedang'),
    ChallengeData(id: 'c9', title: 'Share kegiatan eco di medsos',    description: 'Unggah aktivitas eco-friendly kamu di media sosial.',     points: 60,  icon: '📱', category: 'Sosial',      isDone: false, difficulty: 'Mudah'),
  ];

  List<ChallengeData> get _filtered => _selectedCategory == 'Semua'
      ? _allChallenges
      : _allChallenges
      .where((c) => c.category == _selectedCategory)
      .toList();

  int get _totalPoints => _allChallenges
      .where((c) => c.isDone)
      .fold(0, (sum, c) => sum + c.points);

  int get _doneCount => _allChallenges.where((c) => c.isDone).length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        headerSliverBuilder: (_, __) => [_buildAppBar()],
        body: Column(
          children: [
            // Tab Bar
            Container(
              color: _cardBg,
              child: TabBar(
                controller: _tabController,
                indicatorColor: _primary,
                indicatorWeight: 3,
                labelColor: _primary,
                unselectedLabelColor: _textSec,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Challenge'),
                  Tab(text: 'Riwayat Poin'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChallengeTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryDark,
      automaticallyImplyLeading: false,
      title: const Text('Reward & Challenge',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      actions: [
        // Leaderboard
        IconButton(
          icon: const Icon(Icons.leaderboard_rounded, color: Colors.white),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          tooltip: 'Leaderboard',
        ),
        // Redeem
        IconButton(
          icon: const Icon(Icons.card_giftcard_rounded, color: Colors.white),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RedeemScreen())),
          tooltip: 'Redeem Reward',
        ),
        const SizedBox(width: 4),
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
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Points Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      children: [
                        // Total Points
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Eco Points',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12)),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('1,240',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 6),
                                  Text('pts',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3)),
                        const SizedBox(width: 16),
                        // Challenge Progress
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('$_doneCount/${_allChallenges.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text('Challenge\nSelesai',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 11,
                                    height: 1.3)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Badges
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BadgeScreen())),
                          child: Column(
                            children: [
                              const Text('4',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              Text('Badge\nDiraih',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 11,
                                      height: 1.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Challenge Tab ────────────────────────────
  Widget _buildChallengeTab() {
    return Column(
      children: [
        // Category Filter
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final bool active = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? _primary : _cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: active
                            ? _primary
                            : const Color(0xFFE5E7EB)),
                    boxShadow: active
                        ? [
                      BoxShadow(
                          color: _primary.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ]
                        : [],
                  ),
                  child: Text(cat,
                      style: TextStyle(
                          color: active ? Colors.white : _textSec,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),
        // Challenge List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            physics: const BouncingScrollPhysics(),
            itemCount: _filtered.length,
            itemBuilder: (_, i) => _challengeCard(_filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _challengeCard(ChallengeData c) {
    final Map<String, Color> diffColor = {
      'Mudah': const Color(0xFF10B981),
      'Sedang': const Color(0xFFF59E0B),
      'Sulit': const Color(0xFFEF4444),
    };
    final color = diffColor[c.difficulty] ?? _primary;

    return GestureDetector(
      onTap: () => _showChallengeDetail(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: c.isDone
                ? const Color(0xFF2E9E6E).withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: c.isDone
                      ? const Color(0xFFE8F7F0)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                    child:
                    Text(c.icon, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Difficulty chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(c.difficulty,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8F7F0),
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(c.category,
                              style: const TextStyle(
                                  color: Color(0xFF2E9E6E),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
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
                    const SizedBox(height: 3),
                    Text(c.description,
                        style: TextStyle(color: _textSec, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Points + Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF59E0B), size: 13),
                        const SizedBox(width: 3),
                        Text('+${c.points}',
                            style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Checkbox
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: c.isDone
                          ? const Color(0xFF2E9E6E)
                          : Colors.transparent,
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
            ],
          ),
        ),
      ),
    );
  }

  // ── History Tab ──────────────────────────────
  Widget _buildHistoryTab() {
    final history = [
      {'title': 'Bawa tumbler hari ini',       'pts': 50,  'date': 'Hari ini, 08.12',  'type': 'earn'},
      {'title': 'Ajak 2 teman ikut challenge', 'pts': 100, 'date': 'Kemarin, 14.30',   'type': 'earn'},
      {'title': 'Redeem: Voucher Kantin 10rb', 'pts': -200,'date': '29 Mei, 11.00',    'type': 'redeem'},
      {'title': 'Zero waste 1 hari penuh',     'pts': 80,  'date': '28 Mei, 20.00',    'type': 'earn'},
      {'title': 'Laporan diselesaikan admin',  'pts': 30,  'date': '27 Mei, 15.45',    'type': 'bonus'},
      {'title': 'Redeem: Tumbler EcoCampus',   'pts': -500,'date': '20 Mei, 10.00',    'type': 'redeem'},
      {'title': 'Foto lingkungan bersih',      'pts': 30,  'date': '19 Mei, 09.22',    'type': 'earn'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final h = history[i];
        final bool isEarn = (h['pts'] as int) > 0;
        final bool isRedeem = h['type'] == 'redeem';
        return Container(
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isRedeem
                      ? const Color(0xFFFEF2F2)
                      : h['type'] == 'bonus'
                      ? const Color(0xFFF5F3FF)
                      : const Color(0xFFE8F7F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRedeem
                      ? Icons.card_giftcard_rounded
                      : h['type'] == 'bonus'
                      ? Icons.workspace_premium_rounded
                      : Icons.star_rounded,
                  color: isRedeem
                      ? const Color(0xFFEF4444)
                      : h['type'] == 'bonus'
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF2E9E6E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h['title'] as String,
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(h['date'] as String,
                        style: TextStyle(color: _textSec, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                isEarn ? '+${h['pts']} pts' : '${h['pts']} pts',
                style: TextStyle(
                  color: isEarn
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Challenge Detail Bottom Sheet ────────────
  void _showChallengeDetail(ChallengeData c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(c.icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          style: TextStyle(
                              color: _textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _chip(c.difficulty, const Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          _chip(c.category, _primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(c.description,
                style: TextStyle(color: _textSec, fontSize: 14, height: 1.5)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFF59E0B), size: 22),
                  const SizedBox(width: 8),
                  Text('Hadiah: +${c.points} Eco Points',
                      style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: c.isDone
                    ? null
                    : () {
                  Navigator.pop(context);
                  setState(() {
                    // TODO: connect ke Firebase
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '✅ Challenge "${c.title}" dimulai!'),
                      backgroundColor: _primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.isDone ? Colors.grey[300] : _primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  c.isDone ? '✓ Sudah Selesai' : 'Mulai Challenge',
                  style: TextStyle(
                      color: c.isDone ? Colors.grey[600] : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}