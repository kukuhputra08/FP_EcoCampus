import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../challenges/pages/challenge_submission_page.dart';
import '../events/event_detail_page.dart';
import '../events/events_page.dart';
import '../reports/pages/create_report_page.dart';

class HomePage extends StatefulWidget {
  final void Function(int index)? onNavigate;

  const HomePage({
    super.key,
    this.onNavigate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomeStats {
  final int points;
  final int reportCount;
  final int? rank;

  const _HomeStats({
    required this.points,
    required this.reportCount,
    required this.rank,
  });
}

class _HomeChallenge {
  final String id;
  final String title;
  final String description;
  final String points;
  final IconData icon;
  final Color iconBackground;
  final String submissionStatus;
  final String adminNote;

  const _HomeChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.icon,
    required this.iconBackground,
    required this.submissionStatus,
    required this.adminNote,
  });

  bool get canSubmit {
    return id.isNotEmpty &&
        (submissionStatus == 'not_submitted' ||
            submissionStatus == 'rejected');
  }

  bool get isCompleted {
    return submissionStatus == 'approved';
  }

  String get statusLabel {
    if (submissionStatus == 'approved') return 'Disetujui';
    if (submissionStatus == 'submitted') return 'Review';
    if (submissionStatus == 'rejected') return 'Ditolak';
    if (submissionStatus == 'fallback') return 'Demo';

    return 'Belum Submit';
  }

  Color get statusBackground {
    if (submissionStatus == 'approved') return const Color(0xFFD9FBE8);
    if (submissionStatus == 'submitted') return const Color(0xFFFFF4BA);
    if (submissionStatus == 'rejected') return const Color(0xFFFEE2E2);
    if (submissionStatus == 'fallback') return const Color(0xFFF1F5F9);

    return const Color(0xFFE0F4FF);
  }

  Color get statusTextColor {
    if (submissionStatus == 'approved') return const Color(0xFF0F8A5F);
    if (submissionStatus == 'submitted') return const Color(0xFFB7791F);
    if (submissionStatus == 'rejected') return const Color(0xFFEF4444);
    if (submissionStatus == 'fallback') return const Color(0xFF64748B);

    return const Color(0xFF087EA4);
  }

  IconData get actionIcon {
    if (submissionStatus == 'approved') return Icons.check_rounded;
    if (submissionStatus == 'submitted') return Icons.hourglass_top_rounded;
    if (submissionStatus == 'rejected') return Icons.refresh_rounded;
    if (submissionStatus == 'fallback') return Icons.lock_outline_rounded;

    return Icons.add_rounded;
  }
}

class _LatestReport {
  final String title;
  final String dateText;
  final String status;
  final IconData icon;

  const _LatestReport({
    required this.title,
    required this.dateText,
    required this.status,
    required this.icon,
  });
}

class _HomeEvent {
  final String id;
  final String title;
  final String location;
  final String status;
  final DateTime? date;
  final int quota;
  final int registeredCount;

