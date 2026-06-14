import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RewardHistoryPage extends StatefulWidget {
  const RewardHistoryPage({super.key});

  @override
  State<RewardHistoryPage> createState() => _RewardHistoryPageState();
}

class _RewardHistoryPageState extends State<RewardHistoryPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  String? errorMessage;

  List<_RewardHistoryItem> histories = [];

  @override
  void initState() {
    super.initState();
    loadRewardHistory();
  }

  Future<void> loadRewardHistory() async {
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

      String studentId = '';
      String studentEmail = user.email ?? '';

      try {
        final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await firestore.collection('users').doc(user.uid).get();

        final Map<String, dynamic> userData = userSnapshot.data() ?? {};

        studentId = getString(userData, 'studentId', fallback: '');
        studentEmail = getString(
          userData,
          'email',
          fallback: user.email ?? '',
        );
      } catch (_) {}

      final Map<String, _RewardHistoryItem> historyMap = {};

      Future<void> fetchByField(String field, String value) async {
        if (value.trim().isEmpty) return;

        try {
          final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
              .collection('rewardRedemptions')
              .where(field, isEqualTo: value)
              .get();

          for (final doc in snapshot.docs) {
            historyMap[doc.id] = _RewardHistoryItem.fromFirestore(
              id: doc.id,
              data: doc.data(),
            );
          }
        } catch (_) {}
      }

      await fetchByField('studentUid', user.uid);
      await fetchByField('userId', user.uid);
      await fetchByField('uid', user.uid);
      await fetchByField('studentId', user.uid);
      await fetchByField('studentId', studentId);
      await fetchByField('studentEmail', studentEmail);

      final List<_RewardHistoryItem> loadedHistories =
          historyMap.values.toList();

      loadedHistories.sort((a, b) {
        return b.createdAtMillis.compareTo(a.createdAtMillis);
      });

      if (!mounted) return;

      setState(() {
        histories = loadedHistories;
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

  int getTotalPointsUsed() {
    int total = 0;

    for (final item in histories) {
      total += item.pointsCost;
    }

    return total;
  }

  int getActiveCodeCount() {
    return histories.where((item) => item.isActiveCode).length;
  }

  String formatNumber(int number) {
    final String text = number.toString();

    return text.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
  }

  void copyRedeemCode(String code) {
    if (code.trim().isEmpty || code == '-') {
      showMessage('Kode redeem tidak tersedia.');
      return;
    }

    Clipboard.setData(
      ClipboardData(text: code),
    );

    showMessage('Kode redeem berhasil disalin.');
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0F8A5F),
                onRefresh: loadRewardHistory,
                child: histories.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 16),
                          _buildStatsRow(),
                          const SizedBox(height: 24),
                          _buildSectionTitle(),
                          const SizedBox(height: 14),
                          ...histories.map(
                            (item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _RewardHistoryCard(
                                  item: item,
                                  formatNumber: formatNumber,
                                  onCopyCode: () {
                                    copyRedeemCode(item.redeemCode);
                                  },
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
                  'Reward History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Riwayat penukaran reward kamu',
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
            onTap: loadRewardHistory,
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

  Widget _buildSummaryCard() {
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
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${histories.length} Reward Ditukar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Total ${formatNumber(getTotalPointsUsed())} poin digunakan untuk reward.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _RewardStatCard(
            icon: Icons.history_rounded,
            value: histories.length.toString(),
            label: 'Total',
            color: const Color(0xFF0F8A5F),
            background: const Color(0xFFD9FBE8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RewardStatCard(
            icon: Icons.confirmation_number_outlined,
            value: getActiveCodeCount().toString(),
            label: 'Active Code',
            color: const Color(0xFF087EA4),
            background: const Color(0xFFE0F4FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RewardStatCard(
            icon: Icons.star_rounded,
            value: formatNumber(getTotalPointsUsed()),
            label: 'Points Used',
            color: const Color(0xFFB7791F),
            background: const Color(0xFFFFF4BA),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Redeem List',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFD9FBE8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${histories.length} item',
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
                  Icons.card_giftcard_rounded,
                  color: Color(0xFFB7791F),
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Belum ada reward history',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Reward yang kamu tukar akan muncul di sini beserta kode redeem dan status klaimnya.',
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
                        'Mengambil reward history...',
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
                        'Gagal mengambil history',
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
                          onPressed: loadRewardHistory,
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

class _RewardHistoryItem {
  final String id;
  final String rewardTitle;
  final String rewardDescription;
  final String redeemCode;
  final String status;
  final int pointsCost;
  final int createdAtMillis;
  final String createdAtText;

  const _RewardHistoryItem({
    required this.id,
    required this.rewardTitle,
    required this.rewardDescription,
    required this.redeemCode,
    required this.status,
    required this.pointsCost,
    required this.createdAtMillis,
    required this.createdAtText,
  });

  factory _RewardHistoryItem.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final String rewardTitle = pickString(
      data,
      [
        'rewardTitle',
        'rewardName',
        'title',
        'name',
      ],
      fallback: 'Reward EcoCampus',
    );

    final String rewardDescription = pickString(
      data,
      [
        'rewardDescription',
        'description',
        'rewardDetail',
      ],
      fallback: 'Reward yang sudah kamu tukar.',
    );

    final String redeemCode = pickString(
      data,
      [
        'redeemCode',
        'redemptionCode',
        'claimCode',
        'code',
      ],
      fallback: '-',
    );

    final String status = pickString(
      data,
      [
        'status',
        'redemptionStatus',
        'claimStatus',
      ],
      fallback: 'pending',
    );

    final int pointsCost = pickInt(
      data,
      [
        'pointsCost',
        'pointsUsed',
        'pointCost',
        'cost',
        'points',
      ],
    );

    final dynamic createdAtValue = pickValue(
      data,
      [
        'createdAt',
        'redeemedAt',
        'requestedAt',
        'updatedAt',
      ],
    );

    final int createdAtMillis = getCreatedAtMillis(createdAtValue);
    final String createdAtText = formatDate(createdAtValue);

    return _RewardHistoryItem(
      id: id,
      rewardTitle: rewardTitle,
      rewardDescription: rewardDescription,
      redeemCode: redeemCode,
      status: status,
      pointsCost: pointsCost,
      createdAtMillis: createdAtMillis,
      createdAtText: createdAtText,
    );
  }

  bool get isActiveCode {
    final String cleanStatus = status.toLowerCase().trim();

    return cleanStatus != 'claimed' &&
        cleanStatus != 'used' &&
        cleanStatus != 'expired' &&
        cleanStatus != 'cancelled' &&
        cleanStatus != 'canceled' &&
        cleanStatus != 'rejected';
  }

  String get normalizedStatus {
    final String cleanStatus = status.toLowerCase().trim();

    if (cleanStatus == 'claimed') return 'Claimed';
    if (cleanStatus == 'used') return 'Used';
    if (cleanStatus == 'expired') return 'Expired';
    if (cleanStatus == 'cancelled' || cleanStatus == 'canceled') {
      return 'Cancelled';
    }
    if (cleanStatus == 'rejected') return 'Rejected';
    if (cleanStatus == 'approved') return 'Approved';
    if (cleanStatus == 'redeemed') return 'Redeemed';
    if (cleanStatus == 'pending') return 'Pending';

    return status.isEmpty ? 'Pending' : status;
  }

  static dynamic pickValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final dynamic value = data[key];

      if (value != null) return value;
    }

    return null;
  }

  static String pickString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final key in keys) {
      final dynamic value = data[key];

      if (value == null) continue;

      final String text = value.toString().trim();

      if (text.isNotEmpty) return text;
    }

    return fallback;
  }

  static int pickInt(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
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

  static int getCreatedAtMillis(dynamic value) {
    if (value == null) return 0;

    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }

    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }

    return 0;
  }

  static String formatDate(dynamic value) {
    if (value == null) return '-';

    DateTime? dateTime;

    if (value is Timestamp) {
      dateTime = value.toDate();
    } else if (value is DateTime) {
      dateTime = value;
    }

    if (dateTime == null) return '-';

    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();

    return '$day/$month/$year';
  }
}

class _RewardHistoryCard extends StatelessWidget {
  final _RewardHistoryItem item;
  final String Function(int number) formatNumber;
  final VoidCallback onCopyCode;

  const _RewardHistoryCard({
    required this.item,
    required this.formatNumber,
    required this.onCopyCode,
  });

  Color getStatusColor() {
    final String status = item.status.toLowerCase().trim();

    if (status == 'claimed' || status == 'used' || status == 'approved') {
      return const Color(0xFF0F8A5F);
    }

    if (status == 'expired' ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'rejected') {
      return const Color(0xFFEF4444);
    }

    if (status == 'pending' || status == 'redeemed') {
      return const Color(0xFFB7791F);
    }

    return const Color(0xFF64748B);
  }

  Color getStatusBackground() {
    final String status = item.status.toLowerCase().trim();

    if (status == 'claimed' || status == 'used' || status == 'approved') {
      return const Color(0xFFD9FBE8);
    }

    if (status == 'expired' ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'rejected') {
      return const Color(0xFFFEE2E2);
    }

    if (status == 'pending' || status == 'redeemed') {
      return const Color(0xFFFFF4BA);
    }

    return const Color(0xFFF1F5F9);
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = getStatusColor();
    final Color statusBackground = getStatusBackground();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4BA),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFFB7791F),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBackground,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.normalizedStatus.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.createdAtText,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      item.rewardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.rewardDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.8,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: Color(0xFF0F8A5F),
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.redeemCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onCopyCode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9FBE8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Copy',
                      style: TextStyle(
                        color: Color(0xFF0F8A5F),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFB7791F),
                size: 20,
              ),
              const SizedBox(width: 7),
              Text(
                '${formatNumber(item.pointsCost)} points used',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                item.isActiveCode ? 'Kode aktif' : 'Sudah tidak aktif',
                style: TextStyle(
                  color: item.isActiveCode
                      ? const Color(0xFF0F8A5F)
                      : const Color(0xFF94A3B8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  const _RewardStatCard({
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