import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_campus/features/profile/pages/leaderboard_page.dart';
import 'package:eco_campus/features/profile/pages/my_badges_page.dart';
import 'package:eco_campus/features/profile/pages/reward_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../auth/pages/login_page.dart';
import 'edit_profile_page.dart';
import 'notification_settings_page.dart';
import 'notifications_page.dart';
import 'privacy_security_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService authService = AuthService();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isLoggingOut = false;
  String? errorMessage;

  Map<String, dynamic>? profileData;
  int reportCount = 0;
  int rank = 0;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
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
        throw Exception('Data profile tidak ditemukan.');
      }

      final Map<String, dynamic> data = userSnapshot.data() ?? {};

      final int totalReports = await getReportCount(user.uid);
      final int userRank = await getUserRank(user.uid);

      if (!mounted) return;

      setState(() {
        profileData = data;
        reportCount = totalReports;
        rank = userRank;
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

  Future<int> getReportCount(String uid) async {
    final Set<String> reportIds = {};

    try {
      final QuerySnapshot<Map<String, dynamic>> studentUidSnapshot =
          await firestore
              .collection('reports')
              .where('studentUid', isEqualTo: uid)
              .get();

      for (final doc in studentUidSnapshot.docs) {
        reportIds.add(doc.id);
      }
    } catch (_) {}

    try {
      final QuerySnapshot<Map<String, dynamic>> reportedBySnapshot =
          await firestore
              .collection('reports')
              .where('reportedBy', isEqualTo: uid)
              .get();

      for (final doc in reportedBySnapshot.docs) {
        reportIds.add(doc.id);
      }
    } catch (_) {}

    return reportIds.length;
  }

  Future<int> getUserRank(String uid) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> students =
          snapshot.docs.toList();

      students.sort((a, b) {
        final int pointsA = toInt(a.data()['points']);
        final int pointsB = toInt(b.data()['points']);

        return pointsB.compareTo(pointsA);
      });

      final int index = students.indexWhere((doc) {
        final Map<String, dynamic> data = doc.data();
        final String dataUid = (data['uid'] ?? '').toString();

        return doc.id == uid || dataUid == uid;
      });

      if (index == -1) return 0;

      return index + 1;
    } catch (_) {
      return 0;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUnreadNotificationsStream() {
    final User? user = auth.currentUser;

    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  int toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

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

  String getInitial(String name) {
    final String cleanName = name.trim();

    if (cleanName.isEmpty) return 'E';

    return cleanName[0].toUpperCase();
  }

  _EcoProgress getEcoProgress(int points, String firestoreLevel) {
    final List<_EcoLevel> levels = [
      const _EcoLevel(name: 'Eco Starter', minPoint: 0),
      const _EcoLevel(name: 'Eco Warrior', minPoint: 500),
      const _EcoLevel(name: 'Green Champion', minPoint: 1000),
      const _EcoLevel(name: 'Eco Hero', minPoint: 2000),
      const _EcoLevel(name: 'Eco Legend', minPoint: 3500),
    ];

    int currentIndex = 0;

    for (int i = 0; i < levels.length; i++) {
      if (points >= levels[i].minPoint) {
        currentIndex = i;
      }
    }

    final _EcoLevel currentLevel = levels[currentIndex];
    final _EcoLevel? nextLevel = currentIndex + 1 < levels.length
        ? levels[currentIndex + 1]
        : null;

    final String displayLevel = firestoreLevel.trim().isNotEmpty
        ? firestoreLevel
        : currentLevel.name;

    if (nextLevel == null) {
      return _EcoProgress(
        displayLevel: displayLevel,
        nextLevel: null,
        progress: 1,
        percentage: 100,
        remainingPoints: 0,
      );
    }

    final int currentMin = currentLevel.minPoint;
    final int nextMin = nextLevel.minPoint;
    final int range = nextMin - currentMin;
    final int currentProgressPoint = points - currentMin;

    final double progress = range == 0 ? 0 : currentProgressPoint / range;
    final int percentage = (progress.clamp(0.0, 1.0) * 100).round();
    final int remainingPoints = nextMin - points;

    return _EcoProgress(
      displayLevel: displayLevel,
      nextLevel: nextLevel.name,
      progress: progress.clamp(0.0, 1.0),
      percentage: percentage,
      remainingPoints: remainingPoints < 0 ? 0 : remainingPoints,
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan ditambahkan nanti.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> handleLogout() async {
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      await authService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (error) {
      showMessage('Logout gagal: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: const Text(
            'Logout?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun EcoCampus?',
            style: TextStyle(color: Color(0xFF64748B), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsMenuItem() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: getUnreadNotificationsStream(),
      builder: (context, snapshot) {
        final int unreadCount = snapshot.data?.docs.length ?? 0;

        return _ProfileMenuItem(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: unreadCount == 0
              ? 'Lihat update laporan, challenge, event, dan reward'
              : '$unreadCount notifikasi belum dibaca',
          trailing: unreadCount > 0
              ? _UnreadNotificationBadge(count: unreadCount)
              : null,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingPage();
    }

    if (errorMessage != null) {
      return _buildErrorPage();
    }

    final Map<String, dynamic> data = profileData ?? {};

    final String name = getString(data, 'name', fallback: 'EcoCampus User');
    final String email = getString(
      data,
      'email',
      fallback: auth.currentUser?.email ?? '-',
    );
    final String studentId = getString(data, 'studentId');
    final String departmentName = getString(data, 'departmentName');
    final String universityName = getString(data, 'universityName');
    final String universityShortName = getString(
      data,
      'universityShortName',
      fallback: universityName,
    );
    final String level = getString(data, 'level', fallback: 'Eco Starter');
    final int points = toInt(data['points']);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadProfileData,
          color: const Color(0xFF0F8A5F),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              children: [
                _buildHeader(context),
                Transform.translate(
                  offset: const Offset(0, -42),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        _buildProfileCard(
                          name: name,
                          email: email,
                          studentId: studentId,
                          departmentName: departmentName,
                          universityName: universityShortName,
                          level: level,
                          photoUrl: getString(data, 'photoUrl', fallback: ''),
                        ),
                        const SizedBox(height: 18),
                        _buildStatsRow(
                          points: points,
                          reports: reportCount,
                          rank: rank,
                        ),
                        const SizedBox(height: 24),
                        _buildEcoLevelCard(points: points, level: level),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Account'),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          children: [
                            _ProfileMenuItem(
                              icon: Icons.person_outline_rounded,
                              title: 'Edit Profile',
                              subtitle: 'Ubah nama dan foto profile',
                              onTap: () async {
                                final bool? updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(
                                      initialData: profileData ?? {},
                                    ),
                                  ),
                                );

                                if (updated == true) {
                                  loadProfileData();
                                }
                              },
                            ),
                            _buildNotificationsMenuItem(),
                            _ProfileMenuItem(
                              icon: Icons.tune_rounded,
                              title: 'Notification Settings',
                              subtitle:
                                  'Atur notifikasi laporan, challenge, event, dan reward',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationSettingsPage(),
                                  ),
                                );
                              },
                            ),
                            _ProfileMenuItem(
                              icon: Icons.lock_outline_rounded,
                              title: 'Privacy & Security',
                              subtitle: 'Kelola keamanan akun kamu',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PrivacySecurityPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('EcoCampus'),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          children: [
                            _ProfileMenuItem(
                              icon: Icons.workspace_premium_outlined,
                              title: 'My Badges',
                              subtitle:
                                  'Lihat badge dan progress pencapaian kamu',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MyBadgesPage(),
                                  ),
                                );
                              },
                            ),
                            _ProfileMenuItem(
                              icon: Icons.history_rounded,
                              title: 'Reward History',
                              subtitle: 'Riwayat penukaran reward kamu',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RewardHistoryPage(),
                                  ),
                                );
                              },
                            ),
                            _ProfileMenuItem(
                              icon: Icons.leaderboard_rounded,
                              title: 'Leaderboard',
                              subtitle: 'Lihat peringkat Eco Warrior',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LeaderboardPage(),
                                        
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildLogoutButton(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Transform.translate(
              offset: const Offset(0, -42),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 42,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14532D).withOpacity(0.08),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF0F8A5F)),
                      SizedBox(height: 18),
                      Text(
                        'Mengambil data profile...',
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
        child: RefreshIndicator(
          onRefresh: loadProfileData,
          color: const Color(0xFF0F8A5F),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              children: [
                _buildHeader(context),
                Transform.translate(
                  offset: const Offset(0, -42),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF14532D).withOpacity(0.08),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Gagal mengambil profile',
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
                              onPressed: loadProfileData,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text(
                                'Coba Lagi',
                                style: TextStyle(fontWeight: FontWeight.w900),
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
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 76),
      decoration: const BoxDecoration(
        color: Color(0xFF0F8A5F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String email,
    required String studentId,
    required String departmentName,
    required String universityName,
    required String level,
    required String photoUrl,
  }) {
    final String initial = getInitial(name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.08),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFD9FBE8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFF0F8A5F), width: 3),
            ),
            child: photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(29),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Color(0xFF0F8A5F),
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF0F8A5F),
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$studentId • $departmentName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$universityName • $email',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD9FBE8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.eco_rounded,
                  size: 17,
                  color: Color(0xFF0F8A5F),
                ),
                const SizedBox(width: 6),
                Text(
                  level,
                  style: const TextStyle(
                    color: Color(0xFF0F8A5F),
                    fontSize: 13,
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

  Widget _buildStatsRow({
    required int points,
    required int reports,
    required int rank,
  }) {
    return Row(
      children: [
        Expanded(
          child: _ProfileStatCard(
            icon: Icons.star_rounded,
            value: formatNumber(points),
            label: 'Points',
            color: const Color(0xFF0F8A5F),
            background: const Color(0xFFD9FBE8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProfileStatCard(
            icon: Icons.article_outlined,
            value: formatNumber(reports),
            label: 'Reports',
            color: const Color(0xFF087EA4),
            background: const Color(0xFFE0F4FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProfileStatCard(
            icon: Icons.emoji_events_rounded,
            value: rank == 0 ? '-' : '#$rank',
            label: 'Rank',
            color: const Color(0xFFB7791F),
            background: const Color(0xFFFFF4BA),
          ),
        ),
      ],
    );
  }

  Widget _buildEcoLevelCard({required int points, required String level}) {
    final _EcoProgress ecoProgress = getEcoProgress(points, level);

    final String description = ecoProgress.nextLevel == null
        ? 'Kamu sudah mencapai level tertinggi. Pertahankan kontribusimu untuk lingkungan kampus.'
        : 'Kumpulkan ${formatNumber(ecoProgress.remainingPoints)} poin lagi untuk naik ke level ${ecoProgress.nextLevel}.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F8A5F),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F8A5F).withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ecoProgress.displayLevel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${ecoProgress.percentage}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ecoProgress.progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.20),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: isLoggingOut ? null : () => showLogoutDialog(context),
        icon: isLoggingOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Color(0xFFEF4444),
                ),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(
          isLoggingOut ? 'Logging out...' : 'Logout',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF4444),
          side: const BorderSide(color: Color(0xFFFECACA), width: 1.4),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  const _ProfileStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final Widget? trailing;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9FBE8),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: const Color(0xFF0F8A5F), size: 23),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                trailing ??
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFCBD5E1),
                      size: 28,
                    ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}

class _UnreadNotificationBadge extends StatelessWidget {
  final int count;

  const _UnreadNotificationBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final String text = count > 99 ? '99+' : count.toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.22),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFCBD5E1),
          size: 28,
        ),
      ],
    );
  }
}

class _EcoLevel {
  final String name;
  final int minPoint;

  const _EcoLevel({required this.name, required this.minPoint});
}

class _EcoProgress {
  final String displayLevel;
  final String? nextLevel;
  final double progress;
  final int percentage;
  final int remainingPoints;

  const _EcoProgress({
    required this.displayLevel,
    required this.nextLevel,
    required this.progress,
    required this.percentage,
    required this.remainingPoints,
  });
}
