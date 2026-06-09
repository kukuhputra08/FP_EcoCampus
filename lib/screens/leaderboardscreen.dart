import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────
class LeaderboardEntry {
  final int rank;
  final String name;
  final String faculty;
  final int points;
  final String badge;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.faculty,
    required this.points,
    required this.badge,
    this.isCurrentUser = false,
  });
}

// ─────────────────────────────────────────────
// LEADERBOARD SCREEN
// ─────────────────────────────────────────────
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryDark = Color(0xFF0D4A30);
  static const Color _primary     = Color(0xFF1A6B4A);
  static const Color _surface     = Color(0xFFF4FAF7);
  static const Color _cardBg      = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0D2B1E);
  static const Color _textSec     = Color(0xFF5A7A6A);

  late TabController _tabController;

  final List<LeaderboardEntry> _allTime = const [
    LeaderboardEntry(rank: 1,  name: 'Rina Kusuma',    faculty: 'Teknik Lingkungan', points: 4850, badge: '🥇'),
    LeaderboardEntry(rank: 2,  name: 'Dimas Pratama',  faculty: 'Biologi',           points: 4200, badge: '🥈'),
    LeaderboardEntry(rank: 3,  name: 'Sari Dewi',      faculty: 'Kimia',             points: 3900, badge: '🥉'),
    LeaderboardEntry(rank: 4,  name: 'Agus Widodo',    faculty: 'Fisika',            points: 3400, badge: '🏅'),
    LeaderboardEntry(rank: 5,  name: 'Mega Lestari',   faculty: 'Arsitektur',        points: 3100, badge: '🏅'),
    LeaderboardEntry(rank: 6,  name: 'Fajar Nugroho',  faculty: 'Teknik Sipil',      points: 2800, badge: '🏅'),
    LeaderboardEntry(rank: 7,  name: 'Putri Rahma',    faculty: 'Manajemen',         points: 2500, badge: '🏅'),
    LeaderboardEntry(rank: 8,  name: 'Hendra Saputra', faculty: 'Ekonomi',           points: 2200, badge: '🌿'),
    LeaderboardEntry(rank: 9,  name: 'Novia Sari',     faculty: 'Psikologi',         points: 1900, badge: '🌿'),
    LeaderboardEntry(rank: 10, name: 'Rizky Aditya',   faculty: 'Hukum',             points: 1700, badge: '🌿'),
    LeaderboardEntry(rank: 11, name: 'Laila Anggun',   faculty: 'Sastra',            points: 1500, badge: '🌿'),
    LeaderboardEntry(rank: 12, name: 'Budi Santoso',   faculty: 'Teknik Informatika',points: 1240, badge: '🌿', isCurrentUser: true),
    LeaderboardEntry(rank: 13, name: 'Citra Melati',   faculty: 'Pendidikan',        points: 1100, badge: '🌿'),
    LeaderboardEntry(rank: 14, name: 'Bayu Setiawan',  faculty: 'Kedokteran',        points: 900,  badge: '🌱'),
    LeaderboardEntry(rank: 15, name: 'Tika Permata',   faculty: 'Farmasi',           points: 750,  badge: '🌱'),
  ];

  final List<LeaderboardEntry> _weekly = const [
    LeaderboardEntry(rank: 1,  name: 'Fajar Nugroho',  faculty: 'Teknik Sipil',      points: 520,  badge: '🥇'),
    LeaderboardEntry(rank: 2,  name: 'Sari Dewi',      faculty: 'Kimia',             points: 480,  badge: '🥈'),
    LeaderboardEntry(rank: 3,  name: 'Mega Lestari',   faculty: 'Arsitektur',        points: 390,  badge: '🥉'),
    LeaderboardEntry(rank: 4,  name: 'Rina Kusuma',    faculty: 'Teknik Lingkungan', points: 340,  badge: '🏅'),
    LeaderboardEntry(rank: 5,  name: 'Rizky Aditya',   faculty: 'Hukum',             points: 310,  badge: '🏅'),
    LeaderboardEntry(rank: 6,  name: 'Budi Santoso',   faculty: 'Teknik Informatika',points: 280,  badge: '🏅', isCurrentUser: true),
    LeaderboardEntry(rank: 7,  name: 'Putri Rahma',    faculty: 'Manajemen',         points: 250,  badge: '🌿'),
    LeaderboardEntry(rank: 8,  name: 'Dimas Pratama',  faculty: 'Biologi',           points: 220,  badge: '🌿'),
    LeaderboardEntry(rank: 9,  name: 'Novia Sari',     faculty: 'Psikologi',         points: 190,  badge: '🌿'),
    LeaderboardEntry(rank: 10, name: 'Hendra Saputra', faculty: 'Ekonomi',           points: 160,  badge: '🌿'),
  ];

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
                  Tab(text: 'All Time'),
                  Tab(text: 'Minggu Ini'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_allTime),
                  _buildList(_weekly),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Leaderboard',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Top 3 podium
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Rank 2
                      _podiumItem(_allTime[1], 80, const Color(0xFFC0C0C0)),
                      const SizedBox(width: 12),
                      // Rank 1
                      _podiumItem(_allTime[0], 100, const Color(0xFFFFD700)),
                      const SizedBox(width: 12),
                      // Rank 3
                      _podiumItem(_allTime[2], 65, const Color(0xFFCD7F32)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _podiumItem(LeaderboardEntry e, double size, Color medalColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(e.badge, style: TextStyle(fontSize: size == 100 ? 20 : 16)),
        const SizedBox(height: 4),
        Container(
          width: size == 100 ? 54 : 46,
          height: size == 100 ? 54 : 46,
          decoration: BoxDecoration(
            color: medalColor.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: medalColor, width: 2.5),
          ),
          child: Center(
            child: Text(
              e.name.split(' ').first[0] +
                  (e.name.split(' ').length > 1
                      ? e.name.split(' ')[1][0]
                      : ''),
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size == 100 ? 18 : 14),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 70,
          child: Text(
            e.name.split(' ').first,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${e.points} pts',
          style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildList(List<LeaderboardEntry> entries) {
    // Cari posisi user saat ini
    final userEntry = entries.firstWhere(
          (e) => e.isCurrentUser,
      orElse: () => const LeaderboardEntry(
          rank: 0, name: '', faculty: '', points: 0, badge: ''),
    );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: entries.length + (userEntry.rank > 4 ? 1 : 0),
      itemBuilder: (_, i) {
        // Sticky "posisi kamu" di atas jika rank user > 4
        if (i == 0 && userEntry.rank > 4) {
          return _myPositionBanner(userEntry);
        }
        final entry = userEntry.rank > 4 ? entries[i - 1] : entries[i];
        return _leaderboardCard(entry);
      },
    );
  }

  Widget _myPositionBanner(LeaderboardEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A6B4A), Color(0xFF2E9E6E)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Text('Posisi kamu saat ini',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('Rank #${e.rank}  •  ${e.points} pts',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _leaderboardCard(LeaderboardEntry e) {
    final bool isTop3 = e.rank <= 3;
    final Map<int, Color> rankColors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: e.isCurrentUser
            ? const Color(0xFFE8F7F0)
            : _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: e.isCurrentUser
            ? Border.all(color: _primary.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: isTop3
                ? Text(e.badge,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22))
                : Text('#${e.rank}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: e.isCurrentUser ? _primary : _textSec,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTop3
                  ? rankColors[e.rank]!.withOpacity(0.2)
                  : e.isCurrentUser
                  ? _primary.withOpacity(0.15)
                  : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
              border: isTop3
                  ? Border.all(color: rankColors[e.rank]!, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                e.name.split(' ').map((w) => w[0]).take(2).join(),
                style: TextStyle(
                    color: e.isCurrentUser ? _primary : _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name & Faculty
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.isCurrentUser ? '${e.name} (Kamu)' : e.name,
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(e.faculty,
                    style: TextStyle(color: _textSec, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${e.points}',
                  style: TextStyle(
                      color: isTop3
                          ? rankColors[e.rank]!
                          : e.isCurrentUser
                          ? _primary
                          : _textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text('pts',
                  style: TextStyle(color: _textSec, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}