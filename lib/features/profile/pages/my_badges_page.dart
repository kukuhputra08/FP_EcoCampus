import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyBadgesPage extends StatefulWidget {
  const MyBadgesPage({super.key});

  @override
  State<MyBadgesPage> createState() => _MyBadgesPageState();
}

class _MyBadgesPageState extends State<MyBadgesPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  String? errorMessage;

  int points = 0;
  int reportCount = 0;
  int approvedChallengeCount = 0;
  int eventCount = 0;
  int rewardRedeemCount = 0;

  String name = 'EcoCampus User';
  String level = 'Eco Starter';

  @override
  void initState() {
    super.initState();
    loadBadgesData();
  }

  Future<void> loadBadgesData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final User? user = auth.currentUser;

      if (user == null) {
        throw Exception('User belum login.');
      }

      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await firestore.collection('users').doc(user.uid).get();

      if (!userSnapshot.exists) {
        throw Exception('Data user tidak ditemukan.');
      }

      final Map<String, dynamic> userData = userSnapshot.data() ?? {};

      final int loadedPoints = toInt(userData['points']);
      final String loadedName = getString(
        userData,
        'name',
        fallback: user.displayName ?? 'EcoCampus User',
      );
      final String loadedLevel = getString(
        userData,
        'level',
        fallback: 'Eco Starter',
      );

      final int loadedReportCount = await getReportCount(
        uid: user.uid,
        studentName: loadedName,
      );

      final int loadedApprovedChallengeCount =
          await getApprovedChallengeCount(uid: user.uid);

      final int loadedEventCount = await getEventCount(uid: user.uid);

      final int loadedRewardRedeemCount =
          await getRewardRedeemCount(uid: user.uid);

      if (!mounted) return;

      setState(() {
        points = loadedPoints;
        name = loadedName;
        level = loadedLevel;
        reportCount = loadedReportCount;
        approvedChallengeCount = loadedApprovedChallengeCount;
        eventCount = loadedEventCount;
        rewardRedeemCount = loadedRewardRedeemCount;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<int> getReportCount({
    required String uid,
    required String studentName,
  }) async {
    final Set<String> reportIds = {};

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('reports')
          .where('studentUid', isEqualTo: uid)
          .get();

      for (final doc in snapshot.docs) {
        reportIds.add(doc.id);
      }
    } catch (_) {}

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('reports')
          .where('reportedBy', isEqualTo: studentName)
          .get();

      for (final doc in snapshot.docs) {
        reportIds.add(doc.id);
      }
    } catch (_) {}

    return reportIds.length;
  }

  Future<int> getApprovedChallengeCount({
    required String uid,
  }) async {
    final Set<String> submissionIds = {};

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('challengeSubmissions')
          .where('studentUid', isEqualTo: uid)
          .where('status', isEqualTo: 'approved')
          .get();

      for (final doc in snapshot.docs) {
        submissionIds.add(doc.id);
      }
    } catch (_) {}

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('challengeSubmissions')
          .where('studentId', isEqualTo: uid)
          .where('status', isEqualTo: 'approved')
          .get();

      for (final doc in snapshot.docs) {
        submissionIds.add(doc.id);
      }
    } catch (_) {}

    return submissionIds.length;
  }

  Future<int> getEventCount({
    required String uid,
  }) async {
    final Set<String> participantIds = {};

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('eventParticipants')
          .where('studentUid', isEqualTo: uid)
          .get();

      for (final doc in snapshot.docs) {
        participantIds.add(doc.id);
      }
    } catch (_) {}

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('eventParticipants')
          .where('studentId', isEqualTo: uid)
          .get();

      for (final doc in snapshot.docs) {
        participantIds.add(doc.id);
      }
    } catch (_) {}

    return participantIds.length;
  }

  Future<int> getRewardRedeemCount({
    required String uid,
  }) async {
    final Set<String> redemptionIds = {};

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('rewardRedemptions')
          .where('studentUid', isEqualTo: uid)
          .get();

      for (final doc in snapshot.docs) {
        redemptionIds.add(doc.id);
      }
    } catch (_) {}

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('rewardRedemptions')
          .where('studentId', isEqualTo: uid)
          .get();

      for (final doc in snapshot.docs) {
        redemptionIds.add(doc.id);
      }
    } catch (_) {}

    return redemptionIds.length;
  }

  int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String getString(
    Map<String, dynamic> data,
    String key, {
    String fallback = '-',
  }) {
    final dynamic value = data[key];

    if (value == null) return fallback;

    final String text = value.toString().trim();

    if (text.isEmpty) return fallback;

    return text;
  }

  String formatNumber(int number) {
    final String text = number.toString();

    return text.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
  }

  List<_BadgeData> getBadges() {
    return [
      _BadgeData(
        title: 'First Reporter',
        description: 'Mengirim laporan pertama di EcoCampus.',
        category: 'Reports',
        icon: Icons.article_outlined,
        currentValue: reportCount,
        targetValue: 1,
        unit: 'laporan',
        color: const Color(0xFF087EA4),
        background: const Color(0xFFE0F4FF),
      ),
      _BadgeData(
        title: 'Campus Reporter',
        description: 'Mengirim minimal 5 laporan lingkungan kampus.',
        category: 'Reports',
        icon: Icons.fact_check_outlined,
        currentValue: reportCount,
        targetValue: 5,
        unit: 'laporan',
        color: const Color(0xFF087EA4),
        background: const Color(0xFFE0F4FF),
      ),
      _BadgeData(
        title: 'Eco Guardian',
        description: 'Mengirim minimal 10 laporan untuk membantu kampus.',
        category: 'Reports',
        icon: Icons.shield_outlined,
        currentValue: reportCount,
        targetValue: 10,
        unit: 'laporan',
        color: const Color(0xFF087EA4),
        background: const Color(0xFFE0F4FF),
      ),
      _BadgeData(
        title: 'Challenge Starter',
        description: 'Menyelesaikan 1 challenge yang disetujui admin.',
        category: 'Challenges',
        icon: Icons.task_alt_rounded,
        currentValue: approvedChallengeCount,
        targetValue: 1,
        unit: 'challenge',
        color: const Color(0xFF0F8A5F),
        background: const Color(0xFFD9FBE8),
      ),
      _BadgeData(
        title: 'Challenge Achiever',
        description: 'Menyelesaikan 5 challenge yang disetujui admin.',
        category: 'Challenges',
        icon: Icons.workspace_premium_outlined,
        currentValue: approvedChallengeCount,
        targetValue: 5,
        unit: 'challenge',
        color: const Color(0xFF0F8A5F),
        background: const Color(0xFFD9FBE8),
      ),
      _BadgeData(
        title: 'Volunteer Spirit',
        description: 'Mengikuti 1 event atau volunteer EcoCampus.',
        category: 'Events',
        icon: Icons.event_available_outlined,
        currentValue: eventCount,
        targetValue: 1,
        unit: 'event',
        color: const Color(0xFF7C3AED),
        background: const Color(0xFFF3E8FF),
      ),
      _BadgeData(
        title: 'Community Hero',
        description: 'Mengikuti 3 event atau volunteer kampus.',
        category: 'Events',
        icon: Icons.groups_rounded,
        currentValue: eventCount,
        targetValue: 3,
        unit: 'event',
        color: const Color(0xFF7C3AED),
        background: const Color(0xFFF3E8FF),
      ),
      _BadgeData(
        title: 'Reward Hunter',
        description: 'Berhasil menukar reward pertama.',
        category: 'Rewards',
        icon: Icons.card_giftcard_rounded,
        currentValue: rewardRedeemCount,
        targetValue: 1,
        unit: 'reward',
        color: const Color(0xFFB7791F),
        background: const Color(0xFFFFF4BA),
      ),
      _BadgeData(
        title: 'Eco Starter',
        description: 'Mengumpulkan minimal 100 points.',
        category: 'Points',
        icon: Icons.eco_rounded,
        currentValue: points,
        targetValue: 100,
        unit: 'points',
        color: const Color(0xFF0F8A5F),
        background: const Color(0xFFD9FBE8),
      ),
      _BadgeData(
        title: 'Green Champion',
        description: 'Mengumpulkan minimal 500 points.',
        category: 'Points',
        icon: Icons.emoji_events_rounded,
        currentValue: points,
        targetValue: 500,
        unit: 'points',
        color: const Color(0xFFB7791F),
        background: const Color(0xFFFFF4BA),
      ),
      _BadgeData(
        title: 'Eco Hero',
        description: 'Mengumpulkan minimal 1000 points.',
        category: 'Points',
        icon: Icons.bolt_rounded,
        currentValue: points,
        targetValue: 1000,
        unit: 'points',
        color: const Color(0xFFEF4444),
        background: const Color(0xFFFEE2E2),
      ),
    ];
  }

  int getUnlockedBadgeCount() {
    return getBadges().where((badge) => badge.isUnlocked).length;
  }

  double getOverallProgress() {
    final List<_BadgeData> badges = getBadges();

    if (badges.isEmpty) return 0;

    return getUnlockedBadgeCount() / badges.length;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingPage();
    }

    if (errorMessage != null) {
      return _buildErrorPage();
    }

    final List<_BadgeData> badges = getBadges();
    final int unlockedCount = getUnlockedBadgeCount();
    final int totalCount = badges.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0F8A5F),
                onRefresh: loadBadgesData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  children: [
                    _buildSummaryCard(
                      unlockedCount: unlockedCount,
                      totalCount: totalCount,
                    ),
                    const SizedBox(height: 16),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      unlockedCount: unlockedCount,
                      totalCount: totalCount,
                    ),
                    const SizedBox(height: 14),
                    ...badges.map(
                      (badge) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _BadgeCard(
                            badge: badge,
                            formatNumber: formatNumber,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: const BoxDecoration(
        color: Color(0xFF0F8A5F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Badges',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Pencapaian EcoCampus kamu',
                  style: TextStyle(
                    color: Color(0xFFE5FFF1),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: loadBadgesData,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int unlockedCount,
    required int totalCount,
  }) {
    final double progress = getOverallProgress();
    final int percentage = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4BA),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFB7791F),
              size: 38,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlockedCount dari $totalCount Badge',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$name • $level',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0F8A5F),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$percentage% badge terbuka',
                  style: const TextStyle(
                    color: Color(0xFF0F8A5F),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _MiniStatsCard(
            icon: Icons.star_rounded,
            value: formatNumber(points),
            label: 'Points',
            color: const Color(0xFF0F8A5F),
            background: const Color(0xFFD9FBE8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatsCard(
            icon: Icons.article_outlined,
            value: formatNumber(reportCount),
            label: 'Reports',
            color: const Color(0xFF087EA4),
            background: const Color(0xFFE0F4FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatsCard(
            icon: Icons.task_alt_rounded,
            value: formatNumber(approvedChallengeCount),
            label: 'Approved',
            color: const Color(0xFF7C3AED),
            background: const Color(0xFFF3E8FF),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({
    required int unlockedCount,
    required int totalCount,
  }) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Badge Collection',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD9FBE8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$unlockedCount/$totalCount',
            style: const TextStyle(
              color: Color(0xFF0F8A5F),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingPage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 34,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14532D).withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF0F8A5F),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Mengambil badge kamu...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14532D).withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Gagal mengambil badges',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage ?? 'Terjadi kesalahan.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: loadBadgesData,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(
                            'Coba Lagi',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F8A5F),
                            foregroundColor: Colors.white,
                            elevation: 0,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeData {
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final int currentValue;
  final int targetValue;
  final String unit;
  final Color color;
  final Color background;

  const _BadgeData({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.color,
    required this.background,
  });

  bool get isUnlocked => currentValue >= targetValue;

  double get progress {
    if (targetValue <= 0) return 0;

    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  int get remaining {
    final int value = targetValue - currentValue;

    if (value < 0) return 0;

    return value;
  }
}

class _BadgeCard extends StatelessWidget {
  final _BadgeData badge;
  final String Function(int number) formatNumber;

  const _BadgeCard({
    required this.badge,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = badge.isUnlocked;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isUnlocked ? const Color(0xFFB7E4C7) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BadgeIcon(badge: badge),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BadgeTopRow(badge: badge),
                const SizedBox(height: 9),
                Text(
                  badge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnlocked
                        ? const Color(0xFF111827)
                        : const Color(0xFF64748B),
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.8,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: badge.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUnlocked ? badge.color : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isUnlocked
                      ? '${formatNumber(badge.currentValue)} ${badge.unit} • selesai'
                      : '${formatNumber(badge.currentValue)}/${formatNumber(badge.targetValue)} ${badge.unit} • kurang ${formatNumber(badge.remaining)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnlocked ? badge.color : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final _BadgeData badge;

  const _BadgeIcon({
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = badge.isUnlocked;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: isUnlocked ? badge.background : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Icon(
            isUnlocked ? badge.icon : Icons.lock_outline_rounded,
            color: isUnlocked ? badge.color : const Color(0xFF94A3B8),
            size: 30,
          ),
        ),
        if (isUnlocked)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF0F8A5F),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _BadgeTopRow extends StatelessWidget {
  final _BadgeData badge;

  const _BadgeTopRow({
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = badge.isUnlocked;

    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isUnlocked ? badge.background : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge.category.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnlocked ? badge.color : const Color(0xFF94A3B8),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isUnlocked
                ? const Color(0xFFD9FBE8)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            isUnlocked ? 'OPEN' : 'LOCKED',
            style: TextStyle(
              color: isUnlocked
                  ? const Color(0xFF0F8A5F)
                  : const Color(0xFF64748B),
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStatsCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  const _MiniStatsCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}