  const _HomeEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.status,
    required this.date,
    required this.quota,
    required this.registeredCount,
  });
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? get currentUser => auth.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream() {
    final User? user = currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return firestore.collection('users').doc(user.uid).snapshots();
  }

  Future<_HomeStats> _getHomeStats(int points) async {
    final User? user = currentUser;

    if (user == null) {
      return _HomeStats(
        points: points,
        reportCount: 0,
        rank: null,
      );
    }

    final int reportCount = await _getReportCount(user.uid);
    final int? rank = await _getUserRank(user.uid);

    return _HomeStats(
      points: points,
      reportCount: reportCount,
      rank: rank,
    );
  }

  Future<int> _getReportCount(String uid) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('reports')
          .where('studentUid', isEqualTo: uid)
          .get();

      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int?> _getUserRank(String uid) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await firestore.collection('users').get();

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> students =
          snapshot.docs.where((doc) {
        final Map<String, dynamic> data = doc.data();
        return (data['role'] ?? '').toString() == 'student';
      }).toList();

      students.sort((a, b) {
        final int pointsA = _toInt(a.data()['points']);
        final int pointsB = _toInt(b.data()['points']);
        return pointsB.compareTo(pointsA);
      });

      final int index = students.indexWhere((doc) => doc.id == uid);

      if (index == -1) {
        return null;
      }

      return index + 1;
    } catch (_) {
      return null;
    }
  }

  Future<List<_HomeChallenge>> _getDailyChallenges() async {
    try {
      final User? user = currentUser;

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await firestore.collection('challenges').limit(10).get();

      if (snapshot.docs.isEmpty) {
        return _fallbackChallenges();
      }

      final Map<String, Map<String, dynamic>> latestSubmissionByChallengeId =
          user == null
              ? {}
              : await _getLatestChallengeSubmissionsByChallengeId(user.uid);

      final List<_HomeChallenge> items = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();

        final String title =
            (data['title'] ?? data['name'] ?? 'Challenge').toString();

        final String description =
            (data['description'] ?? 'Selesaikan challenge ini.').toString();

        final int pointValue = _toInt(
          data['points'] ?? data['rewardPoints'] ?? data['point'],
        );

        final String category =
            (data['category'] ?? data['type'] ?? '').toString().toLowerCase();

        final Map<String, dynamic>? latestSubmission =
            latestSubmissionByChallengeId[doc.id];

        final String submissionStatus = _mapHomeSubmissionStatus(
          (latestSubmission?['status'] ?? '').toString(),
        );

        final String adminNote =
            (latestSubmission?['adminNote'] ?? '').toString();

        return _HomeChallenge(
          id: doc.id,
          title: title,
          description: description,
          points: '+${pointValue == 0 ? 30 : pointValue} pts',
          icon: _challengeIcon(title, category),
          iconBackground: _challengeBackground(title, category),
          submissionStatus: submissionStatus,
          adminNote: adminNote,
        );
      }).toList();

      return items.take(2).toList();
    } catch (_) {
      return _fallbackChallenges();
    }
  }

  Future<Map<String, Map<String, dynamic>>>
      _getLatestChallengeSubmissionsByChallengeId(String uid) async {
    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> submissionMap =
        {};

    Future<void> fetchSubmissionsByField(String field, String value) async {
      if (value.trim().isEmpty) return;

      try {
        final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
            .collection('challengeSubmissions')
            .where(field, isEqualTo: value)
            .get();

        for (final doc in snapshot.docs) {
          submissionMap[doc.id] = doc;
        }
      } catch (_) {}
    }

    await fetchSubmissionsByField('studentUid', uid);
    await fetchSubmissionsByField('studentId', uid);

    try {
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await firestore.collection('users').doc(uid).get();

      final String studentId =
          (userSnapshot.data()?['studentId'] ?? '').toString();

      await fetchSubmissionsByField('studentId', studentId);
    } catch (_) {}

    final Map<String, Map<String, dynamic>> latestByChallengeId = {};
    final Map<String, int> latestMillisByChallengeId = {};

    for (final doc in submissionMap.values) {
      final Map<String, dynamic> data = doc.data();
      final String challengeId = (data['challengeId'] ?? '').toString();

      if (challengeId.isEmpty) continue;

      final int millis = _getSubmissionSortMillis(data);
      final int oldMillis = latestMillisByChallengeId[challengeId] ?? -1;

      if (millis >= oldMillis) {
        latestByChallengeId[challengeId] = data;
        latestMillisByChallengeId[challengeId] = millis;
      }
    }

    return latestByChallengeId;
  }

  int _getSubmissionSortMillis(Map<String, dynamic> data) {
    final List<String> keys = [
      'submittedAt',
      'createdAt',
      'updatedAt',
      'reviewedAt',
    ];

    int latestMillis = 0;

    for (final String key in keys) {
      final dynamic value = data[key];

      if (value is Timestamp) {
        final int millis = value.millisecondsSinceEpoch;

        if (millis > latestMillis) {
          latestMillis = millis;
        }
      } else if (value is DateTime) {
        final int millis = value.millisecondsSinceEpoch;

        if (millis > latestMillis) {
          latestMillis = millis;
        }
      }
    }

    return latestMillis;
  }

  String _mapHomeSubmissionStatus(String status) {
    final String normalized = status
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    if (normalized.isEmpty) {
      return 'not_submitted';
    }

    if (normalized == 'approved' ||
        normalized == 'accepted' ||
        normalized == 'disetujui') {
      return 'approved';
    }

    if (normalized == 'rejected' ||
        normalized == 'ejected' ||
        normalized == 'ditolak' ||
        normalized == 'failed' ||
        normalized == 'gagal' ||
        normalized == 'cancelled' ||
        normalized == 'canceled') {
      return 'rejected';
    }

    if (normalized == 'submitted' ||
        normalized == 'pending' ||
        normalized == 'menunggu_review' ||
        normalized == 'waiting_review' ||
        normalized == 'in_review' ||
        normalized == 'review') {
      return 'submitted';
    }

    return 'submitted';
  }


  Future<_LatestReport?> _getLatestReport() async {
    final User? user = currentUser;

    if (user == null) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('reports')
          .where('studentUid', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
          snapshot.docs.toList();

      docs.sort((a, b) {
        final DateTime dateA = _toDateTime(a.data()['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime dateB = _toDateTime(b.data()['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return dateB.compareTo(dateA);
      });

      final Map<String, dynamic> data = docs.first.data();

      final String title =
          (data['title'] ?? data['category'] ?? 'Laporan fasilitas').toString();

      final String status = (data['status'] ?? 'pending').toString();

      return _LatestReport(
        title: title,
        dateText: _formatReportDate(data['createdAt']),
        status: status,
        icon: _reportIcon(title),
      );
    } catch (_) {
      return null;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _eventsStream({
    required String universityId,
  }) {
    return firestore
        .collection('events')
        .where('universityId', isEqualTo: universityId)
        .snapshots();
  }

  List<_HomeEvent> _parseHomeEvents(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final List<_HomeEvent> events = docs.map((doc) {
      final Map<String, dynamic> data = doc.data();

      return _HomeEvent(
        id: doc.id,
        title: (data['title'] ?? 'Event Tanpa Judul').toString(),
        location: (data['location'] ?? '-').toString(),
        status: (data['status'] ?? '-').toString(),
        date: _toDateTime(data['date']),
        quota: _toInt(data['quota']),
        registeredCount: _toInt(data['registeredCount']),
      );
    }).where((event) {
      final String status = event.status.toLowerCase();

      return status == 'active';
    }).toList();

    events.sort((a, b) {
      final DateTime dateA = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime dateB = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);

      return dateA.compareTo(dateB);
    });

    return events.take(3).toList();
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static String _formatNumber(int value) {
    final String text = value.toString();
    final RegExp regExp = RegExp(r'\B(?=(\d{3})+(?!\d))');

    return text.replaceAllMapped(
      regExp,
      (match) => ',',
    );
  }

  static String _firstName(String name) {
    final String trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'Mahasiswa';
    }

    return trimmed.split(' ').first;
  }

  static String _initial(String name) {
    final String trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'M';
    }

    return trimmed[0].toUpperCase();
  }

  static String _formatReportDate(dynamic value) {
    final DateTime? date = _toDateTime(value);

    if (date == null) {
      return 'Baru saja';
    }

    final DateTime now = DateTime.now();

    final bool isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');
      return 'Hari ini, $hour:$minute';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatEventDate(DateTime? date) {
    if (date == null) return '-';

    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final String day = date.day.toString().padLeft(2, '0');
    final String month = months[date.month - 1];
    final String year = date.year.toString();

    return '$day $month $year';
  }

  static String _statusLabel(String status) {
    final String value = status.toLowerCase();

    if (value == 'pending') return 'PENDING';
    if (value == 'in_progress') return 'PROSES';
    if (value == 'completed') return 'SELESAI';
    if (value == 'resolved') return 'SELESAI';
    if (value == 'rejected') return 'DITOLAK';

    return status.toUpperCase();
  }

  static Color _statusBackground(String status) {
    final String value = status.toLowerCase();

    if (value == 'completed' || value == 'resolved') {
      return const Color(0xFFD9FBE8);
    }

    if (value == 'rejected') {
      return const Color(0xFFFEE2E2);
    }

    if (value == 'in_progress') {
      return const Color(0xFFFFF7D6);
    }

    return const Color(0xFFE0F2FE);
  }

  static Color _statusTextColor(String status) {
    final String value = status.toLowerCase();

    if (value == 'completed' || value == 'resolved') {
      return const Color(0xFF166534);
    }

    if (value == 'rejected') {
      return const Color(0xFFB91C1C);
    }

    if (value == 'in_progress') {
      return const Color(0xFF715C00);
    }

    return const Color(0xFF0369A1);
  }

  static IconData _challengeIcon(String title, String category) {
    final String value = '$title $category'.toLowerCase();

    if (value.contains('tumbler') || value.contains('drink')) {
      return Icons.local_drink_outlined;
    }

    if (value.contains('foto') || value.contains('photo')) {
      return Icons.camera_alt_rounded;
    }

    if (value.contains('tanam') || value.contains('pohon')) {
      return Icons.park_rounded;
    }

    if (value.contains('bersih') || value.contains('clean')) {
      return Icons.cleaning_services_rounded;
    }

    if (value.contains('teman') || value.contains('sosial')) {
      return Icons.groups_rounded;
    }

    return Icons.emoji_events_rounded;
  }

  static Color _challengeBackground(String title, String category) {
    final String value = '$title $category'.toLowerCase();

    if (value.contains('tumbler') || value.contains('foto')) {
      return const Color(0xFFE0F2FE);
    }

    if (value.contains('tanam') || value.contains('pohon')) {
      return const Color(0xFFD9FBE8);
    }

    return const Color(0xFFF1F5F3);
  }

  static IconData _reportIcon(String title) {
    final String value = title.toLowerCase();

    if (value.contains('sampah')) return Icons.delete_outline_rounded;
    if (value.contains('lampu')) return Icons.lightbulb_outline_rounded;
    if (value.contains('ac')) return Icons.ac_unit_rounded;
    if (value.contains('toilet')) return Icons.wc_rounded;
    if (value.contains('proyektor')) return Icons.videocam_off_outlined;

    return Icons.assignment_rounded;
  }

  static List<_HomeChallenge> _fallbackChallenges() {
    return const [
      _HomeChallenge(
        id: '',
        icon: Icons.local_drink_outlined,
        iconBackground: Color(0xFFE0F2FE),
        title: 'Bawa tumbler hari ini',
        description: 'Gunakan tumbler pribadi dan kurangi plastik sekali pakai.',
        points: '+50 pts',
        submissionStatus: 'fallback',
        adminNote: '',
      ),
      _HomeChallenge(
        id: '',
        icon: Icons.camera_alt_rounded,
        iconBackground: Color(0xFFF1F5F3),
        title: 'Foto lingkungan bersih',
        description: 'Unggah bukti foto area kampus yang bersih.',
        points: '+30 pts',
        submissionStatus: 'fallback',
        adminNote: '',
      ),
    ];
  }

  Future<void> _goToChallengeSubmission(
    BuildContext context, {
    required String challengeId,
    required String title,
    required String description,
    required String points,
    required IconData icon,
  }) async {
    if (challengeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Challenge demo tidak bisa disubmit. Buka challenge dari admin.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeSubmissionPage(
          challengeId: challengeId,
          challengeTitle: title,
          challengeDescription: description,
          points: points,
          icon: icon,
        ),
      ),
    );

    if (updated == true && mounted) {
      setState(() {});
    }
  }

  void _handleDailyChallengeTap(
    BuildContext context,
    _HomeChallenge challenge,
  ) {
    if (!challenge.canSubmit) {
      String message = 'Challenge ini belum bisa disubmit.';

      if (challenge.submissionStatus == 'submitted') {
        message = 'Submission challenge ini masih menunggu review admin.';
      } else if (challenge.submissionStatus == 'approved') {
        message = 'Challenge ini sudah disetujui admin.';
      } else if (challenge.submissionStatus == 'fallback') {
        message = 'Challenge demo tidak bisa disubmit.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    _goToChallengeSubmission(
      context,
      challengeId: challenge.id,
      title: challenge.title,
      description: challenge.description,
      points: challenge.points,
      icon: challenge.icon,
    );
  }


  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be added soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goToTab(BuildContext context, int index) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation is not ready yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCreateReportPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateReportPage(),
      ),
    );
  }

  void _openEventsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventsPage(),
      ),
    );
  }

  void _openEventDetail(BuildContext context, String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(
          eventId: eventId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7FBF8),
        body: Center(
          child: Text(
            'User belum login.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0F8A5F),
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Gagal memuat data user.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Data user tidak ditemukan.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            );
          }

          final Map<String, dynamic> userData = snapshot.data!.data() ?? {};

          final String name = (userData['name'] ?? 'Mahasiswa').toString();
          final String universityId =
              (userData['universityId'] ?? '').toString();
          final String universityName =
              (userData['universityName'] ?? 'Universitas').toString();
          final String level = (userData['level'] ?? 'Eco Starter').toString();
          final int points = _toInt(userData['points']);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreenHeader(
                    context,
                    name: name,
                    universityName: universityName,
                    level: level,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsRow(points: points),
                          const SizedBox(height: 30),
                          _buildSectionTitle(
                            icon: Icons.flash_on_rounded,
                            title: 'Aksi Cepat',
                          ),
                          const SizedBox(height: 16),
                          _buildQuickActions(context),
                          const SizedBox(height: 34),
                          _buildSectionHeader(
                            icon: Icons.emoji_events_rounded,
                            title: 'Daily Challenge',
                            actionText: 'Lihat Semua',
                            onTap: () => _goToTab(context, 2),
                          ),
                          const SizedBox(height: 14),
                          _buildChallengeCard(context),
                          const SizedBox(height: 28),
                          _buildReportCard(context),
                          const SizedBox(height: 34),
                          _buildEventsSection(
                            context,
                            universityId: universityId,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreenHeader(
    BuildContext context, {
    required String name,
    required String universityName,
    required String level,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 48, 22, 82),
      decoration: const BoxDecoration(
        color: Color(0xFF0F8A5F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'EcoCampus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              _buildHeaderIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () => _showComingSoon(context, 'Notifications'),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: Center(
                  child: Text(
                    _initial(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          Text(
            'Halo, ${_firstName(name)}! 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$universityName • $level 🏆',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
            const Positioned(
              top: 12,
              right: 12,
              child: CircleAvatar(
                radius: 4,
                backgroundColor: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow({
    required int points,
  }) {
    return FutureBuilder<_HomeStats>(
      future: _getHomeStats(points),
      builder: (context, snapshot) {
        final _HomeStats stats = snapshot.data ??
            _HomeStats(
              points: points,
              reportCount: 0,
              rank: null,
            );

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                iconBackground: const Color(0xFFDDFCEB),
                iconColor: const Color(0xFF0F8A5F),
                value: _formatNumber(stats.points),
                label: 'Eco Points',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.assignment_rounded,
                iconBackground: const Color(0xFFDFF3FF),
                iconColor: const Color(0xFF087EA4),
                value: '${stats.reportCount}',
                label: 'Laporan',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_rounded,
                iconBackground: const Color(0xFFFFF4BA),
                iconColor: const Color(0xFFB7791F),
                value: stats.rank == null ? '-' : '#${stats.rank}',
                label: 'Rank',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFF0F8A5F),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildSectionTitle(
            icon: icon,
            title: title,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F8A5F),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.add_photo_alternate_outlined,
        title: 'Buat\nLaporan',
        backgroundColor: const Color(0xFFD9FBE8),
        iconColor: const Color(0xFF0F8A5F),
        onTap: () => _openCreateReportPage(context),
      ),
      _QuickActionData(
        icon: Icons.emoji_events_rounded,
        title: 'Challenge\nHarian',
        backgroundColor: const Color(0xFFFFF3B0),
        iconColor: const Color(0xFFB7791F),
        onTap: () => _goToTab(context, 2),
      ),
      _QuickActionData(
        icon: Icons.card_giftcard_rounded,
        title: 'Tukar\nReward',
        backgroundColor: const Color(0xFFF1E4FF),
        iconColor: const Color(0xFF7E22CE),
        onTap: () => _goToTab(context, 3),
      ),
      _QuickActionData(
        icon: Icons.event_available_rounded,
        title: 'Event\nKampus',
        backgroundColor: const Color(0xFFE0F4FF),
        iconColor: const Color(0xFF087EA4),
        onTap: () => _openEventsPage(context),
      ),
    ];

    return Row(
      children: List.generate(actions.length, (index) {
        final item = actions[index];

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == actions.length - 1 ? 0 : 12,
            ),
            child: _QuickActionCard(data: item),
          ),
        );
      }),
    );
  }

  Widget _buildChallengeCard(BuildContext context) {
    return FutureBuilder<List<_HomeChallenge>>(
      future: _getDailyChallenges(),
      builder: (context, snapshot) {
        final List<_HomeChallenge> challenges =
            snapshot.data ?? _fallbackChallenges();

        return Column(
          children: List.generate(challenges.length, (index) {
            final _HomeChallenge challenge = challenges[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == challenges.length - 1 ? 0 : 14,
              ),
              child: _DailyChallengeItem(
                icon: challenge.icon,
                iconBackground: challenge.iconBackground,
                title: challenge.title,
                points: challenge.points,
                isCompleted: challenge.isCompleted,
                statusLabel: challenge.statusLabel,
                statusBackground: challenge.statusBackground,
                statusTextColor: challenge.statusTextColor,
                actionIcon: challenge.actionIcon,
                canSubmit: challenge.canSubmit,
                onTap: () => _handleDailyChallengeTap(
                  context,
                  challenge,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildReportCard(BuildContext context) {
    return FutureBuilder<_LatestReport?>(
      future: _getLatestReport(),
      builder: (context, snapshot) {
        final _LatestReport? report = snapshot.data;

        if (report == null) {
          return GestureDetector(
            onTap: () => _openCreateReportPage(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: _whiteCardDecoration(),
              child: Row(
                children: [
                  _SmallIconBox(
                    icon: Icons.add_photo_alternate_outlined,
                    backgroundColor: const Color(0xFFF1F5F3),
                    iconColor: const Color(0xFF475569),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Belum ada laporan',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Buat laporan fasilitas pertamamu.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 28,
                  ),
                ],
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _goToTab(context, 1),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _whiteCardDecoration(),
            child: Row(
              children: [
                _SmallIconBox(
                  icon: report.icon,
                  backgroundColor: const Color(0xFFF1F5F3),
                  iconColor: const Color(0xFF475569),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.dateText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBackground(report.status),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(report.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _statusTextColor(report.status),
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

  Widget _buildEventsSection(
    BuildContext context, {
    required String universityId,
  }) {
    if (universityId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildSectionHeader(
          icon: Icons.event_available_rounded,
          title: 'Campus Events',
          actionText: 'Lihat Semua',
          onTap: () => _openEventsPage(context),
        ),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _eventsStream(universityId: universityId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: _whiteCardDecoration(),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0F8A5F),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: _whiteCardDecoration(),
                child: const Text(
                  'Gagal memuat event kampus.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            final List<_HomeEvent> events = _parseHomeEvents(
              snapshot.data?.docs ?? [],
            );

            if (events.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: _whiteCardDecoration(),
                child: Row(
                  children: [
                    _SmallIconBox(
                      icon: Icons.event_busy_rounded,
                      backgroundColor: const Color(0xFFF1F5F3),
                      iconColor: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Belum ada event aktif dari admin kampus.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: List.generate(events.length, (index) {
                final _HomeEvent event = events[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == events.length - 1 ? 0 : 14,
                  ),
                  child: _HomeEventCard(
                    event: event,
                    formattedDate: _formatEventDate(event.date),
                    onTap: () => _openEventDetail(context, event.id),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF14532D).withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 76,
            decoration: BoxDecoration(
              color: data.backgroundColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: data.iconColor.withOpacity(0.13),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 32,
              color: data.iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyChallengeItem extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String points;
  final bool isCompleted;
  final String statusLabel;
  final Color statusBackground;
  final Color statusTextColor;
  final IconData actionIcon;
  final bool canSubmit;
  final VoidCallback onTap;

  const _DailyChallengeItem({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.points,
    required this.isCompleted,
    required this.statusLabel,
    required this.statusBackground,
    required this.statusTextColor,
    required this.actionIcon,
    required this.canSubmit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 98,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14532D).withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                size: 28,
                color: const Color(0xFF0F8A5F),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            color: isCompleted
                                ? const Color(0xFF64748B)
                                : const Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusBackground,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: statusTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 17,
                        color: Color(0xFFB7791F),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        points,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB7791F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: canSubmit
                    ? const Color(0xFF0F8A5F)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: canSubmit
                      ? const Color(0xFF0F8A5F)
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              child: Icon(
                actionIcon,
                color: canSubmit ? Colors.white : const Color(0xFF94A3B8),
                size: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallIconBox extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _SmallIconBox({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        size: 28,
        color: iconColor,
      ),
    );
  }
}

class _HomeEventCard extends StatelessWidget {
  final _HomeEvent event;
  final String formattedDate;
  final VoidCallback onTap;

  const _HomeEventCard({
    required this.event,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int remainingQuota = event.quota - event.registeredCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14532D).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFD9FBE8),
                borderRadius: BorderRadius.circular(21),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Color(0xFF0F8A5F),
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF94A3B8),
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF94A3B8),
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.quota <= 0
                        ? '${event.registeredCount} peserta terdaftar'
                        : '${event.registeredCount}/${event.quota} peserta • Sisa ${remainingQuota < 0 ? 0 : remainingQuota}',
                    style: const TextStyle(
                      color: Color(0xFF0F8A5F),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}