import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  String? errorMessage;

  List<_LeaderboardUser> users = [];
  _LeaderboardUser? currentUserData;

  @override
  void initState() {
    super.initState();
    loadLeaderboard();
  }

  Future<void> loadLeaderboard() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final User? currentUser = auth.currentUser;

      if (currentUser == null) {
        throw Exception('User belum login.');
      }

      final QuerySnapshot<Map<String, dynamic>> userSnapshot =
          await firestore.collection('users').get();

      final Map<String, String> studentIdToUid = {};
      final Map<String, String> emailToUid = {};
      final Set<String> userUidSet = {};

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> studentDocs = [];

      for (final doc in userSnapshot.docs) {
        final Map<String, dynamic> data = doc.data();

        final String role = getString(data, 'role', fallback: '').toLowerCase();

        final bool isStudentRole = role == 'student' ||
            role == 'mahasiswa' ||
            role == 'user' ||
            role.isEmpty;

        if (!isStudentRole) {
          continue;
        }

        studentDocs.add(doc);
        userUidSet.add(doc.id);

        final String studentId = getString(data, 'studentId', fallback: '');
        final String email = getString(data, 'email', fallback: '');

        if (studentId.isNotEmpty) {
          studentIdToUid[studentId] = doc.id;
        }

        if (email.isNotEmpty) {
          emailToUid[email] = doc.id;
        }
      }

      final Map<String, int> leaderboardPointsByUid =
          await calculateLeaderboardPointsFromApprovedSubmissions(
        userUidSet: userUidSet,
        studentIdToUid: studentIdToUid,
        emailToUid: emailToUid,
      );

      final List<_LeaderboardUser> loadedUsers = [];

      for (final doc in studentDocs) {
        final int calculatedLeaderboardPoints =
            leaderboardPointsByUid[doc.id] ?? 0;

        loadedUsers.add(
          _LeaderboardUser.fromFirestore(
            uid: doc.id,
            data: doc.data(),
            currentUserUid: currentUser.uid,
            leaderboardPoints: calculatedLeaderboardPoints,
          ),
        );
      }

      loadedUsers.sort((a, b) {
        return b.leaderboardPoints.compareTo(a.leaderboardPoints);
      });

      for (int i = 0; i < loadedUsers.length; i++) {
        loadedUsers[i] = loadedUsers[i].copyWith(rank: i + 1);
      }

      _LeaderboardUser? myData;

      for (final leaderboardUser in loadedUsers) {
        if (leaderboardUser.uid == currentUser.uid) {
          myData = leaderboardUser;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        users = loadedUsers;
        currentUserData = myData;
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

  Future<Map<String, int>> calculateLeaderboardPointsFromApprovedSubmissions({
    required Set<String> userUidSet,
    required Map<String, String> studentIdToUid,
    required Map<String, String> emailToUid,
  }) async {
    final Map<String, int> pointsByUid = {};

    final QuerySnapshot<Map<String, dynamic>> submissionSnapshot =
        await firestore.collection('challengeSubmissions').get();

    for (final doc in submissionSnapshot.docs) {
      final Map<String, dynamic> data = doc.data();

      final String status = getString(data, 'status', fallback: '');

      if (!isApprovedSubmissionStatus(status)) {
        continue;
      }

      final int points = getSubmissionPoints(data);

      if (points <= 0) {
        continue;
      }

      String uid = '';

      final String studentUid = getString(data, 'studentUid', fallback: '');
      final String userId = getString(data, 'userId', fallback: '');
      final String rawUid = getString(data, 'uid', fallback: '');
      final String studentId = getString(data, 'studentId', fallback: '');
      final String studentEmail =
          getString(data, 'studentEmail', fallback: '');
      final String email = getString(data, 'email', fallback: '');

      if (studentUid.isNotEmpty && userUidSet.contains(studentUid)) {
        uid = studentUid;
      } else if (userId.isNotEmpty && userUidSet.contains(userId)) {
        uid = userId;
      } else if (rawUid.isNotEmpty && userUidSet.contains(rawUid)) {
        uid = rawUid;
      } else if (studentId.isNotEmpty && userUidSet.contains(studentId)) {
        uid = studentId;
      } else if (studentId.isNotEmpty &&
          studentIdToUid.containsKey(studentId)) {
        uid = studentIdToUid[studentId] ?? '';
      } else if (studentEmail.isNotEmpty &&
          emailToUid.containsKey(studentEmail)) {
        uid = emailToUid[studentEmail] ?? '';
      } else if (email.isNotEmpty && emailToUid.containsKey(email)) {
        uid = emailToUid[email] ?? '';
      }

      if (uid.isEmpty) {
        continue;
      }

      pointsByUid[uid] = (pointsByUid[uid] ?? 0) + points;
    }

    return pointsByUid;
  }

  bool isApprovedSubmissionStatus(String status) {
    final String normalized = status
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    return normalized == 'approved' ||
        normalized == 'accepted' ||
        normalized == 'disetujui';
  }

  int getSubmissionPoints(Map<String, dynamic> data) {
    final List<String> keys = [
      'pointsAwarded',
      'finalPointsAwarded',
      'awardedPoints',
      'challengePoints',
      'points',
      'rewardPoints',
    ];

    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) continue;

      if (value is int) return value;
      if (value is double) return value.toInt();

      if (value is String) {
        final int? parsed = int.tryParse(value);

        if (parsed != null) return parsed;
      }
    }

    return 0;
  }

  String getString(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
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

  List<_LeaderboardUser> getTopThreeUsers() {
    return users.take(3).toList();
  }

  List<_LeaderboardUser> getOtherUsers() {
    if (users.length <= 3) return [];

    return users.skip(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingPage();
    }

    if (errorMessage != null) {
      return _buildErrorPage();
    }

    final List<_LeaderboardUser> topThree = getTopThreeUsers();
    final List<_LeaderboardUser> otherUsers = getOtherUsers();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0F8A5F),
                onRefresh: loadLeaderboard,
                child: users.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                        children: [
                          _buildMyRankCard(),
                          const SizedBox(height: 20),
                          _buildTopThreeSection(topThree),
                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            title: 'All Rankings',
                            count: users.length,
                          ),
                          const SizedBox(height: 14),
                          if (otherUsers.isEmpty)
                            _buildSmallInfoCard()
                          else
                            ...otherUsers.map(
                              (user) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _LeaderboardUserCard(
                                    user: user,
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
                  'Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ranking dari total challenge approved',
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
            onTap: loadLeaderboard,
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

  Widget _buildMyRankCard() {
    final _LeaderboardUser? user = currentUserData;

    if (user == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Text(
          'Data ranking kamu belum tersedia.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F8A5F),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F8A5F).withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                '#${user.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ranking Kamu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${formatNumber(user.leaderboardPoints)} total points • ${user.level}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saldo reward: ${formatNumber(user.pointsBalance)} points',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.74),
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.emoji_events_rounded,
            color: Colors.white,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildTopThreeSection(List<_LeaderboardUser> topThree) {
    if (topThree.isEmpty) {
      return const SizedBox.shrink();
    }

    final _LeaderboardUser? first = topThree.isNotEmpty ? topThree[0] : null;
    final _LeaderboardUser? second = topThree.length > 1 ? topThree[1] : null;
    final _LeaderboardUser? third = topThree.length > 2 ? topThree[2] : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B),
            Color(0xFF065F46),
            Color(0xFF0F8A5F),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withOpacity(0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFD9FBE8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Eco Warriors',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Peringkat 1, 2, dan 3 EcoCampus',
                      style: TextStyle(
                        color: Color(0xFFD9FBE8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 286,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: second == null
                      ? const SizedBox.shrink()
                      : _TopRankUserCard(
                          user: second,
                          formatNumber: formatNumber,
                          avatarSize: 72,
                          podiumHeight: 128,
                          totalHeight: 236,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: first == null
                      ? const SizedBox.shrink()
                      : _TopRankUserCard(
                          user: first,
                          formatNumber: formatNumber,
                          avatarSize: 90,
                          podiumHeight: 158,
                          totalHeight: 278,
                          isChampion: true,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: third == null
                      ? const SizedBox.shrink()
                      : _TopRankUserCard(
                          user: third,
                          formatNumber: formatNumber,
                          avatarSize: 72,
                          podiumHeight: 118,
                          totalHeight: 226,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required int count,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
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
            '$count user',
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

  Widget _buildSmallInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFDF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFB7E4C7),
        ),
      ),
      child: const Text(
        'Saat ini baru ada beberapa user di leaderboard.',
        style: TextStyle(
          color: Color(0xFF166534),
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
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
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4BA),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.leaderboard_rounded,
                  color: Color(0xFFB7791F),
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Leaderboard masih kosong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'User student akan muncul di sini setelah challenge disetujui admin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
                        'Mengambil leaderboard...',
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
                        'Gagal mengambil leaderboard',
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
                          onPressed: loadLeaderboard,
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

class _LeaderboardUser {
  final String uid;
  final String name;
  final String displayName;
  final String photoUrl;
  final String departmentName;
  final String level;
  final int pointsBalance;
  final int leaderboardPoints;
  final int rank;
  final bool isCurrentUser;
  final bool showNameInLeaderboard;
  final bool showPhotoInLeaderboard;

  const _LeaderboardUser({
    required this.uid,
    required this.name,
    required this.displayName,
    required this.photoUrl,
    required this.departmentName,
    required this.level,
    required this.pointsBalance,
    required this.leaderboardPoints,
    required this.rank,
    required this.isCurrentUser,
    required this.showNameInLeaderboard,
    required this.showPhotoInLeaderboard,
  });

  factory _LeaderboardUser.fromFirestore({
    required String uid,
    required Map<String, dynamic> data,
    required String currentUserUid,
    required int leaderboardPoints,
  }) {
    final Map<String, dynamic> privacySettings = data['privacySettings'] is Map
        ? Map<String, dynamic>.from(data['privacySettings'])
        : {};

    final bool isCurrentUser = uid == currentUserUid;

    final bool showName = getBool(
      privacySettings,
      'showNameInLeaderboard',
      true,
    );

    final bool showPhoto = getBool(
      privacySettings,
      'showPhotoInLeaderboard',
      true,
    );

    final String realName = getString(
      data,
      'name',
      fallback: 'EcoCampus User',
    );

    return _LeaderboardUser(
      uid: uid,
      name: realName,
      displayName: isCurrentUser || showName ? realName : 'Eco Warrior',
      photoUrl: getString(data, 'photoUrl', fallback: ''),
      departmentName: getString(data, 'departmentName', fallback: '-'),
      level: getString(data, 'level', fallback: 'Eco Starter'),
      pointsBalance: getInt(data, 'points'),
      leaderboardPoints: leaderboardPoints,
      rank: 0,
      isCurrentUser: isCurrentUser,
      showNameInLeaderboard: showName,
      showPhotoInLeaderboard: showPhoto,
    );
  }

  _LeaderboardUser copyWith({
    int? rank,
  }) {
    return _LeaderboardUser(
      uid: uid,
      name: name,
      displayName: displayName,
      photoUrl: photoUrl,
      departmentName: departmentName,
      level: level,
      pointsBalance: pointsBalance,
      leaderboardPoints: leaderboardPoints,
      rank: rank ?? this.rank,
      isCurrentUser: isCurrentUser,
      showNameInLeaderboard: showNameInLeaderboard,
      showPhotoInLeaderboard: showPhotoInLeaderboard,
    );
  }

  String get initial {
    final String cleanName = displayName.trim();

    if (cleanName.isEmpty) return 'E';

    return cleanName[0].toUpperCase();
  }

  bool get canShowPhoto {
    return isCurrentUser || showPhotoInLeaderboard;
  }

  static String getString(
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

  static int getInt(
    Map<String, dynamic> data,
    String key,
  ) {
    final dynamic value = data[key];

    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static bool getBool(
    Map<String, dynamic> data,
    String key,
    bool fallback,
  ) {
    final dynamic value = data[key];

    if (value == null) return fallback;
    if (value is bool) return value;

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return fallback;
  }
}

class _TopRankUserCard extends StatelessWidget {
  final _LeaderboardUser user;
  final String Function(int number) formatNumber;
  final double avatarSize;
  final double podiumHeight;
  final double totalHeight;
  final bool isChampion;

  const _TopRankUserCard({
    required this.user,
    required this.formatNumber,
    required this.avatarSize,
    required this.podiumHeight,
    required this.totalHeight,
    this.isChampion = false,
  });

  Color get rankColor {
    if (user.rank == 1) return const Color(0xFFD9FBE8);
    if (user.rank == 2) return const Color(0xFF86EFAC);
    return const Color(0xFF34D399);
  }

  Color get rankAccentColor {
    if (user.rank == 1) return const Color(0xFF0F8A5F);
    if (user.rank == 2) return const Color(0xFF10B981);
    return const Color(0xFF22C55E);
  }

  Color get rankBackground {
    if (user.rank == 1) return const Color(0xFFD9FBE8);
    if (user.rank == 2) return const Color(0xFFDCFCE7);
    return const Color(0xFFECFDF5);
  }

  Color get podiumColor {
    if (user.rank == 1) return const Color(0xFF0B6B4A);
    if (user.rank == 2) return const Color(0xFF075A42);
    return const Color(0xFF064E3B);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: totalHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 30,
            child: isChampion
                ? const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFF4BA),
                    size: 30,
                  )
                : const SizedBox.shrink(),
          ),
          Transform.translate(
            offset: const Offset(0, 18),
            child: _PodiumAvatar(
              user: user,
              size: avatarSize,
              borderColor: rankColor,
              badgeColor: rankAccentColor,
              backgroundColor: rankBackground,
            ),
          ),
          Container(
            width: double.infinity,
            height: podiumHeight,
            padding: EdgeInsets.fromLTRB(
              8,
              isChampion ? 34 : 30,
              8,
              12,
            ),
            decoration: BoxDecoration(
              color: podiumColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isChampion ? 34 : 28),
                topRight: Radius.circular(isChampion ? 34 : 28),
                bottomLeft: const Radius.circular(18),
                bottomRight: const Radius.circular(18),
              ),
              border: Border.all(
                color: user.isCurrentUser
                    ? const Color(0xFFD9FBE8)
                    : Colors.white.withOpacity(0.10),
                width: user.isCurrentUser ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF022C22).withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isChampion ? 15.5 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatNumber(user.leaderboardPoints),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: rankColor,
                    fontSize: isChampion ? 23 : 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.level,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFA7F3D0),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (user.isCurrentUser) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9FBE8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        color: Color(0xFF0F8A5F),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumAvatar extends StatelessWidget {
  final _LeaderboardUser user;
  final double size;
  final Color borderColor;
  final Color badgeColor;
  final Color backgroundColor;

  const _PodiumAvatar({
    required this.user,
    required this.size,
    required this.borderColor,
    required this.badgeColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool showImage = user.canShowPhoto && user.photoUrl.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 3.2,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.26),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: showImage
                ? Image.network(
                    user.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _PodiumInitialAvatar(
                        initial: user.initial,
                        size: size,
                      );
                    },
                  )
                : _PodiumInitialAvatar(
                    initial: user.initial,
                    size: size,
                  ),
          ),
        ),
        Positioned(
          bottom: -10,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF064E3B),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Text(
                '${user.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PodiumInitialAvatar extends StatelessWidget {
  final String initial;
  final double size;

  const _PodiumInitialAvatar({
    required this.initial,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFFDF4),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: const Color(0xFF0F8A5F),
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LeaderboardUserCard extends StatelessWidget {
  final _LeaderboardUser user;
  final String Function(int number) formatNumber;

  const _LeaderboardUserCard({
    required this.user,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: user.isCurrentUser ? const Color(0xFFEFFDF4) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: user.isCurrentUser
              ? const Color(0xFFB7E4C7)
              : const Color(0xFFE5E7EB),
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
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: user.rank <= 3
                  ? const Color(0xFFFFF4BA)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                '#${user.rank}',
                style: TextStyle(
                  color: user.rank <= 3
                      ? const Color(0xFFB7791F)
                      : const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _UserAvatar(
            user: user,
            size: 48,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (user.isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9FBE8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Color(0xFF0F8A5F),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.departmentName} • ${user.level}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saldo reward: ${formatNumber(user.pointsBalance)} pts',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatNumber(user.leaderboardPoints),
                style: const TextStyle(
                  color: Color(0xFF0F8A5F),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'total pts',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final _LeaderboardUser user;
  final double size;

  const _UserAvatar({
    required this.user,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final bool showImage = user.canShowPhoto && user.photoUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFD9FBE8),
        borderRadius: BorderRadius.circular(size * 0.36),
        border: Border.all(
          color: user.isCurrentUser
              ? const Color(0xFF0F8A5F)
              : const Color(0xFFE5E7EB),
          width: user.isCurrentUser ? 2 : 1,
        ),
      ),
      child: showImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.32),
              child: Image.network(
                user.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _AvatarInitial(
                    initial: user.initial,
                    size: size,
                  );
                },
              ),
            )
          : _AvatarInitial(
              initial: user.initial,
              size: size,
            ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  final String initial;
  final double size;

  const _AvatarInitial({
    required this.initial,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: const Color(0xFF0F8A5F),
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}