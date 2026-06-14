import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../challenges/pages/challenge_submission_page.dart';

class ChallengeItem {
  final String id;
  final String title;
  final String description;
  final int points;
  final String category;
  final String difficulty;
  final IconData icon;
  final String submissionStatus;
  final String adminNote;

  const ChallengeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.category,
    required this.difficulty,
    required this.icon,
    required this.submissionStatus,
    this.adminNote = '',
  });
}

class RewardItem {
  final String id;
  final String title;
  final String description;
  final int cost;
  final String category;
  final int stock;
  final IconData icon;
  final bool isAvailable;

  const RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.category,
    required this.stock,
    required this.icon,
    required this.isAvailable,
  });
}

class MyVoucherItem {
  final String id;
  final String rewardId;
  final String rewardTitle;
  final String code;
  final int cost;
  final String status;
  final String redeemedAt;
  final IconData icon;

  const MyVoucherItem({
    required this.id,
    required this.rewardId,
    required this.rewardTitle,
    required this.code,
    required this.cost,
    required this.status,
    required this.redeemedAt,
    required this.icon,
  });
}

class RewardsPage extends StatefulWidget {
  final int initialTabIndex;

  const RewardsPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  int selectedTabIndex = 0;
  String selectedChallengeCategory = 'Semua';
  String selectedRewardCategory = 'Semua';

  int myPoints = 0;
  String myLevel = 'Eco Starter';

  Map<String, dynamic>? studentData;

  List<ChallengeItem> challenges = [];
  List<RewardItem> rewards = [];
  List<MyVoucherItem> myVouchers = [];

  bool isLoading = true;

  final List<String> challengeCategories = [
    'Semua',
    'Harian',
    'Mingguan',
    'Lingkungan',
    'Sosial',
  ];

  final List<String> rewardCategories = [
    'Semua',
    'Makanan',
    'Merchandise',
    'Voucher',
    'Donasi',
  ];

  @override
  void initState() {
    super.initState();
    selectedTabIndex = widget.initialTabIndex;
    loadData();
  }

  List<ChallengeItem> get filteredChallenges {
    if (selectedChallengeCategory == 'Semua') {
      return challenges;
    }

    return challenges
        .where((item) => item.category == selectedChallengeCategory)
        .toList();
  }

  List<RewardItem> get filteredRewards {
    if (selectedRewardCategory == 'Semua') {
      return rewards;
    }

    return rewards
        .where((item) => item.category == selectedRewardCategory)
        .toList();
  }

  int get completedChallengeCount {
    return challenges
        .where((item) => item.submissionStatus == 'Disetujui')
        .length;
  }

  int get pendingVoucherCount {
    return myVouchers.where((item) => item.status == 'Pending Claim').length;
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final User? user = auth.currentUser;

      if (user == null) {
        throw Exception('User belum login.');
      }

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw Exception('Data mahasiswa tidak ditemukan.');
      }

      final Map<String, dynamic> data = userDoc.data() ?? {};

      final String universityId = (data['universityId'] ?? '').toString();
      final String departmentId = (data['departmentId'] ?? '').toString();
      final String studentId = (data['studentId'] ?? '').toString();

      final int points = toInt(data['points']);
      final String level = (data['level'] ?? 'Eco Starter').toString();

      final List<RewardItem> loadedRewards = await fetchRewards(
        universityId: universityId,
        departmentId: departmentId,
      );

      final List<ChallengeItem> loadedChallenges = await fetchChallenges(
        universityId: universityId,
        departmentId: departmentId,
        studentUid: user.uid,
        studentId: studentId,
      );

      final List<MyVoucherItem> loadedVouchers = await fetchMyVouchers(
        universityId: universityId,
        departmentId: departmentId,
        studentUid: user.uid,
        studentId: studentId,
      );

      if (!mounted) return;

      setState(() {
        studentData = data;
        myPoints = points;
        myLevel = level;
        rewards = loadedRewards;
        challenges = loadedChallenges;
        myVouchers = loadedVouchers;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data reward/challenge: $error'),
        ),
      );
    }
  }

  Future<List<RewardItem>> fetchRewards({
    required String universityId,
    required String departmentId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
        .collection('rewards')
        .where('universityId', isEqualTo: universityId)
        .where('departmentId', isEqualTo: departmentId)
        .get();

    final List<RewardItem> items = snapshot.docs.map((doc) {
      final Map<String, dynamic> data = doc.data();

      final String title = (data['title'] ?? 'Reward Tanpa Judul').toString();
      final String description = (data['description'] ?? '').toString();
      final int pointsRequired = toInt(data['pointsRequired']);
      final int stock = toInt(data['stock']);
      final String status = (data['status'] ?? 'inactive').toString();

      return RewardItem(
        id: doc.id,
        title: title,
        description: description,
        cost: pointsRequired,
        category: detectRewardCategory(title, description),
        stock: stock,
        icon: rewardIcon(title, description),
        isAvailable: status == 'active' && stock > 0,
      );
    }).toList();

    items.sort((a, b) => a.cost.compareTo(b.cost));

    return items;
  }

  Future<List<ChallengeItem>> fetchChallenges({
    required String universityId,
    required String departmentId,
    required String studentUid,
    required String studentId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> challengeSnapshot =
        await firestore
            .collection('challenges')
            .where('universityId', isEqualTo: universityId)
            .where('departmentId', isEqualTo: departmentId)
            .get();

    final QuerySnapshot<Map<String, dynamic>> submissionSnapshot =
        await firestore
            .collection('challengeSubmissions')
            .where('universityId', isEqualTo: universityId)
            .where('departmentId', isEqualTo: departmentId)
            .get();

    final List<Map<String, dynamic>> submissions =
        submissionSnapshot.docs.map((doc) {
      return {
        '__id': doc.id,
        ...doc.data(),
      };
    }).toList();

    final List<ChallengeItem> items = challengeSnapshot.docs.map((doc) {
      final Map<String, dynamic> data = doc.data();

      final String challengeId = doc.id;
      final String title =
          (data['title'] ?? 'Challenge Tanpa Judul').toString();
      final String description = (data['description'] ?? '').toString();
      final int points = toInt(data['points']);
      final String challengeStatus = (data['status'] ?? 'inactive').toString();

      final List<Map<String, dynamic>> relatedSubmissions =
          submissions.where((submission) {
        final String submissionChallengeId =
            (submission['challengeId'] ?? '').toString();

        final String submissionStudentUid =
            (submission['studentUid'] ?? '').toString();

        final String submissionStudentId =
            (submission['studentId'] ?? '').toString();

        final bool sameChallenge = submissionChallengeId == challengeId;

        final bool sameStudent = submissionStudentUid == studentUid ||
            submissionStudentId == studentUid ||
            submissionStudentId == studentId;

        return sameChallenge && sameStudent;
      }).toList();

      String submissionStatus = 'Belum Submit';
      String adminNote = '';

      if (relatedSubmissions.isNotEmpty) {
        relatedSubmissions.sort((a, b) {
          final int aMillis = getSubmissionSortMillis(a);
          final int bMillis = getSubmissionSortMillis(b);

          return bMillis.compareTo(aMillis);
        });

        final Map<String, dynamic> submission = relatedSubmissions.first;

        final String rawStatus =
            (submission['status'] ?? 'submitted').toString();

        submissionStatus = mapSubmissionStatus(rawStatus);
        adminNote = (submission['adminNote'] ?? '').toString();
      }

      return ChallengeItem(
        id: challengeId,
        title: title,
        description: description,
        points: points,
        category: detectChallengeCategory(title, description),
        difficulty: detectDifficulty(points),
        icon: challengeIcon(title, description),
        submissionStatus: submissionStatus,
        adminNote: adminNote,
      );
    }).where((item) {
      final QueryDocumentSnapshot<Map<String, dynamic>> originalDoc =
          challengeSnapshot.docs.firstWhere((doc) => doc.id == item.id);

      final String originalStatus =
          (originalDoc.data()['status'] ?? 'inactive').toString();

      return originalStatus == 'active';
    }).toList();

    return items;
  }

  Future<List<MyVoucherItem>> fetchMyVouchers({
    required String universityId,
    required String departmentId,
    required String studentUid,
    required String studentId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
        .collection('rewardRedemptions')
        .where('universityId', isEqualTo: universityId)
        .where('departmentId', isEqualTo: departmentId)
        .get();

    final List<MyVoucherItem> items = snapshot.docs.where((doc) {
      final Map<String, dynamic> data = doc.data();

      final String redemptionStudentUid =
          (data['studentUid'] ?? '').toString();

      final String redemptionStudentId =
          (data['studentId'] ?? '').toString();

      final String redemptionStudentNumber =
          (data['studentNumber'] ?? '').toString();

      return redemptionStudentUid == studentUid ||
          redemptionStudentId == studentUid ||
          redemptionStudentId == studentId ||
          redemptionStudentNumber == studentId;
    }).map((doc) {
      final Map<String, dynamic> data = doc.data();

      final String rewardTitle = (data['rewardTitle'] ?? '-').toString();
      final String status = (data['status'] ?? 'pending').toString();

      return MyVoucherItem(
        id: doc.id,
        rewardId: (data['rewardId'] ?? '').toString(),
        rewardTitle: rewardTitle,
        code: (data['redeemCode'] ?? '-').toString(),
        cost: toInt(data['pointsUsed']),
        status: mapVoucherStatus(status),
        redeemedAt: formatDate(data['createdAt']),
        icon: rewardIcon(rewardTitle, rewardTitle),
      );
    }).toList();

    return items;
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is String) {
      final String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleaned) ?? 0;
    }

    return 0;
  }

  int getSubmissionSortMillis(Map<String, dynamic> data) {
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

  String formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String mapSubmissionStatus(String status) {
    final String normalized = status
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    if (normalized == 'approved' ||
        normalized == 'accepted' ||
        normalized == 'disetujui') {
      return 'Disetujui';
    }

    if (normalized == 'rejected' ||
        normalized == 'ejected' ||
        normalized == 'ditolak' ||
        normalized == 'failed' ||
        normalized == 'gagal' ||
        normalized == 'cancelled' ||
        normalized == 'canceled') {
      return 'Ditolak';
    }

    if (normalized == 'submitted' ||
        normalized == 'pending' ||
        normalized == 'menunggu_review' ||
        normalized == 'waiting_review' ||
        normalized == 'in_review' ||
        normalized == 'review') {
      return 'Menunggu Review';
    }

    return 'Belum Submit';
  }

  String mapVoucherStatus(String status) {
    if (status == 'pending') return 'Pending Claim';
    if (status == 'claimed') return 'Claimed';

    return status;
  }

  String detectChallengeCategory(String title, String description) {
    final String value = '$title $description'.toLowerCase();

    if (value.contains('harian') || value.contains('today')) return 'Harian';
    if (value.contains('mingguan') || value.contains('week')) return 'Mingguan';
    if (value.contains('teman') || value.contains('ajak')) return 'Sosial';

    if (value.contains('pohon') ||
        value.contains('bersih') ||
        value.contains('sampah') ||
        value.contains('lingkungan')) {
      return 'Lingkungan';
    }

    return 'Harian';
  }

  String detectRewardCategory(String title, String description) {
    final String value = '$title $description'.toLowerCase();

    if (value.contains('makan') ||
        value.contains('kantin') ||
        value.contains('kopi')) {
      return 'Makanan';
    }

    if (value.contains('voucher') ||
        value.contains('diskon') ||
        value.contains('discount')) {
      return 'Voucher';
    }

    if (value.contains('donasi') || value.contains('pohon')) {
      return 'Donasi';
    }

    return 'Merchandise';
  }

  String detectDifficulty(int points) {
    if (points <= 50) return 'Mudah';
    if (points <= 150) return 'Sedang';

    return 'Sulit';
  }

  IconData challengeIcon(String title, String description) {
    final String value = '$title $description'.toLowerCase();

    if (value.contains('tumbler')) return Icons.local_drink_outlined;
    if (value.contains('foto')) return Icons.camera_alt_rounded;
    if (value.contains('bersih')) return Icons.cleaning_services_rounded;
    if (value.contains('pohon') || value.contains('tanam')) {
      return Icons.park_rounded;
    }
    if (value.contains('teman') || value.contains('ajak')) {
      return Icons.groups_rounded;
    }
    if (value.contains('sampah')) return Icons.delete_outline_rounded;

    return Icons.emoji_events_rounded;
  }

  IconData rewardIcon(String title, String description) {
    final String value = '$title $description'.toLowerCase();

    if (value.contains('makan') || value.contains('kantin')) {
      return Icons.restaurant_rounded;
    }

    if (value.contains('tumbler') || value.contains('botol')) {
      return Icons.local_drink_rounded;
    }

    if (value.contains('tas') || value.contains('bag')) {
      return Icons.shopping_bag_rounded;
    }

    if (value.contains('print') || value.contains('fotokopi')) {
      return Icons.print_rounded;
    }

    if (value.contains('pohon') || value.contains('donasi')) {
      return Icons.eco_rounded;
    }

    if (value.contains('kaos') || value.contains('shirt')) {
      return Icons.checkroom_rounded;
    }

    return Icons.card_giftcard_rounded;
  }

  void showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be added soon.'),
      ),
    );
  }

  void openChallengeSubmission(ChallengeItem challenge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeSubmissionPage(
          challengeId: challenge.id,
          challengeTitle: challenge.title,
          challengeDescription: challenge.description,
          points: '+${challenge.points} pts',
          icon: challenge.icon,
        ),
      ),
    ).then((_) {
      loadData();
    });
  }

  void showRedeemConfirmation(RewardItem reward) {
    final bool canRedeem =
        reward.isAvailable && reward.stock > 0 && myPoints >= reward.cost;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(34),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9FBE8),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(
                  reward.icon,
                  size: 34,
                  color: const Color(0xFF0F8A5F),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                reward.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                reward.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 22),
              _RedeemInfoRow(
                label: 'Poin dibutuhkan',
                value: '${reward.cost} pts',
              ),
              const SizedBox(height: 10),
              _RedeemInfoRow(
                label: 'Poin kamu',
                value: '$myPoints pts',
              ),
              const SizedBox(height: 10),
              _RedeemInfoRow(
                label: 'Stok',
                value: '${reward.stock}',
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: canRedeem
                      ? () {
                          Navigator.pop(context);
                          redeemReward(reward);
                        }
                      : null,
                  icon: const Icon(Icons.card_giftcard_rounded),
                  label: Text(
                    canRedeem ? 'Tukar Reward' : 'Tidak Bisa Ditukar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F8A5F),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> redeemReward(RewardItem reward) async {
    final User? user = auth.currentUser;

    if (user == null || studentData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User belum login.'),
        ),
      );
      return;
    }

    if (myPoints < reward.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poin kamu belum cukup.'),
        ),
      );
      return;
    }

    if (!reward.isAvailable || reward.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reward tidak tersedia.'),
        ),
      );
      return;
    }

    final String redeemCode =
        'ECO-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

    try {
      final DocumentReference<Map<String, dynamic>> rewardRef =
          firestore.collection('rewards').doc(reward.id);

      final DocumentReference<Map<String, dynamic>> userRef =
          firestore.collection('users').doc(user.uid);

      final DocumentReference<Map<String, dynamic>> redemptionRef =
          firestore.collection('rewardRedemptions').doc();

      await firestore.runTransaction((transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> rewardSnapshot =
            await transaction.get(rewardRef);

        final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await transaction.get(userRef);

        if (!rewardSnapshot.exists) {
          throw Exception('Reward tidak ditemukan.');
        }

        if (!userSnapshot.exists) {
          throw Exception('User tidak ditemukan.');
        }

        final Map<String, dynamic> rewardData = rewardSnapshot.data() ?? {};
        final Map<String, dynamic> userData = userSnapshot.data() ?? {};

        final int currentStock = toInt(rewardData['stock']);
        final int currentPoints = toInt(userData['points']);
        final int pointsRequired = toInt(rewardData['pointsRequired']);

        if (currentStock <= 0) {
          throw Exception('Stok reward habis.');
        }

        if (currentPoints < pointsRequired) {
          throw Exception('Poin tidak cukup.');
        }

        transaction.set(redemptionRef, {
          'rewardId': reward.id,
          'rewardTitle': reward.title,

          'studentId': user.uid,
          'studentUid': user.uid,
          'studentNumber': (studentData?['studentId'] ?? '').toString(),
          'studentName': (studentData?['name'] ?? 'Mahasiswa').toString(),
          'studentEmail': (studentData?['email'] ?? user.email ?? '').toString(),

          'pointsUsed': pointsRequired,
          'redeemCode': redeemCode,
          'status': 'pending',

          'universityId': (studentData?['universityId'] ?? '').toString(),
          'universityName': (studentData?['universityName'] ?? '').toString(),
          'universityShortName':
              (studentData?['universityShortName'] ?? '').toString(),

          'departmentId': (studentData?['departmentId'] ?? '').toString(),
          'departmentName': (studentData?['departmentName'] ?? '').toString(),

          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),

          'claimedAt': null,
          'claimedBy': null,
        });

        transaction.update(rewardRef, {
          'stock': currentStock - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(userRef, {
          'points': currentPoints - pointsRequired,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      showRedeemSuccessDialog(
        reward: reward,
        redeemCode: redeemCode,
      );

      await loadData();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menukar reward: $error'),
        ),
      );
    }
  }

  void showRedeemSuccessDialog({
    required RewardItem reward,
    required String redeemCode,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9FBE8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 42,
                    color: Color(0xFF0F8A5F),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Redeem Berhasil!',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tunjukkan kode ini ke admin untuk mengambil ${reward.title}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F3),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFD1FAE5),
                    ),
                  ),
                  child: Text(
                    redeemCode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F8A5F),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      setState(() {
                        selectedTabIndex = 2;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F8A5F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Lihat Voucher Saya',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
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

  void copyVoucherCode(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kode $code disalin.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7FBF8),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0F8A5F),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF0F8A5F),
          onRefresh: loadData,
          child: Column(
            children: [
              _buildHeader(),
              _buildTabSwitcher(),
              Expanded(
                child: selectedTabIndex == 0
                    ? _buildChallengeContent()
                    : selectedTabIndex == 1
                        ? _buildRewardContent()
                        : _buildVoucherContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      decoration: const BoxDecoration(
        color: Color(0xFF0F8A5F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reward & Challenge',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              _HeaderButton(
                icon: Icons.leaderboard_rounded,
                onTap: () => showComingSoon('Leaderboard'),
              ),
              const SizedBox(width: 10),
              _HeaderButton(
                icon: Icons.workspace_premium_rounded,
                onTap: () => showComingSoon('Badges'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeaderStatCard(
                  title: 'Eco Points',
                  value: '$myPoints',
                  icon: Icons.star_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderStatCard(
                  title: 'Approved',
                  value: '$completedChallengeCount',
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderStatCard(
                  title: 'Voucher',
                  value: '$pendingVoucherCount',
                  icon: Icons.confirmation_number_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Challenge',
            icon: Icons.emoji_events_rounded,
            isActive: selectedTabIndex == 0,
            onTap: () {
              setState(() {
                selectedTabIndex = 0;
              });
            },
          ),
          _TabButton(
            label: 'Reward',
            icon: Icons.card_giftcard_rounded,
            isActive: selectedTabIndex == 1,
            onTap: () {
              setState(() {
                selectedTabIndex = 1;
              });
            },
          ),
          _TabButton(
            label: 'Voucher',
            icon: Icons.confirmation_number_rounded,
            isActive: selectedTabIndex == 2,
            onTap: () {
              setState(() {
                selectedTabIndex = 2;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeContent() {
    if (challenges.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(22, 60, 22, 110),
        children: const [
          _EmptyDataWidget(
            icon: Icons.emoji_events_outlined,
            title: 'Belum ada challenge',
            description: 'Challenge dari admin akan tampil di sini.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 110),
      children: [
        _buildCategoryFilter(
          categories: challengeCategories,
          selectedCategory: selectedChallengeCategory,
          onSelected: (value) {
            setState(() {
              selectedChallengeCategory = value;
            });
          },
        ),
        const SizedBox(height: 20),
        ...filteredChallenges.map(
          (challenge) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ChallengeCard(
              item: challenge,
              onSubmit: () => openChallengeSubmission(challenge),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardContent() {
    if (rewards.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(22, 60, 22, 110),
        children: const [
          _EmptyDataWidget(
            icon: Icons.card_giftcard_rounded,
            title: 'Belum ada reward',
            description: 'Reward dari web admin akan tampil di sini.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 110),
      children: [
        _buildCategoryFilter(
          categories: rewardCategories,
          selectedCategory: selectedRewardCategory,
          onSelected: (value) {
            setState(() {
              selectedRewardCategory = value;
            });
          },
        ),
        const SizedBox(height: 20),
        GridView.builder(
          itemCount: filteredRewards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.60,
          ),
          itemBuilder: (context, index) {
            final RewardItem reward = filteredRewards[index];

            return _RewardCard(
              item: reward,
              canRedeem:
                  myPoints >= reward.cost && reward.stock > 0 && reward.isAvailable,
              onTap: () => showRedeemConfirmation(reward),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVoucherContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 110),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFD9FBE8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFBBF7D0),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF0F8A5F),
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tunjukkan kode voucher ini ke admin untuk mengambil reward. Status akan berubah menjadi Claimed setelah admin memvalidasi kode.',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Voucher Saya',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Text(
              '${myVouchers.length} voucher',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (myVouchers.isEmpty)
          const _EmptyDataWidget(
            icon: Icons.confirmation_number_outlined,
            title: 'Belum ada voucher',
            description: 'Voucher hasil penukaran reward akan muncul di sini.',
          )
        else
          ...myVouchers.map(
            (voucher) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _VoucherCard(
                voucher: voucher,
                onCopy: () => copyVoucherCode(voucher.code),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryFilter({
    required List<String> categories,
    required String selectedCategory,
    required ValueChanged<String> onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final bool isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onSelected(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F8A5F) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0F8A5F)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F8A5F).withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _HeaderStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.0,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF14532D).withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    isActive ? const Color(0xFF0F8A5F) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: isActive
                        ? const Color(0xFF0F8A5F)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeItem item;
  final VoidCallback onSubmit;

  const _ChallengeCard({
    required this.item,
    required this.onSubmit,
  });

  bool get canSubmit {
    return item.submissionStatus == 'Belum Submit' ||
        item.submissionStatus == 'Ditolak';
  }

  Color get statusColor {
    switch (item.submissionStatus) {
      case 'Belum Submit':
        return const Color(0xFF64748B);
      case 'Menunggu Review':
        return const Color(0xFFB7791F);
      case 'Disetujui':
        return const Color(0xFF0F8A5F);
      case 'Ditolak':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get statusBackground {
    switch (item.submissionStatus) {
      case 'Belum Submit':
        return const Color(0xFFF1F5F3);
      case 'Menunggu Review':
        return const Color(0xFFFFF7D6);
      case 'Disetujui':
        return const Color(0xFFD9FBE8);
      case 'Ditolak':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F3);
    }
  }

  IconData get actionIcon {
    switch (item.submissionStatus) {
      case 'Belum Submit':
        return Icons.add_rounded;
      case 'Menunggu Review':
        return Icons.schedule_rounded;
      case 'Disetujui':
        return Icons.check_rounded;
      case 'Ditolak':
        return Icons.refresh_rounded;
      default:
        return Icons.add_rounded;
    }
  }

  Color get actionBackground {
    if (canSubmit) {
      return Colors.white;
    }

    if (item.submissionStatus == 'Disetujui') {
      return const Color(0xFF0F8A5F);
    }

    return const Color(0xFFF1F5F3);
  }

  Color get actionBorderColor {
    if (canSubmit) {
      return const Color(0xFFD1D5DB);
    }

    if (item.submissionStatus == 'Disetujui') {
      return const Color(0xFF0F8A5F);
    }

    return const Color(0xFFE2E8F0);
  }

  Color get actionIconColor {
    if (canSubmit) {
      return const Color(0xFF64748B);
    }

    if (item.submissionStatus == 'Disetujui') {
      return Colors.white;
    }

    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    final bool isApproved = item.submissionStatus == 'Disetujui';

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color:
                  isApproved ? const Color(0xFFD9FBE8) : const Color(0xFFF1F5F3),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              item.icon,
              size: 29,
              color:
                  isApproved ? const Color(0xFF0F8A5F) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color:
                        isApproved ? const Color(0xFF64748B) : const Color(0xFF111827),
                    decoration: isApproved ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SmallChip(
                      label: '+${item.points} pts',
                      color: const Color(0xFFFFF7D6),
                      textColor: const Color(0xFFB7791F),
                    ),
                    _SmallChip(
                      label: item.difficulty,
                      color: const Color(0xFFF1F5F3),
                      textColor: const Color(0xFF64748B),
                    ),
                    _SmallChip(
                      label: item.submissionStatus,
                      color: statusBackground,
                      textColor: statusColor,
                    ),
                  ],
                ),
                if (item.adminNote.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.adminNote,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: canSubmit ? onSubmit : null,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: actionBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: actionBorderColor,
                  width: 2,
                ),
              ),
              child: Icon(
                actionIcon,
                color: actionIconColor,
                size: 27,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final RewardItem item;
  final bool canRedeem;
  final VoidCallback onTap;

  const _RewardCard({
    required this.item,
    required this.canRedeem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = item.stock <= 0 || !item.isAvailable;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? const Color(0xFFF1F5F3)
                        : const Color(0xFFD9FBE8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    item.icon,
                    size: 25,
                    color: isOutOfStock
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F8A5F),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? const Color(0xFFF1F5F3)
                        : const Color(0xFFFFF7D6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isOutOfStock ? 'Habis' : '${item.stock} stok',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isOutOfStock
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFFB7791F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.3,
                color: Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7D6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${item.cost} pts',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFB7791F),
                ),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: canRedeem ? onTap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F8A5F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  isOutOfStock ? 'Tidak tersedia' : 'Tukar',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

class _VoucherCard extends StatelessWidget {
  final MyVoucherItem voucher;
  final VoidCallback onCopy;

  const _VoucherCard({
    required this.voucher,
    required this.onCopy,
  });

  Color get statusColor {
    switch (voucher.status) {
      case 'Pending Claim':
        return const Color(0xFFB7791F);
      case 'Claimed':
        return const Color(0xFF0F8A5F);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get statusBackground {
    switch (voucher.status) {
      case 'Pending Claim':
        return const Color(0xFFFFF7D6);
      case 'Claimed':
        return const Color(0xFFD9FBE8);
      default:
        return const Color(0xFFF1F5F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isClaimed = voucher.status == 'Claimed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClaimed ? const Color(0xFFF8FAF9) : Colors.white,
        borderRadius: BorderRadius.circular(28),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isClaimed
                      ? const Color(0xFFF1F5F3)
                      : const Color(0xFFD9FBE8),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  voucher.icon,
                  color: isClaimed
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0F8A5F),
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.rewardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isClaimed
                            ? const Color(0xFF64748B)
                            : const Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${voucher.redeemedAt} • ${voucher.cost} pts',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  voucher.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: isClaimed ? null : onCopy,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: isClaimed
                    ? const Color(0xFFF1F5F3)
                    : const Color(0xFFF8FAF9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isClaimed
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFFD1FAE5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    color: isClaimed
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F8A5F),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      voucher.code,
                      style: TextStyle(
                        color: isClaimed
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0F8A5F),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  Icon(
                    isClaimed ? Icons.check_circle_rounded : Icons.copy_rounded,
                    color: isClaimed
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _SmallChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }
}

class _RedeemInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _RedeemInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EmptyDataWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyDataWidget({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFD9FBE8),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0F8A5F),
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}